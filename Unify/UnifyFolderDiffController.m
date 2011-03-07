//
//  UnifyFolderDiffController.m
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "UnifyFolderDiffController.h"
#import "CCDiffViewController.h"
#import "NSBox+OBSDisplay.h"
#import "OBSDirectory.h"
#import "OBSDiffSession.h"
#import "OBSTextCell.h"
#import "NSColor+OBSDiff.h"

NSString *stringFromFileSize( int theSize );

@implementation UnifyFolderDiffController

@synthesize fileDiffController;

- (id) init
{
	if ( self = [super initWithNibName:@"FolderDiffView" bundle:nil] )
    {
		dateFormatter = [[NSDateFormatter alloc] init];
		
		[dateFormatter setDoesRelativeDateFormatting:YES];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		
		//
		// Set Fonts
		//
		
		NSFontManager *fontManager = [NSFontManager sharedFontManager];
		
		cellMainFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
		[cellMainFont retain];
		
		cellItalicFont = [fontManager convertFont:cellMainFont 
									  toHaveTrait:NSItalicFontMask];
		
		NSFontTraitMask fontTraits = [fontManager traitsOfFont:cellItalicFont];
		
		if ( !( (fontTraits & NSItalicFontMask) == NSItalicFontMask ) ) 
		{
			const CGFloat kRotationForItalicText = -14.0;
			
			NSAffineTransform *fontTransform = [NSAffineTransform transform];           
			
			[fontTransform scaleBy:[NSFont smallSystemFontSize]];
			
			NSAffineTransformStruct italicTransformData;
			
			italicTransformData.m11 = 1;
			italicTransformData.m12 = 0;
			italicTransformData.m21 = -tanf( kRotationForItalicText * acosf(0) / 90 );
			italicTransformData.m22 = 1;
			italicTransformData.tX  = 0;
			italicTransformData.tY  = 0;
			
			NSAffineTransform   *italicTransform = [NSAffineTransform transform];
			
			[italicTransform setTransformStruct:italicTransformData];
			
			[fontTransform appendTransform:italicTransform];
			
			cellItalicFont = [NSFont fontWithDescriptor:[cellItalicFont fontDescriptor] 
										  textTransform:fontTransform];
		}
		
		[cellItalicFont retain];
		
		cellBoldFont = [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]];
		[cellBoldFont retain];
		
		
		//
		// Set Icons
		//
		
		NSBundle *bundle = [NSBundle mainBundle];
		
		NSString *modifyIconPath  = [bundle pathForResource:@"pencil" ofType:@"png"];
		modifyIcon = [[NSImage alloc] initWithContentsOfFile:modifyIconPath];
		
		NSString *addIconPath  = [bundle pathForResource:@"add" ofType:@"png"];
		addIcon = [[NSImage alloc] initWithContentsOfFile:addIconPath];

		NSString *removeIconPath  = [bundle pathForResource:@"delete" ofType:@"png"];
		removeIcon = [[NSImage alloc] initWithContentsOfFile:removeIconPath];

		[self setTitle:@"FolderDiffView"];
	
		//
		// Operations
		//
		
		operationQueue = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[operationQueue release];
	[removeIcon release];
	[addIcon release];
	[modifyIcon release];
	[cellMainFont release];
	[cellItalicFont release];
	[cellBoldFont release];
	[dateFormatter release];
	[diffTree release];
	[super dealloc]; 
}

- (void) awakeFromNib
{	
	fileDiffController = [[CCDiffViewController alloc] init];
	
	OBSTextCell *textCell = [[[OBSTextCell alloc] init] autorelease];

	[[filesView tableColumnWithIdentifier:@"Name"] setDataCell:textCell];
	[[filesView tableColumnWithIdentifier:@"Name2"] setDataCell:textCell];
		
	[filesView setDataSource:self];
	[filesView setDelegate:self];
}

- (void)forwardInvocation:(NSInvocation *) invocation
{
    if ([fileDiffController respondsToSelector:[invocation selector]])
	{
        [invocation invokeWithTarget:fileDiffController];
	}
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
	return [fileDiffController validateToolbarItem:toolbarItem];
}

-(void) setDiffTree:(NSTreeNode*) _diffTree
{
@synchronized(self)
	{
		[diffTree release];
		diffTree = _diffTree;
		[diffTree retain];
		[filesView reloadData];
	}
}

-(void) setDiffSession:(OBSDiffSession*) session
{
	[session retain];
	[diffSession release];
	diffSession = session;
	
	[leftPathControl setURL:[NSURL fileURLWithPath:
							 [[[diffSession leftSource] root] path]]];
	[rightPathControl setURL:[NSURL fileURLWithPath:
							 [[[diffSession rightSource] root] path]]];
}

- (IBAction) nextDiff:(NSToolbarItem*) item
{
	[fileDiffController nextDiff:item];
}

- (IBAction) prevDiff:(NSToolbarItem*) item
{
	[fileDiffController prevDiff:item];
}

- (IBAction) mergeRight:(NSToolbarItem*) item
{
	[fileDiffController mergeRight:item];
}

- (IBAction) mergeLeft:(NSToolbarItem*) item
{
	[fileDiffController mergeLeft:item];
}

- (IBAction) saveChanges:(NSToolbarItem*) item
{
	
}


// -------------------------- Data Source Start -------------------------------

- (id)outlineView:(NSOutlineView *)outlineView 
			child:(NSInteger)index 
		   ofItem:(id)item
{
	if ( diffTree == nil )
	{
		return nil;
	}
	
	if ( item != nil )
	{
		return [[item childNodes] objectAtIndex:index];
	}
	else
	{
		return [[diffTree childNodes] objectAtIndex:index];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
	return [self outlineView:outlineView numberOfChildrenOfItem:item] > 0;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView 
  numberOfChildrenOfItem:(id)item
{
	if ( item )
	{
		return [[item childNodes] count];
	}
	else if ( diffTree )
	{
		return [[diffTree childNodes] count];
	}
	else
	{
		return 0;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
		   byItem:(id)item
{
	OBSDirectoryComparedNode *node = [item representedObject];
	
	if ([[tableColumn identifier] isEqualToString:@"Name"])
	{
		if ( [node status] != kOBSFileAdded )
		{
			return [[[node leftEntry] path] lastPathComponent];
		}
		else
		{
			return [[[node rightEntry] path] lastPathComponent];
		}
	}

	if ([[tableColumn identifier] isEqualToString:@"Name2"])
	{
		if ( [node status] !=  kOBSFileRemoved )
		{
			return [[[node rightEntry] path] lastPathComponent];
		}
		else
		{
			return [[[node leftEntry] path] lastPathComponent];
		}
	}
	
	if ([[tableColumn identifier] isEqualToString:@"Size"])
	{ 
		if ( [node status] !=  kOBSFileAdded )
		{
			return stringFromFileSize( [[node leftEntry] fileStatus].st_size );
		}
	}
	
	if ([[tableColumn identifier] isEqualToString:@"Size2"])
	{ 
		if ( [node status] !=  kOBSFileRemoved )
		{
			return stringFromFileSize( [[node rightEntry] fileStatus].st_size );
		}
	}
	
	if ([[tableColumn identifier] isEqualToString:@"Modified"])
	{ 
		if ( [node status] !=  kOBSFileAdded )
		{
			return [dateFormatter stringFromDate:[[node leftEntry] modificationDate]];
		}
	}
	
	if ([[tableColumn identifier] isEqualToString:@"Modified2"])
	{ 
		if ( [node status] !=  kOBSFileRemoved )
		{
			return [dateFormatter stringFromDate:[[node rightEntry] modificationDate]];
		}
	}
	
	return @"--";
}

- (void)outlineView:(NSOutlineView *)outlineView 
sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	NSArray *newDescriptors = [outlineView sortDescriptors];
	[diffTree sortWithSortDescriptors:newDescriptors recursively:YES];
	[outlineView reloadData];
}

// -------------------------- Data Source End ----------------------------------


// --------------------- OutlineView Delegate Start ----------------------------

-(void) startDiffSession:(OBSDirectoryComparedNode*) comparedNode
{
	if ( [comparedNode status] == kOBSFileModified )
	{
		NSError *error;
		
		NSString *leftFilePath = [[comparedNode leftEntry] path];
		NSString *rightFilePath = [[comparedNode rightEntry] path];
		
		NSString *leftFile = [NSString stringWithContentsOfFile:leftFilePath 
													   encoding:NSUTF8StringEncoding 
														  error:&error];
		
		NSString *rightFile = [NSString stringWithContentsOfFile:rightFilePath 
														encoding:NSUTF8StringEncoding 
														   error:&error];
		if ( rightFile && leftFile )
		{		
			[diffContainer displayViewController:fileDiffController];
			[fileDiffController setStringsBefore:leftFile 
										andAfter:rightFile];
		}
		else
		{
			// Binary file?
		}
		
		//CCDiff *diff = 
		//	[[CCDiff alloc] initWithBefore:[leftFile andAfter:rightFile]];
		
		//NSArray *diffArray = [diff diff];
	}
	else 
	{
		// Set a standard file viewer.
	}
	
	/*
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
			 [folderDiffProgressIndicator startAnimation:self];
			 [mainContainer displayViewController:folderDiffController];
			 [folderDiffController setDiffSession:currentSession];
		 }
	 }
	 ];
	
	[compareDirectories setThreadPriority:1.0];
	
	[operationQueue addOperation:compareDirectories];
	 */
	}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSTreeNode *treeNode = (NSTreeNode*)[filesView itemAtRow:[filesView selectedRow]];
	
	OBSDirectoryComparedNode *comparedNode = [treeNode representedObject];
	
	[self startDiffSession:comparedNode];
}

- (void)outlineView:(NSOutlineView *)outlineView 
didClickTableColumn:(NSTableColumn *)tableColumn
{
	// Pass
}

- (void)outlineView:(NSOutlineView *)olv 
	willDisplayCell:(NSCell*)cell 
	 forTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{
	OBSDirectoryComparedNode *node = [item representedObject];
	OBSDirectoryEntry *entry = nil;
	
	OBSTextCell *textCell = (OBSTextCell*) cell;
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSFont *font = cellMainFont;
	NSImage *icon;
	
	if ( ( [node status] == kOBSFileModified ) ||
		 ( [node status] == kOBSFileAdded )    ||
		 ( [node status] == kOBSFileRemoved ) )
	{
		font = cellBoldFont;
	}
	else
	{
		font = cellItalicFont;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"Name"])
	{
		entry = [node leftEntry];
		if ( entry == nil )
		{
			font = cellItalicFont;
			entry = [node rightEntry];
		}		
	} 
	else if ([[tableColumn identifier] isEqualToString:@"Name2"])
	{
		entry = [node rightEntry];
		if ( entry == nil )
		{
			font = cellItalicFont;
			entry = [node leftEntry];
		}
	}
	
	if ( entry )
	{
		icon = [ws iconForFile:[entry path]];
		
		if ( [node status] == kOBSFileModified )
		{
			[textCell setTextColor:[NSColor blackColor]];
	    }
		else if ( [node status] == kOBSFileAdded )
		{
			[textCell setTextColor:[NSColor addedLineColor]];
		}
		else if ( [node status] == kOBSFileRemoved )
		{
			[textCell setTextColor:[NSColor removedLineColor]];
		}
		
		[textCell setImage:icon];
	}
	
	if ( font == cellItalicFont )
	{
		[textCell setTextColor:[NSColor grayColor]];
	}
	/*else
	{
		[textCell setTextColor:[NSColor blackColor]];
	}*/

	[textCell setFont:font];
}


// --------------------- OutlineView Delegate End ------------------------------


@end

NSString *stringFromFileSize( int size )
{
	float floatSize = size;
	
	if ( size < 0 )
	{
		size = 0;
	}
	
	if (size < 1023)
		return([NSString stringWithFormat:@"%i bytes",size]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
	floatSize = floatSize / 1024;
	
	return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}


