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

NSString *description;
NSTextStorage *text;

@interface GitFrontTreeLeaf: NSObject
{
	NSString* description;
	NSTextStorage* text;
	NSData *sha1;
	GitRepo *repo;
}

@property (readwrite, retain) NSString* description;
@property (readwrite, retain) NSTextStorage* text;
@property (readwrite, retain) NSData *sha1;
@property (readwrite, retain) GitRepo *repo;


@end


@interface GitFrontTree : NSObject 
{
	NSMutableArray	*children;
	NSString* description;
	NSImage*  nodeIcon;
	GitRepo *repo;
}

@property (readwrite, retain) NSString* description;
@property (readwrite, retain) NSImage*  nodeIcon;
@property (readwrite, retain) GitRepo *repo;


-(id) initTreeWithRepo:(GitRepo*) repo;

-(void) addChildren:(id) ref key: (id) key;

-(NSArray*) children;



@end
