//
//  GitReference.h
//  gitfend
//
//  Created by Manuel Astudillo on 8/4/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitReferenceStorage;

@interface GitReference : NSObject {
	NSString *name;
	NSString *path;
	
	NSData   *sha1;
	NSString *symbolicReference; 
}

@property (readonly, retain) NSString* name;
@property (readonly, retain) NSString* path;
@property (readwrite, retain) NSData* sha1;
@property (readonly, retain) NSString* symbolicReference;


-(id) initWithName:(NSString *)refName;

-(id) initWithName:(NSString *)refName 
		   content:(NSString *)content;

-(id) initWithName:(NSString *)refName 
		   content:(NSString *)content 
			  path:(NSString*) path;


-(void) setSymbolicReference:(GitReference*) reference;

/**
	Resolves a reference and returns the resulting SHA1.
 
 */
-(NSData*) resolve:(GitReferenceStorage*) referenceStorage;


/**
	Returns the branch name associated to this reference.
 */
-(NSString*) branch; 


@end
