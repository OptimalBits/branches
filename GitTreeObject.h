//
//  gittreeobject.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/25/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitobject.h"

@interface GitTreeNode : NSObject
{
	NSData *sha1;
	NSString *mode;
}

@property (readwrite, retain) NSData *sha1;
@property (readwrite, retain) NSString *mode;

@end

@interface GitTreeObject : GitObject 
{
	NSMutableDictionary *tree;
}

@property (readonly) NSMutableDictionary *tree;

-(id) init;

-(id) initWithData: (NSData*) data;

-(void) appendObject:(GitObject*) object 
			filename:(NSString*) filename
				mode:(NSString*) mode;


/**
	Returns a tree with the difference between trees.

 */
- (GitTreeObject*) treeDiff: (GitTreeObject*) prevTree;


@end
