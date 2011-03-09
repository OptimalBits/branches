//
//  CCDiffViewController.m
//  gitfend
//
//  Created by Manuel Astudillo on 9/10/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "CCDiffViewController.h"
#import "CCDiffViewModel.h"
#import "CCDiffView.h"
#import "CCDiff.h"
#import "NSColor+OBSDiff.h"

#import "NSString+OBSDiff.h"

#include <Carbon/Carbon.h>

#import "OBSScrollViewAnimation.h"

// #import "NSTextView+Wrapping.h"

// references:
//	http://developer.apple.com/documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html#//apple_ref/doc/uid/20000938-164652-BCIDFBBH
//	http://www.cocoabuilder.com/archive/message/cocoa/2003/12/28/89458


static NSRange getOldRange( NSRange newRange, NSInteger delta );

static NSRange lineRangeFromCharRange( NSArray *lines,
									   NSUInteger startLineIndex, 
									   NSRange charRange );

static NSString *getSubstringFromLineRange( NSArray *lines, 
										    NSRange lineRange,
										    NSUInteger *numEmptyLines );

static NSRange expandRangeIncludingEmptyLines( NSArray *lines, 
											   NSRange lineRange );

static NSRange charRangeFromLines( NSArray *lines, NSRange lineRange );

@implementation CCDiffViewController

- (id) init
{
	if ( self = [super initWithNibName:@"DiffView" bundle:nil] )
    {
		[self setTitle:@"DiffView"];
		
		allowMoveHunkMarker = YES;
		font = [[NSFont fontWithName:@"Menlo-Regular" size:11.0] retain];
	}
	return self;
}

- (void) dealloc
{
	[font release];
	[leftView release];
	[rightView release];
	[leftScrollView release];
	[rightScrollView release];

	[super dealloc];
}

- (void) awakeFromNib
{
	leftScrollViewAnimator = 
		[[OBSScrollViewAnimation alloc] initWithScrollView:leftScrollView
												  duration:0.3
											animationCurve:NSAnimationEaseInOut];
	[leftScrollViewAnimator setDelegate:self];

	rightScrollViewAnimator = 
		[[OBSScrollViewAnimation alloc] initWithScrollView:rightScrollView
												  duration:0.3
											animationCurve:NSAnimationEaseInOut];
	[rightScrollViewAnimator setDelegate:self];
	
	[self gotoDiff];
}


-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
	SEL action = [toolbarItem action];
	
    if ( (action == @selector(mergeLeft:)) ||
		 (action == @selector(mergeRight:)) )
	{
		if ( allowMoveHunkMarker )
		{
			if ( leftView && [leftView selectedHunkIndex] >= 0 )
			{
				return YES;
			}
		}
		return NO;
	} 
	else if (action == @selector(nextDiff:)) 
	{
		if ( leftView && [leftView nextHunk] )
		{
			return YES;
		}
		else
		{
			return NO;
		}
	} 
	else if (action == @selector(prevDiff:)) 
	{
		if ( [leftView prevHunk] )
		{
			return YES;
		}
		else
		{
			return NO;
		}
	} 
	
	return NO;
}


-(void) animationDidEnd:(NSAnimation*) animation
{
	[self bindScrollViews];
}

-(void) animationDidStop:(NSAnimation*) animation
{
	[self bindScrollViews];
}

-(void) bindScrollViews
{
	// Register notifications used to keep the text views synchronized.
	[leftScrollView setPostsBoundsChangedNotifications:YES];
	[rightScrollView setPostsBoundsChangedNotifications:YES];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:[leftScrollView contentView]];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:[rightScrollView contentView]];	
}

-(void) unbindScrollViews
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSViewBoundsDidChangeNotification 
												  object:[leftScrollView contentView]];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSViewBoundsDidChangeNotification 
												  object:[rightScrollView contentView]];	
}


-(void) setStringsBefore:(NSString*) before andAfter:(NSString*) after
{
	CCDiff *diff = 
		[[[CCDiff alloc] initWithBefore:before andAfter:after] autorelease];
	
	[diffViewModel release];
	[leftView release];
	[rightView release];
	
	diffViewModel = [[CCDiffViewModel alloc] initWithDiffLines:[diff diff]];
	
	leftView = [[CCDiffView alloc] initWithScrollView:leftScrollView
												 font:font
												lines:[diffViewModel leftLines]
												 mask:CCDiffViewLineOriginal|CCDiffViewLineRemoved
										   controller:self];
	
	rightView =[[CCDiffView alloc] initWithScrollView:rightScrollView
												 font:font
								 				lines:[diffViewModel rightLines]
												 mask:CCDiffViewLineOriginal|CCDiffViewLineAdded
										   controller:self];
	
	[[leftView textStorage] setDelegate:self];
	[[rightView textStorage] setDelegate:self];
	
	[self bindScrollViews];
}


-(void) keyDown:(NSEvent *)theEvent
{
	unsigned short keyCode = [theEvent keyCode];
	
	switch( keyCode )
	{
		case kVK_DownArrow:
			
 			[leftView moveToNextDiff];
			
			 break;
			
		case kVK_UpArrow:
			[leftView moveToPreviousDiff];

			break;
	}
}

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification
{
	NSScrollView *scrollView;
	
	if ( [leftScrollViewAnimator isAnimating] ||
		 [rightScrollViewAnimator isAnimating] )
	{
		return;
	}
	
	if ( NSEqualPoints( [[leftScrollView contentView] bounds].origin,
						[[rightScrollView contentView] bounds].origin ) )
	{
		return;
	}
	
    NSClipView *changedContentView = [notification object];
	
    NSPoint changedBoundsOrigin = 
		[changedContentView documentVisibleRect].origin;
	
    if ( [leftScrollView contentView] != changedContentView )
	{
		scrollView = leftScrollView;
	}
	else
	{
		scrollView = rightScrollView;
	}

	[[scrollView contentView] scrollToPoint:changedBoundsOrigin];
	[scrollView reflectScrolledClipView:[scrollView contentView]];
}

-(void) gotoDiff
{
	NSInteger index;
	
	index = [leftView selectedHunkIndex];
	NSAssert( index == [rightView selectedHunkIndex], @"index missmatch" );
	
	[self gotoDiffIndex:index];
	
	allowMoveHunkMarker = YES;
}

-(void) gotoDiffIndex:(NSUInteger) index
{	
#if 0
	if ( [leftScrollViewAnimator isAnimating] )
	{
		[leftScrollViewAnimator stopAnimation];
	}
	if ( [rightScrollViewAnimator isAnimating] )
	{
		[rightScrollViewAnimator stopAnimation];
	}
	
	[leftScrollViewAnimator scrollToPoint:[leftView hunkOrigin:index]];		
	[rightScrollViewAnimator scrollToPoint:[rightView hunkOrigin:index]];
#else
	[leftView setSelectedHunkIndex:index];
	[rightView setSelectedHunkIndex:index];
	
	[[leftScrollView contentView] scrollToPoint:[leftView hunkOrigin:index]];
	[[rightScrollView contentView] scrollToPoint:[rightView hunkOrigin:index]];
	[leftScrollView reflectScrolledClipView:[leftScrollView contentView]];
	[rightScrollView reflectScrolledClipView:[rightScrollView contentView]];
	[rightView setNeedsDisplayInRect:[rightScrollView documentVisibleRect] 
			   avoidAdditionalLayout:NO];
	[leftView setNeedsDisplayInRect:[leftScrollView documentVisibleRect] 
			   avoidAdditionalLayout:NO];
#endif
}

- (IBAction) nextDiff:(id) sender
{
	if ( allowMoveHunkMarker )
	{
		[leftView moveToNextDiff];
		[rightView moveToNextDiff];
	}
	[self gotoDiff];
}

- (IBAction) prevDiff:(id) sender
{
	[leftView moveToPreviousDiff];
	[rightView moveToPreviousDiff];
	[self gotoDiff];
}

- (IBAction) mergeRight:(id) sender
{
	[self merge:leftView to: rightView];
}

- (IBAction) mergeLeft:(id) sender
{
	[self merge:rightView to: leftView];
}

- (void) merge:(CCDiffView*) srcView to:(CCDiffView*) dstView
{
	[srcView mergeTo:dstView];
	allowMoveHunkMarker = NO;
}

- (void) setHunkSelector:(NSInteger) index
{
	[rightView setSelectedHunkMarker:index];
	[leftView setSelectedHunkMarker:index];
	
	[rightView setNeedsDisplayInRect:[rightScrollView documentVisibleRect]
		  avoidAdditionalLayout:YES];
	[leftView setNeedsDisplayInRect:[leftScrollView documentVisibleRect]
		  avoidAdditionalLayout:YES];
}

/*
-(NSArray*) modifiedLines:(NSTextStorage*) storage
			   startIndex:(NSUInteger) startIndex
			 changeLength:(NSInteger) changeLength
{
	NSRange range;
	NSUInteger startIndex;
	NSUInteger endIndex;
	
	if ( changeLength > 0 )
	{
		range = NSMakeRange(starIndex, changeLength);
	}
	
	[[storage string] getLineStart:&startIndex 
							   end:nil
					   contentsEnd:nil 
						  forRange:range];
	
	
	
}

-(void) updateDiff:(BOOL) modifiedLeft
		 startLine:(NSUInteger) startLine
	  changeLength:(NSInteger) changeLength
{
	// Compute a new lines array for the modified storage and range.
	
}
*/


-(void) intervalIncludingEmptyLines:(NSArray*) lines
					 startLineIndex:(NSUInteger*) startLineIndex
					   endLineIndex:(NSUInteger*) endLineIndex
{
	NSInteger index;
	
	index = *startLineIndex - 1;
	
	while( index >= 0 )
	{
		CCDiffLine *line = [lines objectAtIndex:index];
		if ( [line status] != kLineEmpty )
		{
			break;
		}
		
		index --;
	}
	
	index ++;
	*startLineIndex = index;
	
	index = *endLineIndex + 1;
	
	NSUInteger count = [lines count];
	while( index < count )
	{
		CCDiffLine *line = [lines objectAtIndex:index];
		if ( [line status] != kLineEmpty )
		{
			break;
		}
		index ++;
	}
	
	index --;
	*endLineIndex = index;
}


/**
	This function updated the diff lines array with the edited string data.

 */
-(void) updateDiffLines:(CCDiffView*) modifiedView
		  originalLines:(CCDiffView*) originalView
		 startLineIndex:(NSUInteger) startLineIndex
	   oldCharLineRange:(NSRange) oldCharLineRange
			   newRange:(NSRange) newRange
			   delta:(NSInteger) delta
			  substring:(NSString*) substring
{
	CCDiff *diff;
	CCDiffViewModel *model;
	
	NSMutableArray *modifiedLines = [modifiedView lines];
	NSMutableArray *originalLines = [originalView lines];
	
	NSRange oldRange = NSMakeRange(newRange.location, newRange.length-delta);
	
	NSRange lineRange = lineRangeFromCharRange( modifiedLines,  
											    startLineIndex, 
											    oldRange );
	
	lineRange = expandRangeIncludingEmptyLines( modifiedLines, lineRange );
	
	NSUInteger numEmptyLines;
	NSString *oldString = getSubstringFromLineRange(modifiedLines, 
													lineRange,
 													&numEmptyLines );
	oldRange.length -= numEmptyLines; // HAck
	NSString *newString = 
		[oldString stringByReplacingCharactersInRange:oldRange
										   withString:substring];
	
	NSUInteger dummy;
	NSString *originalString = 
		getSubstringFromLineRange(originalLines, lineRange, &dummy);
	
	diff = [[CCDiff alloc] initWithBefore:newString andAfter:originalString];
	model = [[CCDiffViewModel alloc] initWithDiffLines:[diff diff]];
	
	NSRange oldOriginalCharRange = [originalView charRangeFromLines:lineRange];
	NSRange oldModifiedCharRange = NSMakeRange( oldCharLineRange.location, 
	 									//	   [newString length] + numEmptyLines );
											   [newString length] );
	
	[modifiedLines replaceObjectsInRange:lineRange 
					withObjectsFromArray:[model leftLines]];
		
	[originalLines replaceObjectsInRange:lineRange 
					withObjectsFromArray:[model rightLines]];
	
	lineRange.length = [[model leftLines] count];
	
	[modifiedView updateStorage:oldModifiedCharRange newLineRange:lineRange];		
	[originalView updateStorage:oldOriginalCharRange newLineRange:lineRange];
	
	[diff release];
	[model release];
}

- (void)textStorageWillProcessEditing:(NSNotification *) notification
{
	// Pass
}

-(NSUInteger) lineNumber:(CGFloat) y 
		   layoutManager:(NSLayoutManager*) layoutManager
{
	return y / [layoutManager defaultLineHeightForFont:font];
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
	NSTextStorage *storage = [notification object];
	
	NSRange editedRange = [storage editedRange];
		
	if ( storage == [leftView textStorage] )
	{
		NSRect rect;
			
		NSString *newString = 
			[[storage attributedSubstringFromRange:editedRange] string];
							
		NSRange lineCharRange = [[storage string] lineRangeForRange:editedRange];
				
		rect = [[leftView layoutManager]
					lineFragmentRectForGlyphAtIndex:lineCharRange.location
									 effectiveRange:nil];
		
		NSUInteger startLineNumber = [self lineNumber:rect.origin.y
										layoutManager:[leftView layoutManager]];
		
		NSRange newEditedRange = editedRange;
		newEditedRange.location -= lineCharRange.location;
		
		[self updateDiffLines:leftView
				originalLines:rightView
			   startLineIndex:(NSUInteger) startLineNumber
				 oldCharLineRange:lineCharRange
					 newRange:newEditedRange
						delta:[storage changeInLength]
					substring:newString];
		
		// TODO: Optimize
		[leftView generateHunks]; 		
		[rightView generateHunks];
		
		[leftView updateTrackingAreas];
		[rightView updateTrackingAreas];
		
		[leftView setSelectedRange:NSMakeRange(editedRange.location, 0)];
		
		[leftView setNeedsDisplayInRect:[leftScrollView documentVisibleRect] 
				  avoidAdditionalLayout:NO];
		[rightView setNeedsDisplayInRect:[rightScrollView documentVisibleRect] 
				   avoidAdditionalLayout:NO];
	}
	else if ( storage == [rightView textStorage] )
	{
		//NSLog(@"Right View changed");
	}
}

@end

static NSRange lineRangeFromCharRange( NSArray *lines,
									   NSUInteger startLineIndex, 
									   NSRange charRange )
{
	NSUInteger charCount = 0;
	NSUInteger totalCount = NSMaxRange(charRange);
	
	NSUInteger index = startLineIndex;
	
	// Note: sometimes we pick one extra line to handle some special use cases
	while (charCount <= totalCount)
	{
		CCDiffLine *diffLine = [lines objectAtIndex:index];
		charCount += [diffLine length] + 1;
		index++;
	};
	
	NSInteger endLineIndex = index - 1;
	
	if ( endLineIndex < startLineIndex )
	{
		endLineIndex = startLineIndex;
	}
	
	return NSMakeRange(startLineIndex, (endLineIndex - startLineIndex) + 1);
}

static NSString *getSubstringFromLineRange( NSArray *lines, 
										    NSRange lineRange,
										    NSUInteger *numEmptyLines )
{
	NSUInteger emptyLinesCounter = 0;
	
	NSMutableString *s = 
		[[[NSMutableString alloc] initWithString:@""] autorelease];
	
	for ( int i = lineRange.location; i < NSMaxRange(lineRange); i++ )
	{
		CCDiffLine *diffLine = [lines objectAtIndex:i];
		if ( [diffLine status] != kLineEmpty )
		{
			[s appendString:[diffLine line]];
			[s appendString:@"\n"];
		}
		else
		{
			emptyLinesCounter ++;
		}
	}
	
	*numEmptyLines = emptyLinesCounter;
	
	return s;
}

static NSRange expandRangeIncludingEmptyLines( NSArray *lines, 
											   NSRange lineRange )
{
	NSRange expandedRange;
	
	NSInteger index;
	
	index = lineRange.location - 1;
	
	while( index >= 0 )
	{
		CCDiffLine *line = [lines objectAtIndex:index];
		if ( [line status] != kLineEmpty )
		{
			break;
		}
		
		index --;
	}
	
	index ++;
	
	expandedRange.location = index;
	
	index = NSMaxRange(lineRange);
	
	NSUInteger count = [lines count];
	while( index < count )
	{
		CCDiffLine *line = [lines objectAtIndex:index];
		if ( [line status] != kLineEmpty )
		{
			break;
		}
		index ++;
	}
	
	index --;
	
	
	expandedRange.length = (index - expandedRange.location) + 1;
	
	return expandedRange;
}




