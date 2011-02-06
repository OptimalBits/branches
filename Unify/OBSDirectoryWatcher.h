//
//  OBSDirectoryWatcher.h
//  Unify
//
//  Created by Manuel Astudillo on 1/31/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol OBSDirectoryWatcherDelegate <NSObject>

-(void) modifiedDirectories:(NSArray*) directories;

@end


/**
	Class that wrapps FSEvents in order to update directories that
	have changed faster than traversing them and checking every file one
	by one.
 
 */
@interface OBSDirectoryWatcher : NSObject {
	FSEventStreamRef stream;
	FSEventStreamContext streamContext;
	
	id <OBSDirectoryWatcherDelegate> delegate;
}

-(id) initWithPath:(NSString*) path 
		  delegate:(id <OBSDirectoryWatcherDelegate>) delegate;

@end
