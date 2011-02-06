//
//  UnifyAppController.h
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UnifyFileDiffController, UnifyFolderDiffController, OBSDiffSession;

@interface UnifyAppController : NSObject 
<NSOutlineViewDataSource, NSOutlineViewDelegate>{

	IBOutlet NSTextField *bottomInfoText;
	IBOutlet NSTextField *activityInfoText;

	IBOutlet NSProgressIndicator *progressIndicator;
	
	NSString *recentsArchivePath;
	NSString *bookmarksArchivePath;
	
	// <bookmarks>
	
	NSMutableArray   *recents;
	NSMutableArray	 *bookmarks;
	
	IBOutlet NSOutlineView *bookmarksView;
	
	// </bookmarks>
	
	IBOutlet NSBox *mainContainer;
		
	IBOutlet NSWindow *newSessionSheet;
	IBOutlet NSTextField *leftFilePath;
	IBOutlet NSTextField *rightFilePath;
	
	IBOutlet NSButton *leftOpenFileDlgButton;
	IBOutlet NSButton *rightOpenFileDlgButton;

	OBSDiffSession *currentSession;
	

	
	UnifyFolderDiffController *folderDiffController;
	UnifyFileDiffController   *fileDiffController;
}


@property (readonly, retain) NSMutableArray *bookmarks;
@property (readonly, retain) NSMutableArray *recents;


- (void)awakeFromNib;

- (IBAction) showNewSessionSheet:(id) sender;
- (IBAction) endNewSessionSheet:(id) sender;

- (IBAction) selectPath:(id)sender;

@end
