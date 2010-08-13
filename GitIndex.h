//
//  GitIndex.h
//  gitfend
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitObjectStore;

typedef struct
{
	uint64_t ctime;
	uint64_t mtime;
	uint32_t dev;
	uint32_t inode;
	uint32_t mode;
	uint32_t uid;
	uint32_t gid;
	uint32_t size;
} EntryInfoStat;

typedef struct
{
	EntryInfoStat stat;
	uint8_t  sha1[20];
	uint16_t flags;
} EntryInfo;

@interface GitIndexEntry : NSObject
{
	EntryInfo entryInfo;
	NSString *filename;
}

@property (readwrite, retain) NSString *filename;

-(EntryInfo*) entryInfo;



@end


@interface GitIndex : NSObject {
	NSMutableDictionary *entries;
}

-(id) initWithUrl:(NSURL*) url;

/**
	Populates an index object from a given Sha1 key representing a tree.
 
	This function is equivalent to 'git read-tree'
 
 */
-(id) initWithTree:(NSURL*) workingDirectory
			  tree:(NSData*) sha1 
	   objectStore:(GitObjectStore*) objectStore;

-(void) dealloc;


/**
	Writes the index to the specified url.
 
 */
-(void) write:(NSURL*) url;


/**
	Writes the index as as a tree object into the object storage.
	
	Returns the Sha1 key of the resulting tree.
 */
-(NSData*) writeTree: (GitObjectStore*) objectStore;


/**
	Returns an array of GitFileStatus objects:
	
	( 3 status: Added, Deleted, Modified:
		Added: file is in index but not in tree.
	  Deleted: file is in tree but not in index.
	 Modified: Sha1 keys are different ( for the blob representing the file ).

 */
-(NSArray*) status:(NSData*) tree;


/**
	Returns a list of the files that have been modified in the working directory.
 
	i.e. do a stat in every file present in the index, and returns the ones that
	have been modified.

 */
-(NSArray*) modifiedFiles:(NSURL*) workDir;

/**
	 
 */
-(void) updateFilename: (NSURL*) url;

-(void) addFile:(NSURL*) url;
-(void) removeFile:(NSURL*) url;

////
-(void) checkoutFilename: (NSURL*) url;
-(void) checkout;

///
-(void) commitTree:(NSData*) tree withParents:(NSArray*) parents;

@end
