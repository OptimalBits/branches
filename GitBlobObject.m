//
//  GitBlobObject.m
//  GitLib
//
//  Created by Manuel Astudillo on 5/29/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitBlobObject.h"


@implementation GitBlobObject

- (id) initWithData: (NSData*) data
{	
	if ( self = [super init] )
	{
		// Why make a copy here?
		content = [NSData dataWithData:data];
	}
	
	return self;
}

- (NSData*) data
{
	return content;
}

@end
