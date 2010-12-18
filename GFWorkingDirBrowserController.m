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
#import "GitWorkingDir.h"
#import "GitReference.h"
#import "GitReferenceStorage.h"
#import "GitIndex.h"
#import "GitBlobObject.h"
#import "GitFile.h"

#import "GitFrontIcons.h"

#import "NSDataExtension.h"
#import "NSMutableArray+Reverse.h"

#import "ImageAndTextCell.h"


/**
	A Category adding support for filtering tree nodes.
 
 */
@interface NSTreeNode (Filter)

-(NSArray*) childNodesFiltered:(GitFileStatus) statusMask;

@end

@implementation NSTreeNode (Filter)

-(NSArray*) childNodesFiltered:(GitFileStatus) statusMask
{
	if ( statusMask )
	{
		NSMutableArray *array = [NSMutableArray array];
		
		for ( NSTreeNode *node in [self childNodes] ) 
		{
			if ( [[node representedObject] status] & statusMask )
			{
				[array addObject:node];
			}
		}
		return array;
	}
	else
	{
		return [self childNodes];
	}
}

@end



static NSTreeNode *findTreeNode( NSTreeNode *fileTree, NSString *subPath );

static NSTreeNode *createSubTree( GitRepo *repo, 
								  NSFileManager *fileManager, 
								  NSURL *url,
								  NSError **error );

static void updateStatus( NSTreeNode *node, GitFileStatus status );


@implementation GFWorkingDirBrowserController

- (id) init
{
	if ( self = [super initWithNibName:@"WorkingDirBrowser" bundle:nil] )
    {
		fileTree = nil;
		statusTree = nil;
		
		repo = nil;
		
		workingDir = nil;
		
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
	[repo release];
	repo = _repo;
	
	[workingDir release];
	workingDir = [[GitWorkingDir alloc] initWithRepo:repo fileTree:nil];
	
	if ( workingDir )
	{
		fileTree = [workingDir fileTree];
		
		[repoWatcher release];
		repoWatcher = [[GFRepoWatcher alloc] initWithRepo:repo delegate:self];
	
		[self updateView];
	}
}

- (GitRepo*) repo
{
	return repo;
}

-(BOOL) commitButtonEnabled
{
	// if ( staged files > 0 )
	// return YES;
	// else
	// return NO;
	
	return YES;
}

- (IBAction) commit:(id) sender
{
	
}

- (IBAction) modifiedFilesFilter:(id) sender
{
	status_mask ^= kFileStatusModified;
	[workingDirBrowseView reloadData];
}

- (IBAction) untrackedFilesFilter:(id) sender
{
	status_mask ^= kFileStatusUntracked;
	[workingDirBrowseView reloadData];
}

- (IBAction) addFile:(id) sender
{
    int row = [workingDirBrowseView selectedRow];
	NSTreeNode *treeNode = [workingDirBrowseView itemAtRow:row];
    GitFile *file = [treeNode representedObject];
    NSURL *url = [file url];
	
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
	if ( workingDir )
	{
		[fileTree release];
		fileTree = [workingDir fileTree];
		[fileTree retain];
	}
	
	NSData *headSha1 = [[[repo refs] head] resolve:[repo refs]];
	GitTreeObject *tree = [[repo objectStore] getTreeFromCommit:headSha1];
	
	NSDictionary *headTree = [[repo objectStore] flattenTree:tree];
	
	[statusTree release];
	statusTree = [self treeFromStatus:[[repo index] stageStatus:headTree] 
							   object:nil];
	[statusTree retain];
	
	[workingDirBrowseView reloadData];
	[stageAreaBrowseView reloadData];
}


//
// OutlineView Datasource. (TODO: use Bindings )
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
		return [[item childNodesFiltered:status_mask] objectAtIndex:index];
	}
	else
	{
		NSTreeNode *tree;
		
		if ( outlineView == workingDirBrowseView )
		{
			if ( fileTree )
			{
				tree = fileTree;
			}
			else
			{
				return nil;
			}
		}
		else if( outlineView == stageAreaBrowseView )
		{
			tree = statusTree;
		}
		else
		{
			return nil;
		}

		return [[tree childNodesFiltered:status_mask] objectAtIndex:index];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
	if ( item != nil )
	{
		return [[item childNodesFiltered:status_mask] count] > 0;
	}
	else
	{
		NSTreeNode *tree;
		
		if ( outlineView == workingDirBrowseView )
		{
			if ( fileTree )
			{
				tree = fileTree;
			}
			else
			{
				return 0;
			}
		}
		else if( outlineView == stageAreaBrowseView )
		{
			tree = statusTree;
		}
		else
		{
			return 0;
		}

		return [[tree childNodesFiltered:status_mask] count] > 0;
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
		return [[item childNodesFiltered:status_mask] count];
	}
	else
	{
		NSTreeNode *tree;

		if ( outlineView == workingDirBrowseView )
		{
			if ( fileTree )
			{
				tree = fileTree;
			}
			else
			{
				return 0;
			}
		}
		else if( outlineView == stageAreaBrowseView )
		{
			tree = statusTree;
		}
		else
		{
			return 0;
		}

		return [[tree childNodesFiltered:status_mask] count];
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
			GitFileStatus maskedStatus;
			
			if ( status_mask )
			{
				maskedStatus = [file status] & status_mask;
			}
			else
			{
				maskedStatus = [file status];
			}

			if ( maskedStatus & kFileStatusModified )
			{
				[iconCell setImage:[icons objectForKey:@"exclamation"]];
			}
			else if ( maskedStatus & kFileStatusUntracked )
			{
				[iconCell setImage:[icons objectForKey:@"question"]];
			}
			else if ( maskedStatus & kFileStatusTracked )
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
			char modeStr[8];
			
			strmode([file mode], modeStr);
			return [NSString stringWithUTF8String:modeStr];
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
	if ( workingDir )
	{
		[workingDir updateFileTree:directories];
	
		[workingDirBrowseView reloadData];
	}
}


@end
