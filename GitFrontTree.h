//
//  GitFrontTree.h
//  gitfend
//
//  Created by Manuel Astudillo on 6/8/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitrepo.h"

/**
	Tree structure to be used by the outline view
 
 */


@interface GitFrontTreeLeaf: NSObject
{
	NSString* name;
	NSTextStorage* text;
	NSData *sha1;
	NSImage*  icon;
	GitRepo *repo;
}

@property (readwrite, retain) NSString* name;
@property (readwrite, retain) NSTextStorage* text;
@property (readwrite, retain) NSData *sha1;
@property (readwrite, retain) NSImage*  icon;
@property (readwrite, retain) GitRepo *repo;

@end

@interface GitFrontTree : NSObject 
{
	NSMutableArray	*children;
	NSString* name;
	NSImage*  icon;
	GitRepo *repo;

	NSDictionary *iconsDict;
}

@property (readwrite, retain) NSString* name;
@property (readwrite, retain) NSImage*  icon;
@property (readwrite, retain) GitRepo *repo;

-(id) initTreeWithRepo:(GitRepo*) repo icons:(NSDictionary*) icons;

-(id) initTreeWithIcons:(NSDictionary*) icons;

-(void) addChildren:(id) ref key: (id) key;

-(void) addLeaf:(id) content key:(id) key;

-(NSArray*) children;

@end
