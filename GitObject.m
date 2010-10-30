//
//  gitobject.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/20/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GitObject.h"
#import "NSDataExtension.h"

@implementation GitObject


-(id) initWithType:(NSString*) _type
{
	if ( self = [super init] )
	{
		type = _type;
		[type retain];
	}
	
	return self;
}

-(void) dealloc
{
	[type release];
	[super dealloc];
}

-(NSData*) data
{
	return nil;
}
/*
-(NSData*) sha1
{
	return nil;
}
 */

-(NSData*) encode
{
	NSData *content = [self data];
	
	NSString *header = 
		[NSString stringWithFormat:@"%@ %d", type, [content length]];
	
	const char* cString = [header UTF8String];
	
	NSMutableData *data = [NSMutableData dataWithCapacity:
						   [header length] + [content length] + 1];
	
	// length is wrong here, it is characters not number of bytes!
	[data appendData:[NSData dataWithBytes:cString length:[header length] + 1]];
	[data appendData:content];
	
	return data;
}

-(NSData*) sha1
{
	return [[self encode] sha1Digest];
}


@end

