//
//  GFWorkingDirBrowserController.h
//  GitFront
//
//  Created by Manuel Astudillo on 8/17/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GFRepoWatcher.h"
#import "GitFile.h"

@class GitRepo, GitWorkingDir, GitFrontIcons, CCDiffViewController;
@class GitModificationDateResolver, gitfendRepositoryController;

@interface GFWorkingDirBrowserController : NSViewController 
<NSOutlineViewDataSource, GFRepoWatcherDelegate>
{
	IBOutlet NSOutlineView *workingDirBrowseView;
	IBOutlet NSOutlineView *stageAreaBrowseView;
	IBOutlet NSButton *commitButton;
	
	IBOutlet NSWindow *commitSheet;
	IBOutlet NSTextView *commitMessageView;
	
	gitfendRepositoryController *controller;
	
	CCDiffViewController *diffView;
	
	GitRepo *repo;
	GitWorkingDir *workingDir;
	
	GitModificationDateResolver *dateResolver;
	NSDateFormatter *dateFormatter;
	
	NSFileManager *fileManager;
	
	NSTreeNode *statusTree;
	NSTreeNode *fileTree;
	
	GFRepoWatcher *repoWatcher;
	
	NSDictionary *icons;
	
	GitFileStatus status_mask;
	
}

- (IBAction) commit:(id) sender;

- (IBAction) modifiedFilesFilter:(id) sender;
- (IBAction) untrackedFilesFilter:(id) sender;
- (IBAction) ignoredFilesFilter:(id) sender;

- (IBAction) expandFilesTree:(id) sender;
- (IBAction) collapseFilesTree:(id) sender;

- (IBAction) addFile:(id) sender;
- (IBAction) removeFile:(id) sender;
- (IBAction) renameFile:(id) sender;

- (void) showCommitSheet;	
- (IBAction) endCommitSheet:(id) sender;

- (id) initWithController:(gitfendRepositoryController*) _controller;
- (void) awakeFromNib;
- (void) dealloc;

- (void)     setRepo:(GitRepo*) _repo;
- (GitRepo*) repo;

- (void) setDiffView:(CCDiffViewController*) diffView;

-(void) updateView;

@end

