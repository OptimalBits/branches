//
//  GitIgnore.h
//  gitfend
//
//  Created by Manuel Astudillo on 11/29/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitFile;

/**
	Represents a .gitignore file.
 
	It handles parsing and writing.
 
    Note: 
	.gitignore files are meant to be edited by hand, so over-writting
	them with this class will remove comments and empty lines.
 */
@interface GitIgnore : NSObject {
	NSMutableArray *patterns; /// Array of patterns.
	
	NSMutableArray *stack;/// Stack of GitIgnore objects.
	
	NSURL *url;		/// Complete url to .gitignore file
	NSString *path; /// Path to the directory where the .gitignore file is.
}


/**
	Initializes a GitIgnore object.
 
	This function parses the given .gitignore file and creates a list of 
	patterns.
 
	@param url The absolute path name to a .gitignore file
 
 */
-(id) initWithUrl:(NSURL*) url;
-(void) dealloc;

/**
	Tells if a file should be ignored or not.
 */
-(BOOL) isFileIgnored:(NSString*) filename isDirectory:(BOOL) isDirectory;


-(BOOL) shouldIgnoreFile:(GitFile*) filename isDirectory:(BOOL) isDirectory;

/**
	Pushes a GitIgnore so that its patterns will override the ones 
	defined by the receiver.
 */
-(void) push:(GitIgnore*) gitIgnore;


/**
	Pops previously pushed GitIgnore objects.
	If called and no pushed objects exists, the function will be equivalent to
    a release of the receiver object.
 
 */
-(void) pop;



@end


