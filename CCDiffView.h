//
//  CCDiffView.h
//  gitfend
//
//  Created by Manuel Astudillo on 9/18/10.
//  Copyright 2010 Optimal Bits Sweden AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "CCDiff.h"

@class CCDiffViewController;
@class OBSScrollViewAnimation, OBSGenericAnimation, OBSDiffScroller;


typedef enum CCDiffViewLineMask
{
	CCDiffViewLineAdded = 1,
	CCDiffViewLineRemoved = 2,
	CCDiffViewLineOriginal = 4
}CCDiffViewLineMask;


@interface CCDiffView : NSTextView {
	NSRect prevBounds;
	
	NSMutableArray *lines;
	NSMutableArray *hunks;
	NSMutableArray *hunkMarkers;
	
	NSMutableArray *lineIndexes; // start char index for every line.
	
	NSInteger selectedHunkMarker;
	
	NSInteger selectedHunkIndex;
	
	NSFont *font;
	NSRect fontBoundingRect;
	
	NSScrollView *scrollView;
	
	NSColor *currentSelectorColor;
	NSColor *currentSelectorStroke;
	OBSGenericAnimation *selectorAnimator;
	
	OBSDiffScroller *diffScroller;
	
	CCDiffViewController *controller;
	
	IBOutlet NSButton *prevButton;
	IBOutlet NSButton *nextButton;
	IBOutlet NSButton *stageButton;
}

@property (readonly)  NSMutableArray *lines;
@property (readwrite) NSInteger selectedHunkIndex;
@property (readwrite) NSInteger selectedHunkMarker;


- (id) initWithScrollView:(NSScrollView*) view 
					 font:(NSFont*) font
					lines:(NSMutableArray*) lines
					 mask:(CCDiffViewLineMask) mask
			   controller:(CCDiffViewController*) controller;

-(void) updateStorage:(NSTextStorage*) storage;

- (NSRange) charRangeFromLines:(NSRange) lineRange;

- (CCDiffHunk*) selectedHunk;


- (void) moveToNextDiff;
- (void) moveToPreviousDiff;

- (void) moveToDiff;

- (CCDiffHunk*) nextHunk;
- (CCDiffHunk*) prevHunk;

-(void) mergeTo:(CCDiffView*) dstView;


/**
	Returns YES if the hunk is in the visible part of the document view.
 */
- (BOOL) isHunkVisible:(NSUInteger) hunkIndex;


/**
	Returns the origin point of the hunk indexed by index.
 
 */
-(NSPoint) hunkOrigin:(NSUInteger) index;


-(void) removeHunk:(CCDiffHunk*) hunk;
-(void) removeSelectedHunk:(NSInteger) bias;

-(void) updateStorage:(NSRange) oldCharRange
		 newLineRange:(NSRange) newLineRange;

@end



