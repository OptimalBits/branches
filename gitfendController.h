//
//  gitfendController.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitfrontHistoryController.h"

@class GitFrontRepositories;
@class GitFrontBrowseController;
@class GFWorkingDirBrowserController;
@class CCDiffViewController;

@interface gitfendRepositoryController : NSObject <NSOutlineViewDelegate, 
												   NSOutlineViewDataSource> {
	IBOutlet NSBox *box;
	
	IBOutlet NSOutlineView *_outlineView;	// Repo view
	
	IBOutlet NSMenu *repositoryMgmtMenu;
	IBOutlet NSMenuItem *removeRepoMenuItem;
													   
	IBOutlet NSView *bottomView;
	IBOutlet NSBox *bottomBox;

	
	gitfrontHistoryController *historyController;
	GitFrontBrowseController *browseController;
	GFWorkingDirBrowserController *workingDirBrowseController;
	id currentController;
	
	GitFrontRepositories *repos;
	id draggedNode;
	
	NSMutableArray *viewControllers; // TODO: Change to Dictionary.
	NSViewController *currentView;
													   
	CCDiffViewController *diffViewController;
}

- (void) dealloc;
- (void) awakeFromNib;

- (void) displayViewController:(NSViewController*) vc;

- (IBAction) changeMainView:(id) sender;
- (IBAction) addRepo:(id) sender;
- (IBAction) removeRepo:(id) sender;
- (IBAction) addGroup:(id) sender;


- (void) addRepoFromUrl:(NSURL*) repoUrl;


- (NSString *) folderForDataFiles;
- (NSString *) pathForDataFile;
- (void) saveDataToDisk;
- (void) loadDataFromDisk;

// NSOutlineViewDelegate
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;

// NSOutlineViewDataSource protocol:

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

@end


