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
@class GitReferenceStorage;
@class GitRefLog;
@class GitIndex;
@class GitAuthor;


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
	
	GitReferenceStorage *refs;
	GitRefLog *refLog;

	GitObjectStore *objectStore;
		
	GitIndex *index;
}

@property (readwrite,retain) NSString *name;
@property (readonly) NSURL* url;
@property (readonly) NSURL* workingDir;

@property (readonly) GitReferenceStorage *refs;

@property (readonly) GitObjectStore *objectStore;
@property (readonly) GitIndex *index;


//@property (readonly) NSString *description;
//@property (readonly) GitConfig *config;

/**
	Fast check to see if it is seemingly a valid repo.
 */
+ (BOOL) isValidRepo:(NSURL*) workingDir;

/**
	Creates a new repo on the given working directory.
	The directory maybe empty, or not. If the directory already
	contains a repo, missing default directories and templates will
	be added.
 */
+ (BOOL) makeRepo:(NSURL*) workingDir
	  description:(NSString*) description
			error:(NSError**) error;

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
	Returns a Flattened dictionary with the tree pointed by the
	commit in the HEAD.
 
 */
-(NSDictionary*) headTree;


/**
	Returns the history for a given sha. 
 
	TODO: Move to a dedicated class: GitHistory
 */
- (NSArray*) revisionHistoryFor:(NSData*) sha1;


/**
	Makes a commit and stores in the object store.
 
	Notes:
	The commit will be created as a child of the last commit in the head
	branch. If the index does not have any data staged, the function will 
	just return false and do nothing.
 
 
 */
- (BOOL) makeCommit:(NSString*) message 
			 author:(GitAuthor*) author
		   commiter:(GitAuthor*) commiter;


@end


