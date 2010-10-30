//
//  GitReferenceStorage.h
//  gitfend
//
//  Created by Manuel Astudillo on 10/18/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitReference;

@interface GitReferenceStorage : NSObject {

	NSURL *url;
	GitReference *head;
	NSMutableDictionary *refs; // ( name, GitReference )
}

@property (readonly) GitReference *head;


- (id) initWithUrl: (NSURL*) url;

/**
	Returns a dictionary with all the references.
 
 */
-(NSDictionary*) refsDict;


/**
	Resolves a reference returning the SHA1 key that the reference is 
    pointing to.
 
 */
-(NSData*) resolveReference:(NSString*) refName;

/**
	Sets a sha1 associated to this reference.
 
	If the reference is a symbolic reference, the sha1 is associated
	to the resulting reference after resolution.
 
 */
-(void) setReference:(GitReference*) ref sha1:(NSData*) sha1;

/**
	Update reference.
 
	Updates the reference stored in disk.
 
	Note: This function is currently not concurrency safe.
 */
-(void) updateReference:(GitReference*) ref;

-(GitReference*) resolveToReference:(GitReference*) ref;

-(NSData*) resolveToSha1:(GitReference*) ref;

-(NSString*) resolveToPath:(GitReference*) ref;




@end
