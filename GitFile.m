//
//  GitFile.m
//  gitfend
//
//  Created by Manuel Astudillo on 8/9/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitFile.h"
#include <sys/stat.h>


@implementation GitFile

@synthesize filename;
@synthesize status;
@synthesize url;
@synthesize mode;


-(id) initWithUrl:(NSURL*) _url
{
	return [self initWithUrl:_url andStatus:kFileStatusUnknown];
}

-(id) initWithUrl:(NSURL*) _url andStatus:(GitFileStatus) _status
{
	return [self initWithUrl:_url status:_status andMode:0];
}

-(id) initWithUrl:(NSURL*) _url 
		   status:(GitFileStatus) _status
		  andMode:(uint32_t) _mode
{
	if ( self = [super init] )
	{
		[self setUrl:_url];
		[self setFilename:[_url lastPathComponent]];
		
		if ( _mode )
		{
			mode = _mode;
		}
		else
		{
			[self updateMode];
		}

		if ( _status )
		{
			[self setStatus:_status];
		}
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
	[url release];
	[filename release];
	[super dealloc];
}

-(void) updateMode
{
	NSError *error;
	struct stat fileStat;
	
	NSFileHandle *fileHandle =
		[NSFileHandle fileHandleForReadingFromURL:url
											error:&error];
	if ( fileHandle )
	{
		if ( fstat([fileHandle fileDescriptor], &fileStat ) == 0 )
		{
			mode = fileStat.st_mode;
		}
		[fileHandle closeFile];
	}
}

@end

