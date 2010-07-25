//
//  GitFrontTree.m
//  gitfend
//
//  Created by Manuel Astudillo on 6/8/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitFrontBrowseTree.h"
#import "gitobject.h"
#import "gittreeobject.h"
#import "gitcommitobject.h"
#import "NSDataExtension.h"

@implementation GitFrontBrowseTreeLeaf

@synthesize status;
@synthesize nodeIcon;
@synthesize description;
@synthesize author;
@synthesize date;
@synthesize sha1;
@synthesize name;


@end


@implementation GitFrontBrowseTree

@synthesize objectStore;
@synthesize status;
@synthesize description;
@synthesize nodeIcon;
@synthesize name;
@synthesize commitSha1;

-(id) init
{
	if ( self = [super init] )
    {
		children = [[NSMutableArray alloc] init];
	}
	return self;
}

-(id) initWithCommit:(NSData*) commit objectStore:(GitObjectStore*) _objectStore
{
	if ( self = [super init] )
    {
		children = [[NSMutableArray alloc] init];
		
		[self setObjectStore:_objectStore];
		
		[self setCommitSha1:commit];
		
		GitObject *object = [objectStore getTreeFromCommit:commit];
		NSLog( [commit description] );

		if ( [object isKindOfClass:[GitTreeObject class]] )
		{
			GitTreeObject *treeObject =(GitTreeObject*) object;
			[self setDescription:@"ROOT"];
			
			NSDictionary *treeDict = [treeObject tree];
			
			for ( id key in treeDict )
			{
				id content = [[treeObject tree] objectForKey:key];
				[self addChildren:content key:key];
			}
		}
		else
		{
			[super dealloc];
			return nil;
		}
	}
	return self;
}



-(void) addChildren:(id) content key: (id) key
{
	GitObject *object = [[self objectStore] getObject:[content sha1]];
	
	if ( [object isKindOfClass:[GitTreeObject class]] )
	{
		GitTreeObject *treeObject = (GitTreeObject *) object;
		[self setDescription:key];
		
		GitFrontBrowseTree *node = [[[GitFrontBrowseTree alloc] init] autorelease];
		
		[node setName:key];
		
		
		NSArray *history = [[self objectStore] fileHistory:key fromCommit:commitSha1 maxItems:1];
		
		if ( [history count] > 0 )
		{
			[node setDescription:[[history objectAtIndex:0] message]];
		}
	
		[children addObject:node];
		
		for ( id key in [treeObject tree] )
		{
			id content = [[treeObject tree] objectForKey:key];
			[node addChildren:content key:key];
		}
	}
	else
	{
		GitFrontBrowseTreeLeaf *leaf = [[[GitFrontBrowseTreeLeaf alloc] init] autorelease];
		
		[leaf setName:key];
		
		NSArray *history = [[self objectStore] fileHistory:key fromCommit:commitSha1 maxItems:1];
		
		if ( [history count] > 0 )
		{
			[leaf setDescription:[[history objectAtIndex:0] message]];
		}
		
		[children addObject: leaf];
	}
}

-(NSArray*) children
{
	return children;
}

@end

