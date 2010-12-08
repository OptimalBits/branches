//
//  GFWorkingDirBrowserController.h
//  GitFront
//
//  Created by Manuel Astudillo on 8/17/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GFRepoWatcher.h"

@class GitRepo;
@class GitWorkingDir;
@class GitFrontIcons;
@class CCDiffViewController;

@interface GFWorkingDirBrowserController : NSViewController 
<NSOutlineViewDataSource, GFRepoWatcherDelegate>
{
	IBOutlet NSOutlineView *workingDirBrowseView;
	IBOutlet NSOutlineView *stageAreaBrowseView;
	
	CCDiffViewController *diffView;
	
	GitRepo *repo;
	GitWorkingDir *workingDir;
	
	NSFileManager *fileManager;
	
	NSSet *modifiedFiles;

	NSTreeNode *statusTree;
	NSTreeNode *fileTree;
	
	GFRepoWatcher *repoWatcher;
	
	
	NSDictionary *icons;
}

- (IBAction) addFile:(id) sender;
- (IBAction) removeFile:(id) sender;
- (IBAction) renameFile:(id) sender;


- (id) init;
- (void) awakeFromNib;
- (void) dealloc;

- (void) setRepo:(GitRepo*) _repo;
- (GitRepo*) repo;

- (void) setDiffView:(CCDiffViewController*) diffView;

-(void) updateView;

@end
