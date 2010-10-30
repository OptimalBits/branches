//
//  CCDiffView.m
//  gitfend
//
//  Created by Manuel Astudillo on 9/18/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "CCDiffView.h"
#import "CCDiff.h"
#import "NoodleLineNumberView.h"

#include <Carbon/Carbon.h>

@implementation CCDiffView

@synthesize selectedHunk;

- (id) initWithScrollView:(NSScrollView*) view 
					 font:(NSFont*) _font
					lines:(NSArray*) lcs
					 mask:(CCDiffViewLineMask) mask
{
	NSSize contentSize = [view contentSize];
	
	self = [super initWithFrame:NSMakeRect( 0, 0, 
										    contentSize.width, 
										    contentSize.height)];
	if ( self )
	{
		lines = [[NSMutableArray alloc] init];
		hunks = [[NSMutableArray alloc] init];
		
		selectedHunk = 0;
		
		scrollView = view;
		[scrollView retain];
		
		font = _font;
		[font retain];
		
		[self setMinSize:NSMakeSize(0.0, contentSize.height)];
		[self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		
		[self setVerticallyResizable:YES];
		
		[view setDocumentView:self];
		
		
		// Disable word wrap
		NSSize bigSize = NSMakeSize(FLT_MAX, FLT_MAX);
		
		[[self enclosingScrollView] setHasHorizontalScroller:YES];
		[self setHorizontallyResizable:YES];
		[self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		
		[[self textContainer] setContainerSize:bigSize];
		[[self textContainer] setWidthTracksTextView:NO];
		
		//
		NoodleLineNumberView *lineNumberView = 
		   [[[NoodleLineNumberView alloc] initWithScrollView:view] autorelease];
		
		[view setVerticalRulerView:lineNumberView];		
		[view setRulersVisible:YES];
		
		// Compute all the following rect arrays:
		fontBoundingRect = [font boundingRectForFont];
				
		NSDictionary *textAttr = 
		[NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
		nil];
		
		NSAttributedString *newLine = 
		   [[NSAttributedString alloc] initWithString:@"\n" attributes:textAttr];
		[newLine autorelease];
		
		NSTextStorage *storage = [self textStorage];
		
		if ( [lcs count] > 0 )
		{
			NSUInteger lineCount = 0;
			NSUInteger prevCharIndex = 0;
			NSUInteger charIndex = 0;
			CCDiffHunk hunk;
			LineDiffStatus prevStatus;
			
			prevStatus = [(CCDiffLine *)[lcs objectAtIndex:0] status];
			
			hunk.startLine = 0;
			hunk.startCharIndex = 0;
			hunk.status = prevStatus;
			
			for( CCDiffLine *line in lcs )
			{
				NSAttributedString *attributedString;
				
				attributedString = 
				[[[NSAttributedString alloc] initWithString:[line line] 
												 attributes:textAttr] autorelease];
				
				LineDiffStatus status = [line status];
				switch (status) 
				{
					case kLineAdded:
						if ( mask & CCDiffViewLineAdded )
						{
							[storage appendAttributedString:attributedString];
							[lines addObject: line];
						}
						else
						{
							[lines addObject:[CCDiffLine emptyLine:0]];
							status = kLineEmpty;
						}
						
						break;
					case kLineRemoved:
						if ( mask & CCDiffViewLineRemoved )
						{
							[storage appendAttributedString:attributedString];
							[lines addObject: line];
						}
						else
						{
							[lines addObject:[CCDiffLine emptyLine:0]];
							status = kLineEmpty;
						}
						break;
					default:
						if ( mask & CCDiffViewLineOriginal )
						{
							[storage appendAttributedString:attributedString];
							[lines addObject: line];
						}
						else
						{
							[lines addObject:[CCDiffLine emptyLine:0]];
							status = kLineEmpty;
						}
						break;
				}

				if ( ( prevStatus != status ) || 
					 ( lineCount == [lcs count]-1 ) )
				{
					hunk.endLine = lineCount - 1;
					hunk.endCharIndex = prevCharIndex;
					
					if ( hunk.status != kLineOriginal )
					{
						NSValue *hunkValue = [NSValue value: &hunk
											   withObjCType:@encode(CCDiffHunk)];
						[hunks addObject:hunkValue];
					}
					
					hunk.startLine = lineCount;
					hunk.startCharIndex = charIndex;
					
					hunk.status = status;
					
					prevStatus = status;
				}
				
				[storage appendAttributedString:newLine];
				
				prevCharIndex = charIndex;
				
				if ( status != kLineEmpty )
				{
					charIndex += [[line line] length] + 1;
				}
				else
				{
					charIndex ++;
				}
				
				lineCount++;
			}
		}
		
		// use rect = [font boundingRectForFont];
	}
	return self;
}

-(void) dealloc
{
	[hunks release];
	[lines release];
	[scrollView release];
	[font release];
	[super dealloc];
}

-(void) drawViewBackgroundInRect:(NSRect) rect
{
	[super drawViewBackgroundInRect:rect];
	
	NSUInteger startLine;
	NSUInteger endLine;
	NSUInteger index;
	
	NSUInteger charIndex;
/*
	startLine = rect.origin.y / fontBoundingRect.size.height;
	if ( startLine > 0 )
	{
		startLine --;
	}
	endLine = startLine + ( rect.size.height / fontBoundingRect.size.height );
	
//	[layoutManager boundingRectForGlyphRange:inTextContainer:]
*/	
		
//	for ( index = startLine; index < endLine; index ++ )
	/*for ( index = 0; index < [lines count]; index ++ )
	{
		CCDiffLine *line = [lines objectAtIndex:index];
		
		LineDiffStatus status = [line status];
				
		if ( ( status == kLineAdded ) || 
			 ( status == kLineRemoved ) || 
			 ( status == kLineEmpty ) )
		{
			NSRect rect = [[self layoutManager] 
				lineFragmentRectForGlyphAtIndex:charIndex effectiveRange:nil];
			
		
			NSBezierPath* path = [NSBezierPath bezierPath];
		
			[path appendBezierPathWithRoundedRect:rect xRadius:1.0 yRadius:1.0];
			
			if ( status == kLineAdded )
			{
				[[NSColor greenColor] set];
				[path fill];
			}
			else if ( status  == kLineRemoved )
			{
				[[NSColor redColor] set];
				[path fill];
			}
			else if ( status  == kLineEmpty )
			{
				[[NSColor grayColor] set];
				[path fill];
			}
		}
		 
		charIndex += [[line line] length] + 1;
	}
	*/
	
	NSLayoutManager *layoutManager = [self layoutManager];
	
	for ( index = 0; index < [hunks count]; index ++ )
	{
		CCDiffHunk hunk;
		
		[[hunks objectAtIndex:index] getValue:&hunk];
		
		LineDiffStatus status = hunk.status;
		
		if ( ( status == kLineAdded ) || 
			 ( status == kLineRemoved ) || 
			 ( status == kLineEmpty ) )
		{
			NSRect startRect = [ layoutManager
								 lineFragmentRectForGlyphAtIndex:hunk.startCharIndex
												  effectiveRange:nil];
			NSRect endRect = [ layoutManager
							   lineFragmentRectForGlyphAtIndex:hunk.endCharIndex
							   effectiveRange:nil ];
			
			NSRect rect = NSUnionRect( startRect, endRect );
			
			NSBezierPath* path = [NSBezierPath bezierPath];
			
			[path appendBezierPathWithRoundedRect:rect xRadius:1.0 yRadius:1.0];
			
			if ( status == kLineAdded )
			{
				[[NSColor greenColor] set];
			}
			else if ( status == kLineRemoved )
			{
				[[NSColor redColor] set];
			}
			else if ( status == kLineEmpty )
			{
				[[NSColor grayColor] set];
			}
			
			[path fill];
			
			[[NSColor blackColor] set];
			[path stroke];
			
			// Draw Selection
			if ( index == selectedHunk )
			{
				[[NSColor colorWithCalibratedRed:0.5 
										   green:0.5 
											blue:1.0 
										   alpha:0.7] set];
				[path fill];
			}
		}
	}

	
	// Draw a rounded corned box around the diff hunk.
	// Colors should be configurable.
/*	
	NSRect newRect = NSMakeRect(0, 0, rect.size.width, 100);
	
    [thePath appendBezierPathWithRoundedRect:newRect xRadius:15.0 yRadius:15.0];

	[[NSColor blackColor] set];
	[thePath stroke];

	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor greenColor] 
														 endingColor:[NSColor grayColor]];
	
	[gradient drawInBezierPath:thePath angle:90.0f];
//    [thePath fill];	
 */
}

- (void) scrollToHunk:(NSUInteger) hunkIndex
{
	CCDiffHunk hunk;
	
	[[hunks objectAtIndex:hunkIndex] getValue:&hunk];
	
	NSRect startRect = [ [self layoutManager]
						lineFragmentRectForGlyphAtIndex:hunk.startCharIndex
						effectiveRange:nil];
		
	[[scrollView contentView] scrollToPoint:startRect.origin];
}

- (void) moveToNextDiff
{
	if ( selectedHunk < [hunks count] - 1 )
	{
		selectedHunk ++;
		
		CCDiffHunk hunk;
		
		[[hunks objectAtIndex:selectedHunk] getValue:&hunk];
		
		NSRect startRect = [ [self layoutManager]
							 lineFragmentRectForGlyphAtIndex:hunk.startCharIndex
							 effectiveRange:nil];
		
		
		[[scrollView contentView] scrollToPoint:startRect.origin];
	}
	
	[self setNeedsDisplay:YES];
}

- (void) moveToPreviousDiff
{
	if ( selectedHunk > 0 )
	{
		selectedHunk --;
		
		[self scrollToHunk:selectedHunk];
	}
	
	[self setNeedsDisplay:YES];	
}

-(void) keyDown:(NSEvent *)theEvent
{
	[super keyDown:theEvent];
	
	unsigned short keyCode = [theEvent keyCode];
	
	switch( keyCode )
	{
		case kVK_DownArrow:
			
 			[self moveToNextDiff];
			
			break;
			
		case kVK_UpArrow:
			[self moveToPreviousDiff];
			
			break;
	}
}


@end
