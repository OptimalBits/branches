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

@interface GitWorkingDir (Private)

-(NSTreeNode*) createFileSubTree:(NSURL*) url error:(NSError**) error;

-(GitFileStatus) traverseDirTree:(NSURL*) url
							node:(NSTreeNode*) node
					  ignoreFile:(GitIgnore*) ignoreFile
						   error:(NSError**) error;

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
		
		fileManager = [NSFileManager defaultManager];
		[fileManager retain];
		
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
				[nodesToRemove addObject:childNode];
			}
			else
			{
				NSURL *url = [file url];
				
				[fileManager fileExistsAtPath:[url path] 
								  isDirectory:&isDirectory];
				
				if ( ( isDirectory == NO ) && 
					 ( [[childNode childNodes] count] ) )
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
					[nodesToRemove addObject:node];
				}
			}
		}
		
		NSMutableSet *childrenSet = 
			[[NSMutableSet alloc] initWithCapacity:[nodes count]];
		for ( NSTreeNode *node in nodes )
		{
			[childrenSet addObject:[[node representedObject] filename]];
		}
		
		// Create new children nodes with paths not in interesection
		for ( NSString *subPath in subPaths )
		{
			file = nil;
			
			if ( [childrenSet containsObject:subPath] == NO )
			{
				if ([subPath isEqualToString:@".git"] == NO) 
				{
					NSString *fullPath = 
						[path stringByAppendingPathComponent:subPath];
					
					NSURL *u = [NSURL URLWithString:fullPath];
					
					[fileManager fileExistsAtPath:fullPath 
									  isDirectory:&isDirectory];
					
					if ( isDirectory )
					{
						node = [self createFileSubTree:u 
												 error:&error];
						if ( node )
						{
							file = [node representedObject];
						}
					}
					else
					{
						file = [[GitFile alloc] initWithUrl:u];
						
						node = [NSTreeNode treeNodeWithRepresentedObject:file];
						
						[file setStatus:[index fileStatus:u 
											   workingDir:workingDirPath]];
						[file release];
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
							[nodes addObject:node];
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
										 ignoreFile:ignoreFile
											  error:error];
	if ( *error != nil )
	{
		tree = nil;
	}
	
	[file setStatus:dirStatus];
	
	[ignoreFile release];
	[file release];
	
	return tree;	
}


-(GitFileStatus) traverseDirTree:(NSURL*) url
							node:(NSTreeNode*) node
					  ignoreFile:(GitIgnore*) ignoreFile
						   error:(NSError**) error
{
	GitFileStatus status = kFileStatusUntracked;
	BOOL existsLocalIgnoreFile = NO;
		
	NSMutableArray *childs = [node mutableChildNodes];
		
	NSArray *subPaths = [fileManager contentsOfDirectoryAtURL:url 
								   includingPropertiesForKeys:nil 
													  options:0
														error:error];
	if ( *error )
	{
		NSLog([*error localizedDescription], nil);
		return 0;
	}
		
	NSURL *gitIgnoreUrl = [url URLByAppendingPathComponent:@".gitignore"];
	GitIgnore* localIgnoreFile = [[GitIgnore alloc] initWithUrl:gitIgnoreUrl];
	if ( localIgnoreFile )
	{
		existsLocalIgnoreFile = YES;
		[ignoreFile push:localIgnoreFile];
	}		
	
	for (NSURL *u in subPaths)
	{
		if ([[u lastPathComponent] isEqualToString:@".git"] == NO) 
		{
			GitFile *file;
			NSTreeNode *node;
			BOOL isDirectory;
			GitFileStatus newStatus;
			
			file = [[GitFile alloc] initWithUrl:u];
			
			node = [NSTreeNode treeNodeWithRepresentedObject:file];
						
			[fileManager fileExistsAtPath:[u path] isDirectory:&isDirectory];
			
			if ( isDirectory )
			{
				newStatus = [self traverseDirTree:u
											 node:node
									   ignoreFile:ignoreFile
											error:error];
				if ( *error != nil )
				{
					return 0;
				}
			}
			else
			{			
				newStatus = [[repo index] fileStatus:u
										  workingDir:[[repo workingDir] path]];
			}
			
			[file setStatus:newStatus];
			
			if ( ( status != kFileStatusModified ) && 
				 ( [file status] != kFileStatusUntracked ) )
			{
				status = [file status];
			}
			
			if ( ( [file status] == kFileStatusUntracked ) && 
					ignoreFile && 
				[ignoreFile isFileIgnored:[u path] isDirectory:YES] )
			{
				// TODO: path is removing the trailing slash for directories
				// which is not what we want...
				// pass
			}
			else
			{
				[childs addObject:node];
			}
			
			[file release];
		}
	}
	
	if ( existsLocalIgnoreFile ) 
	{
		[ignoreFile pop];
		[localIgnoreFile release];
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

