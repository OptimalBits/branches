//
//  GitFile.h
//  GitLib
//
//  Created by Manuel Astudillo on 8/9/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitTreeObject;

typedef enum
{
	kFileStatusUnknown		= 0,
	kFileStatusUpdated		= 1,
	kFileStatusAdded		= 2,
	kFileStatusRemoved		= 4,
	kFileStatusRenamed		= 8,
	kFileStatusModified		= 16,
	kFileStatusStaged		= 32,
	kFileStatusTracked		= 64,
	kFileStatusUntracked	= 128,
	kFileStatusMissing		= 256
} GitFileStatus;

@interface GitFile : NSObject {
	
	GitFileStatus status;
	NSURL		  *url;
	NSString	  *filename;
	uint32_t	  mode;
	GitTreeObject *tree;
}

@property (readwrite, assign)	GitFileStatus status;
@property (readwrite, copy)		NSString *filename;
@property (readwrite, copy)		NSURL *url;
@property (readonly)			uint32_t mode;

-(id) initWithUrl:(NSURL*) url 
		   status:(GitFileStatus) status 
		  andMode:(uint32_t) mode;

-(id) initWithUrl:(NSURL*) url andStatus:(GitFileStatus) status;
-(id) initWithUrl:(NSURL*) url;
-(id) initWithName:(NSString*) filename andStatus:(GitFileStatus) status;

-(void) updateMode;

-(void) dealloc;

@end
