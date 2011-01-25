//
//  OBSScrollViewAnimation.m
//  gitfend
//
//  Created by Manuel Astudillo on 1/8/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import "OBSScrollViewAnimation.h"


@implementation OBSScrollViewAnimation

-(id) initWithScrollView:(NSScrollView*) _scrollView
				duration:(NSTimeInterval) duration
		  animationCurve:(NSAnimationCurve) animationCurve
{
	self = [super initWithDuration: duration 
					animationCurve: animationCurve];
	if ( self )
	{
		scrollView = _scrollView;
		[scrollView retain];
		
		[self setAnimationBlockingMode:NSAnimationNonblockingThreaded];
		[self setFrameRate:60];
	}
	
	return self;
}

-(void) dealloc
{
	[super dealloc];
	
	[scrollView release];
}

-(void) scrollToPoint:(NSPoint) _targetPoint
{
	NSRect rect = [[scrollView contentView] documentVisibleRect];
	
	startPoint = rect.origin;
	targetPoint = _targetPoint;
	
	[super startAnimation];
}

-(void) setCurrentProgress:(NSAnimationProgress)progress
{
	[super setCurrentProgress:progress];
		
	NSPoint newPosition;
	
	newPosition.x = startPoint.x * ( 1 - progress ) + targetPoint.x * progress;
	newPosition.y = startPoint.y * ( 1 - progress ) + targetPoint.y * progress;
		
	if ( progress != 1.0 )
	{
		[[scrollView contentView] setBoundsOrigin:newPosition];
	}
	else
	{
		[[scrollView contentView] scrollToPoint:newPosition];
	}
	[scrollView reflectScrolledClipView:[scrollView contentView]];
			
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

