//
//  gitcommitobject.h
//  GitLib
//
//  Created by Manuel Astudillo on 5/22/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GitObject.h"


@interface GitUserInfo : NSObject
{
	NSString *name;
	NSString *email;
	NSDate *time;
	NSInteger *gmtSeconds;
}

@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSString *email;
@property (readwrite, retain) NSDate *time;
@property (readwrite, retain) NSTimeZone *offutc;

/*
- (id)initWithTimestamp: (NSTimeInterval)seconds timeZoneOffset: (NSString *)offset {
    return [self initWithDate:[NSDate dateWithTimeIntervalSince1970:seconds]
                     timeZone:[NSTimeZone timeZoneWithStringOffset:offset]];
}
 */

@end

@interface GitAuthor : NSObject
{
	NSString *name;
	NSString *email;
	NSDate *time;
	NSInteger gmtSeconds;
}

@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSString *email;
@property (readwrite, retain) NSDate *time;
@property (readwrite, assign)   NSInteger gmtSeconds;

-(id) initWithName: name email: email andTime: time;

-(NSString*) encode:(NSString*) user;

@end


@interface GitCommitObject : GitObject 
{
	NSData *sha1;
	NSMutableArray *parents;
	NSData *tree;
	
	NSString *message;
	
	GitAuthor *author;
	GitAuthor *committer;
}

@property (readwrite, retain) NSData *sha1;
@property (readwrite, retain) NSMutableArray *parents;
@property (readwrite, retain) NSData *tree;

@property (readwrite, retain) NSString *message;

@property (readwrite, retain) GitAuthor *author;
@property (readwrite, retain) GitAuthor *committer;


- (id) initWithTree:(NSData*) tree 
			parents:(NSArray*) parents
			message:(NSString*) message
			 author:(GitAuthor*) author
		   commiter:(GitAuthor*) commiter;

- (id) initWithData: (NSData*) data sha1: (NSData*) sha1;

/**
	Returns the commit as a serialized NSData object.
 */
- (NSData*) data;

- (BOOL) isEqual:(id)object;
-(NSUInteger) hash;
-(NSComparisonResult) compareDate:(GitCommitObject*) obj;

@end
