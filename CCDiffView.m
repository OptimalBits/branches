//
//  CCDiffView.m
//  gitfend
//
//  Created by Manuel Astudillo on 9/18/10.
//  Copyright 2010 Optimal Bits Software AB. All rights reserved.
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
	LineDiffStatus status;
	
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


-(id) initWithRect:(NSRect) rect status:(LineDiffStatus) status;

-(void) startRollOver:(NSView*) targetView targetColor:(NSColor*) targetColor;
-(void) endRollOver:(NSView*) targetView;

-(NSColor*) strokeColor;

-(void) draw;

@end

@implementation HunkMarker

@synthesize rect;

-(id) initWithRect:(NSRect) _rect status:(LineDiffStatus) _status
{
	if ( self = [super init] )
	{
		rect = _rect;
		status = _status;
		
		switch ( status )
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

	[selectorColor release];
	selectorColor = [NSColor interpolateAlpha:[NSColor selectedLineColor]
									   factor:alpha];
	[selectorColor retain];
	
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
	
	
	[NSBezierPath setDefaultLineWidth:0.0];
	[strokeColor set];
	
	CGFloat x1, y1, x2, y2;
	
	x1 = rect.origin.x;
	y1 = floor(rect.origin.y) + 0.5;
	x2 = x1 + rect.size.width;
	y2 = y1 + rect.size.height;
	
	// Upper line
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

@end


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
		   strokeColor:(NSColor*) strokeColor;

-(void) updateStorage:(NSTextStorage*) storage;

-(void) generateHunks;
-(void) updateButtonsStates;
-(void) generateTrackingAreas;

@end

@implementation CCDiffView

//@synthesize selectedHunk;

- (id) initWithScrollView:(NSScrollView*) view 
					 font:(NSFont*) _font
					lines:(NSArray*) _lines
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
		
		hunks = [[NSMutableArray alloc] init];
		
		selectedHunk = 0;
		selectedHunkMarker = -1;
		
		scrollView = view;
		[scrollView retain];
		
		font = _font;
		[font retain];
		
		controller = _controller;
		[controller retain];
		
		[self setMinSize:NSMakeSize(0.0, contentSize.height)];
		[self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		
		[self setVerticallyResizable:YES];
		
		[view setDocumentView:self];
		
		//
		// Disable word wrap
		//
		
		NSSize bigSize = NSMakeSize(FLT_MAX, FLT_MAX);
		
		[[self enclosingScrollView] setHasHorizontalScroller:YES];
		[self setHorizontallyResizable:YES];
		[self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		
		[[self textContainer] setContainerSize:bigSize];
		[[self textContainer] setWidthTracksTextView:NO];
		
		//
		// Line numbering
		//
		
		NoodleLineNumberView *lineNumberView = 
		   [[[NoodleLineNumberView alloc] initWithScrollView:view] autorelease];
		
		[scrollView setVerticalRulerView:lineNumberView];
		[scrollView setRulersVisible:YES];
		
		
		// Compute all the following rect arrays:
		fontBoundingRect = [font boundingRectForFont];
				
		NSTextStorage *storage = [self textStorage];
		
		[self updateStorage:storage];
		[self generateHunks];
	//	[self generateTrackingAreas];
		[self updateButtonsStates];
		
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
	[super dealloc];
}

-(void) updateStorage:(NSTextStorage*) storage
{
	NSDictionary *textAttr = 
		[NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
		 nil];
	
	NSAttributedString *newLine = 
		[[NSAttributedString alloc] initWithString:@"\n" attributes:textAttr];
		[newLine autorelease];
	
	if ( [lines count] > 0 )
	{		
		for( CCDiffLine *line in lines )
		{			
			LineDiffStatus status = [line status];
			switch (status) 
			{
				case kLineAdded:
				case kLineModified:
				case kLineRemoved:
				case kLineOriginal:
				{
					NSAttributedString *attributedString;
					
					attributedString = 
					[[[NSAttributedString alloc] initWithString:[line line] 
													 attributes:textAttr] autorelease];
					
					[storage appendAttributedString:attributedString];
				}
					break;
				case kLineEmpty:
					break;
			}
	
			[storage appendAttributedString:newLine];
		}
	}
}

-(void) generateHunks
{
	NSUInteger lineCount = 0;
	NSUInteger charIndex = 0;
	
	CCDiffHunk *hunk;
	
	LineDiffStatus prevStatus;
	LineDiffStatus status;		

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
	
	boundsRect = [self bounds];
	
	hunkMarkers = [[NSMutableArray alloc] init];
	
	NSLayoutManager *layoutManager = [self layoutManager];
	
	for ( CCDiffHunk *hunk in hunks )
	{
		startRect = [layoutManager
					 lineFragmentRectForGlyphAtIndex:[hunk startCharIndex]
									  effectiveRange:nil];
		endRect = [layoutManager
				   lineFragmentRectForGlyphAtIndex:[hunk endCharIndex]
									effectiveRange:nil];
		
		unionRect = NSIntersectionRect( NSUnionRect(startRect, endRect),
									    boundsRect );
		
		hunkMarker = [[HunkMarker alloc] initWithRect:unionRect
											   status:[hunk status]];
		userInfoDict = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				hunkMarker, @"hunkMarker", 
				nil];

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
				
				if ( index == selectedHunk )
				{				
					[self drawHunkMarker:[hunkMarker rect] 
							   fillColor:currentSelectorColor
							 strokeColor:currentSelectorStroke];
				}
			}
		}
	}
}


-(void) drawHunkMarker:(NSRect) rect 
			 fillColor:(NSColor*) fillColor
		   strokeColor:(NSColor*) strokeColor
{
	// Draw background color
	NSBezierPath* path = [NSBezierPath bezierPathWithRect:rect];
	
	[fillColor set];
	[path fill];
	
	[NSBezierPath setDefaultLineWidth:0.0];
	[strokeColor set];
	
	// Upper line
	{
		CGFloat x1, y1, x2, y2;
		
		x1 = rect.origin.x;
		y1 = rect.origin.y;
		x2 = x1 + rect.size.width;
		y2 = y1 + rect.size.height;
		
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


- (void) scrollToHunk:(NSUInteger) hunkIndex
{
	NSPoint origin = [self hunkOrigin:hunkIndex];
	
	[[scrollView contentView] scrollToPoint:origin];
	[scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (void) moveToNextDiff
{
	if ( selectedHunk < [hunks count] - 1 )
	{
		selectedHunk ++;
	}
}

- (void) moveToPreviousDiff
{
	if ( selectedHunk > 0 )
	{
		selectedHunk --;
	}
}


-(NSUInteger) selectedHunkIndex
{
	return selectedHunk;
}

- (void) moveToHunk:(NSInteger) hunkIndex
{
	selectedHunk = hunkIndex;
	[self scrollToHunk:selectedHunk];
}

-(CCDiffHunk*) selectedHunk
{
	return [hunks objectAtIndex:selectedHunk];
}

-(void) removeHunk:(CCDiffHunk*) hunk
{
	[hunks removeObject:hunk];	
}

-(void) removeSelectedHunk:(NSInteger) bias
{
	CCDiffHunk *hunk = [self selectedHunk];
		
	// Update char indexes and lines of all hunks after this one
	for ( int i = selectedHunk+1; i < [hunks count]; i++ )
	{
		hunk = [hunks objectAtIndex:i];
		
		[hunk setStartCharIndex:[hunk startCharIndex] + bias];
	}
	
	[hunks removeObjectAtIndex:selectedHunk];
	
	// TODO: Remove hunk marker.
	
	if ( selectedHunk >= [hunks count] )
	{
		selectedHunk = [hunks count] - 1;
	}
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

- (void)updateTrackingAreas
{
	/*
	for ( NSTrackingArea *ta in [super trackingAreas] )
	{
		[self removeTrackingArea:ta];
	}
	
	[super updateTrackingAreas];
	
	[self generateTrackingAreas];
	[self display];
	 */
}

- (void) mouseEntered:(NSEvent *)event
{
	NSDictionary *userInfo = [event userData];

	if ( userInfo )
	{
		HunkMarker *hunkMarker = [userInfo objectForKey:@"hunkMarker"];
		if ( hunkMarker )
		{
			[hunkMarker startRollOver:self 
						  targetColor:[NSColor selectedLineColor]];
			
			selectedHunkMarker = [hunkMarkers indexOfObject:hunkMarker];
		}
	}
}

- (void) mouseExited:(NSEvent *)event
{
	NSDictionary *userInfo = [event userData];
	
	if ( userInfo )
	{
		HunkMarker *hunkMarker = [userInfo objectForKey:@"hunkMarker"];
		if ( hunkMarker )
		{
			[hunkMarker endRollOver:self];
			selectedHunkMarker = -1;
		}
	}
}

-(void) mouseDown:(NSEvent*) event
{
	// Set current hunk as the selected one ( if any ).
	if ( selectedHunkMarker != -1 )
	{
		if ( selectedHunk < [hunks count] - 1 )
		{
			selectedHunk = selectedHunkMarker;
		}
		[controller gotoDiffIndex:selectedHunkMarker];
	}
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

- (void)viewDidMoveToWindow
{
	//
}

// Move to Controller class!
-(void) updateButtonsStates
{
	if ( selectedHunk > 0) 
	{
		[prevButton setEnabled:YES];
	}
	else
	{
		[prevButton setEnabled:NO];
	}

	if ( ( [hunks count] > 0 ) && ( selectedHunk < [hunks count]-1 ) )
	{
		[nextButton setEnabled:YES];
	}
	else
	{
		[nextButton setEnabled:NO];
	}
}

@end

