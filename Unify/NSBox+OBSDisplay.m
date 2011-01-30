//
//  NSBox+OBSDisplay.m
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "NSBox+OBSDisplay.h"


@implementation NSBox (OBSDisplay)

-(void) displayViewController:(NSViewController*) vc
{
	NSWindow *w = [self window];
	
	BOOL ended = [w makeFirstResponder:w];
	if( !ended )
	{
		NSBeep();
		return;
	}
	
	NSView *v = [vc view];
	[self setContentView:v];
}

@end
