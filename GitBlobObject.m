//
//  GitBlobObject.m
//  GitLib
//
//  Created by Manuel Astudillo on 5/29/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitObject.h"
#import "GitBlobObject.h"

@implementation GitBlobObject

- (id) initWithData: (NSData*) data
{	
	if ( self = [super initWithType:@"blob"] )
	{
		content = data;
		[content retain];
	}
	
	return self;
}

-(void) dealloc
{
	[content release];
	[super dealloc];
}

- (NSData*) data
{
	return content;
}

-(NSData*) sha1
{
	return [super sha1];
}


@end
