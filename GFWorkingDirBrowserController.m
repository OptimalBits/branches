//
//  GFWorkingDirBrowserController.m
//  GitFront
//
//  Created by Manuel Astudillo on 8/17/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GFWorkingDirBrowserController.h"
#import "CCDiffViewController.h"

#import "GFRepoWatcher.h"

#import "GitRepo.h"
#import "GitReference.h"
#import "GitReferenceStorage.h"
#import "GitIndex.h"
#import "GitBlobObject.h"
#import "GitFile.h"
#import "GitIgnore.h"
#import "GitFrontIcons.h"

#import "NSDataExtension.h"
#import "NSMutableArray+Reverse.h"

#import "ImageAndTextCell.h"

#include <sys/stat.h>


static NSTreeNode *findTreeNode( NSTreeNode *fileTree, NSString *subPath );

static NSTreeNode *createSubTree( GitRepo *repo, 
								  NSFileManager *fileManager, 
								  NSURL *url,
								  NSError **error );

static void updateStatus( NSTreeNode *node, GitFileStatus status );

static GitIgnore *getParentIgnoreFile( NSTreeNode *node, 
									   NSFileManager *fileManager );


@implementation GFWorkingDirBrowserController

- (id) init
{
	if ( self = [super initWithNibName:@"WorkingDirBrowser" bundle:nil] )
    {
		fileTree = nil;
		statusTree = nil;
		
		repoWatcher = nil;
		
		fileManager = [[NSFileManager alloc] init];

		[self setTitle:@"GitFront - Browser"];
		
		icons = [GitFrontIcons icons];
	}
	return self;
}

- (void) dealloc
{
	[fileManager release];
	[modifiedFiles release];
	[repo release];
	[super dealloc];
}


- (void) awakeFromNib
{
	NSTableColumn *tableColumn;
	ImageAndTextCell *imageAndTextCell;
		
	tableColumn = [workingDirBrowseView tableColumnWithIdentifier:@"Status"];
	
	imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
	
	tableColumn = [stageAreaBrowseView tableColumnWithIdentifier:@"Main"];
	
	imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
}


-(NSTreeNode*) treeFromStatus:(NSDictionary*) tree object:(id) object
{
	if ( object == nil )
	{
		object = @"furls";
	}
	
	NSTreeNode *result = [NSTreeNode treeNodeWithRepresentedObject:object];

	NSMutableArray *children = [result mutableChildNodes];
	
	for ( NSString *key in tree )
	{
		NSTreeNode *child;
		id node = [tree objectForKey:key];
	
		if ( [node isKindOfClass:[NSDictionary class]] )
		{
			child = [self treeFromStatus:node object:key];
		}
		else
		{
			GitFile *file = node;
			
			child = [NSTreeNode treeNodeWithRepresentedObject:file];
		}
		
		[children addObject:child];
	}
	
	return result;
}

- (void) setRepo:(GitRepo*) _repo
{
	[_repo retain];
	repo = _repo;
		
	[repoWatcher release];
	repoWatcher = [[GFRepoWatcher alloc] initWithRepo:repo delegate:self];
	
	[self updateView];
}

- (GitRepo*) repo
{
	return repo;
}

- (IBAction) addFile:(id) sender
{
    int row = [workingDirBrowseView selectedRow];
	NSTreeNode *treeNode = [workingDirBrowseView itemAtRow:row];
    GitFile *file = [treeNode representedObject];
    NSURL *url = [file url];
	
	NSString *filename = [[url path] substringFromIndex:[[[repo workingDir] path] length]+1];
	
//	if ( [modifiedFiles containsObject:filename] )
	{
		NSData *fileContents = [NSData dataWithContentsOfURL:url];
	
		GitBlobObject *object = 
			[[[GitBlobObject alloc] initWithData:fileContents] autorelease];
		
		[[repo index] addFile:filename blob:object];
	
		[self updateView];
	}
}

- (void) setDiffView:(CCDiffViewController*) _diffView
{
	diffView = _diffView;
}

-(void) updateView
{
	NSError *error = nil;
	
	NSLog( @"Creating file tree...", nil);
	[fileTree release];
	fileTree = createSubTree( repo, 
							  fileManager,
							  [repo workingDir], 
							  &error );
	[fileTree retain];
	NSLog( @"Finished!", nil);
	
	NSData *headSha1 = [[[repo refs] head] resolve:[repo refs]];
	GitTreeObject *tree = [[repo objectStore] getTreeFromCommit:headSha1];
	
	NSDictionary *headTree = [[repo objectStore] flattenTree:tree];
	
	[statusTree release];
	statusTree = [self treeFromStatus:[[repo index] status:headTree] 
							   object:nil];
	[statusTree retain];
	
	[workingDirBrowseView reloadData];
	[stageAreaBrowseView reloadData];
}


//
// OutlineView datasource.
//

- (id)outlineView:(NSOutlineView *)outlineView 
			child:(NSInteger)index 
		   ofItem:(id)item
{
	if ( repo == nil )
	{
		return nil;
	}
	
	if ( item != nil )
	{
		return [[item childNodes] objectAtIndex:index];
	}
	else
	{
		NSTreeNode *tree;
		
		if ( outlineView == workingDirBrowseView )
		{
			tree = fileTree;
		}
		else if( outlineView == stageAreaBrowseView )
		{
			tree = statusTree;
		}
		else
		{
			return nil;
		}

		return [[tree childNodes] objectAtIndex:index];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
	if ( item != nil )
	{
		return [[item childNodes] count] > 0;
	}
	else
	{
		NSTreeNode *tree;
		
		if ( outlineView == workingDirBrowseView )
		{
			tree = fileTree;
		}
		else if( outlineView == stageAreaBrowseView )
		{
			tree = statusTree;
		}
		else
		{
			return 0;
		}

		return [[tree childNodes] count] > 0;
	}
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView 
  numberOfChildrenOfItem:(id)item
{
	if ( repo == nil )
	{
		return 0;
	}
	
	if ( item != nil )
	{
		return [[item childNodes] count];
	}
	else
	{
		NSTreeNode *tree;

		if ( outlineView == workingDirBrowseView )
		{
			tree = fileTree;
		}
		else if( outlineView == stageAreaBrowseView )
		{
			tree = statusTree;
		}
		else
		{
			return 0;
		}

		return [[tree childNodes] count];
	}
}

- (void)outlineView:(NSOutlineView *)olv 
	willDisplayCell:(NSCell*)cell 
	 forTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{	 
	ImageAndTextCell* iconCell = (ImageAndTextCell*) cell;
	
	if( olv == workingDirBrowseView )
	{
		if ([[[tableColumn headerCell] stringValue] compare:@"Status"] == NSOrderedSame) 
		{
			GitFile *file = [item representedObject];
						
			if ( [file status] == kFileStatusModified )
			{
				[iconCell setImage:[icons objectForKey:@"exclamation"]];
			}
			else if ( [file status] == kFileStatusTracked )
			{
				[iconCell setImage:[icons objectForKey:@"tick"]];
			}
			else
			{
				[iconCell setImage:[icons objectForKey:@"question"]];
			}
		}
	}
	else if( olv == stageAreaBrowseView )
	{
		if ([[tableColumn identifier] isEqualToString:@"Main"])
		{
			if ([cell isKindOfClass:[ImageAndTextCell class]])
			{
				id obj = [item representedObject];
				
				if ( [obj isKindOfClass:[GitFile class]] )
				{
					GitFile *gitFile = obj;
					
					if ( [gitFile status] == kFileStatusAdded )
					{
						[iconCell setImage:[icons objectForKey:@"add"]];
					}
					else if ( [gitFile status] == kFileStatusRemoved )
					{
						[iconCell setImage:[icons objectForKey:@"delete"]];
					}
					else if ( [gitFile status] == kFileStatusUpdated )
					{
						[iconCell setImage:[icons objectForKey:@"tick"]];
					}
					else if ( [gitFile status] == kFileStatusRenamed )
					{
						[iconCell setImage:[icons objectForKey:@"rename"]];
					}
					else
					{
						[iconCell setImage:[icons objectForKey:@"question"]];
					}
				}
			}
		}
	}
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
		   byItem:(id)item
{
	if ( outlineView == workingDirBrowseView )
	{
		GitFile *file = [item representedObject];
		
		if ([[[tableColumn headerCell] stringValue] compare:@"Name"] == NSOrderedSame) 
		{
			return [file filename];
		}
		
		else if ([[[tableColumn headerCell] stringValue] compare:@"Status"] == NSOrderedSame) 
		{

		}
		
		else if ([[[tableColumn headerCell] stringValue] compare:@"Mode"] == NSOrderedSame) 
		{
			// TODO: move mode to GitFile to avoid this extra fstat.
			NSError *error;
			char modeStr[8];
			struct stat fileStat;
			
			NSFileHandle *fileHandle = 
				[NSFileHandle fileHandleForReadingFromURL:[file url]
													error:&error];
			if ( fileHandle )
			{
				if ( fstat([fileHandle fileDescriptor], &fileStat ) == 0 )
				{
					strmode(fileStat.st_mode, modeStr);
					return [NSString stringWithUTF8String:modeStr];
				}
			}
			return nil;
		}
	}
	else if( outlineView == stageAreaBrowseView )
	{
		if ([[[tableColumn headerCell] stringValue] compare:@"Staged files"] == NSOrderedSame) 
		{
			NSString *text;
			id obj = [item representedObject];
			
			if ( [obj isKindOfClass:[GitFile class]] )
			{
				GitFile *gitFile = obj;
				text = [gitFile filename];
			}
			else
			{
				text = obj;
			}
			
			return text;
		}
	}
	
	return @"";
}

- (void)outlineView:(NSOutlineView *)outlineView 
	 setObjectValue:(id)object 
	 forTableColumn:(NSTableColumn *)tableColumn 
			 byItem:(id)item
{
	// pass
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSTreeNode *node = 
		[workingDirBrowseView itemAtRow:[workingDirBrowseView selectedRow]];
	
	GitFile *file = [node representedObject];
	
	BOOL isDirectory;
	
	[fileManager fileExistsAtPath:[[file url] path] isDirectory:&isDirectory];
	
	if (isDirectory == NO)
	{
		NSError *error;
				
		NSString *contents = [NSString stringWithContentsOfURL:[file url]
													   encoding:NSUTF8StringEncoding
														  error:&error];
		GitIndex *index = [repo index];
		if ( [file status] == kFileStatusModified )
		{
			NSString *filename = [repo relativizeFilePath:[file url]];

			GitBlobObject *obj = 
				[repo getObject:[index sha1ForFilename:filename]];
				  
			NSString *before = [[NSString alloc ] initWithBytes:[[obj data] bytes]
														 length:[[obj data] length]
													   encoding:NSUTF8StringEncoding];
			
			[diffView setStringsBefore:before andAfter:contents];
			
			[before release];
		}
	}
}

// Delegate method called everytime a directory within the current repo has
// changed.
-(void) modifiedDirectories:(NSArray*) directories
{
	NSError *error = nil;
	
	for( NSString *path in directories )
	{
		GitFileStatus status;
		
		BOOL isDirectory;
		
		status = kFileStatusUntracked;
		
		// remove last slash. 
		// I think NSURL are introducing a lot of ackwardness here...
		// It is usefull to keep an ending slash as a cheap way to represent 
		// paths to directories.
		path = [path substringToIndex:[path length]-1];
		
		NSTreeNode *node = findTreeNode( fileTree, path );
		
		// Get Parent GitIgnore file.
		GitIgnore *gitIgnoreFile = getParentIgnoreFile( node, fileManager );
				
		NSMutableArray *nodes = [node mutableChildNodes];
		
		NSMutableSet *childrenSet = 
								[NSMutableSet setWithCapacity:[nodes count]];
		
		for ( NSTreeNode *childNode in nodes )
		{
			GitFile *file = [childNode representedObject];
			[childrenSet addObject:[file filename]];
		}

		NSArray *subPaths = [fileManager contentsOfDirectoryAtPath:path 
															 error:&error];
		NSSet *pathsSet = [NSSet setWithArray:subPaths];
		
		// Intersection ( Files not renamed, deleted or added ).
		[childrenSet intersectSet:pathsSet];
		
		// Release all children nodes not in intersection (deleted or renamed )
		NSMutableArray *nodesToRemove = [[NSMutableArray alloc] init];
		for ( NSTreeNode *childNode in nodes )
		{
			if ( [childrenSet containsObject:[[childNode representedObject] filename]] == NO )
			{
				[nodesToRemove addObject:childNode];
			}
		}
		
		[nodes removeObjectsInArray:nodesToRemove];
		[nodesToRemove release];
		
		GitIndex *index = [repo index];
		
		// Update possibly modified files

		nodesToRemove = [[NSMutableArray alloc] init];
		for ( NSTreeNode *childNode in nodes )
		{			
			GitFile *file = [childNode representedObject];
			
			NSString *filename = [file filename];
			NSURL *url = [file url];

			if ( [childrenSet containsObject:filename] )
			{
				[fileManager fileExistsAtPath:[url path] 
								  isDirectory:&isDirectory];
				
				if ( isDirectory == NO )
				{					
					[file setStatus:[index fileStatus:url 
										   workingDir:[[repo workingDir] path]]];
					
					if ( ( status != kFileStatusModified ) && 
						( [file status] != kFileStatusUntracked ) )
					{
						status = [file status];
					}
				}
				
				if ( ( [file status] == kFileStatusUntracked ) && 
					   gitIgnoreFile && 
					   [gitIgnoreFile isFileIgnored:[url	path]] )
				{
					// TODO: path is removing the trailing slash for directories
					// which is not what we want...
					// pass
					[nodesToRemove addObject:node];
				}
			}
		}
		
		// Create new children nodes with paths not in interesection
		for ( NSString *subPath in subPaths )
		{
			GitFile *file;
			
			file = nil;
			
			if ( [childrenSet containsObject:subPath] == NO )
			{
				if ([subPath isEqualToString:@".git"] == NO) 
				{
					NSTreeNode* subTree;
					NSString *fullPath = [path stringByAppendingPathComponent:subPath];
					NSURL *u = [NSURL URLWithString:fullPath];
					
					[fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
					
					if ( isDirectory )
					{
						node = createSubTree( repo, 
											  fileManager, 
										      u,
											  &error );
						if ( node )
						{
							[nodes addObject:node];
							
							file = [node representedObject];
						}
					}
					else
					{
						file = [[[GitFile alloc] initWithUrl:u] autorelease];
						
						node = [NSTreeNode treeNodeWithRepresentedObject:file];
						
						[file setStatus:[index fileStatus:u 
											   workingDir:[[repo workingDir] path]]];
						
						[nodes addObject:node];
					}
					
					if ( file ) 
					{
						if ( ( status != kFileStatusModified ) && 
							( [file status] != kFileStatusUntracked ) )
						{
							status = [file status];
						}
					}
					
					if ( ( [file status] == kFileStatusUntracked ) && 
						gitIgnoreFile && 
						[gitIgnoreFile isFileIgnored:fullPath] )
					{
						// TODO: path is removing the trailing slash for directories
						// which is not what we want...
						// pass
						[nodesToRemove addObject:node];
					}
				}
			}
		}
		
		// Remove ignored files & dirs
		for ( NSTreeNode *childNode in nodesToRemove )
		{
			[nodes removeObject:childNode];
		}
		[nodesToRemove release];
		
		// Update this directory status.
		updateStatus( node, status );
	}
	
	[workingDirBrowseView reloadData];
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
   
static GitIgnore *getParentIgnoreFile( NSTreeNode *node, 
									   NSFileManager *fileManager )
{
	NSTreeNode *parent;
	GitIgnore *ignoreFile = nil;
	
	NSMutableArray *nodes = [NSMutableArray array];
	
	[nodes addObject:node];
	
	parent = [node parentNode];
	while( parent )
	{
		[nodes addObject:parent];
		parent = [parent parentNode];
	}
	
	[nodes reverse];
	
	for ( NSTreeNode *node in nodes )
	{
		GitFile *file;
		
		file = [node representedObject];
		
		NSURL *gitIgnoreUrl = 
			[[file url] URLByAppendingPathComponent:@".gitignore"];
		
		if ( [fileManager fileExistsAtPath:[gitIgnoreUrl path]] )
		{
			GitIgnore* localIgnoreFile = 
				[[GitIgnore alloc] initWithUrl:gitIgnoreUrl];
			
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

static GitFileStatus traverseDirTree( GitIndex *index,
									  GitIgnore *ignoreFile,
									  NSString *workingDir,
									  NSFileManager *fileManager, 
									  NSURL *url,
									  NSTreeNode *tree,
									  NSError **error )
{	
	GitFileStatus status = kFileStatusUntracked;
	BOOL existsLocalIgnoreFile = NO;

	
	NSMutableArray *childs = [tree mutableChildNodes];

	NSArray *subPaths = 
	[fileManager contentsOfDirectoryAtURL:url 
			   includingPropertiesForKeys:nil 
								  options:0
									error:error];
	
	NSURL *gitIgnoreUrl = [url URLByAppendingPathComponent:@".gitignore"]; 
	if ( [fileManager fileExistsAtPath:[gitIgnoreUrl path]] )
	{
		GitIgnore* localIgnoreFile = [[GitIgnore alloc] initWithUrl:gitIgnoreUrl];
		existsLocalIgnoreFile = YES;
		[ignoreFile push:localIgnoreFile];
	}
	
	if ( *error != nil )
	{
		NSLog([*error localizedDescription], nil);
		return 0;
	}
	
	for (NSURL *u in subPaths)
	{
		if ([[u lastPathComponent] isEqualToString:@".git"] == NO) 
		{
			GitFile *file = [[[GitFile alloc] initWithUrl:u] autorelease];
			
			NSTreeNode *node = [NSTreeNode treeNodeWithRepresentedObject:file];
			
			BOOL isDirectory;
			
			[fileManager fileExistsAtPath:[u path] isDirectory:&isDirectory];
			
			if ( isDirectory )
			{
				GitFileStatus dirStatus = 
				traverseDirTree( index, ignoreFile, workingDir, fileManager, u, node, error );
				if ( *error != nil )
				{
					continue; //return 0;
				}
				[file setStatus:dirStatus];
			}
			else
			{			
				[file setStatus:[index fileStatus:u workingDir: workingDir]];
			}
			
			if ( ( status != kFileStatusModified ) && 
				 ( [file status] != kFileStatusUntracked ) )
			{
				status = [file status];
			}
			
			if ( ( [file status] == kFileStatusUntracked ) && 
				ignoreFile && 
				[ignoreFile isFileIgnored:[u path]] )
			{
				// TODO: path is removing the trailing slash for directories
				// which is not what we want...
				// pass
			}
			else
			{
				[childs addObject:node];
			}
		}
	}
	
	if ( existsLocalIgnoreFile ) 
	{
		[ignoreFile pop];
	}
	
	return status;
}

static NSTreeNode *createSubTree( GitRepo *repo, 
								 NSFileManager *fileManager, 
								 NSURL *url,
								 NSError **error )
{
	NSTreeNode *tree;
	GitIgnore *ignoreFile;
		
	GitFile *file = [[[GitFile alloc] initWithUrl:url] autorelease];
	
	ignoreFile = [[GitIgnore alloc] init];
	
	tree = [NSTreeNode treeNodeWithRepresentedObject:file];
	
	GitFileStatus dirStatus = traverseDirTree( [repo index], 
											   ignoreFile,
											   [[repo workingDir] path], 
											   fileManager, 
											   url,
											   tree, 
											   error );
	if ( *error != nil )
	{
		tree = nil;
	}
	
	[file setStatus:dirStatus];
	
	[ignoreFile release];
	
	return tree;	
}

static NSTreeNode *findTreeNode( NSTreeNode *fileTree, NSString *subPath )
{	
	GitFile *gitFile;
	
	gitFile = [fileTree representedObject];
	
	NSString *path = [[gitFile url] path];
	
	if ( [path isEqualToString:subPath] )
	{
		return fileTree;
	}
	else
	{
		NSMutableArray *children = [fileTree mutableChildNodes];
		
		for ( NSTreeNode *child in children )
		{
			NSTreeNode *node = findTreeNode( child, subPath );
			if ( node )
			{
				return node;
			}
		}
	}
	return nil;
}




