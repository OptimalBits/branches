//
//  GitIndex.h
//  gitfend
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct
{
	uint64_t ctime;
	uint64_t mtime;
	uint32_t dev;
	uint32_t inode;
	uint32_t mode;
	uint32_t uid;
	uint32_t gid;
	uint32_t size;
	uint8_t  sha1[20];
	uint16_t flags;
} EntryInfo;

@interface GitIndexEntry : NSObject
{
	EntryInfo entryInfo;
	NSString *filename;
}

@property (readwrite, retain) NSString *filename;

-(EntryInfo*) entryInfo;


@end


@interface GitIndex : NSObject {
	NSMutableDictionary *entries;
}

-(id) initWithUrl:(NSURL*) url;
-(void) dealloc;

-(NSData*) writeTree;
-(void) readTree: (NSData*) sha1;

-(void) updateFilename: (NSURL*) url;
-(void) checkoutFilename: (NSURL*) url;
-(void) checkout;

-(void) commitTree:(NSData*) tree withParents:(NSArray*) parents;

@end
