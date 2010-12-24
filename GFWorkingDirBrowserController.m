//
//  GFWorkingDirBrowserController.m
//  GitFront
//
//  Created by Manuel Astudillo on 8/17/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GFWorkingDirBrowserController.h"
#import "gitfendController.h"
#import "CCDiffViewController.h"
#import "GFRepoWatcher.h"
#import "GitRepo.h"
#import "GitWorkingDir.h"
#import "GitReference.h"
#import "GitReferenceStorage.h"
#import "GitIndex.h"
#import "GitBlobObject.h"
#import "GitFile.h"
#import "GitModificationDateResolver.h"
#import "GitCommitObject.h"
#import "GitFrontIcons.h"
#import "NSDataExtension.h"
#import "NSMutableArray+Reverse.h"
#import "ImageAndTextCell.h"


#include <sys/stat.h>

#define COMMIT_TAG 1

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

- (id) initWithController:(gitfendRepositoryController*) _controller
{
	if ( self = [super initWithNibName:@"WorkingDirBrowser" bundle:nil] )
    {
		controller = _controller;
		[controller retain];
		
		fileTree	= nil;
		statusTree	= nil;
		repo		= nil;
		workingDir	= nil;
		repoWatcher = nil;
		dateResolver = nil;
		
		fileManager = [[NSFileManager alloc] init];
		
		dateFormatter = [[NSDateFormatter alloc] init];
		
		[dateFormatter setDoesRelativeDateFormatting:YES];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];

		[self setTitle:@"GitFront - Browser"];
		
		icons = [GitFrontIcons icons];
	}
	return self;
}

- (void) dealloc
{
	[fileTree release];
	[statusTree release];
	[repo release];
	[workingDir release];
	[repoWatcher release];
	[fileManager release];
	[dateResolver release];
	[controller release];
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
		NSLog(@"treeFromStatus received nil object", nil);
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

-(void) updateCommitButton
{
	if ( [[statusTree childNodes] count] )
	{
		[commitButton setEnabled:YES];
	}
	else
	{
		[commitButton setEnabled:NO];		
	}
}

- (IBAction) commit:(id) sender
{
	[self showCommitSheet];
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
	
	NSData *fileContents = [NSData dataWithContentsOfURL:url];
	
	GitBlobObject *object = 
	[[[GitBlobObject alloc] initWithData:fileContents] autorelease];
	
	[[repo index] addFile:filename blob:object];
	
	[self updateView];
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
	
	GitObjectStore *objectStore = [repo objectStore];
	
	NSData *headSha1 = [[[repo refs] head] resolve:[repo refs]];
	
	GitTreeObject *tree = [objectStore getTreeFromCommit:headSha1];
	
	NSDictionary *headTree = [objectStore flattenTree:tree];
	
	[statusTree release];
	statusTree = [self treeFromStatus:[[repo index] stageStatus:headTree] 
							   object:nil];
	[statusTree retain];
	
	[self updateCommitButton];
	
	[dateResolver release];
	dateResolver = [[GitModificationDateResolver alloc] 
					initWithObjectStore:[repo objectStore]
							 commitSha1:headSha1];
	
	[workingDirBrowseView reloadData];
	[stageAreaBrowseView reloadData];
}

- (void) showCommitSheet
{
	NSWindow *window = [NSApp mainWindow];
	
	[NSApp beginSheet:commitSheet 
	   modalForWindow:window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:NULL];
	
}

- (IBAction) endCommitSheet:(id) sender
{
	if ( [sender tag] == COMMIT_TAG )
	{
		GitAuthor *author;
		
		author = [[GitAuthor alloc] initWithName:@"pepe" 
										   email:@"mymail@casa.se"
										 andTime:@"1234"];
		
		NSString *commitMessage = [[commitMessageView textStorage] string];
		
		if ( [commitMessage length] == 0 )
		{
			// Show Alarm
		}
		
		[repo makeCommit:commitMessage
				  author:author
				commiter:author];
		
		[self updateView];
		
		NSAttributedString *emptyString = 
		[[[NSAttributedString alloc] initWithString:@""] autorelease];
		
		
		[[commitMessageView textStorage] setAttributedString:emptyString];
		
		// update the commit window (window showing the commits not yet pushed)
		// and also increase the number in the repo browser.
	}
	
	[NSApp endSheet:commitSheet];
	[commitSheet orderOut:sender];
}


//
// OutlineView Datasource. (TODO: use Bindings if possible )
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
		
		if ([[tableColumn identifier] isEqualToString:@"Name"]) 
		{
			return [file filename];
		}
		else if ([[tableColumn identifier] isEqualToString:@"Status"]) 
		{

		}
		else if ([[tableColumn identifier] isEqualToString:@"Mode"]) 
		{
			char modeStr[8];
			
			strmode([file mode], modeStr);
			return [NSString stringWithUTF8String:modeStr];
		}
		else if ([[tableColumn identifier] isEqualToString:@"ModificationDate"])  
		{
			NSDate *date;
			
			if ( ( [file status] & kFileStatusModified ) || 
			     ( [file status] & kFileStatusUntracked ) )
			{
				struct stat fileStat;
				
				if ( stat([[[file url] path] UTF8String], &fileStat ) == 0 )
				{
					float t = fileStat.st_mtimespec.tv_sec;
					date = [NSDate dateWithTimeIntervalSince1970:t];
				}
			}
			else 
			{
				NSString *pathname = [repo relativizeFilePath:[file url]];
				date = [dateResolver resolveDate:pathname];
			}

			return [dateFormatter stringFromDate:date];
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
