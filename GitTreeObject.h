//
//  gittreeobject.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/25/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitobject.h"

@class GitObject;

typedef enum
{
	kFileTypeMask =		0xf000, // bit mask for the file type bit fields
	kSocket =			0xc000,
    kSymbolicLink =		0xa000,
	kRegularFile =		0x8000,
	kBlockDevice =		0x6000,
	kDirectory =		0x4000,
	kCharacterDevice =	0x2000,
	kFifo =				0x1000,
	kUidBit =			0x800,
	kGidBit=			0x400,   
	kStickyBit =		0x200,
	kOwnerMask =		0x1C0, // mask for file owner permissions
	kOwnerRead =		0x100, // owner has read permission
	kOwnerWrite =		0x80,  // owner has write permission
	kOwnerExe =			0x40,  // owner has execute permission
	kGroupMask =		0x38,  // mask for group permissions
	kGroupRead =		0x20,  // group has read permission
	kGroupWrite =		0x10,  // group has write permission
	kGroupExe =			0x8,   // group has execute permission
	kOtherMask =		0x7,   // mask for permissions for others (not in group)
	kOtherRead =		0x4,   // others have read permission

	kOtherWrite =		0x2,   // others have write permission
	kOtherExe =			0x1    // others have execute permission
} GitMode;

@interface GitTreeNode : NSObject
{
	NSData *sha1;
	uint32 mode;
}

@property (readwrite, retain) NSData *sha1;
@property (readwrite, assign) uint32 mode;

@end

@interface GitTreeObject : GitObject 
{
	NSMutableDictionary *tree;
}

@property (readonly) NSMutableDictionary *tree;

-(id) initWithData: (NSData*) data;

-(void) setEntry:(NSString*) filename
			mode:(uint32) mode
			sha1:(NSData*) sha1;

-(void) removeEntry:(NSString*) filename;

-(void) addTree:(uint32) mode sha1:(NSData*) sha1;

-(NSData*) data;


/**
	Returns a tree with the difference between trees.

 */
- (GitTreeObject*) treeDiff: (GitTreeObject*) prevTree;


@end
