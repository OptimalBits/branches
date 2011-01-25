//
//  CCDiffView.h
//  gitfend
//
//  Created by Manuel Astudillo on 9/18/10.
//  Copyright 2010 CodeTonic. All rights reserved.
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
	
	NSArray *lines;
	NSMutableArray *hunks;
	NSMutableArray *hunkMarkers;
	NSInteger selectedHunkMarker;
	
	NSUInteger selectedHunk;
	
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

- (id) initWithScrollView:(NSScrollView*) view 
					 font:(NSFont*) font
					lines:(NSArray*) lines
					 mask:(CCDiffViewLineMask) mask
			   controller:(CCDiffViewController*) controller;


- (NSUInteger) selectedHunkIndex;
- (CCDiffHunk*) selectedHunk;


- (void) moveToNextDiff;
- (void) moveToPreviousDiff;

- (void) moveToDiff;


/**
	Returns the origin point of the hunk indexed by index.
 
 */
-(NSPoint) hunkOrigin:(NSUInteger) index;


-(void) removeHunk:(CCDiffHunk*) hunk;
-(void) removeSelectedHunk:(NSInteger) bias;

@end

