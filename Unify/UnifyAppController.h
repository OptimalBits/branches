//
//  UnifyAppController.h
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Sweden AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXSourceList.h"

@class UnifyFileDiffController, UnifyFolderDiffController, OBSDiffSession;

@interface UnifyAppController : NSObject 
<PXSourceListDelegate, PXSourceListDataSource, NSUserInterfaceValidations>{

	IBOutlet NSTextField *bottomInfoText;
	IBOutlet NSTextField *activityInfoText;

	NSString *recentsArchivePath;
	NSString *bookmarksArchivePath;
	
	IBOutlet NSToolbar *toolbar;
	
	// <bookmarks>
	
	NSMutableArray   *recents;
	NSMutableArray	 *bookmarks;
	
	IBOutlet PXSourceList *bookmarksView;
	
	// </bookmarks>
	
	IBOutlet NSBox *mainContainer;
	NSViewController *currentViewController;
		
	// <session>
	IBOutlet NSWindow *newSessionSheet;
	IBOutlet NSTextField *leftFilePath;
	IBOutlet NSTextField *rightFilePath;
	
	IBOutlet NSButton *leftOpenFileDlgButton;
	IBOutlet NSButton *rightOpenFileDlgButton;

	OBSDiffSession *currentSession;
	
	// </session>
	
	UnifyFolderDiffController *folderDiffController;
	UnifyFileDiffController   *fileDiffController;
	
	// <operations>
	
	NSOperationQueue *operationQueue;
	NSInvocationOperation *folderDiffOperation;

	IBOutlet NSProgressIndicator *folderDiffProgressIndicator;

	// </operatione>
}


@property (readonly, retain) NSMutableArray *bookmarks;
@property (readonly, retain) NSMutableArray *recents;

- (void)awakeFromNib;

- (IBAction) showNewSessionSheet:(id) sender;
- (IBAction) endNewSessionSheet:(id) sender;

- (IBAction) selectPath:(id)sender;
- (IBAction) deleteBookmark:(id) sender;

// --

- (IBAction) nextDiff:(NSToolbarItem*) item;
- (IBAction) prevDiff:(NSToolbarItem*) item;
- (IBAction) mergeRight:(NSToolbarItem*) item;
- (IBAction) mergeLeft:(NSToolbarItem*) item;

- (IBAction) saveChanges:(NSToolbarItem*) item;

@end
