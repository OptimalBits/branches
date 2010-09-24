//
//  CCDiffView.h
//  gitfend
//
//  Created by Manuel Astudillo on 9/18/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum CCDiffViewLineMask
{
	CCDiffViewLineAdded = 1,
	CCDiffViewLineRemoved = 2,
	CCDiffViewLineOriginal = 4
}CCDiffViewLineMask;


@interface CCDiffView : NSTextView {
	NSMutableArray *lines;
	NSFont *font;
	NSRect fontBoundingRect;
}

//- (id) initWithScrollView:(NSScrollView*) view;

- (id) initWithScrollView:(NSScrollView*) view 
					 font:(NSFont*) font
					lines:(NSArray*) lines
					 mask:(CCDiffViewLineMask) mask;

@end
