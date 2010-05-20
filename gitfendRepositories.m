//
//  gitfendRepositories.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "gitfendRepositories.h"
#import "gitrepo.h"


@implementation gitfendRepositories

- (id) init
{	
    if ( self = [super init] )
    {
		repositories = [[NSMutableArray alloc] init];
		
		GitRepo *repo;
		
		repo = [[GitRepo alloc] initWithUrl:[NSURL fileURLWithPath:@"/Users/manuel/dev/gitfend/.git" isDirectory:YES]];
		
		[self addRepo:repo];
	}
    return self;
}

-(void) dealloc
{
	[repositories dealloc];
	[super dealloc];
}

- (void) addRepo:(GitRepo *) repo
{
	[repositories addObject:repo];
}

///////

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if ( item == nil ) // return parent
	{
		return self;
	}
	else if ( item == self )
	{
		return [repositories objectAtIndex:index];
	}
	else if ([item isKindOfClass:[GitRepo class]])
	{
		NSMutableDictionary *refsDict = [item refs];
		
		return [refsDict objectForKey:[[refsDict allKeys] objectAtIndex:index]];
	}
	else if ([item isKindOfClass:[NSDictionary class]])
	{
		return [item objectForKey:[[item allKeys] objectAtIndex:index]];
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if ([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSDictionary class]])
    {
        if ([item count] > 0)
		{
            return YES;
		}
    }
	else if ( item == self )
	{
		if ([repositories count] > 0)
		{
			return YES;
		}
	}
	else if ( [item isKindOfClass:[GitRepo class]] )
	{
		if ( [[item refs] count] > 0 )
		{
			return YES;
		}
	}
    
	return NO;	
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if ( item == nil )
	{
		return 1;// we may have other things than repos in the future. [repositories count];
	}
	else if ( item == self )
	{
		return [repositories count];
	}
	else if ([item isKindOfClass:[NSDictionary class]])
	{
		return [item count];
	}
	else if ([item isKindOfClass:[GitRepo class]])
	{
		return [[item refs] count];
	}
	else
	{
		return 0;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	// NSOutlineView calls this for each column in your NSOutlineView, for each item.
	// You need to work out what you want displayed in each column; in our case we
	// create in Interface Builder two columns, one called "Key" and the other "Value".
	// 
	// If the NSOutlineView is after the key for an item, we use either the NSDictionary
	// key for that item, or we count from 0 for NSArrays. 
	//
	// Note that you can find the parent of a given item using [outlineView parentForItem:item];
			
	if ([[[tableColumn headerCell] stringValue] compare:@"Main"] == NSOrderedSame) 
	{
		// Return the key for this item. First, get the parent array or dictionary.
		// If the parent is nil, then that must be root, so we'll get the root
		// dictionary.
		
		if ([item isKindOfClass:[gitfendRepositories class]]) 
		{
			return @"REPOSITORIES";
		}
		else if ([item isKindOfClass:[GitRepo class]]) 
		{
			NSURL *url = [item url];
			return [url path];
		} 
		else if ([item isKindOfClass:[NSDictionary class]])
		{
			id parentObject = [outlineView parentForItem:item] ? [outlineView parentForItem:item] : self;
			if ([parentObject isKindOfClass:[NSDictionary class]]) 
			{
				// Dictionaries have keys, so we can return the key name. We'll assume
				// here that keys/objects have a one to one relationship.
				
				return [[parentObject allKeysForObject:item] objectAtIndex:0];
			}
			else if ([parentObject isKindOfClass:[GitRepo class]]) 
			{
				return [[[parentObject refs] allKeysForObject:item] objectAtIndex:0];
			} 
			else if ([parentObject isKindOfClass:[NSArray class]]) 
			{
				// Arrays don't have keys (usually), so we have to use a name
				// based on the index of the object.
				
				return [NSString stringWithFormat:@"Item %d", [parentObject indexOfObject:item]];
			}
		}
		else if ([item isKindOfClass:[NSString class]]) 
		{
			return item;
		}
			
		/*
		id parentObject = [outlineView parentForItem:item] ? [outlineView parentForItem:item] : self;
				
		if ([parentObject isKindOfClass:[NSDictionary class]]) 
		{
			// Dictionaries have keys, so we can return the key name. We'll assume
			// here that keys/objects have a one to one relationship.
					
			return [[parentObject allKeysForObject:item] objectAtIndex:0];
		} 
		else if ([parentObject isKindOfClass:[NSArray class]]) 
		{
			// Arrays don't have keys (usually), so we have to use a name
			// based on the index of the object.
					
			return [NSString stringWithFormat:@"Item %d", [parentObject indexOfObject:item]];
		}
		else if ([parentObject isKindOfClass:[gitfendRepositories class]]) 
		{
			return [[item url] path];
		}
		 */
	} 
		
	return nil;
}
			
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	// pass
}

			

@end
