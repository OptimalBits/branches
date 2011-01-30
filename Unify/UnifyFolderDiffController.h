//
//  UnifyFolderDiffController.h
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UnifyFileDiffController, OBSDirectory;

@interface UnifyFolderDiffController : NSViewController 
<NSOutlineViewDataSource, NSOutlineViewDelegate> 
{	
	UnifyFileDiffController   *fileDiffController;
	
	OBSDirectory *leftDirectory;
	OBSDirectory *rightDirectory;
	
	NSDateFormatter *dateFormatter;
	
	NSFont *cellMainFont;
	NSFont *cellItalicFont;
	NSFont *cellBoldFont;
	
	NSImage *modifyIcon;
	NSImage *addIcon;
	NSImage *removeIcon;
	
	
	NSTreeNode *diffTree;
	
	IBOutlet NSBox *diffContainer;
	IBOutlet NSTreeController *leftDirectoryViewController;
	IBOutlet NSTreeController *rightDirectoryViewController;
	
	IBOutlet NSOutlineView *filesView;
	IBOutlet NSTableColumn *nameColumn;
	
}

-(IBAction) startDiffSession:(id) sender;

@end


