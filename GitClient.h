//
//  GitClient.h
//  gitfend
//
//  Created by Manuel Astudillo on 7/31/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitrepo.h"
#import "GitReference.h"

/**
	Abstract class for git clients.

 
 */
@interface GitClient : NSObject {
	
	
	
}

-(id) init;
-(void) dealloc;

/**
	Return a dictionary with all the refs available in the server.
 */

-(id) refs;

/**
	Checks if there are new commits in the server for the given branch.
 
	returns TRUE if the check has started, or FALSE if for some reason
	it couldn't.
 
	The selector will be called with an array of commits.
 */
-(BOOL) checkNewCommitsInBranch:(GitReference*) branch;

@end


@interface GitHttpClient : GitClient
{
	NSURL  *url;
	NSData *receivedData;
}

@property (readwrite, retain) NSURL *url;

-(id) initWithUrl:(NSURL*) url;

-(NSArray*) newCommitsInBranch:(GitReference*) branch;

@end



/**
 This object will traverse the 
 
 */

@interface GitHttpCommitWalker : NSObject
{
	
}

-(id) initWithUrl:(NSURL*) url startCommit:(NSData*) startSha1 
							  targetCommit:(NSData*) targetSha1;



@end






