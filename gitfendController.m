//
//  gitfendController.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gitfendController.h"
#import "ImageAndTextCell.h"
#import "NSDataExtension.h"
#import "gitcommitobject.h"
#import "GitFrontTree.h"

#import "GitFrontBrowseController.h"
#import "GFWorkingDirBrowserController.h"
#import "CCDiffViewController.h"

#import "GitFrontRepositories.h"
#import "GitFrontIcons.h"

#define MAIN_COLUMN_ID	@"Main"
#define NEW_GROUP_NAME @"New Group"
#define GITFRONT_BPOARD_TYPE  @"GitFrontPboardType"

#define COMMIT_TAG 1


@interface gitfendRepositoryController(Private)

-(void)updateViews;

@end


@implementation gitfendRepositoryController

- (id) init
{	
    if ( self = [super init] )
    {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *folder = [self folderForDataFiles];
		
		if ([fileManager fileExistsAtPath: folder] == NO)
		{
			NSError *error;
			[fileManager createDirectoryAtPath: folder 
				   withIntermediateDirectories:YES attributes: nil error:&error];
		}
		
		if ([fileManager fileExistsAtPath:[self pathForDataFile]] == YES )
		{
			[self loadDataFromDisk];
		}
		else
		{
			repos = [[GitFrontRepositories alloc] initWithName:@"REPOSITORIES"];
		}
				
		viewControllers = [[NSMutableArray alloc] init];
		
		// tag 0
		id vc = [[[gitfrontHistoryController alloc] init] autorelease];
		[viewControllers addObject:vc];
		historyController = vc;
		
		// tag 1
		vc = [[[GitFrontBrowseController alloc] init] autorelease];
		[viewControllers addObject:vc];
		browseController = vc;
		
		// tag 2
		vc = [[[GFWorkingDirBrowserController alloc] 
			   initWithController:self] autorelease];
		[viewControllers addObject:vc];
		workingDirBrowseController = vc;
	}
    return self;
}

-(void) dealloc
{
	[repos release];
	[viewControllers release];
	[historyController release];
	[super dealloc];
}

- (void)awakeFromNib
{
	// apply our custom ImageAndTextCell for rendering the first column's cells
	NSTableColumn *tableColumn = [_outlineView tableColumnWithIdentifier:@"Main"];
	
	ImageAndTextCell *imageAndTextCell = 
								[[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
	
	[_outlineView expandItem:repos];
	
	// needed?
	[repositoryMgmtMenu setAutoenablesItems:NO];
	
	//
	// Drag and Drop
	//
	
	// Enable destination support.
	[_outlineView registerForDraggedTypes:
		[NSArray arrayWithObjects:NSFilenamesPboardType, 
								  GITFRONT_BPOARD_TYPE, 
								  nil]];
      
	[_outlineView setDraggingSourceOperationMask:NSDragOperationEvery 
										forLocal:NO];
	
	[_outlineView setDraggingSourceOperationMask:NSDragOperationEvery 
										forLocal:YES];
	
	// Diff View
	diffViewController = [[CCDiffViewController alloc] init];
	//[bottomView addSubview:[vc view]];
	//[bottomView setNeedsDisplay:YES];
	
	NSView *v = [diffViewController view];
	[bottomBox setContentView:v];
	[bottomBox setNeedsDisplay:YES];
	
	[workingDirBrowseController setDiffView:diffViewController];
}


- (BOOL)validateMenuItem:(NSMenuItem *)item {
	
	id repoItem = [_outlineView itemAtRow:[_outlineView selectedRow]];

	if ([item action] == @selector(removeRepo:))
	{
		if ( ( [repoItem respondsToSelector:@selector(repo)] ) && 
			 ( ![repoItem respondsToSelector:@selector(sha1)] ) )
		{
			return [repoItem repo] != nil;
		}
		else
		{
			return NO;
		}
	}
	
    return YES;
}

- (IBAction) changeMainView:(id) sender
{	
	NSInteger clickedSegment = [sender selectedSegment];
    NSInteger tag = [[sender cell] tagForSegment:clickedSegment];
	
	currentController = [viewControllers objectAtIndex:tag];
	
	[self updateViews]; // TODO: This should be a NSOperation in order 
						// not to block.
	
	[self displayViewController:currentController];
}

- (IBAction) addRepo: sender
{	
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
	
	[openDlg setCanChooseFiles:NO];
	[openDlg setCanChooseDirectories:YES];
	[openDlg setAllowsMultipleSelection:NO];
	
	// Display the dialog.  If the OK button was pressed, process the files.
	if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
	{
		NSArray* dirs = [openDlg URLs];
		
		if ( [dirs count] > 0 )
		{
			NSError *error;
			
			NSURL *workingDir = [dirs objectAtIndex:0];
			NSURL *repoDir = [workingDir URLByAppendingPathComponent:@".git"];
			
			if ([repoDir checkResourceIsReachableAndReturnError:&error] == YES)
			{				
				[self addRepoFromUrl:workingDir];
			
				[self saveDataToDisk];
			
				[_outlineView reloadData];
			}
			else
			{
				(void) NSRunAlertPanel(@"Invalid Repository",
									   @"%@ does not contain a valid Git repo", 
									   @"Ok", 
									   nil, 
									   nil,
									   [workingDir description] );
			}
		}
	}
}


- (IBAction) newRepo:(id) sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];;
	
	[panel setCanChooseFiles:NO];
	[panel setCanCreateDirectories:YES];
	[panel setCanChooseDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	
	// Display the dialog.  If the OK button was pressed, process the files.
	if ( [panel runModal] == NSFileHandlingPanelOKButton )
	{
		NSURL* workingDir = [[panel URLs] objectAtIndex:0];
		
		if ( workingDir )
		{
			NSError *error;
			
			NSURL *repoDir = [workingDir URLByAppendingPathComponent:@".git"];
			
			if ([repoDir checkResourceIsReachableAndReturnError:&error] == YES)
			{
				(void) NSRunAlertPanel(@"Invalid Directory",
									   @"%@ already contains a Git repository", 
									   @"Ok", 
									   nil, 
									   nil,
									   [workingDir description] );
			}
			else
			{
				[GitRepo makeRepo:(NSURL*) workingDir
					  description:(NSString*) description
							error:(NSError**) error];
				
				[self addRepoFromUrl:workingDir];
				
				[self saveDataToDisk];
				
				[_outlineView reloadData];
			}
		}
	}
}


- (IBAction) removeRepo: sender
{
	int choice = NSAlertErrorReturn;
	
	id item = [_outlineView itemAtRow:[_outlineView selectedRow]];
	
	if ( [item isKindOfClass:[GitFrontRepositoriesLeaf class]] )
	{
		choice = NSRunAlertPanel(@"Remove repository", 
									 @"Are you sure that you want to remove '%@' repository?",
									 @"Cancel", 
									 @"Remove",
									 nil,
									 [item name]);
	}
	else if ( [item isKindOfClass:[GitFrontRepositories class]] && 
			   item != repos )
	{
		choice = NSRunAlertPanel(@"Remove Group", 
								 @"Are you sure that you want to remove the group '%@' and all its contens?",
								 @"Cancel", 
								 @"Remove",
								 nil,
								 [item name]);
	}
	
	if ( choice == NSAlertAlternateReturn )
	{
		GitFrontRepositories *parent = [_outlineView parentForItem:item];
		
		[[parent children] removeObject:item];
		
		[self saveDataToDisk];
		[_outlineView reloadData];
	}
}


- (IBAction) addGroup: sender
{
	id item = [_outlineView itemAtRow:[_outlineView selectedRow]];
	GitFrontRepositories *node;
	
	if ( [item isKindOfClass:[GitFrontRepositories class]] )
	{
		node = item;
		
		item = [node addGroup:NEW_GROUP_NAME];
		[_outlineView reloadItem:node reloadChildren:YES];
	}
	else
	{
		node = [_outlineView parentForItem:item];
		if ( [node isKindOfClass:[GitFrontRepositories class]] )
		{
			NSUInteger index = [node indexOfChild: item];
		
			if ( index != NSNotFound )
			{
				item = [node insertGroup:NEW_GROUP_NAME atIndex:index];
				[_outlineView reloadItem:node reloadChildren:YES];
			}
		}
	}
	
	[_outlineView expandItem:node];

	NSInteger newRow = [_outlineView rowForItem:item];
    
	[_outlineView editColumn:0 row:newRow withEvent:nil select:YES];
		
	[self saveDataToDisk];
}

-(void) displayViewController:(NSViewController*) vc
{
	NSWindow *w = [box window];
	BOOL ended = [w makeFirstResponder:w];
	if( !ended )
	{
		NSBeep();
		return;
	}
	
	NSView *v = [vc view];
	[box setContentView:v];
}

- (void) addRepoFromUrl:(NSURL*) repoUrl
{
	id item = [_outlineView itemAtRow:[_outlineView selectedRow]];
	
	while( ![item isKindOfClass:[GitFrontRepositories class]] && item != nil )
	{
		item = [_outlineView parentForItem:item];
	}
	
	if ( item == nil )
	{
		item = repos;
	}
		
	if ( item )
	{
		GitRepo *repo = [[[GitRepo alloc] initWithUrl:repoUrl name:nil] autorelease];

		[item addRepo:repo];
		
		[_outlineView expandItem:item];
	}	
}


- (NSString *) folderForDataFiles
{
	NSString *folder = @"~/Library/Application Support/GitFront/";
	folder = [folder stringByExpandingTildeInPath];
	
	return folder;
}

- (NSString *) pathForDataFile
{    
	NSString *fileName = @"Repositories.gitfront";
	return [[self folderForDataFiles] stringByAppendingPathComponent: fileName];    
}

- (void) saveDataToDisk
{
	NSString * path = [self pathForDataFile];
	    
	[NSKeyedArchiver archiveRootObject: repos toFile: path];
}

- (void) loadDataFromDisk
{
	NSString *path = [self pathForDataFile];
	
	repos = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	[repos retain];
}

//
// NSOutlineProtocol 
//

- (id)outlineView:(NSOutlineView *)outlineView 
			child:(NSInteger)index 
		   ofItem:(id)item
{
	if ( item == nil ) // return parent
	{
		return repos;
	}
	
	else if ( [item isKindOfClass:[GitFrontRepositories class]] )
	{
		id child = [[item children] objectAtIndex:index];

		return child;
	}
	else if ([item isKindOfClass:[GitFrontRepositoriesLeaf class]])
	{
		GitFrontRepositoriesLeaf *leaf = item;
		GitFrontTree *tree = [leaf tree];
		
		return [[tree children] objectAtIndex: index];		
	}	
	
	else if ([item isKindOfClass:[GitFrontTree class]])
	{
		return [[item children] objectAtIndex: index];		
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ovl isItemExpandable:(id)item
{
	if ( [item isKindOfClass:[GitFrontRepositories class]] ||
		 [self outlineView:ovl numberOfChildrenOfItem:item] > 0) 
	{
		return YES;
	} 
	else
	{
		return NO;
	}
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView 
  numberOfChildrenOfItem:(id)item
{
	if ( item == nil )
	{
		return 1;
	}
	
	else if ( item == self )
	{
		return [[repos children] count];
	}
	
	else if ( [item isKindOfClass:[GitFrontRepositories class]] )
	{
		return [[item children] count];
	}
	
	else if ( [item isKindOfClass:[GitFrontRepositoriesLeaf class]] )
	{
		GitFrontRepositoriesLeaf *leaf = item;
		GitFrontTree *tree = [leaf tree];
		return [[tree children] count];
	}
	
	else if ( [item isKindOfClass:[GitFrontTree class]] )
	{
		GitFrontTree *tree = item;
		
		return [[tree children] count];
	}
	
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
		   byItem:(id)item
{
	if ([[[tableColumn headerCell] stringValue] compare:@"Main"] == NSOrderedSame) 
	{		
		return [item name];
	} 
	
	return nil;
}


/**
	We use this to allow renaming the repos and groups in the repository view.
 
 */
- (void)outlineView:(NSOutlineView *)outlineView 
	 setObjectValue:(id)object 
	 forTableColumn:(NSTableColumn *)tableColumn 
			 byItem:(id)item
{
	GitFrontRepositories *r = item;
	[r setName:object];
	[self saveDataToDisk];
}

/**
	Display Tooltip
 */

- (NSString *)outlineView:(NSOutlineView *)outlineView 
		   toolTipForCell:(NSCell *)cell 
					 rect:(NSRectPointer)rect 
			  tableColumn:(NSTableColumn *)tc 
					 item:(id)item 
			mouseLocation:(NSPoint)mouseLocation
{
	return @"My super duper tooltip";
}
/**
	Display Icons
 */
- (void)outlineView:(NSOutlineView *)olv 
	willDisplayCell:(NSCell*)cell 
	 forTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{	 
	if ([[tableColumn identifier] isEqualToString:MAIN_COLUMN_ID])
	{
		if ([cell isKindOfClass:[ImageAndTextCell class]])
		{
			NSImage *icon;
			
			if ( item )
			{
				if (([item isKindOfClass:[GitFrontTree class]] ||
					 [item isKindOfClass:[GitFrontTreeLeaf class]] ||
					 [item isKindOfClass:[GitFrontRepositories class]] ||
					 [item isKindOfClass:[GitFrontRepositoriesLeaf class]]) &&
					 item != repos )
				{
					icon = [item icon];
				}
				else
				{
					icon = nil;
				}
				
				[(ImageAndTextCell*)cell setImage:icon];
			}
			
		}
	}
}


-(void)updateViews
{
	id item = [_outlineView itemAtRow:[_outlineView selectedRow]];
	
	if ( ( [item isKindOfClass:[GitFrontRepositoriesLeaf class]] ) ||
		 ( [item isKindOfClass:[GitFrontTreeLeaf class]] ) )
	{	
		NSData *sha1;
		GitRepo *repo = [item repo];
		
		if ( repo == nil )
		{
			return;
		}
		
		if ( [item isKindOfClass:[GitFrontTreeLeaf class]] )
		{
			sha1 = [item sha1];
		}
		else
		{
			sha1 = [[[repo refs] head] resolve:[repo refs]];
		}
			
		if ( currentController == historyController )
		{
			[historyController setHistory:[repo revisionHistoryFor:sha1]];
		}
		else if ( currentController == browseController )
		{
			GitCommitObject *commit = [repo getObject:sha1];
				
			NSData *tree = [commit tree];
			[browseController setTree:tree commit:sha1 repo:repo];
		}
		else if ( currentController == workingDirBrowseController )
		{
			[workingDirBrowseController setRepo:repo];
		}
	}
}


- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[self updateViews];
}


//
// Drag And Drop Delegates
//
- (BOOL) isParent:(id) parent ofNode:(id) node
{
	while ( ( node != nil ) && ( node != parent ) )
	{
		node = [_outlineView parentForItem:node];
	}
	
	if ( node == parent )
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov 
				  validateDrop:(id <NSDraggingInfo>)info 
				  proposedItem:(id)item 
			proposedChildIndex:(NSInteger)childIndex 
{    
	// To make it easier to see exactly what is called, uncomment the following line:
	NSLog(@"outlineView:validateDrop:proposedItem:%@ proposedChildIndex:%ld", 
		  item, (long)childIndex);
	
	if ( [item isKindOfClass:[GitFrontRepositories class]] )
	{
		return NSDragOperationGeneric;
	}
	else
	{
		return NSDragOperationNone;
	}
}

- (BOOL)outlineView:(NSOutlineView *)ov 
		 acceptDrop:(id <NSDraggingInfo>)info 
			   item:(id)item 
		 childIndex:(NSInteger)childIndex 
{
	NSPasteboard *pasteboard = [info draggingPasteboard];
	
	NSString *path = 
		[[pasteboard propertyListForType:NSFilenamesPboardType] lastObject];
	
	if ( path )
	{
		NSURL *repoUrl = [NSURL fileURLWithPath:path isDirectory:YES];
		
		if ( [GitRepo isValidRepo:repoUrl] )
		{
			GitRepo *repo = [[[GitRepo alloc] initWithUrl: repoUrl
												 name:nil] autorelease];
		
			if ( childIndex >= 0 )
			{
				[item insertRepo:repo atIndex:childIndex];
			}	
			else
			{
				[item addRepo:repo];
			}
		}
		else
		{
			return NO;
		}

	}
	else if ([info draggingSource] == _outlineView && 
			[pasteboard availableTypeFromArray:
			 [NSArray arrayWithObject:GITFRONT_BPOARD_TYPE]] != nil) 
	{
		if ( [self isParent:draggedNode ofNode:item] )
		{
			return NO;
		}
		
		GitFrontRepositories *parent = [ov parentForItem:draggedNode];

		if ( parent )
		{
			[draggedNode retain];
			
			[[parent children] removeObject:draggedNode];
			
			if ( childIndex >= 0 )
			{
				[item insertNode:draggedNode atIndex:childIndex];
			}	
			else
			{
				[item addNode:draggedNode];
			}
			
			[draggedNode release];
		}
	}
	else
	{
		return NO;
	}

	[self saveDataToDisk];
	[ov reloadData];
	
	[ov expandItem:item];
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
		 writeItems:(NSArray *)items 
	   toPasteboard:(NSPasteboard *)pboard
{
	draggedNode = [items objectAtIndex:0];
	
	if ( [draggedNode isKindOfClass:[GitFrontRepositories class]] ||
		 [draggedNode isKindOfClass:[GitFrontRepositoriesLeaf class]] )
	{
		// Provide data for our custom type, and simple NSStrings.
		[pboard declareTypes:[NSArray arrayWithObjects:GITFRONT_BPOARD_TYPE, 
							  NSStringPboardType, 
							  NSFilesPromisePboardType, 
							  nil] owner:self];
	
		[pboard setData:[NSData data] forType:GITFRONT_BPOARD_TYPE];
    
		// Put string data on the pboard... notice you can drag into TextEdit!
		[pboard setString:[draggedNode name] forType:NSStringPboardType];
		
		return YES;	
	}
	else
	{
		return NO;
	}
}

@end


