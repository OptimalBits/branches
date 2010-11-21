//
//  GFRepoWatcher.m
//  gitfend
//
//  Created by Manuel Astudillo on 11/21/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GFRepoWatcher.h"
#import "GitRepo.h"

#include <CoreServices/CoreServices.h>

void RepoWatcherStreamCallback ( ConstFSEventStreamRef streamRef,
						  	     void *clientCallBackInfo,
							     size_t numEvents,
							     void *eventPaths,
							     const FSEventStreamEventFlags eventFlags[],
							     const FSEventStreamEventId eventIds[] );

@interface GFRepoWatcher (Private)

-(void) callDelegate:(NSArray*) paths;

@end


@implementation GFRepoWatcher


-(id) initWithRepo:(GitRepo*) repo 
		  delegate:(id <GFRepoWatcherDelegate>) _delegate
{
	if ( self = [super init] )
	{
		delegate = _delegate;
		
		NSString *path = [[repo workingDir] path];
		NSArray *pathsToWatch = [NSArray arrayWithObject:path];
	
		CFAbsoluteTime latency = 1.0; 
		
		streamContext.version = 0;
		streamContext.info = self;
		streamContext.retain = NULL; 
		streamContext.release = NULL;
		streamContext.copyDescription = NULL;
		
		stream = FSEventStreamCreate( NULL,
									  RepoWatcherStreamCallback,
									  &streamContext,
									  (CFArrayRef) pathsToWatch,
									  kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
									  latency,
									  kFSEventStreamCreateFlagNone /* Flags explained in reference */
									  );
		
		FSEventStreamScheduleWithRunLoop( stream, 
										  CFRunLoopGetCurrent(),
										  kCFRunLoopDefaultMode );
		FSEventStreamStart( stream );
	}
	return self;
}

-(void) dealloc
{
	FSEventStreamStop( stream );
	FSEventStreamUnscheduleFromRunLoop( stream, 
									    CFRunLoopGetCurrent(), 
									    kCFRunLoopDefaultMode );
	FSEventStreamInvalidate( stream );
	FSEventStreamRelease( stream );
	
	[super dealloc];
}

-(void) callDelegate:(NSArray*) paths
{
	if ( delegate )
	{
		if ( [delegate respondsToSelector:@selector(modifiedDirectories:)] )
		{
			@synchronized(delegate)
			{
				[delegate modifiedDirectories:paths];
			}
		}
	}
}

@end


/**
	This callback will produce a list of paths that changes may have occured.
	The list is passed to the selector specified at the initialization.
 
 */
void RepoWatcherStreamCallback ( ConstFSEventStreamRef streamRef,
								 void *clientCallBackInfo,
								 size_t numEvents,
								 void *eventPaths,
								 const FSEventStreamEventFlags eventFlags[],
								 const FSEventStreamEventId eventIds[] )
{	
	FSEventStreamStop( streamRef );
	
	NSMutableSet *pathsToScan = [NSMutableSet set];
	
	int i;
    char **paths = eventPaths;
	
    // printf("Callback called\n");
    for (i=0; i < numEvents; i++) 
	{
		[pathsToScan addObject:[NSString stringWithUTF8String:paths[i]]];
		
		if ( eventFlags[i] & kFSEventStreamEventFlagMustScanSubDirs )
		{
			// Add all directories under this one.
		}
	
        /* flags are unsigned long, IDs are uint64_t */
        printf("Change %llu in %s, flags %lu\n", eventIds[i], paths[i], eventFlags[i]);
	}

	GFRepoWatcher *repoWatcher = clientCallBackInfo;
	[repoWatcher callDelegate:[pathsToScan allObjects]];
	
	FSEventStreamStart( streamRef );
}








