//
//  UnifyAppController.m
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "UnifyAppController.h"
#import "UnifyFolderDiffController.h"
#import "UnifyFileDiffController.h"

#import "NSBox+OBSDisplay.h"

#import "OBSDirectory.h"
#import "OBSDiffSession.h"
#import "OBSTextCell.h"

#import "NSFileManager+DirectoryLocations.h"


@interface PXSourceList (SelectItem)

- (void)setSelectedItem:(id)item;

@end

@implementation PXSourceList (SelectItem)

- (void)setSelectedItem:(id)item {
    NSInteger itemIndex = [self rowForItem:item];
    if (itemIndex < 0) {
        // You need to decide what happens if the item doesn't exist
        return;
    }
	
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
}
	
@end


@interface UnifyAppController (Private)

-(void) startFolderDiffSession:(OBSDiffSession*) session;

@end

@implementation UnifyAppController

@synthesize bookmarks, recents;

- (void)awakeFromNib
{
	bookmarks = [[NSMutableArray alloc] init];
	recents = [[NSMutableArray alloc] init];
	
	NSString *applicationSupportPath = 
		[[NSFileManager defaultManager] applicationSupportDirectory];
		
	recentsArchivePath = [[applicationSupportPath
						  stringByAppendingPathComponent:@"recents.archive"] retain];
	
	bookmarksArchivePath = [[applicationSupportPath
							stringByAppendingPathComponent:@"bookmarks.archive"] retain];

	recents = [[NSKeyedUnarchiver unarchiveObjectWithFile:recentsArchivePath] retain];
	if ( recents == nil )
	{
		recents = [[NSMutableArray alloc] init];
	}
	
	bookmarks = [[NSKeyedUnarchiver unarchiveObjectWithFile:bookmarksArchivePath] retain];
	if ( bookmarks == nil )
	{
		bookmarks = [[NSMutableArray alloc] init];
	}
	
	OBSTextCell *textCell = [[[OBSTextCell alloc] init] autorelease];
	
	[[bookmarksView tableColumnWithIdentifier:@"bookmarks"] setDataCell:textCell];
	[[bookmarksView tableColumnWithIdentifier:@"changes"] setDataCell:textCell];	
	
	[bookmarksView setDataSource:self];
	[bookmarksView setDelegate:self];
	[bookmarksView reloadData];
	
	[bookmarksView expandItem:bookmarks];
	[bookmarksView expandItem:recents];
	
	[[bottomInfoText cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[bottomInfoText setStringValue:@"Ready"];
	
	folderDiffController = [[UnifyFolderDiffController alloc] init];
	currentViewController = nil;
	
	operationQueue = [[NSOperationQueue alloc] init];
	
	//
	//[toolbar validateVisibleItems];
}

-(void) dealloc
{
	[operationQueue release];
	[bookmarks release];
	[recents release];
	[folderDiffController release];
	[super dealloc];
}


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	
    if ( action == @selector(nextDiff:)	||
		 action == @selector(prevDiff:) ||
		 action == @selector(mergeLeft:) ||
		 action == @selector(mergeRight:) )
	{
		return [currentViewController validateUserInterfaceItem:anItem];
	}
	
	return NO;
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
	SEL action = [toolbarItem action];
	
    if ( action == @selector(nextDiff:)	||
		 action == @selector(prevDiff:) ||
		 action == @selector(mergeLeft:) ||
		 action == @selector(mergeRight:) )
	{
		return [currentViewController validateToolbarItem:toolbarItem];
	}
	return NO;
}


- (IBAction) nextDiff:(NSToolbarItem*) item
{
	[currentViewController nextDiff:item];
}

- (IBAction) prevDiff:(NSToolbarItem*) item
{
	[currentViewController prevDiff:item];
}

- (IBAction) mergeRight:(NSToolbarItem*) item
{
	[currentViewController mergeRight:item];
}

- (IBAction) mergeLeft:(NSToolbarItem*) item
{
	[currentViewController mergeLeft:item];
}

- (IBAction) saveChanges:(NSToolbarItem*) item
{
	
}

/**
	This will forward all not implemented actions to the current controller.
 */
- (void)forwardInvocation:(NSInvocation *) invocation
{
    if ([currentViewController respondsToSelector:[invocation selector]])
	{
        [invocation invokeWithTarget:currentViewController];
	}
}

- (IBAction) showNewSessionSheet:(id) sender
{
	NSWindow *window = [NSApp mainWindow];
	
	[NSApp beginSheet: newSessionSheet
	   modalForWindow: window
		modalDelegate:nil
	   didEndSelector:NULL 
		  contextInfo:NULL];
}

- (IBAction) endNewSessionSheet:(id) sender
{
	[NSApp endSheet:newSessionSheet];
	[newSessionSheet orderOut:sender];

	if ( [sender tag] == 0 )
	{
		if ( ( [leftFilePath stringValue] != nil ) && 
			 ( [rightFilePath stringValue] != nil ) )
		{
			OBSDirectory *leftSource = 
			[[[OBSDirectory alloc] initWithPath:[leftFilePath stringValue]] autorelease];
			
			OBSDirectory *rightSource = 
			[[[OBSDirectory alloc] initWithPath:[rightFilePath stringValue]] autorelease];
			
			[currentSession release];
			
			currentSession = [[OBSDiffSession alloc] init];
			[currentSession setLeftSource:leftSource];
			[currentSession setRightSource:rightSource];
			
			// TODO: move to own method
			//if ( [recents containsObject:currentSession] == NO)
			{
				[recents insertObject:currentSession atIndex:0];
				if ( [recents count] > 20 )
				{
					[recents removeLastObject];
				}
				NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:recents];
				[archivedData writeToFile:recentsArchivePath atomically:YES];
			}
				
			[bookmarksView reloadData];

			[bookmarksView expandItem:recents];
			[bookmarksView setSelectedItem:currentSession];
		}
	}	
}

- (IBAction) selectPath:(id)sender
{
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];

	[openDlg setCanChooseFiles:YES];
	[openDlg setCanChooseDirectories:YES];

	// In the future we should be able to allow multiple selections as well!
	[openDlg setAllowsMultipleSelection:NO];

	if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
	{
		NSArray* dirs = [openDlg URLs];
		
		if ( [dirs count] > 0 )
		{
			NSError *error;
			
			NSURL *workingDir = [dirs objectAtIndex:0];
		
			if ([workingDir checkResourceIsReachableAndReturnError:&error] == YES)
			{				
				if ( sender == leftOpenFileDlgButton )
				{
					[leftFilePath setStringValue:[workingDir path]];
				}
				else if ( sender == rightOpenFileDlgButton )
				{
					[rightFilePath setStringValue:[workingDir path]];
				}
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

-(void) startFolderDiffSession:(OBSDiffSession*) session
{
	OBSCompareDirectories *compareDirectories;
	
	[folderDiffProgressIndicator startAnimation:self];
	
	[mainContainer setContentView:folderDiffProgressIndicator];
	
	currentSession = session;
	
	[operationQueue cancelAllOperations];
	
	compareDirectories = [[OBSCompareDirectories alloc] 
						  initWithLeftDirectory:[currentSession leftSource]
						  rightDirectory:[currentSession rightSource]];
	
	[compareDirectories setCompletionBlock:^void (void)
	 {
		 if ([compareDirectories isFinished])
		 {
			 [folderDiffController setDiffTree:[compareDirectories resultTree]];
			 [folderDiffController setDiffSession:currentSession];
			 [folderDiffProgressIndicator startAnimation:self];
			 [mainContainer displayViewController:folderDiffController];
			 currentViewController = folderDiffController;
		 }
	 }
	 ];
	
	[compareDirectories setThreadPriority:1.0];
	
	[operationQueue addOperation:compareDirectories];
}

// -------------------- Bookmarks  Data Source Start ---------------------------

- (id)sourceList:(PXSourceList *)aSourceList 
		   child:(NSUInteger)index 
		  ofItem:(id)item
{
	if ( item == nil )
	{
		switch (index) {
			case 0:
				return bookmarks;
				break;
			case 1:
				return recents;
			default:
				return 0;
				break;
		}
	}
	else
	{
		return [item objectAtIndex:index];
	}
}

- (BOOL)sourceList:(PXSourceList *)aSourceList 
  isItemExpandable:(id)item
{
	return [self sourceList:aSourceList numberOfChildrenOfItem:item] > 0;
}

- (NSUInteger)sourceList:(PXSourceList *)sourceList 
  numberOfChildrenOfItem:(id)item
{
	if ( item )
	{
		if ([item isKindOfClass:[NSArray class]]) 
		{
			return [item count];
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return 2; // Bookmarks & Recents
	}
}

- (id)sourceList:(PXSourceList *)aSourceList objectValueForItem:(id)item
{
	if ( item == nil )
	{
		return @"--";
	}
	if ( item == bookmarks )
	{
		return @"BOOKMARKS";
	}
	else if ( item == recents )
	{
		return @"RECENTS";
	}
	else
	{
		OBSDiffSession *session = item;
		return [session name];
	}
}

- (void)sourceList:(PXSourceList *)aSourceList setObjectValue:(id)object forItem:(id)item
{
	
}

- (BOOL)sourceList:(PXSourceList *)aSourceList itemHasIcon:(id)item
{
	return NO;
}

- (NSImage *)sourceList:(PXSourceList *)aSourceList iconForItem:(id)item
{
	return nil;
}


// -------------------------- Data Source End ----------------------------------


// --------------------- OutlineView Delegate Start ----------------------------
- (void)sourceListSelectionDidChange:(NSNotification *)notification
{
	id item = [bookmarksView itemAtRow:[bookmarksView selectedRow]];
	
	if ( [item isKindOfClass:[OBSDiffSession class]] )
	{
		[self startFolderDiffSession:item];
	}
}


// Renaming support!.
- (void)outlineView:(NSOutlineView *)outlineView 
	 setObjectValue:(id)object 
	 forTableColumn:(NSTableColumn *)tableColumn 
			 byItem:(id)item
{
//	GitFrontRepositories *r = item;
//	[r setName:object];
//	[self saveDataToDisk];
}

// Tooltip support!
- (NSString *)outlineView:(NSOutlineView *)outlineView 
		   toolTipForCell:(NSCell *)cell 
					 rect:(NSRectPointer)rect 
			  tableColumn:(NSTableColumn *)tc 
					 item:(id)item 
			mouseLocation:(NSPoint)mouseLocation
{
	return @"My super duper tooltip";
}

- (void)outlineView:(NSOutlineView *)olv 
	willDisplayCell:(NSCell*)cell 
	 forTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{
	OBSTextCell *textCell = (OBSTextCell*) cell;
/*	
	if ( ( item == bookmarks ) || ( item == recents ) )
	{
		[textCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
		[textCell setTextColor:[NSColor darkGrayColor]];
		//[textCell setBackgroundStyle:NSBackgroundStyleRaised];
		//[textCell setDrawsBackground:NO];
	}
	else
	{
		[textCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
		[textCell setTextColor:[NSColor blackColor]];
	}
 */
}


// --------------------- OutlineView Delegate End ------------------------------



@end
