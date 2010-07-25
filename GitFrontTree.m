//
//  GitFrontTree.m
//  gitfend
//
//  Created by Manuel Astudillo on 6/8/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitFrontTree.h"
#import "NSDataExtension.h"

@implementation GitFrontTreeLeaf

@synthesize description;
@synthesize text;
@synthesize repo;
@synthesize sha1;


@end


@implementation GitFrontTree

@synthesize description;
@synthesize nodeIcon;
@synthesize repo;

-(id) init
{
	if ( self = [super init] )
    {
		children = [[NSMutableArray alloc] init];
	}
	return self;
}

-(id) initTreeWithRepo:(GitRepo*) _repo
{	
	if ( self = [super init] )
    {
		children = [[NSMutableArray alloc] init];
		
		NSDictionary *dict = [_repo refs];
		
		[self setDescription:[[_repo url] description]];
		[self setRepo:_repo];
		
		for (id key in dict) 
		{
			id content = [dict objectForKey:key];
			
			[self addChildren:content key:key];
		}
	}
	return self;
}

-(void) addChildren:(id) content key: (id) key
{
	if ( [content isKindOfClass:[NSDictionary class]] )
	{
		NSDictionary *dict = content;
		
		GitFrontTree *node = [[[GitFrontTree alloc] init] autorelease];
		
		[node setDescription:key];
		[node setRepo:[self repo]];

		[children addObject:node];

		for (id key in dict) 
		{
			id content = [dict objectForKey:key];
			
			[node addChildren: content key:key];
		}
	}
	else
	{
		GitFrontTreeLeaf *leaf = [[[GitFrontTreeLeaf alloc] init] autorelease];
		
		[leaf setDescription:key];
		[leaf setSha1:[NSData dataWithHexString:content]];
		[leaf setRepo:[self repo]];
		
		[children addObject: leaf];
	}
}

-(NSArray*) children
{
	return children;
}




@end
