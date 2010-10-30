//
//  gitobject.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/20/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GitObject : NSObject {
	NSString *type;
}

//@property (readonly) NSStream *dataStream;
//@property (readwrite,assign) NSString *sha1;
//@property (readwrite,assign) NSURL *repo;

//- (id) writeObject: (NSStream*) stream;

-(id) initWithType:(NSString*) type;

/**
	Returns a serialized version of the object in a NSData object.
	Note: This method should be overrided by the subclass.
 */
-(NSData*) data;

/**
	Returns the sha1 key associated to this object.
	Note: This method usually will not be overrided. 
 */
-(NSData*) sha1;

/**
	Returns the encoded data according to git format for objects.
	Note: This method usually will not be overrided.
*/
-(NSData*) encode;

//-(NSData*) sha1WithContent:(NSData*) content;

@end
