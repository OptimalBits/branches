//
//  CCDiffViewController.h
//  Branches
//
//  Created by Manuel Astudillo on 9/10/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NoodleLineNumberView;
@class CCDiffView;

@interface CCDiffViewController : NSViewController {
	CCDiffView *leftView;
	CCDiffView *rightView;
	
	IBOutlet NSScrollView *leftScrollView;
	IBOutlet NSScrollView *rightScrollView;
	
	NoodleLineNumberView *lineNumberViewLeft;
	NoodleLineNumberView *lineNumberViewRight;
}


-(id) init;

-(void) setStringsBefore:(NSString*) before andAfter:(NSString*) after;

-(void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;


@end
