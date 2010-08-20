//
//  gitobject.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GitObject : NSObject {

}

//@property (readonly) NSStream *dataStream;
//@property (readwrite,assign) NSString *sha1;
//@property (readwrite,assign) NSURL *repo;

//- (id) writeObject: (NSStream*) stream;

/**
	Returns a serialized version of the object in a NSData object.
 */
-(NSData*) data;

/**
	Returns the sha1 key associated to this object.
 */
-(NSData*) sha1;

@end
