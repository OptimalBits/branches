//
//  gitrepo.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/8/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GitObjectStore.h"

@class GitReference;
@class GitIndex;


@interface GitHistoryVisitor: NSObject <GitNodeVisitor>
{
	NSMutableArray *history;
}

@property (readonly) NSArray *history;

-(BOOL) visit:(GitObject *)object;

@end



@interface GitRepo : NSObject <NSCoding> {
	NSString *name;
	NSURL* url;
	NSURL* workingDir;
	
	GitReference *head;
	NSMutableDictionary *refs;	// ( name, GitReference )

	GitObjectStore *objectStore;
		
	GitIndex *index;
}

@property (readwrite,retain) NSString *name;
@property (readonly) NSURL* url;
@property (readonly) NSURL* workingDir;
@property (readonly) GitReference *head;
@property (readonly) NSMutableDictionary *refs;
@property (readonly) GitObjectStore *objectStore;
@property (readonly) GitIndex *index;

//@property (readonly) NSString *description;
//@property (readonly) GitObject *head;
//@property (readonly) GitConfig *config;


/**
	Fast check to see if it is seemingly a valid repo.
 */
+ (BOOL) isValidRepo:(NSURL*) workingDir;

- (id) initWithUrl: (NSURL*) path name:(NSString*) name;
- (void) dealloc;

- (id) initWithCoder: (NSCoder *)coder;
- (void) encodeWithCoder: (NSCoder *)coder;

// (void) createHead:
// (void) createTag:
// (void) createRemote:
/// ...

//- (GitCommit*) commit:(Sha1) sha1;

/**
	Finds and returns the object that matches the given sha key.
 
	Returns nil if the object is not found.
 
 */
- (id) getObject:(NSData*) sha1;

-(NSData*) resolveReference:(NSString*) refName;

/**
	Returns the history for a given sha. 
 
	TODO: Move to a dedicated class: GitHistory
 */
- (NSArray*) revisionHistoryFor:(NSData*) sha1;


@end


