//
//  gitpack.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct
{
	uint8_t sha1[20];
} Sha1Key;


@interface GitPackIndex : NSObject
{
	uint32_t fanouts[256];
	Sha1Key *keys;
	uint32_t *offsets;
	uint32_t *crcs;
	
	Sha1Key packFileChecksum;
	Sha1Key packIndexChecksum;
}

- (id) initWithURL:(NSURL*) index largerThan2G: (BOOL*) largePack;

- (uint32_t) findObjectOffset:(NSData*) key;

- (void) dealloc;

@end



@interface GitPackFile : NSObject 
{
	NSURL *pack;
	GitPackIndex *index;
	
	NSFileHandle *packFileHandle;
}

- (id) initWithIndexURL:(NSURL*) indexURL andPackURL:(NSURL*) packURL;
- (id) getObject:(NSData*) key;
- (id) getObjectFromShaCString:(char*) string;

- (void) dealloc;


@end


