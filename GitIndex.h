//
//  GitIndex.h
//  GitLib
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GitFile.h" // GitFileStatus

@class GitObjectStore;
@class GitBlobObject;
@class GitIgnore;
@class GitTreeObject;


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


/**
	GitIndexEntry - Represents one entry in the index file.
 
	Besides the standard fields present in a git index entry, there is also
	a field for a blob object. This field may be nil, that means that the
	sha1 key is pointing to an object in the object store.
 
	If the blob field is not nil, it means that the object has been staged
	but it is not yet in the object store. This field is used to allow adding
	objects to the index without poluting the database. When making a commit,
	all the objects left in the blob will be stored in the database.
 
 */

@interface GitIndexEntry : NSObject
{
	EntryInfo entryInfo;
	NSString *filename;
	GitBlobObject *blob;
}

@property (readwrite, copy) NSString *filename;

-(EntryInfo*) entryInfo;
-(NSData*) sha1;
-(void) setBlob:(GitBlobObject*) blob;
-(GitBlobObject*) blob;

@end


@interface GitIndex : NSObject {
	NSMutableDictionary *entries;		// Flattened dictionary of entries
	
	NSMutableDictionary *commitTree;  // Latest commited tree.
	NSMutableDictionary *stagedFiles; // Dictionary of blob objects.
									  // Filename is the full path.
	NSURL *url;
	BOOL isDirty;
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
	Overwrites the index with the current one.
 
 */
-(void) write;


/**
	Writes the index as a tree object into the object storage,
	as well as all the blob objects that have been added.
	
	Returns the Sha1 key of the resulting tree. 
	If the index has no staged objects, the function will return nil.
 */
-(NSData*) writeTree:(GitObjectStore*) objectStore 
		headTreeSha1:(NSData*) treeSha1;


/**
	Returns a dictionary of (name, GitFileStatus) *staged* objects.
 
	Note: this function is not exactly the same as git status, which also 
	returns the status of the working directory files.
 
 */
-(NSDictionary*) stageStatus:(NSDictionary*) flattenedTree;

/**
	Returns the status of the given file in the working directory.
 
 */
-(GitFileStatus) fileStatus:(NSURL*) fileUrl workingDir:(NSString*) workingDir;


/**
	Returns a list of the files that have been modified in the 
	working directory.
 
	i.e. do a stat in every file present in the index, and returns 
	the ones that have been modified.
 */
-(NSSet*) modifiedFiles:(NSURL*) workDir;


/**
	Checks if a file has been modified. Returns true whether the file content
	or the file mode have been modified.
 
	@params fileUrl The absolute file path to the file.
	@params filename The filename relative the root of the working dir.
 
 */
-(BOOL) isFileModified:(NSURL*) fileUrl filename:(NSString*) filename;

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
	Returns the Sha1 key for the blob associated to the filename.
 */
-(NSData*) sha1ForFilename:(NSString*) filename;

/**
	 
 */
-(void) updateFilename: (NSURL*) url;

/**
	Adds a file to the index.
 
    @param filename a filename with the relative path to the root 
	of the repository prepended.
 
 */
-(void) addFile:(NSString*) filename blob:(GitBlobObject*) blobObject;



-(void) removeFile:(NSURL*) url;

////
-(void) checkoutFilename: (NSURL*) url;
-(void) checkout;


@end


