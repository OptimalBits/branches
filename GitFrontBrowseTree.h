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

@interface GitFrontBrowseTreeLeaf: NSObject
{
	NSString* status;
	NSImage*  nodeIcon;
	NSString* description;
	NSString* author;
	NSString* date;
	NSString* name;
	NSData *sha1;
}

@property (readwrite, retain) NSString* status;
@property (readwrite, retain) NSImage*  nodeIcon;
@property (readwrite, retain) NSString* description;
@property (readwrite, retain) NSString* author;
@property (readwrite, retain) NSString* date;
@property (readwrite, retain) NSString* name;
@property (readwrite, retain) NSData* sha1;

@end

@interface GitFrontBrowseTree : NSObject 
{
	NSMutableArray	*children;
	
	GitObjectStore* objectStore;
	NSString*		status;
    NSString*		description;
	NSString*		name;
	NSImage*		nodeIcon;
	NSData*			commitSha1;
}

@property (readwrite, retain) GitObjectStore* objectStore;
@property (readwrite, retain) NSString*		  status;
@property (readwrite, retain) NSString*		  description;
@property (readwrite, retain) NSString*		  name;
@property (readwrite, retain) NSImage*		  nodeIcon;
@property (readwrite, retain) NSData*		  commitSha1;

-(id) initWithCommit:(NSData*) commit objectStore:(GitObjectStore*) _objectStore;

-(void) addChildren:(id) ref key: (id) key;

-(NSArray*) children;

@end
