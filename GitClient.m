//
//  GitClient.m
//  gitfend
//
//  Created by Manuel Astudillo on 7/31/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitClient.h"


@implementation GitClient

@end


@implementation GitHttpClient

@synthesize url;

-(id) initWithUrl:(NSURL*) _url
{
	if (self = [super init])
	{
		[self setUrl:_url];

		NSURLRequest *request = 
			[NSURLRequest requestWithURL:url
							 cachePolicy:NSURLRequestUseProtocolCachePolicy
						 timeoutInterval:60.0];
		
		NSURLConnection *_connection = 
			[[NSURLConnection alloc] initWithRequest:request
											delegate:self];

		if (_connection)
		{
			receivedData = [[NSMutableData data] retain];
		} 
		else 
		{
			// Inform the user that the connection failed.
		}
	}
	return self;
}


-(BOOL) checkNewCommitsInBranch:(GitReference*) branch
{
	// Create a new object that just traverses commits in the server
	// until it finds the one given. 
	// Set a maximum depth in the traversing.
	// The walk should be a breadth first traversing, otherwise it could
	// happen that the traversing misses the given reference.
}

- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
	
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
	
    // receivedData is an instance variable declared elsewhere.
    [receivedData setLength:0];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
    // receivedData is declared as a method instance elsewhere
    [receivedData release];
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
	
    // release the connection, and the data object
    [connection release];
    [receivedData release];
}

@end


typedef enum
{
	kGettingObject,
	kGettingAlternates,
	
	
} WalkerStates;


/*
@implementation GitHttpCommitWalker

-(id) initWithUrl:(NSURL*) url startCommit:(NSData*) startSha1 
	 targetCommit:(NSData*) targetSha1;

{
	if (self = [super init])
	{
		[self setUrl:_url];
		
		[self getObject:startSha1];
		
	}
	return self;
}


-(void) getObject:(NSData*) sha1
{
	NSURLRequest *request = 
	[NSURLRequest requestWithURL:url
					 cachePolicy:NSURLRequestUseProtocolCachePolicy
				 timeoutInterval:60.0];
	
	NSURLConnection *_connection = 
	[[NSURLConnection alloc] initWithRequest:request
									delegate:self];
	
	if (_connection)
	{
		receivedData = [[NSMutableData data] retain];
	} 
	else 
	{
		// Inform the user that the connection failed.
	}
	
}


- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
	
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
	
    // receivedData is an instance variable declared elsewhere.
    [receivedData setLength:0];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
    // receivedData is declared as a method instance elsewhere
    [receivedData release];
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
	
    // release the connection, and the data object
    [connection release];
    [receivedData release];
}


@end

*/





