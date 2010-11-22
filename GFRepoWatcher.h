//
//  GFRepoWatcher.h
//  gitfend
//
//  Created by Manuel Astudillo on 11/21/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol GFRepoWatcherDelegate <NSObject>

-(void) modifiedDirectories:(NSArray*) directories;

@end


@class GitRepo;


@interface GFRepoWatcher : NSObject {
	FSEventStreamRef stream;
	FSEventStreamContext streamContext;
	
	id <GFRepoWatcherDelegate> delegate;
}

-(id) initWithRepo:(GitRepo*) repo 
		  delegate:(id <GFRepoWatcherDelegate>) delegate;

@end
