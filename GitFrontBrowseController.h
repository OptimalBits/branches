//
//  GitFrontBrowseController.h
//  gitfend
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitrepo.h"
#import "gittreeobject.h"
#import "GitFrontBrowseTree.h"


@interface GitFrontBrowseController : NSViewController <NSOutlineViewDataSource> {
	IBOutlet NSOutlineView *browseView;
	
	NSData* tree;
	GitObjectStore *objectStore;
	GitFrontBrowseTree *browseTree;
}

-(void) setTree:(NSData *) _tree commit:(NSData*) commit repo:(GitRepo*) repo;

- (void) awakeFromNib;

// NSOutlineViewDataSource protocol:

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;



@end
