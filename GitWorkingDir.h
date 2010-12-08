//
//  GitWorkingDir.h
//  gitfend
//
//  Created by Manuel Astudillo on 12/5/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class GitRepo;


/**
	This class represents a Git Working Directory. 
	
	It provides methods to interact with the current state of the working 
	directory.
 
	The class uses NSTreeNode to represent the tree structure. This
	class is suitable for NSOutlineView or similar view classes.
 
	This class can be used for integration with FSEvents technology.

	Subtrees within NSTreeNode can be updated independently, providing
	an efficient mechanism to update large working directories.
 
 */
@interface GitWorkingDir : NSObject {
	GitRepo *repo;
	NSFileManager *fileManager;
	NSTreeNode *fileTree;
	NSMutableDictionary *ignoreFiles;
}

/**
	A tree structure representing the current state of the
	working directory. 
 */
@property (readonly) NSTreeNode *fileTree;

/**
	Initialize.
 
	@params repo A repo object associated to this working directory.
	@params fileTree A file tree object as returned by this class property.
	Can be nil if not available.
 
	Note: The reason of acepting an initial fileTree is in order to be able
	to serialize the file tree to reduce the time needed to update it later on.
 
 */
-(id) initWithRepo:(GitRepo*) repo fileTree:(NSTreeNode*) fileTree;


/**
	Finds the subtree representing the given subPath.
 
 */
-(NSTreeNode*) findTreeNode:(NSString*) subPath;

/**
	Updates a given set of directories of the file tree.
 
	@params The array of directories to be updated.
 */
-(void) updateFileTree:(NSArray*) directories;


@end
