//
//  GitFrontBrowseController.m
//  GitFront
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitFrontBrowseController.h"
#import "GitFrontBrowseTree.h"
#import "gittreeobject.h"

#import "NSDataExtension.h"

@implementation GitFrontBrowseController

-(id) init
{
	if ( self = [super initWithNibName:@"Browser" bundle:nil] )
    {
		[self setTitle:@"GitFront - Browser"];
	}
	
	return self;
}

-(void) dealloc
{
	[browseTree release];
	[objectStore release];
	[tree release];
	[super dealloc];
}

-(void) setTree:(NSData *) _tree commit:(NSData*) commit repo:(GitRepo*) repo
{
	if ( _tree != nil )
	{
		[_tree retain];
		[tree release];
		tree = _tree;
	
		[objectStore release];
		objectStore = [repo objectStore];
		[objectStore retain];
	
		//[browseTree release];
		
		browseTree = [[GitFrontBrowseTree alloc] initWithCommit:commit 
													objectStore:objectStore];
		
		
		[browseView reloadData];
	}
}

-(void) awakeFromNib
{
	
}

///////

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if ( item == nil ) // return parent
	{
		return [[browseTree children] objectAtIndex:index];
	}
	else if ([item isKindOfClass:[GitFrontBrowseTree class]])
	{
		return [[item children] objectAtIndex: index];		
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if ([item isKindOfClass:[GitFrontBrowseTree class]] && [[item children] count] > 0 )
	{
		return YES;
	}
    
	return NO;	
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if ( item == nil )
	{
		return [[browseTree children] count];
	}
	else if ([item isKindOfClass:[GitFrontBrowseTree class]])
	{
		return [[item children] count];
	}
	
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	// Note that you can find the parent of a given item using [outlineView parentForItem:item];
	
	if ([[[tableColumn headerCell] stringValue] compare:@"Name"] == NSOrderedSame) 
	{		
		return [item name];
	} 
	else if ([[[tableColumn headerCell] stringValue] compare:@"Description"] == NSOrderedSame) 
	{
		return [item description];
	}
	
	return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	// pass
}


@end
