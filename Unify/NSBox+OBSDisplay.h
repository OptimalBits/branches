//
//  NSBox+OBSDisplay.h
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/**
	Adds support for displaying a given view on a NSBox.
 
 */
@interface NSBox (OBSDisplay)

-(void) displayViewController:(NSViewController*) vc;

@end
