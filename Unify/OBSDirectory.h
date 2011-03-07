//
//  OBSDirectory.h
//  Unify
//
//  Created by Manuel Astudillo on 1/26/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <sys/stat.h>

@interface OBSDirectoryEntry : NSObject
{
	struct stat fileStatus;
	NSString *path;
	NSMutableDictionary *children;
}

@property (readonly) NSString *path;
@property (readonly) struct stat fileStatus;
@property (readonly) NSDictionary *children;


-(id) initWithPath:(NSString*) path
		  children:(NSMutableDictionary*) children 
			  stat:(struct stat) fileStatus;

-(NSData*) contentsOfChild:(NSString*) childFilename;

-(NSUInteger) size;
-(NSDate*) modificationDate;

-(void) setEntry:(OBSDirectoryEntry*) entry forPath:(NSString*) path;
-(void) deleteEntry:(NSString*) path;

@end

typedef enum
{
	kOBSFileOriginal	= 0,
	kOBSFileModified	= 1,
	kOBSFileAdded		= 2,
	kOBSFileRemoved		= 4
} OBSDirectoryCompareStatus;


@interface OBSDirectoryComparedNode : NSObject
{
	OBSDirectoryEntry *leftEntry;
	OBSDirectoryEntry *rightEntry;

	OBSDirectoryCompareStatus status;
}

-(id) initWithLeftEntry:(OBSDirectoryEntry*) leftEntry
				  right:(OBSDirectoryEntry*) rightEntry 
				 status:(OBSDirectoryCompareStatus) status;

@property (readwrite, retain) OBSDirectoryEntry *leftEntry;
@property (readwrite, retain) OBSDirectoryEntry *rightEntry;
@property (readwrite) OBSDirectoryCompareStatus status;

@end


/**
	TODO: Add support for ignoring given directories and files
	( Using git ignore syntax ).
 */
@interface OBSDirectory : NSObject <NSCoding> {
	OBSDirectoryEntry *root;
}

@property (readonly) OBSDirectoryEntry *root;

-(id) initWithPath:(NSString*) path;

/**
	Returns a comparision tree. Returned as a NSTreeNode with 
	OBSDirectoryComparedNode objects.
  
 */
-(NSTreeNode*) compareDirectory:(OBSDirectory*) directory;

@end


@interface OBSCompareDirectories : NSOperation
{
	OBSDirectory *leftDirectory;
	OBSDirectory *rightDirectory;
	
	NSTreeNode *resultTree;
	
	BOOL isCanceled;
}

@property (readonly) NSTreeNode *resultTree;

-(id) initWithLeftDirectory:(OBSDirectory*) leftDirectory 
			 rightDirectory:(OBSDirectory*) rightDirectory;

-(OBSDirectoryCompareStatus) 
				compareDirectoryEntry:(OBSDirectoryEntry*) leftEntry
								 with:(OBSDirectoryEntry*) rightEntry
							  onArray:(NSMutableArray*) mutableChildNodes;
@end




