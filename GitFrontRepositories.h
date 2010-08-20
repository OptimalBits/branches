//
//  gitfendRepositories.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitrepo.h"

@interface gitfendRepositories : NSObject <NSOutlineViewDataSource> {
	NSMutableArray *repositories;
}

- (id) init;
- (void) dealloc;

- (void) addRepo:(GitRepo *) repo;

// NSOutlineViewDataSource protocol:

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

@end

