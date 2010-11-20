//
//  GFWorkingDirBrowserController.m
//  GitFront
//
//  Created by Manuel Astudillo on 8/17/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GFWorkingDirBrowserController.h"
#import "CCDiffViewController.h"

#import "GitRepo.h"
#import "GitReference.h"
#import "GitReferenceStorage.h"
#import "GitIndex.h"
#import "GitBlobObject.h"
#import "GitFile.h"
#import "GitFrontIcons.h"

#import "NSDataExtension.h"

#import "ImageAndTextCell.h"

#include <sys/stat.h>


static NSTreeNode *workingDirTree( GitRepo *repo,
								   NSFileManager *fileManager, 
								   NSError **error );

@implementation GFWorkingDirBrowserController

- (id) init
{
	if ( self = [super initWithNibName:@"WorkingDirBrowser" bundle:nil] )
    {
		fileTree = nil;
		statusTree = nil;
		
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
		
	[self updateView];
}

- (GitRepo*) repo
{
	return repo;
}

- (IBAction) addFile:(id) sender
{
	NSURL *url = 
		[workingDirBrowseView itemAtRow:[workingDirBrowseView selectedRow]];
	
	NSString *filename = 
		[[url path] substringFromIndex:[[[repo workingDir] path] length]+1];
	
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
	fileTree = workingDirTree( repo, fileManager, &error );
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
		
		NSString *filename = 
		[[[file url] path] substringFromIndex:[[[repo workingDir] path] length]+1];
		
		NSString *contents = [NSString stringWithContentsOfURL:[file url]
													   encoding:NSUTF8StringEncoding
														  error:&error];
		GitIndex *index = [repo index];
		if ( [file status] == kFileStatusModified )
		{
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

@end

static GitFileStatus traverseDirTree( GitIndex *index,
									  NSString *workingDir,
									  NSFileManager *fileManager, 
									  NSURL *url,
									  NSTreeNode *tree,
									  NSError **error )
{	
	GitFileStatus status = kFileStatusUntracked;
	
	NSMutableArray *childs = [tree mutableChildNodes];

	NSArray *subPaths = 
	[fileManager contentsOfDirectoryAtURL:url 
			   includingPropertiesForKeys:nil 
								  options:NSDirectoryEnumerationSkipsHiddenFiles 
									error:error];
	if ( *error != nil )
	{
		return 0;
	}
	
	for (NSURL *u in subPaths)
	{
		GitFile *file = [GitFile alloc];
		
		NSTreeNode *node = [[NSTreeNode alloc] initWithRepresentedObject:file];
		
		BOOL isDirectory;
		
		[fileManager fileExistsAtPath:[u path] isDirectory:&isDirectory];
		
		if ( isDirectory )
		{
			GitFileStatus dirStatus = 
		      traverseDirTree( index, workingDir, fileManager, u, node, error );
			if ( *error != nil )
			{
				return 0;
			}
			[file initWithUrl:u andStatus:dirStatus];
		}
		else
		{
			NSString *filename = 
							[[u path] substringFromIndex:[workingDir length]+1];
			
			if ( [index isFileTracked:filename] )
			{
				if ( [index isFileModified:u filename:filename] )
				{
					[file initWithUrl:u andStatus:kFileStatusModified];
				}
				else
				{
					[file initWithUrl:u andStatus:kFileStatusTracked];
				}
			}
			else
			{
				[file initWithUrl:u andStatus:kFileStatusUntracked];
			}			
		}		
		[childs addObject:node];
		[node release];
		[file release];
		
		if ( ( status != kFileStatusModified ) && 
			 ( [file status] != kFileStatusUntracked ) )
		{
			status = [file status];
		}
	}
	
	return status;
}

static NSTreeNode *workingDirTree( GitRepo *repo,
								   NSFileManager *fileManager, 
								   NSError **error )
{
	// TODO: Add support for .gitignore files.
	
	NSTreeNode *tree;

	tree = [[NSTreeNode alloc] initWithRepresentedObject:nil];
	[tree autorelease];
	
	traverseDirTree( [repo index], 
					 [[repo workingDir] path], 
					 fileManager, 
					 [repo workingDir], 
					 tree, 
					 error );
	
	if ( *error != nil )
	{
		return nil;
	}
	
	return tree;
}




