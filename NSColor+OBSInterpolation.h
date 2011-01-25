//
//  NSColor+OBSInterpolation.h
//  gitfend
//
//  Created by Manuel Astudillo on 1/18/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (OBSInterpolation) 

+(NSColor*) interpolateStartColor:(NSColor*) startColor 
						 endColor:(NSColor*) endColor 
						   factor:(float) factor;

+(NSColor*) interpolateAlpha:(NSColor*) color 
					  factor:(float) factor;

@end
