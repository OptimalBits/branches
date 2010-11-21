//
//  GitFile.m
//  gitfend
//
//  Created by Manuel Astudillo on 8/9/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitFile.h"


@implementation GitFile

@synthesize filename;
@synthesize status;
@synthesize url;

-(id) initWithUrl:(NSURL*) _url andStatus:(GitFileStatus) _status
{
	if ( self = [super init] )
	{
		[self setUrl:_url];
		[self setFilename:[_url lastPathComponent]];
		[self setStatus:_status];
	}
	return self;
}

-(id) initWithName:(NSString*) _filename andStatus:(GitFileStatus) _status
{
	if ( self = [super init] )
	{
		[self setFilename:_filename];
		[self setStatus:_status];
		
	}
	return self;
}


-(void) dealloc
{
	[filename release];
	[super dealloc];
}



@end
