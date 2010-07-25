//
//  gitcommitobject.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/22/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitobject.h"


@interface GitAuthor : NSObject
{
	NSString *name;
	NSString *email;
	NSDate *time;
	NSString *offutc;
}

@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSString *email;
@property (readwrite, retain) NSDate *time;
@property (readwrite, retain) NSString *offutc;

-(id) initWithName: name email: email andTime: time;


@end


@interface GitCommitObject : GitObject 
{
}

@property (readwrite, retain) NSData *tree;
@property (readwrite, retain) NSMutableArray *parents;
@property (readwrite, retain) NSString *message;
@property (readwrite, retain) NSData *sha1;
@property (readwrite, retain) GitAuthor *author;
@property (readwrite, retain) GitAuthor *committer;


- (id) initWithData: (NSData*) data sha1: (NSData*) sha1;

@end
