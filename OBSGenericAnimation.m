//
//  OBSGenericAnimation.m
//  OBSFoundation
//
//  Created by Manuel Astudillo on 1/9/11.
//  Copyright 2011 Optimal Bits Software. All rights reserved.
//

#import "OBSGenericAnimation.h"

@protocol OBSGenericAnimationDelegate

-(void) updateAnimation:(NSAnimationProgress) progress;

@end


@implementation OBSGenericAnimation

-(id) initWithView:(NSView*) _targetView
		  delegate:(id<OBSGenericAnimationDelegate>) _delegate
		  duration:(NSTimeInterval) duration
			 curve:(NSAnimationCurve) curve;

{
	self = [super initWithDuration: duration animationCurve: curve];
	if ( self )
	{
		targetView = _targetView;
		[targetView retain];
		
		delegate = _delegate;
		[delegate retain];
		
		[self setAnimationBlockingMode:NSAnimationNonblocking];
		[self setFrameRate:60];
	}
	
	return self;
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
	[super setCurrentProgress:progress];
		
	[delegate updateAnimation:progress];
	
	
	[targetView setNeedsDisplay:YES];
	
	if ([NSThread isMainThread])
	{
		[targetView displayIfNeeded];
	}
	else
	{
		[targetView performSelectorOnMainThread:@selector(displayIfNeeded)
									 withObject:nil waitUntilDone:NO];
	}
}

@end
