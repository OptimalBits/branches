//
//  CCDiffView.h
//  gitfend
//
//  Created by Manuel Astudillo on 9/18/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "CCDiff.h"

typedef enum CCDiffViewLineMask
{
	CCDiffViewLineAdded = 1,
	CCDiffViewLineRemoved = 2,
	CCDiffViewLineOriginal = 4
}CCDiffViewLineMask;


typedef struct CCDiffHunk
{
	NSUInteger startLine;
	NSUInteger endLine;
	NSUInteger startCharIndex;
	NSUInteger endCharIndex;
	
	LineDiffStatus	status;
} CCDiffHunk;


@interface CCDiffView : NSTextView {
	NSMutableArray *lines;
	NSMutableArray *hunks;
	
	NSUInteger selectedHunk;
	
	NSFont *font;
	NSRect fontBoundingRect;
	
	NSScrollView *scrollView;
}

@property (readwrite, nonatomic) NSUInteger selectedHunk;

//- (id) initWithScrollView:(NSScrollView*) view;

- (id) initWithScrollView:(NSScrollView*) view 
					 font:(NSFont*) font
					lines:(NSArray*) lines
					 mask:(CCDiffViewLineMask) mask;

- (void) moveToNextDiff;
- (void) moveToPreviousDiff;

@end

