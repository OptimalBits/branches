//
//  gitfendRepositories.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/15/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitFrontRepositories.h"
#import "GitRepo.h"
#import "GitFrontTree.h"
#import "GitFrontIcons.h"
#import "NSDataExtension.h"



@implementation GitFrontRepositoriesLeaf
	
@synthesize repo;
@synthesize name;
@synthesize tree;

-(id) initWithRepo:(GitRepo*) _repo
{
	if ( self = [super init] )
	{
		[_repo retain];
		repo = _repo;
		name = [[repo name] retain];
		
		tree = [[GitFrontTree alloc] initTreeWithRepo:repo 
												icons:[GitFrontIcons icons]];
	}
	return self;
}

-(void) dealloc
{
	[repo release];
	[name release];
	[super dealloc];
}

- (NSImage*) icon
{
	return [[GitFrontIcons icons] objectForKey:@"git"];
}

- (void) encodeWithCoder: (NSCoder *)coder
{
	[coder encodeObject: name forKey:@"name"];
	[coder encodeObject: [repo workingDir] forKey:@"repoUrl"];
}

- (id) initWithCoder: (NSCoder *)coder
{
	if (self = [super init])
	{
		name = [[coder decodeObjectForKey:@"name"] retain];
		repo = [[GitRepo alloc] initWithUrl:[coder decodeObjectForKey:@"repoUrl"] 
								   name:name];
		tree = [[GitFrontTree alloc] initTreeWithRepo:repo 
												icons:[GitFrontIcons icons]];
	}
	return self;
}		


@end


@implementation GitFrontRepositories

@synthesize name;
@synthesize children;

- (id) initWithName:(NSString*) _name
{	
    if ( self = [super init] )
    {
		[self setName:_name];
		children = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
	[children release];
	[super dealloc];
}

- (void) addRepo:(GitRepo*) repo 
{
	[children addObject:[[GitFrontRepositoriesLeaf alloc] initWithRepo: repo]];
}

- (void) insertRepo:(GitRepo*) repo atIndex:(NSUInteger) index
{
	[children insertObject:[[GitFrontRepositoriesLeaf alloc] initWithRepo: repo]
				   atIndex:index];
}

- (id) addGroup:(NSString*) groupName
{
	GitFrontRepositories *node = 
	[[GitFrontRepositories alloc] initWithName:groupName];
	
	[children addObject:node];
	
	return node;
}

- (id) insertGroup:(NSString*) groupName atIndex:(NSUInteger) index
{
	GitFrontRepositories *node = 
		[[GitFrontRepositories alloc] initWithName:groupName];
	
	[children insertObject:node
				   atIndex:index];
	
	return node;
}

- (void) insertNode:(id) node atIndex:(NSUInteger) index
{
	[children insertObject:node atIndex:index];
}

- (void) addNode:(id) node
{
	[children addObject:node];
}



- (NSUInteger) indexOfChild:(id) item
{
	NSUInteger index;
	
	index = [children indexOfObject:item];
	if ( index == NSNotFound )
	{
		index = 0;
		for ( id c in children )
		{
			if ( [c isKindOfClass:[GitFrontRepositoriesLeaf class]] && 
				 [c tree] == item )
			{
				return index;
			}
			index ++;
		}
	}
	else 
	{
		return index;
	}

	return NSNotFound;
}

- (NSImage*) icon
{
	return [[GitFrontIcons icons] objectForKey:@"folderStack"];
}

- (void) encodeWithCoder: (NSCoder *)coder
{
	[coder encodeObject: name forKey:@"name"];
	[coder encodeObject: children forKey:@"children"];	
}

- (id) initWithCoder: (NSCoder *)coder
{
	if (self = [super init])
	{
		name = [[coder decodeObjectForKey:@"name"] retain];
		children = [[coder decodeObjectForKey:@"children"] retain];
	}
	return self;
}		

@end
