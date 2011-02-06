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
	[mainContainer displayViewController:folderDiffController];
}

-(void) dealloc
{
	[bookmarks release];
	[recents release];
	[folderDiffController release];
	[super dealloc];
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
			[recents insertObject:currentSession atIndex:0];
			if ( [recents count] > 20 )
			{
				[recents removeLastObject];
			}
			NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:recents];
			[archivedData writeToFile:recentsArchivePath atomically:YES];
			
			[bookmarksView reloadData];
			
			[folderDiffController setDiffSession:currentSession];
		}
	}
	
	[NSApp endSheet:newSessionSheet];
	[newSessionSheet orderOut:sender];
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

// -------------------- Bookmarks  Data Source Start ---------------------------

- (id)outlineView:(NSOutlineView *)outlineView 
			child:(NSInteger)index 
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

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
	//if ( ( item ) && ( item != recents ) && ( item != bookmarks ) )
	{
		return [self outlineView:outlineView numberOfChildrenOfItem:item] > 0;
	}
	//return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView 
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

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
		   byItem:(id)item
{
	if ( [[tableColumn identifier] isEqualToString:@"bookmarks"] )
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
	return nil;
}

/*
- (void)outlineView:(NSOutlineView *)outlineView 
sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	NSArray *newDescriptors = [outlineView sortDescriptors];
	[diffTree sortWithSortDescriptors:newDescriptors recursively:YES];
	[outlineView reloadData];
}
*/

// -------------------------- Data Source End ----------------------------------


// --------------------- OutlineView Delegate Start ----------------------------

- (void)outlineView:(NSOutlineView *)outlineView 
didClickTableColumn:(NSTableColumn *)tableColumn
{
	// Pass
}


- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	//[self updateViews];
	id item = [bookmarksView itemAtRow:[bookmarksView selectedRow]];
	
	if ( [item isKindOfClass:[OBSDiffSession class]] )
	{
		currentSession = item;
		[folderDiffController setDiffSession:currentSession];
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
	
	if ( ( item == bookmarks ) || ( item == recents ) )
	{
		[textCell setTextColor:[NSColor darkGrayColor]];
		//[textCell setBackgroundStyle:NSBackgroundStyleRaised];
		//[textCell setDrawsBackground:NO];
		
		[textCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
	}
	else
	{
		[textCell setTextColor:[NSColor blackColor]];
		[textCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	}
}





// --------------------- OutlineView Delegate End ------------------------------



@end
