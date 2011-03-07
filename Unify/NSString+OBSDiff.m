//
//  NSString+OBSDiff.m
//  Unify
//
//  Created by Manuel Astudillo on 2/27/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "NSString+OBSDiff.h"

@implementation NSString (OBSDiff)

- (NSArray*) arrayWithStringCharacters
{
	NSMutableArray *array;
	
	NSRange		range;
	NSUInteger  length;
	NSUInteger  i;
	
	range.length = 1;
	length = [self length];
	
	array = [NSMutableArray arrayWithCapacity:length];
	
	for ( i = 0; i < length; i++ )
	{
		range.location = i;
		[array addObject:[self substringWithRange:range]];
	}
	
	return array;
}

- (NSArray*) arrayWithStringLines
{
	NSMutableArray *lines = [[[NSMutableArray alloc] init] autorelease];
	[self enumerateLinesUsingBlock:
	 ^(NSString *line, BOOL *stop){[lines addObject:line];}];
	
	if ( ([self hasSuffix:@"\n"]) || ([self hasSuffix:@"\r"]) )
	{
		[lines addObject:[NSString stringWithString:@""]];
	}
	
	return lines;
}

@end
