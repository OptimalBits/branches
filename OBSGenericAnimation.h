//
//  OBSGenericAnimation.h
//  gitfend
//
//  Created by Manuel Astudillo on 1/9/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
	This class can be used to create animations that are rendered into views.
 
	The idea is to provide a delegate that will render one frame in the 
    animation according to the given progress.
 
	The class provides better animation curves that the standard ones provided
	by NSAnimation.
 
 */
@interface OBSGenericAnimation : NSAnimation {
	id delegate;
	NSView *targetView;
}

-(id) initWithView:(NSView*) targetView
		  delegate:(id) delegate
		  duration:(NSTimeInterval) duration
			 curve:(NSAnimationCurve) curve;

@end
