//
//  UnifyFolderDiffController.h
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CCDiffViewController, OBSDirectory, OBSDiffSession;

@interface UnifyFolderDiffController : NSViewController 
<NSOutlineViewDataSource, NSOutlineViewDelegate> 
{	
	CCDiffViewController *fileDiffController;
	
	OBSDiffSession *diffSession;
		
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
	
	IBOutlet NSPathControl *leftPathControl;
	IBOutlet NSPathControl *rightPathControl;
	
	NSOperationQueue *operationQueue;
}

@property (readonly) CCDiffViewController *fileDiffController;

-(void) setDiffSession:(OBSDiffSession*) session;
-(void) setDiffTree:(NSTreeNode*) diffTree;

- (IBAction) nextDiff:(NSToolbarItem*) item;
- (IBAction) prevDiff:(NSToolbarItem*) item;
- (IBAction) mergeRight:(NSToolbarItem*) item;
- (IBAction) mergeLeft:(NSToolbarItem*) item;
- (IBAction) saveChanges:(NSToolbarItem*) item;

@end
