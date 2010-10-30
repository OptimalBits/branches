//
//  GitFile.h
//  GitLib
//
//  Created by Manuel Astudillo on 8/9/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
	kFileStatusUpdated		= 1,
	kFileStatusAdded		= 2,
	kFileStatusRemoved		= 4,
	kFileStatusRenamed		= 8,
	kFileStatusModified		= 16,
	kFileStatusStaged		= 32,
	kFileStatusTracked		= 64,
	kFileStatusUntracked	= 128
} GitFileStatus;

@interface GitFile : NSObject {
	
	GitFileStatus status;
	NSString *filename;
}

@property (readwrite, assign) GitFileStatus status;
@property (readwrite, copy) NSString *filename;

-(id) initWithName:(NSString*) filename andStatus:(GitFileStatus) status;
-(void) dealloc;

@end
