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
	
	NSMutableDictionary *heads;		// example key,pair: refs/heads/master 08567abbeb383da4fae88f4e5a5beb6bd30ffee7
	NSMutableDictionary *remotes;
	NSMutableDictionary *tags;
	
	//GitConfig *config;	
}

- (id) initWithUrl: (NSURL*) path;
-(void) parseRefs: (NSURL*) root; // Parses refs and pack_refs


@end


