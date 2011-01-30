//
//  OBSTextCell.h
//  Unify
//
//  Created by Manuel Astudillo on 1/30/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface OBSTextCell : NSTextFieldCell {

@private NSImage *image;
}

- (NSImage*) image;
- (void) setImage:(NSImage *) image;

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView*) view;
- (NSSize) cellSize;

@end
