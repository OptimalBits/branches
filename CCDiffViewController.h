//
//  CCDiffViewController.h
//  Branches
//
//  Created by Manuel Astudillo on 9/10/10.
//  Copyright 2010 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NoodleLineNumberView;
@class CCDiffView, CCDiffViewModel, OBSScrollViewAnimation;

@interface CCDiffViewController : NSViewController {
	CCDiffView *leftView;
	CCDiffView *rightView;
	
	CCDiffViewModel *diffViewModel;
	
	IBOutlet NSScrollView *leftScrollView;
	IBOutlet NSScrollView *rightScrollView;
	
	OBSScrollViewAnimation *leftScrollViewAnimator;
	OBSScrollViewAnimation *rightScrollViewAnimator;
	
	NoodleLineNumberView *lineNumberViewLeft;
	NoodleLineNumberView *lineNumberViewRight;
	
	BOOL ignoreViewSynchronization;
}

- (id) init;

- (void) setStringsBefore:(NSString*) before andAfter:(NSString*) after;

- (void) bindScrollViews;
- (void) unbindScrollViews;

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;

- (IBAction) mergeToRight:(id) sender;
- (IBAction) mergeToLeft:(id) sender;

- (IBAction) stageDiff:(id) sender;
- (IBAction) nextDiff:(id) sender;
- (IBAction) prevDiff:(id) sender;

- (void) gotoDiffIndex:(NSUInteger) index;

@end
