//
//  CCDiffViewController.h
//  Branches
//
//  Created by Manuel Astudillo on 9/10/10.
//  Copyright 2010 Optimal Bits Sweden AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CCDiffView, CCDiffViewModel, OBSScrollViewAnimation;

@interface CCDiffViewController : NSViewController <NSAnimationDelegate>{
	CCDiffView *leftView;
	CCDiffView *rightView;
	
	CCDiffViewModel *diffViewModel;
	
	IBOutlet NSScrollView *leftScrollView;
	IBOutlet NSScrollView *rightScrollView;
	
	OBSScrollViewAnimation *leftScrollViewAnimator;
	OBSScrollViewAnimation *rightScrollViewAnimator;
		
	BOOL ignoreViewSynchronization;
	BOOL allowMoveHunkMarker;
	
	NSFont *font;
}

- (id) init;

- (void) setStringsBefore:(NSString*) before andAfter:(NSString*) after;

- (void) bindScrollViews;
- (void) unbindScrollViews;

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;

- (IBAction) nextDiff:(id) sender;
- (IBAction) prevDiff:(id) sender;
- (IBAction) mergeRight:(id) sender;
- (IBAction) mergeLeft:(id) sender;

- (void) merge:(CCDiffView*) srcView to:(CCDiffView*) dstView;

- (void) gotoDiffIndex:(NSUInteger) index;

- (void) setHunkSelector:(NSInteger) index;


@end
