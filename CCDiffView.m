//
//  CCDiffView.m
//  gitfend
//
//  Created by Manuel Astudillo on 9/18/10.
//  Copyright 2010 Optimal Bits Sweden AB. All rights reserved.
//

#import "CCDiffView.h"
#import "CCDiff.h"

#import "CCDiffViewController.h"

#import "OBSScrollViewAnimation.h"
#import "OBSGenericAnimation.h"
#import "OBSDiffScroller.h"

#import "NSColor+OBSDiff.h"
#import "NSColor+OBSInterpolation.h"

#import "NoodleLineNumberView.h"

#include <Carbon/Carbon.h>

#define SELECTOR_END_ALPHA		0.7
#define SELECTOR_START_ALPHA	0.0

#define SELECTOR_RED		0.545
#define SELECTOR_GREEN		0.721
#define SELECTOR_BLUE		0.902

/**
	Graphic representation of a hunk selector.
 
 */

#define ROLLOVER_DURATION	0.2

@interface HunkMarker : NSObject
{
	NSRect  rect;
	
	CCDiffHunk *diffHunk;
	
	NSColor *fillColor;
	NSColor *strokeColor;
	
	float animationProgress;

	NSColor *startColor;
	NSColor *endColor;
	
	NSColor *selectorColor;
	
	BOOL rollingIn;
	OBSGenericAnimation *rollOverAnimation;
}

@property (readonly) NSRect rect;


-(id) initWithRect:(NSRect) rect hunk:(CCDiffHunk*) hunk;

-(void) startRollOver:(NSView*) targetView targetColor:(NSColor*) targetColor;
-(void) endRollOver:(NSView*) targetView;

-(NSColor*) strokeColor;

-(void) draw;

@end

@implementation HunkMarker

@synthesize rect;

-(id) initWithRect:(NSRect) _rect hunk:(CCDiffHunk*) hunk
{
	if ( self = [super init] )
	{
		rect = _rect;
		diffHunk = hunk;
		
		switch ( [hunk status] )
		{
			case kLineAdded:
				fillColor = [NSColor addedLineColor];
				break;
			case kLineRemoved:
				fillColor = [NSColor removedLineColor];
				break;
			case kLineModified:
				fillColor = [NSColor modifiedLineColor];
				break;
			case kLineEmpty:
				fillColor = [NSColor emptyLineColor];
				break;
			default:
				fillColor = [NSColor blackColor];
		}
		[fillColor retain];
		
		strokeColor = [NSColor colorWithDeviceRed:0.6 
											green:0.6 
											 blue:0.6 
											alpha:1.0];
		[strokeColor retain];
		
		animationProgress = 1.0f;
		selectorColor = nil;
		startColor = nil;
		endColor = nil;
	}
	return self;
}

-(void) dealloc
{
	[fillColor release];
	[super dealloc];
}

-(NSColor*) fillColor
{
/*	if ( startColor )
	{
		float interpolationFactor;
		
		//return [NSColor interpolateAlpha:endColor
		//						  factor:interpolationFactor];
		return [NSColor interpolateStartColor:startColor 
									 endColor:endColor
									   factor:animationProgress];
	}
	else*/
	{
		return fillColor;
	}
}

-(NSColor*) strokeColor
{
	return strokeColor;
}


-(void) startRollOver:(NSView*) targetView targetColor:(NSColor*) targetColor
{
	if ( rollOverAnimation )
	{
		[rollOverAnimation stopAnimation];
		[rollOverAnimation release];
	}
	
	rollingIn = YES;
	
	[startColor release];
	[endColor release];
	
	[targetColor retain];
	[fillColor retain];
	
	startColor = fillColor;
	endColor = targetColor;	
	
	rollOverAnimation = [[OBSGenericAnimation alloc] 
							initWithView:targetView
								delegate:self
								duration:ROLLOVER_DURATION
								   curve:NSAnimationLinear];
	[rollOverAnimation setCurrentProgress:1-animationProgress];
	
	[rollOverAnimation startAnimation];
}


-(void) endRollOver:(NSView*) targetView
{
	if ( rollOverAnimation )
	{
		[rollOverAnimation stopAnimation];
		[rollOverAnimation release];
	}
	
	rollingIn = NO;
	
	[startColor release];
	startColor = endColor;
	
	[fillColor retain];
	endColor = fillColor;	
	
	rollOverAnimation = [[OBSGenericAnimation alloc]
								initWithView:targetView
									delegate:self
									duration:ROLLOVER_DURATION
									   curve:NSAnimationLinear];
	[rollOverAnimation setCurrentProgress:1-animationProgress];
	
	[rollOverAnimation startAnimation];
}


-(void) updateAnimation:(NSAnimationProgress) progress
{
	float alpha;
	
	animationProgress = progress;
	
	alpha = rollingIn ? progress : 1 - progress;
#if 1
	[selectorColor release];
	selectorColor = [NSColor interpolateAlpha:[NSColor selectedLineColor]
									   factor:alpha];
	[selectorColor retain];	
#endif
}

-(void) draw
{
	NSBezierPath* path = [NSBezierPath bezierPathWithRect:rect];
	
	[[self fillColor] set];
	[path fill];
	
	// Draw Selection Marker on top
	if ( selectorColor )
	{
		[selectorColor set];
		[path fill];
	}
}

@end

/*
NSRect rectForCharacterIndex( NSUInteger charIndex, 
							  NSTextView *textView )
{
	NSLayoutManager *layoutManager = [textView
									  layoutManager];
	NSPoint containerOrigin = [textView
							   textContainerOrigin];
	NSRect r;
	
	int glyphIndex = [layoutManager
					  glyphRangeForCharacterRange:NSMakeRange(charIndex,0)
					  actualCharacterRange:nil].location;
	
	// If there is no valid character at the index we
	// must be at the beginning of the text view,
	// and there must be no text in the text view
	//(because we adjust for this in textDidChange:)
	if ([layoutManager isValidGlyphIndex:glyphIndex])
	{
		// First get the rect of the line the character is
		// in
		r = [layoutManager
			 lineFragmentUsedRectForGlyphAtIndex:glyphIndex
			 effectiveRange:nil];
		
		// Then get the place of the character in the line
		r.origin.x = [layoutManager
					  locationForGlyphAtIndex:glyphIndex].x;
	}
	else
		r = NSZeroRect; // No characters
		
		// NEED to convert to allow for textContainer origin
		//here...
		r = [self convertRect:r fromView:textView];
		return r;
}
*/


@interface HunkSelectorAnimation : NSAnimation
{
	NSScrollView *scrollView;
}

-(void) moveSelector:(NSRect) startRect targetRect:(NSRect) targetRect;

@end

@implementation HunkSelectorAnimation


-(void) moveSelector:(NSRect) startRect targetRect:(NSRect) targetRect
{
	
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
	[super setCurrentProgress:progress];
	
	// Render selector here.
	
	[scrollView setNeedsDisplay:YES];
	
	if ([NSThread isMainThread])
	{
		[scrollView displayIfNeeded];
	}
	else
	{
		[scrollView performSelectorOnMainThread:@selector(displayIfNeeded)
									 withObject:nil waitUntilDone:NO];
	}
}

@end


@interface CCDiffView ( Private )

-(void) drawHunkMarker:(NSRect) rect 
			 fillColor:(NSColor*) fillColor
		   strokeColor:(NSColor*) strokeColor
			 drawLines:(BOOL) drawLines;

-(void) generateHunks;
-(void) generateTrackingAreas;

-(void) updateLinesIndexes:(NSUInteger) firstLineIndex;


- (void) scrollToHunk:(NSUInteger) hunkIndex;

@end

@implementation CCDiffView

@synthesize lines;
@synthesize selectedHunkIndex;
@synthesize selectedHunkMarker;

- (id) initWithScrollView:(NSScrollView*) view 
					 font:(NSFont*) _font
					lines:(NSMutableArray*) _lines
					 mask:(CCDiffViewLineMask) mask
			   controller:(CCDiffViewController*) _controller
{
	NSSize contentSize = [view contentSize];
	
	self = [super initWithFrame:NSMakeRect( 0, 0, 
										    contentSize.width, 
										    contentSize.height)];
	if ( self )
	{
		lines = _lines;
		[lines retain];
		
		selectedHunkIndex = 0;
		selectedHunkMarker = -1;
		
		scrollView = view;
		[scrollView retain];
		
		font = _font;
		[font retain];
		
		controller = _controller;
		[controller retain];
		
		lineIndexes = nil;
		
		[self setMinSize:NSMakeSize(0.0, contentSize.height)];
		[self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		
		[self setVerticallyResizable:YES];

		[self setEditable:YES];
		[self setSelectable:YES];
		
		[self setAllowsUndo:YES];
		
		[self setDelegate:self];
		
		//
		// Disable word wrap
		//
		
		NSSize bigSize = NSMakeSize(FLT_MAX, FLT_MAX);
		
		[[self enclosingScrollView] setHasHorizontalScroller:YES];
		[self setHorizontallyResizable:YES];
		[self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		
		[[self textContainer] setContainerSize:bigSize];
		[[self textContainer] setWidthTracksTextView:NO];
		
		[self setUsesRuler:NO];
		
		//
		// Line numbering
		//
#if 0	
		NoodleLineNumberView *lineNumberView = 
		   [[[NoodleLineNumberView alloc] initWithScrollView:view] autorelease];
		
		[scrollView setVerticalRulerView:lineNumberView];
		[scrollView setRulersVisible:YES];
#endif	

		[self updateStorage:[self textStorage]];
		[self generateHunks];
		[self generateTrackingAreas];
		[self updateLinesIndexes:0];
		
		diffScroller = [[OBSDiffScroller alloc] initWithHunks:hunks
													 numLines:[lines count]];
		
		[scrollView setVerticalScroller:diffScroller];
		
		selectorAnimator = 
			[[OBSGenericAnimation alloc] initWithView:self
											 delegate:self
											 duration:1
												curve:NSAnimationEaseInOut];
		
		currentSelectorColor = [NSColor colorWithDeviceRed:SELECTOR_RED
													 green:SELECTOR_GREEN
													  blue:SELECTOR_BLUE
													 alpha:SELECTOR_END_ALPHA];
		[currentSelectorColor retain];

		currentSelectorStroke = [[NSColor colorWithDeviceRed:0.360
													  green:0.592
													   blue:0.867
													  alpha:1.0] retain];
		prevBounds = NSMakeRect( 0, 0, 0, 0 );
		
		[view setDocumentView:self];
		
		[self scrollToHunk:0];
	}
	return self;
}

-(void) dealloc
{
	[selectorAnimator release];
	[currentSelectorColor release];
	[currentSelectorStroke release];
	[diffScroller release];
	[hunks release];
	[hunkMarkers release];
	[lines release];
	[scrollView release];
	[font release];
	[lineIndexes release];
	[super dealloc];
}



-(void) updateStorage:(NSTextStorage*) storage
{
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	[style setDefaultTabInterval:24.];
	[style setTabStops:[NSArray array]];

	NSDictionary *textAttr = 
		[NSDictionary dictionaryWithObjectsAndKeys: 
			font, NSFontAttributeName, 
			style, NSParagraphStyleAttributeName,
		 nil];

	[style release];
	
	NSDictionary *charModifiedAttrs = 
		[NSDictionary dictionaryWithObject:[NSColor charDiffColor]
									forKey:NSBackgroundColorAttributeName];
	
	NSAttributedString *newLine = 
		[[NSAttributedString alloc] initWithString:@"\n" attributes:textAttr];
	[newLine autorelease];
	
	NSAttributedString *emptyString =
	[[NSAttributedString alloc] initWithString:@""];
	[emptyString autorelease];
	
	[storage replaceCharactersInRange:NSMakeRange(0, [storage length]) 
				 withAttributedString:emptyString];
	
	if ( [lines count] > 0 )
	{
		for( CCDiffLine *line in lines )
		{
			NSMutableAttributedString *attributedString;
			
			LineDiffStatus status = [line status];
			switch (status)
			{
				case kLineAdded:
				case kLineModified:
				case kLineRemoved:
				case kLineOriginal:
					attributedString =
					[[[NSMutableAttributedString alloc] initWithString:[line line] 
															attributes:textAttr] autorelease];
					
					if ( status == kLineModified )
					{
						for ( CCDiffChar *c in [line charDiffs] )
						{
							[attributedString addAttributes:charModifiedAttrs
													  range:NSMakeRange([c charIndex], 1)];
						}
					}
					
					[storage appendAttributedString:attributedString];
					break;
				case kLineEmpty:
				default:
					break;
			}
			
			[storage appendAttributedString:newLine];
		}
	}
}

-(void) updateStorage:(NSRange) charRange
		 newLineRange:(NSRange) newLineRange
{
	NSMutableAttributedString *newString;
	
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	[style setDefaultTabInterval:24.];
	[style setTabStops:[NSArray array]];
	
	NSDictionary *textAttr = 
	[NSDictionary dictionaryWithObjectsAndKeys: 
	 font, NSFontAttributeName, 
	 style, NSParagraphStyleAttributeName,
	 nil];
	
	[style release];
	
	NSDictionary *charModifiedAttrs = 
	[NSDictionary dictionaryWithObject:[NSColor charDiffColor]
								forKey:NSBackgroundColorAttributeName];
	
	NSAttributedString *newLine = 
	[[NSAttributedString alloc] initWithString:@"\n" attributes:textAttr];
	[newLine autorelease];
	
	newString = [[[NSMutableAttributedString alloc] init] autorelease];
	
	if ( [lines count] > 0 )
	{
		for( CCDiffLine *line in [lines subarrayWithRange:newLineRange] )
		{
			NSMutableAttributedString *attributedString;
			
			LineDiffStatus status = [line status];
			switch (status)
			{
				case kLineAdded:
				case kLineModified:
				case kLineRemoved:
				case kLineOriginal:
					attributedString =
					[[[NSMutableAttributedString alloc] initWithString:[line line] 
															attributes:textAttr] autorelease];
					if ( status == kLineModified )
					{
						for ( CCDiffChar *c in [line charDiffs] )
						{
							[attributedString addAttributes:charModifiedAttrs
													  range:NSMakeRange([c charIndex], 1)];
						}
					}
					
					[newString appendAttributedString:attributedString];
					break;
				case kLineEmpty:
				default:
					break;
			}
			
			[newString appendAttributedString:newLine];
		}
	}
	
	[[self textStorage] replaceCharactersInRange:charRange
							withAttributedString:newString];
	
	NSUInteger startIndex = newLineRange.location > 0? newLineRange.location:0;
	[self updateLinesIndexes:startIndex];
}


-(void) mergeTo:(CCDiffView*) dstView
{
	NSRange dstCharRange;
	NSRange srcCharRange;
	
//	NSInteger dstBias;
//	NSInteger srcBias;
	
	CCDiffHunk *dstHunk = [dstView selectedHunk];
	CCDiffHunk *srcHunk = [self selectedHunk];
	
	NSTextStorage *dstStorage = [dstView textStorage];
	NSTextStorage *srcStorage = [self textStorage];
	
	srcCharRange = [srcHunk charRange];
	dstCharRange = [dstHunk charRange];
	
	if ( [srcHunk status] == kLineEmpty )
	{		
//		[srcStorage deleteCharactersInRange:srcCharRange];
		[dstStorage deleteCharactersInRange:dstCharRange];
		
//		srcBias = -srcCharRange.length;
//		dstBias = -dstCharRange.length;
	}
	else
	{
		/// --------------- 8< ------------- 8< -------------------------------
		NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
		[style setDefaultTabInterval:24.];
		[style setTabStops:[NSArray array]];
		
		NSDictionary *textAttr = 
		[NSDictionary dictionaryWithObjectsAndKeys: 
		 font, NSFontAttributeName, 
		 style, NSParagraphStyleAttributeName,
		 nil];
		
		[style release];
		/// --------------- 8< ------------- 8< -------------------------------
		
		NSAttributedString *string;
		
		string = [srcStorage attributedSubstringFromRange:srcCharRange];
		[dstStorage replaceCharactersInRange:dstCharRange
						withAttributedString:string];
		
//		[srcStorage setAttributes:textAttr range:srcCharRange];
//		[dstStorage setAttributes:textAttr range:dstCharRange];
		
//		srcBias = 0;
//		dstBias = srcCharRange.length - dstCharRange.length;
	}
	
//	[dstView removeSelectedHunk:dstBias];
//	[self removeSelectedHunk:srcBias];
	
//	[self gotoDiff];
//	[self refreshDisplay];
	
//	[self setNeedsDisplay:YES];
//	[dstView setNeedsDisplay:YES];	
}

-(void) updateLinesIndexes:(NSUInteger) firstLineIndex
{
	NSArray	   *subarray;
	NSUInteger prevLineLength;
	NSUInteger currentCharIndex;
	NSUInteger length;
	CCDiffLine *firstLine;
	NSRange	   range;
	
	NSMutableArray *newCharIndexes;
	NSRange indexesRange;
	
	firstLine = [lines objectAtIndex:firstLineIndex];
	length = [lines count] - firstLineIndex - 1;
	range = NSMakeRange(firstLineIndex+1, length);
	subarray = [lines subarrayWithRange:range];
		
	if ( lineIndexes )
	{
		currentCharIndex = [[lineIndexes objectAtIndex:firstLineIndex] integerValue];
		
		NSUInteger indexesLength = [lineIndexes count] - firstLineIndex - 1;
		indexesRange = NSMakeRange( firstLineIndex+1, indexesLength ); 
		
		newCharIndexes = [[NSMutableArray alloc] initWithCapacity:indexesLength];
	}
	else
	{
		indexesRange = range;
		currentCharIndex = 0;
		newCharIndexes = [[NSMutableArray alloc] initWithCapacity:range.length + 1];
		[newCharIndexes addObject:[NSNumber numberWithInteger:0]];
	}


	prevLineLength = [firstLine length] + 1;
	
	for ( CCDiffLine *line in subarray )
	{
		currentCharIndex += prevLineLength;
		[newCharIndexes addObject:[NSNumber numberWithInteger:currentCharIndex]];
		
		prevLineLength = [line length] + 1;
	}
	
	if ( lineIndexes )
	{
		[lineIndexes replaceObjectsInRange:indexesRange 
					  withObjectsFromArray:newCharIndexes];
	}
	else
	{
		lineIndexes = newCharIndexes;
	}
}

- (NSRange) charRangeFromLines:(NSRange) lineRange
{
	NSRange charRange;
	
	BOOL first = YES;
	
	charRange.length = 0;
	
	for ( CCDiffLine *line in [lines subarrayWithRange:lineRange] )
	{
		if ( first )
		{
			charRange.location = 
				[[lineIndexes objectAtIndex:lineRange.location] integerValue];
			first = NO;
		}
		charRange.length += [line length] + 1;
	}
	
	return charRange;
}

-(void) generateHunks
{
	NSUInteger lineCount = 0;
	NSUInteger charIndex = 0;
	
	CCDiffHunk *hunk;
	
	LineDiffStatus prevStatus;
	LineDiffStatus status;		

	[hunks release];
	hunks = [[NSMutableArray alloc] init];
	
	prevStatus = [(CCDiffLine *)[lines objectAtIndex:0] status];
	
	hunk = nil;
	
	for( CCDiffLine *line in lines )
	{
		status = [line status];
		
		if ( ( prevStatus != status ) || 
			 ( lineCount == [lines count]-1 ) )
		{
			if ( prevStatus != kLineOriginal )
			{
				[hunk setStatus:prevStatus];
				[hunks addObject:hunk];
			
				hunk = nil;
			}
			
			prevStatus = status;
		}
		
		if ( status != kLineOriginal )
		{
			if ( hunk == nil )
			{
				hunk = [[[CCDiffHunk alloc] init] autorelease];
				[hunk setStartCharIndex:charIndex];
				[hunk setFirstLineNumber:lineCount];
			}
			[hunk addLine:line];
		}
		
		charIndex += [line length] + 1;
		lineCount++;
	}
}

-(void) generateTrackingAreas
{
	HunkMarker *hunkMarker;
	
	NSRect startRect;
	NSRect endRect;
	NSRect unionRect;
	NSRect boundsRect;
		
	NSTrackingArea *trackingArea;
	NSDictionary *userInfoDict;
	
	NSUInteger lineWidth;
	
	boundsRect = [self bounds];
	
	[hunkMarkers release];
	hunkMarkers = [[NSMutableArray alloc] init];
	
	NSLayoutManager *layoutManager = [self layoutManager];
	
	lineWidth = [layoutManager defaultLineHeightForFont:font];
	
	for ( CCDiffHunk *hunk in hunks )
	{
		startRect = NSMakeRect(0, lineWidth * [hunk firstLineNumber], 
							   NSIntegerMax, lineWidth );
		endRect = startRect;
		endRect.origin.y = lineWidth * [hunk lastLineNumber];
		
		/*
		startRect = [layoutManager
					 lineFragmentRectForGlyphAtIndex:[hunk startCharIndex]
									  effectiveRange:nil];
		endRect = [layoutManager
				   
				   lineFragmentRectForGlyphAtIndex:[hunk endCharIndex]
									effectiveRange:nil];
		*/
		unionRect = NSIntersectionRect( NSUnionRect(startRect, endRect),
									    boundsRect );
		
		hunkMarker = [[HunkMarker alloc] initWithRect:unionRect
												 hunk:hunk];
		userInfoDict = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				hunkMarker, @"hunkMarker", 
				nil];
		
		[hunkMarker release];

		trackingArea = 
		[[NSTrackingArea alloc] initWithRect:unionRect 
									 options:NSTrackingMouseEnteredAndExited |
											 NSTrackingActiveAlways |
											 NSTrackingCursorUpdate
									   owner:self
									userInfo:userInfoDict];
		
		[self addTrackingArea:trackingArea];
		[trackingArea release];
		 
		[hunkMarkers addObject:hunkMarker];
	}
}

-(void) updateAnimation:(NSAnimationProgress) progress
{
	float alpha = SELECTOR_START_ALPHA * (1-progress) +
				  SELECTOR_END_ALPHA * progress;
		
	[currentSelectorColor release];
	currentSelectorColor = [NSColor colorWithDeviceRed:SELECTOR_RED
												 green:SELECTOR_GREEN
												  blue:SELECTOR_BLUE 
												 alpha:alpha];
	[currentSelectorColor retain];
}

-(void) drawViewBackgroundInRect:(NSRect) rect
{
	[super drawViewBackgroundInRect:rect];
	
	// Check if bounds rect has changed
	if ( NSEqualRects( [self bounds], prevBounds ) == NO )
	{
		prevBounds = [self bounds];
		[self generateTrackingAreas];
	}
		
	NSUInteger index;
	
	for ( index = 0; index < [hunks count]; index ++ )
	{
		CCDiffHunk *hunk;
		
		hunk = [hunks objectAtIndex:index];
		
		LineDiffStatus status = [hunk status];
		
		if ( ( status == kLineAdded )   || 
			 ( status == kLineRemoved ) || 
			 ( status == kLineEmpty )   ||
			 ( status == kLineModified ) )
		{
			HunkMarker *hunkMarker = [hunkMarkers objectAtIndex:index];
			
			if ( NSIntersectsRect([hunkMarker rect], rect) )
			{
				[hunkMarker draw];
				
				if ( index == selectedHunkIndex )
				{				
					[self drawHunkMarker:[hunkMarker rect] 
							   fillColor:currentSelectorColor
							 strokeColor:currentSelectorStroke
							   drawLines:YES];
				}
				else if ( index == selectedHunkMarker )
				{
					[self drawHunkMarker:[hunkMarker rect] 
							   fillColor:currentSelectorColor
							 strokeColor:currentSelectorStroke
							   drawLines:NO];
				}
			}
		}
	}
}

-(void) drawHunkMarker:(NSRect) rect 
			 fillColor:(NSColor*) fillColor
		   strokeColor:(NSColor*) strokeColor
			 drawLines:(BOOL) drawLines
{
	// Draw background color
	NSBezierPath* path = [NSBezierPath bezierPathWithRect:rect];
	
	[fillColor set];
	[path fill];
	
	[NSBezierPath setDefaultLineWidth:0.0];
	[strokeColor set];
	
	if ( drawLines )
	{
		// Upper line
		CGFloat x1, y1, x2, y2;
		
		x1 = rect.origin.x;
		y1 = ceil(rect.origin.y) + 0.5;
		x2 = x1 + rect.size.width;
		y2 = floor(y1 + rect.size.height) + 0.5;
		
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint( x1, y1 )];
		[path lineToPoint:NSMakePoint( x2, y1 )];
		[path stroke];
		
		// Lower line
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint( x1, y2 )];
		[path lineToPoint:NSMakePoint( x2, y2 )];
		[path stroke];
	}
}

-(NSPoint) hunkOrigin:(NSUInteger) index
{	
	if ( index < [hunks count] )
	{
		NSPoint p;
		CCDiffHunk *hunk;

		hunk = [hunks objectAtIndex:index];
		
		NSRect startRect = [ [self layoutManager]
							 lineFragmentRectForGlyphAtIndex:[hunk startCharIndex]
							 effectiveRange:nil];
		
		NSRect visibleRect = [scrollView documentVisibleRect];
		
		p.x = startRect.origin.x;
		p.y = floor( startRect.origin.y - visibleRect.size.height / 2 );
		
		if ( p.y < 0 )
		{
			p.y = 0;
		}
		return p;
	}
	else
	{
		return NSMakePoint( 0, 0 );
	}
}

- (BOOL) isHunkVisible:(NSUInteger) hunkIndex
{
	NSRect visibleRect = [scrollView documentVisibleRect];
	
	HunkMarker *hunkMarker = [hunkMarkers objectAtIndex:hunkIndex];
	
	if ( NSIntersectsRect(visibleRect, [hunkMarker rect]) )
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void) scrollToHunk:(NSUInteger) hunkIndex
{
	NSPoint origin = [self hunkOrigin:hunkIndex];
	
	[[scrollView contentView] scrollToPoint:origin];
	[scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (void) moveToNextDiff
{
	if ( selectedHunkIndex < [hunks count] - 1 )
	{
		selectedHunkIndex ++;
	}
}

- (void) moveToPreviousDiff
{
	if ( selectedHunkIndex > 0 )
	{
		selectedHunkIndex --;
	}
}

- (void) moveToHunk:(NSInteger) hunkIndex
{
	selectedHunkIndex = hunkIndex;
	[self scrollToHunk:selectedHunkIndex];
}

-(CCDiffHunk*) selectedHunk
{
	return [hunks objectAtIndex:selectedHunkIndex];
}

-(void) removeHunk:(CCDiffHunk*) hunk
{
	[hunks removeObject:hunk];	
}

-(void) removeSelectedHunk:(NSInteger) bias
{
	CCDiffHunk *hunk;
		
	// Update char indexes and lines of all hunks after this one
	for ( int i = selectedHunkIndex+1; i < [hunks count]; i++ )
	{
		hunk = [hunks objectAtIndex:i];
		
		[hunk setStartCharIndex:[hunk startCharIndex] + bias];
	}
	
	[hunks removeObjectAtIndex:selectedHunkIndex];
	
	[hunkMarkers removeObjectAtIndex:selectedHunkIndex];
	
	if ( selectedHunkIndex >= [hunks count] )
	{
		selectedHunkIndex = [hunks count] - 1;
	}
}

/*
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
 */

- (void)updateTrackingAreas
{
	for ( NSTrackingArea *ta in [super trackingAreas] )
	{
		[self removeTrackingArea:ta];
	}
	
	[super updateTrackingAreas];
	
	[self generateTrackingAreas];
	[self display];
}

- (void) mouseEntered:(NSEvent *)event
{
	NSDictionary *userInfo = [event userData];

	if ( userInfo )
	{
		HunkMarker *hunkMarker = [userInfo objectForKey:@"hunkMarker"];
		if ( hunkMarker )
		{
			//[hunkMarker startRollOver:self 
			//			  targetColor:[NSColor selectedLineColor]];
			
			[controller setHunkSelector:[hunkMarkers indexOfObject:hunkMarker]];
		}
	}
	[super mouseEntered:event];
}

- (void) mouseExited:(NSEvent *)event
{
	NSDictionary *userInfo = [event userData];
	
	if ( userInfo )
	{
		HunkMarker *hunkMarker = [userInfo objectForKey:@"hunkMarker"];
		if ( hunkMarker )
		{
			//[hunkMarker endRollOver:self];
			[controller setHunkSelector:-1];
		}
	}
	[super mouseExited:event];
}

-(void) mouseDown:(NSEvent*) event
{
	// Set current hunk as the selected one ( if any ).
	if ( selectedHunkMarker != -1 )
	{
		if ( selectedHunkIndex < [hunks count] )
		{
			selectedHunkIndex = selectedHunkMarker;
		}
		[controller gotoDiffIndex:selectedHunkMarker];
	}
	[super mouseDown:event];
}


- (void)resetCursorRects
{
	// pass
}

/*
- (void)cursorUpdate:(NSEvent *)event 
{
	NSDictionary *userInfo = [event userData];
	
	if ( userInfo )
	{
		CCDiffHunk *hunk = [userInfo objectForKey:@"hunk"];
		if ( hunk )
		{
			[scrollView setDocumentCursor:[NSCursor pointingHandCursor]];
			NSLog(@"Cursor updated");
		}
	}
}
*/
 
/*
- (void)cursorUpdate:(NSEvent *)event;
{
	NSPoint hitPoint;
	NSTrackingArea *trackingArea;
	
	trackingArea = [event trackingArea];
	hitPoint = [self convertPoint:[event locationInWindow]
						 fromView:nil];
	
	if ([self mouse:hitPoint inRect:[trackingArea rect]]) {
		[[[trackingArea userInfo] objectForKey:@"cursor"] set];
	} else {
		[[NSCursor arrowCursor] set];
	}
}
*/

- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
	//NSLog(@"Changed selection");
	
	// Check if cursor is on an empty line or not.
}


-(BOOL) shouldAllowEditing:(NSUInteger) index
{
	NSRect rect = [[self layoutManager]
				   lineFragmentRectForGlyphAtIndex:index
				   effectiveRange:nil];
	
	NSUInteger line = rect.origin.y / 
	[[self layoutManager] defaultLineHeightForFont:font];
	
	CCDiffLine *diffLine = [lines objectAtIndex:line];
		
	if ( [diffLine status] == kLineEmpty )
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

- (BOOL)textView:(NSTextView *)aTextView 
shouldChangeTextInRange:(NSRange)range 
replacementString:(NSString *)replacementString
{
	return [self shouldAllowEditing:range.location];
}

- (NSRange)textView:(NSTextView *)aTextView 
willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange 
   toCharacterRange:(NSRange)newSelectedCharRange
{
	NSRect rect = [[self layoutManager]
				   lineFragmentRectForGlyphAtIndex:newSelectedCharRange.location
				   effectiveRange:nil];
	
	NSInteger line = rect.origin.y / 
	[[self layoutManager] defaultLineHeightForFont:font];
	
	CCDiffLine *diffLine = [lines objectAtIndex:line];
	
	if ( [diffLine status] == kLineEmpty )
	{
		NSInteger emptyLinesCount = 0;
		do {
			if ( oldSelectedCharRange.location < newSelectedCharRange.location )
			{
				emptyLinesCount++;
				line++;
			}
			else
			{
				emptyLinesCount--;
				line--;
			}

			if ( line < 0 ) break;
			if ( line >= [lines count] ) break;
				
			diffLine = [lines objectAtIndex:line];
		} while ([diffLine status] == kLineEmpty);
				  
		newSelectedCharRange.location += emptyLinesCount;
	}

	return newSelectedCharRange;
}

- (void)viewDidMoveToWindow
{
	//
}

- (CCDiffHunk*) nextHunk
{
	if ( selectedHunkIndex < [hunks count] - 1 )
	{
		return [hunks objectAtIndex:selectedHunkIndex+1];
	}
	else
	{
		return nil;
	}
}

- (CCDiffHunk*) prevHunk
{
	if ( selectedHunkIndex > 0 )
	{
		return [hunks objectAtIndex:selectedHunkIndex-1];
	}
	else
	{
		return nil;
	}	
}

@end

