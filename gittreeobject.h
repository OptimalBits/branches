//
//  gittreeobject.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitobject.h"

@interface GitTreeObject : GitObject {
	NSMutableDictionary *tree;
	
}

- (id) initWithData: (NSData*) data;

@end
