//
//  GitBlobObject.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GitBlobObject.h"


@implementation GitBlobObject

- (id) initWithData: (NSData*) data
{	
	if ( self = [super init] )
	{
		content = [NSData dataWithData:data];
	}
	
	return self;
}

@end
