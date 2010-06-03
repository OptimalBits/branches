//
//  gitrepo.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "gitpackfile.h"

typedef char Sha1[40];


@interface GitRepo : NSObject {
	
	
}

@property (retain) NSURL* url;
@property (readonly) NSMutableDictionary *refs;

//@property (readonly) NSString *description;
//@property (readonly) GitObject *head;
//@property (readonly) GitConfig *config;

- (id) initWithUrl: (NSURL*) path;
- (void) dealloc;

// (void) createHead:
// (void) createTag:
// (void) createRemote:
/// ...

//- (GitCommit*) commit:(Sha1) sha1;

- (NSArray*) revisionHistoryFor:(NSData*) sha1 withPackFile: (GitPackFile*) packFile;


// Private func.
- (void) parseRefs; // Parses refs and pack_refs


@end


