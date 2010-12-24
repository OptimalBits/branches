//
//  GitModificationDateResolver.m
//  gitfend
//
//  Created by Manuel Astudillo on 12/22/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitModificationDateResolver.h"
#import "GitObjectStore.h"

static void mergeDict( NSMutableDictionary *dst, 
					   NSDictionary *src, 
					   NSString *prefix );

@implementation GitModificationDateResolver


-(id) initWithObjectStore:(GitObjectStore*) _store 
			   commitSha1:(NSData*) _commitSha1
{
	if ( self = [super init] )
	{
		commitSha1 = _commitSha1;
		[commitSha1 retain];
		
		root = [_store getTreeFromCommit:commitSha1];
		[root retain];
		
		store = _store;
		[store retain];
		
		lastModificationDates = [[NSMutableDictionary alloc] init];
		
		NSDictionary *dict = [store lastModifiedTree:root
										  commitSha1:commitSha1
											   until:nil];
		
		mergeDict( lastModificationDates, dict, @"" );
	}
	return self;
}


-(void) dealloc
{
	[lastModificationDates release];
	[store release];
	[root release];
	[commitSha1 release];
	[super dealloc];
}

/**
 
 @param filename Filename relative the working directory.
 */
-(NSDate*) resolveDate:(NSString*) filename
{
	NSDate *date;
	
	date = [lastModificationDates objectForKey:filename];
	if ( date )
	{
		return date;
	}
	else
	{
		// Traverse tree to find the correct subtree containing the filename
		NSArray *components = [filename pathComponents];
		GitTreeObject *tree = root;
		GitTreeNode *node;
		
		NSString *path = @"";
		
		for ( NSString *component in components )
		{
			path = [path stringByAppendingPathComponent:component];
			
			node = [[tree tree] objectForKey:component];
			if ( ( node ) && ( [node mode] & kDirectory ) )
			{
				tree = [store getObject:[node sha1]];
				NSDictionary *dict = [store lastModifiedTree:tree
												  commitSha1:commitSha1
													until:nil];
				mergeDict( lastModificationDates, dict, path );
			}
			else
			{
				// Something went wrong...
			}
		}
		
		// TODO: Handle untracked files.
	}
	
	return nil;
}

@end

static void mergeDict( NSMutableDictionary *dst, 
					   NSDictionary *src, 
					   NSString *prefix )
{
	for ( NSString *key in src )
	{
		[dst setObject:[src objectForKey:key] 
				forKey:[prefix stringByAppendingPathComponent:key]];
	}
}

