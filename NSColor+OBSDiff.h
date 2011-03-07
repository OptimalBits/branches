//
//  NSColor+OBSDiff.h
//  gitfend
//
//  Created by Manuel Astudillo on 1/15/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (OBSDiff) 

+(NSColor*) modifiedLineColor;
+(NSColor*) addedLineColor;
+(NSColor*) removedLineColor;
+(NSColor*) selectedLineColor;
+(NSColor*) charDiffColor;
+(NSColor*) emptyLineColor;

@end
