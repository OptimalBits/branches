//
//  gitrepo.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GitRepo : NSObject {
	NSString *description;
			
	//GitConfig *config;
	
	NSURL* url;
}

@property (retain) NSURL* url;
@property (readonly) NSMutableDictionary *refs;

- (id) initWithUrl: (NSURL*) path;
- (void) dealloc;
- (void) parseRefs; // Parses refs and pack_refs


@end


