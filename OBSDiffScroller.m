//
//  OBSDiffScroller.m
//  gitfend
//
//  Created by Manuel Astudillo on 1/13/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "OBSDiffScroller.h"
#import "CCDiff.h"
#import "NSColor+OBSDiff.h"

@implementation OBSDiffScroller

- (id) initWithHunks:(NSArray*) _hunks numLines:(NSUInteger) _numLines
{
	if ( self = [super init] )
	{
		hunks = _hunks;
		[hunks retain];
		
		numLines = _numLines;
	}
	return self;
}


-(void) dealloc
{
	[hunks release];
	[super dealloc];
}

- (void) drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
	[super drawKnobSlotInRect:slotRect highlight:flag];
	
	// TODO: Add horizontal support.
			
	float scaleFactor;

	NSRect knobRect = [self rectForPart:NSScrollerKnob];
	NSRect rect;
	
	scaleFactor = (slotRect.size.height - knobRect.size.height) / numLines;
	
	rect.origin.x	= slotRect.origin.x;
	rect.size.width = slotRect.size.width;
	
	[NSBezierPath setDefaultLineWidth:0.0];
	
	for ( CCDiffHunk *hunk in hunks )
	{
		NSUInteger firstLine, lastLine;
		
		NSBezierPath *path;

		firstLine = [hunk firstLineNumber];
		lastLine = [hunk lastLineNumber];
		
		rect.origin.y = round( firstLine * scaleFactor + 
							   knobRect.size.height / 2 +
							   slotRect.origin.y);
		
		rect.size.height = ((lastLine + 1) - firstLine) * scaleFactor;
		
		if ( rect.size.height < 1 )
		{
			rect.size.height = 1;
		}
		
		path = [NSBezierPath bezierPathWithRect:rect];
		switch ( [hunk status] )
		{
			case kLineAdded:
				[[NSColor addedLineColor] set];
				break;
			case kLineRemoved:
				[[NSColor removedLineColor] set];
				break;
			case kLineModified:
				[[NSColor modifiedLineColor] set];
				break;
			case kLineEmpty:
				[[NSColor emptyLineColor] set];
				break;
				
			default:
				[[NSColor blackColor] set];
		}
		
		[path fill];
	}
}


@end
