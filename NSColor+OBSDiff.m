//
//  NSColor+OBSDiff.m
//  gitfend
//
//  Created by Manuel Astudillo on 1/15/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import "NSColor+OBSDiff.h"


@implementation NSColor (OBSDiff)


+(NSColor*) modifiedLineColor
{
	static NSColor*  _modifiedLineColor = nil;
	
	if( _modifiedLineColor == nil )
	{
		_modifiedLineColor = [NSColor colorWithCalibratedRed:0.96 
													   green:0.882
														blue:0.537 
													   alpha:1.0];
		[_modifiedLineColor retain];
	}
	
	return _modifiedLineColor;
}


+(NSColor*) removedLineColor
{
	static NSColor*  _removedLineColor = nil;
	
	if( _removedLineColor == nil )
	{
		_removedLineColor = [NSColor colorWithCalibratedRed:0.96 
													  green:0.557 
													   blue:0.478 
													  alpha:1.0];
		[_removedLineColor retain];
	}
	
	return _removedLineColor;
}

+(NSColor*) addedLineColor
{
	static NSColor*  _addedLineColor = nil;
	
	if( _addedLineColor == nil )
	{
		_addedLineColor = [NSColor colorWithCalibratedRed:0.749
													green:0.859 
													 blue:0.514
													alpha:1.0];
		[_addedLineColor retain];
	}
	
	return _addedLineColor;
}

+(NSColor*) selectedLineColor
{
	static NSColor*  _selectedLineColor = nil;
	
	if( _selectedLineColor == nil )
	{
		_selectedLineColor = [NSColor colorWithCalibratedRed:0.545
													   green:0.721 
														blue:0.902
													   alpha:1.0];
		[_selectedLineColor retain];
	}
	
	return _selectedLineColor;
}

+(NSColor*) emptyLineColor
{
	static NSColor*  _emptyLineColor = nil;
	
	if ( _emptyLineColor == nil)
	{
		NSBundle *bundle = [NSBundle mainBundle];
	
		NSURL *imageUrl = [bundle URLForResource:@"shizoo46" 
								   withExtension:@"jpg"];
		
		NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageUrl];
	
		_emptyLineColor = [NSColor colorWithPatternImage:image];
	
		[image release];
	
		[_emptyLineColor retain];				   
	}
	
	return _emptyLineColor;
}





@end
