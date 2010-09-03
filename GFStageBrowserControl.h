//
//  GFStageBrowserControl.h
//  gitfend
//
//  Created by Manuel Astudillo on 8/21/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GFStageBrowserControl :  NSViewController <NSOutlineViewDataSource> 
{
	IBOutlet NSOutlineView *stageBrowseView;
	
	GitRepo *repo;	
}

/**
	Removes a file from the stage area.
 */
- (IBAction) unstageFile:(id) sender;

- (id) init;
- (void) awakeFromNib;
- (void) dealloc;

- (void) setRepo:(GitRepo*) _repo;



@end
