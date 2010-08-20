//
//  GitFrontTree.m
//  gitfend
//
//  Created by Manuel Astudillo on 6/8/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitFrontTree.h"
#import "GitReference.h"
#import "NSDataExtension.h"

@implementation GitFrontTreeLeaf

@synthesize name;
@synthesize text;
@synthesize sha1;
@synthesize icon;
@synthesize repo;

@end


@implementation GitFrontTree

@synthesize name;
@synthesize icon;
@synthesize repo;

-(id) init
{
	return [self initTreeWithRepo:nil icons: nil];
}

-(id) initTreeWithIcons:(NSDictionary*) icons
{
	return [self initTreeWithRepo:nil icons: icons];
}

-(id) initTreeWithRepo:(GitRepo*) _repo icons:(NSDictionary*) icons
{	
	if ( self = [super init] )
    {
		children = [[NSMutableArray alloc] init];
		
		if ( icons != nil )
		{
			iconsDict = icons;
		}
		
		if ( _repo != nil )
		{
			[self setRepo:_repo];
						
			NSDictionary *dict = [repo refs];
			
			[self setName:[repo name]];
			
			[self setIcon:[iconsDict objectForKey:@"git"]];
			
			[self addLeaf:[repo head] key:@"HEAD"];
			
			NSArray *keyArray = 
				[[dict allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
			for (id key in keyArray) 
			{
				id content = [dict objectForKey:key];
			
				[self addChildren:content key:key];
			}
		}
	}
	return self;
}

-(void) addChildren:(id) content key: (id) key
{
	if ( [content isKindOfClass:[NSDictionary class]] )
	{
		NSDictionary *dict = content;
		
		GitFrontTree *node = 
			[[[GitFrontTree alloc] initTreeWithIcons:iconsDict] autorelease];
		
		if ( [key isEqualToString:@"heads"] )
		{
			[node setName:@"Branches"];
			[node setIcon:[iconsDict objectForKey:@"branch"]];
		}
		else if ( [key isEqualToString:@"remotes"] )
		{
			[node setName:@"Remotes"];
			[node setIcon:[iconsDict objectForKey:@"remote"]];			
		}
		else if ( [key isEqualToString:@"tags"] )
		{
			[node setName:@"Tags"];
			[node setIcon:[iconsDict objectForKey:@"tags"]];
		}
		else if ( [key isEqualToString:@"stash"] )
		{
			[node setName:@"Stash"];
			[node setIcon:[iconsDict objectForKey:@"stash"]];
		}
		else
		{
			[node setName:key];
//			[node setIcon:[iconsDict objectForKey:@"git"]];
		}

		[node setRepo:[self repo]];
		[children addObject:node];

		NSArray *keyArray = 
			[[dict allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		for (id key in keyArray) 
		{
			id content = [dict objectForKey:key];
			
			[node addChildren: content key:key];
		}
	}
	else if ([content isKindOfClass:[GitReference class]] )
	{
		[self addLeaf:content key: key];
	}
}


-(void) addLeaf:(id) content key:(id) key
{
	GitFrontTreeLeaf *leaf = [[[GitFrontTreeLeaf alloc] init] autorelease];

	[leaf setName:key];
	[leaf setSha1:[content resolve:repo]];
	[leaf setRepo:[self repo]];

	if ( [key isEqualToString:@"stash"] )
	{
		[leaf setName:@"Stash"];
		[leaf setIcon:[iconsDict objectForKey:@"stash"]];
	}
	else if ( [key isEqualToString:@"HEAD"] )
	{
		NSString *branchName = [[repo head] branch];
		NSString *head = [NSString stringWithFormat:@"%@", branchName];
		
		[leaf setName:head];
		[leaf setIcon:[iconsDict objectForKey:@"head"]];
	}
	else
	{
		[leaf setIcon:[iconsDict objectForKey:@"folder"]];
	}

	[children addObject: leaf];
}


-(NSArray*) children
{
	return children;
}

@end


