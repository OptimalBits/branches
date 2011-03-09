//
//  GitWorkingDir.m
//  gitfend
//
//  Created by Manuel Astudillo on 12/5/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitWorkingDir.h"
#import "GitIgnore.h"
#import "GitFile.h"
#import "GitRepo.h"
#import "GitIndex.h"

#include <dirent.h>


@interface GitWorkingDir (Private)

-(NSTreeNode*) createFileSubTree:(NSURL*) url error:(NSError**) error;

-(GitFileStatus) traverseDirTree:(NSURL*) url
							node:(NSTreeNode*) node
					  ignoreFile:(GitIgnore*) ignoreFile;

-(NSTreeNode*) findTreeNodeRecursive:(NSTreeNode*) node 
								path:(NSString*) path;

/**
	Returns the ignore file to be applied for the given node.
	The given node is supposed to be representing a directory.
 
	TODO: Add support for info/exclude
 */
-(GitIgnore*) currentIgnore:(NSTreeNode*) node;

/**
	Returns a cached ignore file if any.
 */
-(GitIgnore*) queryIgnoreFile:(NSURL*) baseUrl;


/**
	Caches an ignore file and returns it ( if any ).
 */
-(GitIgnore*) cacheIgnoreFile:(NSURL*) baseUrl;

@end


static void updateStatus( NSTreeNode *node, GitFileStatus status );

@implementation GitWorkingDir

@synthesize fileTree;

-(id) initWithRepo:(GitRepo*) _repo fileTree:(NSTreeNode*) _fileTree
{
	if ( self = [super init] )
	{		
		[_repo retain];
		repo = _repo;
		
		fileManager = [[NSFileManager alloc] init];
		
		ignoreFiles = [[NSMutableDictionary alloc] init];
		
		if ( _fileTree )
		{
			[_fileTree retain];
			fileTree = _fileTree;
		}
		else
		{
			NSError *error = nil;
			
			fileTree = [self createFileSubTree:[repo workingDir] error:&error];
			[fileTree retain];
		}
		
		if ( fileTree == nil )
		{
			[self release];
			self = nil;
		}
	}
	
	return self;
}

-(void) dealloc
{
	[repo release];
	[fileManager release];
	[fileTree release];
	[ignoreFiles release];
	[super dealloc];
}

-(NSTreeNode*) findTreeNode:(NSString*) path
{	
	return [self findTreeNodeRecursive:fileTree path:path];
}

-(NSTreeNode*) findTreeNodeRecursive:(NSTreeNode*) node 
								path:(NSString*) path
{	
	GitFile *gitFile;
	
	gitFile = [node representedObject];
	
	if ( [[[gitFile url] path] isEqualToString:path] )
	{
		return node;
	}
	else
	{
		NSMutableArray *children = [node mutableChildNodes];
		
		for ( NSTreeNode *child in children )
		{
			NSTreeNode *result = [self findTreeNodeRecursive:child path:path];
			if ( result )
			{
				return result;
			}
		}
	}
	return nil;
}

-(void) updateFileTree:(NSArray*) directories
{
	NSError *error = nil;
	GitFile *file;
	
	for( NSString *path in directories )
	{
		GitFileStatus status;
		
		BOOL isDirectory;
		
		status = kFileStatusUntracked;
		
		// remove last slash. ( FIXME! )
		path = [path substringToIndex:[path length]-1];
		
		NSTreeNode *node = [self findTreeNode:path];
		
		GitIgnore *gitIgnoreFile = [self currentIgnore:node];
		
		NSMutableArray *nodes = [node mutableChildNodes];
		
		NSArray *subPaths = [fileManager contentsOfDirectoryAtPath:path 
															 error:&error];
		NSSet *pathsSet = [NSSet setWithArray:subPaths];
		
		GitIndex *index = [repo index];
		NSString *workingDirPath = [[repo workingDir] path];
		
		// Update possibly modified files
		NSMutableArray *nodesToRemove = [[NSMutableArray alloc] init];
		for ( NSTreeNode *childNode in nodes )
		{			
			file = [childNode representedObject];
			
			NSString *filename = [file filename];
			
			if ( [pathsSet containsObject:filename] == NO )
			{	
				// Deleted or Renamed file or directory.
				[nodesToRemove addObject:childNode];
			}
			else
			{
				NSURL *url = [file url];
				
				[fileManager fileExistsAtPath:[url path] 
								  isDirectory:&isDirectory];
				
				if ( ( isDirectory == NO ) && 
					 ( ( [[childNode childNodes] count] ) == 0) )
				{					
					[file setStatus:[index fileStatus:url 
										   workingDir:workingDirPath]];
					
					if ( ( status != kFileStatusModified ) && 
						 ( [file status] != kFileStatusUntracked ) )
					{
						status = [file status];
					}
				}
				else
				{
					// A filename became a directory or the other way around...
					// FIXME!
				}
				
				if ( [gitIgnoreFile shouldIgnoreFile:file 
										 isDirectory:isDirectory] )
				{
					[nodesToRemove addObject:childNode];
				}
			}
		}
		
		NSMutableSet *childrenSet = 
			[[NSMutableSet alloc] initWithCapacity:[nodes count]];
		for ( NSTreeNode *childNode in nodes )
		{
			[childrenSet addObject:[[childNode representedObject] filename]];
		}
		
		// Create new children nodes with paths not in interesection
		for ( NSString *subPath in subPaths )
		{
			file = nil;
			
			if ( [childrenSet containsObject:subPath] == NO )
			{
				if ([subPath isEqualToString:@".git"] == NO) 
				{
					NSTreeNode *childNode;
					
					NSString *fullPath = 
						[path stringByAppendingPathComponent:subPath];
					
					NSURL *u = [NSURL URLWithString:fullPath];
					
					[fileManager fileExistsAtPath:fullPath 
									  isDirectory:&isDirectory];
					
					if ( isDirectory )
					{
						childNode = [self createFileSubTree:u 
													  error:&error];
						if ( childNode )
						{
							file = [childNode representedObject];
						}
					}
					else
					{
						file = [[[GitFile alloc] initWithUrl:u] autorelease];
						
						childNode = [NSTreeNode treeNodeWithRepresentedObject:file];
						
						[file setStatus:[index fileStatus:u 
											   workingDir:workingDirPath]];
					}
					
					if ( file ) 
					{
						if ( ( status != kFileStatusModified ) && 
							( [file status] != kFileStatusUntracked ) )
						{
							status = [file status];
						}
						
						if ( [gitIgnoreFile shouldIgnoreFile:file 
												 isDirectory:isDirectory] == NO)
						{
							[nodes addObject:childNode];
						}
					}
				}
			}
		}
		
		[childrenSet release];
		
		// Remove nodes representing deleted, renamed and ignored files & dirs
		[nodes removeObjectsInArray:nodesToRemove];
		[nodesToRemove release];
		
		// Update this directory status.
		updateStatus( node, status );
	}
}

-(NSTreeNode*) createFileSubTree:(NSURL*) url error:(NSError**) error
{
	NSTreeNode *tree;
	GitIgnore *ignoreFile;
	
	GitFile *file = [[GitFile alloc] initWithUrl:url];
	
	ignoreFile = [[GitIgnore alloc] init];
	
	tree = [NSTreeNode treeNodeWithRepresentedObject:file];
	
	GitFileStatus dirStatus = [self traverseDirTree:url
											   node:tree
										 ignoreFile:ignoreFile];
	[file setStatus:dirStatus];
	
	[ignoreFile release];
	[file release];
	
	return tree;	
}


-(void) getDirectoryContents:(NSURL*) url onArray:(NSMutableArray*) subPaths
{	
	struct dirent **name_list = 0;
	
	NSString *path = [url path];
	const char *string = [path UTF8String];
		 
	// TODO: It should be possible to quickly check if a directory is 
	// not tracked, in that case, if it is ignored then we can just skip it
	// altogether!
	int result = scandir_b(string, &name_list, 
				  ^int (struct dirent *d)
				  {
					  char *s = d->d_name;
					  
					  if ( s[0] == '.' )
					  {
						  if ( ( s[1] == '.' ) && ( s[2] == 0 ) )
						  {
							  return 0;
						  }
						  else if ( s[1] == 0 )
						  {
							  return 0;
						  }
						  else if ( strcmp(s, ".git") == 0 )
						  {
							  return 0;
						  }
					  }
					  
					  NSString *filename = 
						[[NSString alloc]initWithUTF8String:s];
					  
					  NSURL *u = [url URLByAppendingPathComponent:filename];
					  
					  [subPaths addObject:u];
					  
					  [filename release];
					  
					  return 0;
				  }
				  , 0);
	
	if ( result < 0 )
	{
		NSLog(@"Error path: %@", path);
	}
	
	free( name_list );
}

-(GitFileStatus) traverseDirTree:(NSURL*) url
							node:(NSTreeNode*) node
					  ignoreFile:(GitIgnore*) ignoreFile
{
	GitFileStatus status = kFileStatusUnknown;
	BOOL existsLocalIgnoreFile = NO;
	GitIgnore* localIgnoreFile = nil;
	NSMutableArray *subPaths;
	
	subPaths = [[NSMutableArray alloc] init];
	
	[self getDirectoryContents:url onArray:subPaths];
	 
	NSMutableArray *childs = [node mutableChildNodes];
	
	NSURL *gitIgnoreUrl = [url URLByAppendingPathComponent:@".gitignore"];
	localIgnoreFile = [[GitIgnore alloc] initWithUrl:gitIgnoreUrl];
	if ( localIgnoreFile )
	{
		existsLocalIgnoreFile = YES;
		[ignoreFile push:localIgnoreFile];
		[localIgnoreFile release];
	}
	
	for (NSURL *u in subPaths)
	{
		GitFile *file = nil;
		NSTreeNode *node;
		BOOL isDirectory;
		GitFileStatus newStatus;
		
		file = [[GitFile alloc] initWithUrl:u];
		node = [[NSTreeNode alloc] initWithRepresentedObject:file];
		
		[fileManager fileExistsAtPath:[u path] isDirectory:&isDirectory];
		
		if ( isDirectory )
		{
			newStatus = [self traverseDirTree:u
										 node:node
								   ignoreFile:ignoreFile];
		}
		else
		{
			newStatus = [[repo index] fileStatus:u
									  workingDir:[[repo workingDir] path]];
		}
		
		[file setStatus:newStatus];
		
		if ( (newStatus && (newStatus != kFileStatusUntracked ) ) ||
			 [ignoreFile isFileIgnored:[u path] isDirectory:YES] == NO)
		{
			[childs addObject:node];
			status |= newStatus;
		}
		
		[node release];
		[file release];
	}
	
	[subPaths release];
	
	if ( existsLocalIgnoreFile )
	{
		[ignoreFile pop];
	}
	
	return status;
}

-(GitIgnore*) currentIgnore:(NSTreeNode*) node
{
	NSTreeNode *parent;
	GitFile *file;

	GitIgnore *ignoreFile = nil;
	
	NSMutableArray *nodes = [NSMutableArray array];
	
	NSAssert( [[node childNodes] count] > 0, @"Not a directory node" );

	file = [node representedObject];
	
	// Force re-reading of this node's ignore file.
	[self cacheIgnoreFile:[file url]];
	
	[nodes addObject:node];
	
	parent = [node parentNode];
	while( parent )
	{
		[nodes addObject:parent];
		parent = [parent parentNode];
	}
	
	for ( NSTreeNode *node in [nodes reverseObjectEnumerator] )
	{
		GitIgnore *localIgnoreFile;
		
		file = [node representedObject];
		
		localIgnoreFile = [self queryIgnoreFile:[file url]];
		if ( localIgnoreFile == nil )
		{
			localIgnoreFile = [self cacheIgnoreFile:[file url]];
		}
		
		if ( localIgnoreFile )
		{			
			if ( ignoreFile )
			{
				[ignoreFile push:localIgnoreFile];
			}
			else
			{
				ignoreFile = localIgnoreFile;
			}
		}
	}
	
	return ignoreFile;
}

-(GitIgnore*) queryIgnoreFile:(NSURL*) baseUrl
{
	return [ignoreFiles objectForKey:baseUrl];
}

-(GitIgnore*) cacheIgnoreFile:(NSURL*) baseUrl
{
	NSURL *gitIgnoreUrl = [baseUrl URLByAppendingPathComponent:@".gitignore"];
	
	GitIgnore *ignoreFile = [[GitIgnore alloc] initWithUrl:gitIgnoreUrl];
	
	if ( ignoreFile )
	{
		[ignoreFiles setObject:ignoreFile forKey:baseUrl];
		[ignoreFile release];
		
	}
	
	return ignoreFile;
}

@end


// Update the status of all the parent nodes of the given one.
// TODO: This is a shalow operation, the correct one would need to
// check all the nodes at every level and compute the correct status.
static void updateStatus( NSTreeNode *node, GitFileStatus status )
{
	GitFile *file;
	
	NSTreeNode *parent = [node parentNode];
	
	file = [node representedObject];
	
	[file setStatus:status];
	
	while( parent )
	{
		file = [parent representedObject];
		
		if ( status != kFileStatusUntracked )
		{
			[file setStatus:status];
		}
		else
		{
			break;
		}
		
		status = [file status];
		
		parent = [parent parentNode];
	}			 
}

