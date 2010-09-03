//
//  GitBlobObject.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/29/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitobject.h"

@interface GitBlobObject : GitObject {
	NSData *content;
}

- (id) initWithData: (NSData*) data;
- (NSData*) data;

@end
