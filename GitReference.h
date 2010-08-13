//
//  GitReference.h
//  gitfend
//
//  Created by Manuel Astudillo on 8/4/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitRepo;

@interface GitReference : NSObject {
	NSString *content;
	NSString *name;
}

@property (readonly, retain) NSString* name;

-(id) initWithName:(NSString *)refName;
-(id) initWithName:(NSString *)refName content:(NSString *) content;


-(void) setSymbolicReference:(GitReference*) reference;

/**
	Resolves a reference and returns the resulting SHA1.
 
 */
-(NSData*) resolve:(GitRepo*) repo;

/**
	Returns the symbolic reference that this reference is pointing at.
 
	( or nil if its an inmediate SHA key ).
 */
-(NSString*) symbolicReference;


/**
	Returns the branch name associated to this reference.
 */
-(NSString*) branch; 


@end
