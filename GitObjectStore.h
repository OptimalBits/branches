//
//  GitObjectStore.h
//  gitfend
//
//  Created by Manuel Astudillo on 6/13/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitpackfile.h"
#import "gitobject.h"
#import "gittreeobject.h"


@protocol GitNodeVisitor
-(BOOL) visit:(GitObject*) object;
@end


@interface GitObjectStore : NSObject {
	NSURL *url;
	NSURL *objectsUrl;
	GitPackFile *packFile;
	NSMutableArray *packFiles; // There can be more than one, so we need to have an array.	
}

/**
	Init with the url pointing to the .git directory.
 
 */
-(id) initWithUrl:(NSURL*) url;

-(id) getObject:(NSData*) sha1;



-(void) walk: (NSData*) commitSha with: (id) visitor;


/**
	Computes the history for given file starting from the given commit.
 
	max = 0, means all the history.
 
	@return an array of Sha keys for the commits that modified the given file.
 
	Note: This function can be called successivelly, setting a max value different from zero.
    This is because the whole history can take a really long time to be computed.
 
 */
-(NSArray*) fileHistory:(NSString*) filename 
			 fromCommit:(NSData*) sha1 
			   maxItems:(uint32_t) max;


/**
  Flattens the tree object so that every entry points to
  a blob object.
  
  Note: the flattened structure is a convenient representation
  for comparing tree objects against the index.
 
  The keys of the dictionary are the filenames, and the value are 
  GitTreeNode objects.
  
  */
-(NSDictionary*) flattenTree:(GitTreeObject*) tree;


/**
	Returns the tree related to the given commit.
 */
-(id) getTreeFromCommit:(NSData*) sha1;


/**
 Returns a dictionary with every file in the given tree associated to the sha 
 with the last commit where it was modified.
 
 @param tree the tree with files.
 @param sha1 a sha1 key associated to the "head" commit for the operation.
 
 TODO: Move to a dedicated class GitCommits
 */
- (NSDictionary*) lastModifiedCommits:(GitTreeObject*) tree 
								 sha1:(NSData*) sha1;

/**
	Adds the given object to the object store.
 
	returns the sha1 key if succesfull, nil otherwise.
 
 */
-(NSData*) addObject: (GitObject*) object;

/**
	Deletes an object from the object database.
	
	This function is meant to "undo" the addObject operation, and when it is 
	known that no other object in the database is depending on it.
	The common case is when adding objects to the index that are not yet 
	committed, or when adding a file hunk by hunk, where the latest hunk
	is always containing the previous hunks ( therefore they can be safely 
	deleted ).
 
	Note:
	It can only delete objects that are loose. Note that it can delete 
	an object even if other objects depend on it, creating corrupted object 
	stores if used wrongly.
 
 */
-(BOOL) deleteObject: (NSData*) sha1;


@end
