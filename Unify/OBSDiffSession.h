//
//  OBSDiffSession.h
//  Unify
//
//  Created by Manuel Astudillo on 1/31/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OBSDirectory, OBSDirectoryWatcher, GitIgnore;

@interface OBSDiffSource : NSObject <NSCoding>
{
	NSURL *url;
}

@end


/**
	This object represents a difference session.
 
 */
@interface OBSDiffSession : NSObject {

	NSString *name;
	
	OBSDirectory *leftSource;
	OBSDirectory *rightSource;
	
	OBSDirectoryWatcher *leftSourceWatcher;
	OBSDirectoryWatcher *rightSourceWatcher;
	
	GitIgnore *filters;
}

@property (readwrite, retain) OBSDirectory *leftSource;
@property (readwrite, retain) OBSDirectory *rightSource;

- (void) setName:(NSString*) name;
- (NSString*) name;

- (NSTreeNode*) diffTree;

@end
