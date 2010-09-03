//
//  GitIndex.h
//  GitLib
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitObjectStore;
@class GitBlobObject;
@class GitIgnore;

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

@property (readwrite, copy) NSString *filename;

-(EntryInfo*) entryInfo;
-(NSData*) sha1;

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
	Returns a dictionary of (name, GitFileStatus) objects.
 
 */
-(NSDictionary*) status:(NSDictionary*) flattenedTree;

/**
	Returns the status of the given filename.
	The 
 
 */
//-(GitFileStatus) fileStatus:(NSString*) filename;


/**
	Returns a list of the files that have been modified in the 
	working directory.
 
	i.e. do a stat in every file present in the index, and returns 
	the ones that have been modified.
 */
-(NSSet*) modifiedFiles:(NSURL*) workDir;


/**
	Check if a file is tracked.
	
 */
-(BOOL) isFileTracked:(NSString*) filename;


/**  
	Return a set with all the ignored files 
	in the repository.
 */
-(NSSet*) ignoredFiles:(NSURL*) workDir;
 

/**
	Return set with all the staged files.
 */
-(NSArray*) stagedFiles;


/**
	 
 */
-(void) updateFilename: (NSURL*) url;

/**
	Adds a file to the index.
 */
-(void) addFile:(NSString*) filename sha1:(NSData*) sha1;



-(void) removeFile:(NSURL*) url;

////
-(void) checkoutFilename: (NSURL*) url;
-(void) checkout;

///
-(void) commitTree:(NSData*) tree withParents:(NSArray*) parents;

@end


