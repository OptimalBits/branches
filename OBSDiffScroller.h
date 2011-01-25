//
//  OBSDiffScroller.h
//  gitfend
//
//  Created by Manuel Astudillo on 1/13/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
	Customized scroller to be used for text views that present hunks of
	changes.
 
	Note: this scroller can be used for showing vertical or horizontal diff 
	marks.

 */
@interface OBSDiffScroller : NSScroller {
	NSArray *hunks;
	NSUInteger numLines;
}

- (id) initWithHunks:(NSArray*) hunks numLines:(NSUInteger) numLines;

- (void) drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag;


@end
