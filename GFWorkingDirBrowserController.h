//
//  GFWorkingDirBrowserController.h
//  GitFront
//
//  Created by Manuel Astudillo on 8/17/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitRepo;
@class GitFrontIcons;
@class CCDiffViewController;

@interface GFWorkingDirBrowserController : NSViewController <NSOutlineViewDataSource> 
{
	IBOutlet NSOutlineView *workingDirBrowseView;
	IBOutlet NSOutlineView *stageAreaBrowseView;
	
	CCDiffViewController *diffView;
	
	GitRepo *repo;
	NSFileManager *fileManager;
	
	NSSet *modifiedFiles;

	NSTreeNode *statusTree;
	
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
