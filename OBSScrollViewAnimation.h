//
//  OBSScrollViewAnimation.h
//  gitfend
//
//  Created by Manuel Astudillo on 1/8/11.
//  Copyright 2011 Optimal Bits Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
	Animation class to provide smooth scroll to point animations on 
	scroll views.
 
 
 */
@interface OBSScrollViewAnimation : NSAnimation {
	NSScrollView *scrollView;
	NSPoint startPoint;
	NSPoint targetPoint;
}

-(id) initWithScrollView:(NSScrollView*) scrollView
				duration:(NSTimeInterval) duration
		  animationCurve:(NSAnimationCurve) animationCurve;

/**
	Starts an animation that scrolls from current point to the specified point.
 
	
 */
-(void) scrollToPoint:(NSPoint) targetPoint;

@end
