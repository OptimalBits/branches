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
	kFileStatusUpdated,
	kFileStatusAdded,
	kFileStatusRemoved,
	kFileStatusRenamed,
	kFileStatusModified,
	kFileStatusStaged,
	kFileStatusTracked,
	kFileStatusUntracked
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
