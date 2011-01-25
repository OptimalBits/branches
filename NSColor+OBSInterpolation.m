//
//  NSColor+OBSInterpolation.m
//  gitfend
//
//  Created by Manuel Astudillo on 1/18/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import "NSColor+OBSInterpolation.h"


@implementation NSColor (OBSInterpolation)

+(NSColor*) interpolateStartColor:(NSColor*) startColor 
						 endColor:(NSColor*) endColor 
						   factor:(float) factor
{
	float startRed, startGreen, startBlue, startAlpha;
	float endRed, endGreen, endBlue, endAlpha;
	
	float red, green, blue, alpha;
	
    [startColor getRed:&startRed 
				 green:&startGreen 
				  blue:&startBlue
				 alpha:&startAlpha];
	
	[endColor getRed:&endRed 
			   green:&endGreen
				blue:&endBlue
			   alpha:&endAlpha];
	
	red	  = startRed   * (1-factor) + endRed   * factor;
	green = startGreen * (1-factor) + endGreen * factor;
	blue  = startBlue  * (1-factor) + endBlue  * factor;
	alpha = startAlpha * (1-factor) + endAlpha * factor;
	
	return [NSColor colorWithCalibratedRed:red
									 green:green
									  blue:blue
									 alpha:alpha];
}

+(NSColor*) interpolateAlpha:(NSColor*) color 
					  factor:(float) factor
{
	float red, green, blue, alpha;
	
    [color getRed:&red 
			green:&green 
			 blue:&blue
			alpha:&alpha];
		
	//alpha = startAlpha * (1-factor) + endAlpha * factor;
	
	return [NSColor colorWithCalibratedRed:red
									 green:green
									  blue:blue
									 alpha:factor];
}



@end
