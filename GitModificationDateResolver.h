//
//  GitModificationDateResolver.h
//  gitfend
//
//  Created by Manuel Astudillo on 12/22/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitTreeObject, GitObjectStore;

/**
	Helper object used to lazily resolve last modification dates for files
	in a working directory.
 
	Resolve data can be time consuming, and should therefore be executed as
	an NSOperation.
 
 */
@interface GitModificationDateResolver : NSObject {
	GitObjectStore *store;
	GitTreeObject *root;
	
	NSData *commitSha1;
	
	NSMutableDictionary *lastModificationDates;
}

-(id) initWithObjectStore:(GitObjectStore*) _store 
			   commitSha1:(NSData*) _commitSha1;

-(void) dealloc;

/**
 
	@param filename Filename relative the working directory.
 */
-(NSDate*) resolveDate:(NSString*) filename;

@end



