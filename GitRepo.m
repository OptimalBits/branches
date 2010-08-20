//
//  gitrepo.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/8/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gitrepo.h"
#import "gitobject.h"
#import "gitcommitobject.h"
#import "GitReference.h"
#import "GitIndex.h"
#import "NSDataExtension.h"


@implementation GitHistoryVisitor

@synthesize history;

-(id) init
{
	if ( self = [super init] )
	{
		history = [[NSMutableArray alloc] init];
	}
	return self;
}

-(BOOL) visit:(GitObject *)object
{
	[history addObject: object];
	
	//NSLog( [[[object author  ]time] description] );
	return YES;
}

-(void) dealloc
{
	[history release];
	[super dealloc];
}

@end


@interface GitRepo ()

- (void) parseRefs;
- (void) parseHead:(NSURL*) path;

@end


@implementation GitRepo

@synthesize name;
@synthesize url;
@synthesize workingDir;
@synthesize head;
@synthesize refs;
@synthesize objectStore;
@synthesize index;

+ (BOOL) isValidRepo:(NSURL*) workingDir
{
	NSError *error;
	
	NSURL *repoDir = [workingDir URLByAppendingPathComponent:@".git"];
	
	if ([repoDir checkResourceIsReachableAndReturnError:&error] == YES)
	{
		// TODO: make some sanity checks
	
		return YES;
	}
	else
	{
		return NO;
	}
}

- (id) initWithUrl: (NSURL*) _workingDir name:(NSString*) _name
{	
    if ( self = [super init] )
    {	
		[_workingDir retain];
		workingDir = _workingDir;
		
		url = [[workingDir URLByAppendingPathComponent:@".git"] retain];
		
		if ( _name != nil )
		{
			[self setName:_name];
		}
		else
		{
			NSArray *urlComponents = [url pathComponents];
			
			[self setName:
			 [urlComponents objectAtIndex:[urlComponents count]-2]];
		}
		
		refs = [[NSMutableDictionary alloc] init];
		
		objectStore = [[GitObjectStore alloc] initWithUrl: url];
		
		[self parseRefs];
		
		[self parseHead:url];
		
		index = [[GitIndex alloc] initWithUrl: 
				 [url URLByAppendingPathComponent:@"index"]];
	}
    return self;
}

-(void) dealloc
{	
	[refs release];
	[url release];
	[super dealloc];
}

- (void) encodeWithCoder: (NSCoder *)coder
{
	[coder encodeObject: workingDir forKey:@"repo_url"];
	[coder encodeObject: name forKey:@"repo_name"];
}

- (id) initWithCoder: (NSCoder *)coder
{
	return [self initWithUrl:[coder decodeObjectForKey:@"repo_url"]
						name:[coder decodeObjectForKey:@"repo_name"]];
}

- (id) getObject:(NSData*) sha1
{	
	return [objectStore getObject:sha1];
}


-(NSData*) resolveReference:(NSString*) refName
{
	NSUInteger componentCount;
	NSURL *uRefName = [NSURL URLWithString:refName];
	NSArray *pathComponents = [uRefName pathComponents];
	
	componentCount = [pathComponents count];
	
	if ( componentCount >= 3 )
	{
		if ( [[pathComponents objectAtIndex:0] isEqualToString: @"refs"] )
		{
			NSDictionary *dict = refs;
			NSUInteger componentIndex = 1;
			
			while ( componentIndex < componentCount )
			{
				id obj = [dict objectForKey:
							[pathComponents objectAtIndex:componentIndex]];
				if ( [obj isKindOfClass:[GitReference class]] )
				{
					GitReference *ref = obj;
					return [ref resolve:self];
				}
				else if ( [obj isKindOfClass:[NSMutableDictionary class]] )
				{
					dict = obj;
				}
				else
				{
					NSLog(@"Error resolving reference %@", refName);
				
					for ( id o in dict )
					{
						NSLog(@"Object: %@ ", [o description] );
					}
				}
				
				componentIndex++;
			}
		}
	}
	
	return nil;
}


// Private methods.

-(void) parsePackedRefs
{
	NSError *error;
	NSURL *packedRefsPath;
	
	packedRefsPath = [url URLByAppendingPathComponent:@"packed-refs"];
	if ([packedRefsPath checkResourceIsReachableAndReturnError:&error] == YES)
	{
		NSString *packedRefs;
		NSStringEncoding encoding;
		
		packedRefs = [NSString stringWithContentsOfURL:packedRefsPath 
										  usedEncoding:&encoding 
												 error:&error];
		
		NSArray *lines = [packedRefs componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		for(NSString *line in lines)
		{
			NSArray *lineElements = [line componentsSeparatedByString:@" "];
			
			if ( [lineElements count] >= 2 )
			{
				NSString *sha1 = [lineElements objectAtIndex:0];
				
				if ( [sha1 length] == 40 )
				{
					GitReference *ref;
					NSArray *refComponents = 
						[[lineElements objectAtIndex:1] 
							componentsSeparatedByString:@"/"];
					
					NSUInteger componentsCount;
					NSUInteger componentsIndex;
					
					NSMutableDictionary *dict = refs;
					
					componentsCount = [refComponents count];
					componentsIndex = 1;
					
					while ( componentsIndex < ( componentsCount - 1 ) )
					{
						NSMutableDictionary *nextDict;
						
						NSString *component = 
						[refComponents objectAtIndex:componentsIndex];
						
						nextDict = [dict objectForKey:component];
						if ( nextDict == nil )
						{
							nextDict = [[[NSMutableDictionary alloc] init] autorelease];
							[dict setObject:nextDict forKey:component];
						}
						
						dict = nextDict;
						componentsIndex ++;
					}
					
					NSString *refName = 
					[refComponents objectAtIndex:componentsIndex];
					ref = [[[GitReference alloc] initWithName:refName
													  content:sha1] autorelease];
					
					[dict setObject:ref forKey:refName];
				}
			}
		}
	}
}

-(void) parseLooseRefsInDir:(NSURL*) dir 
					   dict:(NSMutableDictionary*) dict
				fileManager:(NSFileManager*) fileManager
					  error:(NSError**) error
{
	
	NSStringEncoding encoding;
	
	NSArray *urls = 
	[fileManager contentsOfDirectoryAtURL:dir 
			   includingPropertiesForKeys:nil 
								  options:NSDirectoryEnumerationSkipsHiddenFiles 
									error:error];
	for(NSURL *u in urls)
	{
		GitReference *ref;
		NSString *component;
		
		NSMutableDictionary *nextDict;
		
		component = [u lastPathComponent];
		
		NSString *sha1 = [NSString stringWithContentsOfURL:u 
											  usedEncoding:&encoding 
													 error:error];
		
		if ( sha1 != nil ) // Otherwise we hare handling a directory.
		{			
			ref = [[[GitReference alloc] initWithName:component 
											  content:sha1] autorelease];
			
			
			[dict setObject:ref forKey:component];
		}
		
		nextDict = [dict objectForKey:component];
		if ( nextDict == nil )
		{
			nextDict = [[[NSMutableDictionary alloc] init] autorelease];
			[dict setObject:nextDict forKey:component];
		}
		
		[self parseLooseRefsInDir:u 
							 dict:nextDict 
					  fileManager:fileManager
							error:error];
	}
}

-(void) parseLooseRefs
{
	NSError *error;
	NSFileManager *fileManager;
	NSURL *refsPath;
	
	fileManager = [NSFileManager defaultManager];
	
	refsPath = [url URLByAppendingPathComponent:@"refs"];
	if ([refsPath checkResourceIsReachableAndReturnError:&error] == YES)
	{
		[self parseLooseRefsInDir:refsPath
							 dict:refs
					  fileManager:fileManager
							error:&error];
	}
}

- (void) parseRefs
{
	[self parsePackedRefs];
	[self parseLooseRefs];
}

- (void) parseHead:(NSURL*) path
{
	NSStringEncoding encoding;
	NSError *error;
	
	NSURL *headPath = [path URLByAppendingPathComponent:@"HEAD"];
	
	NSString *headRef = [NSString stringWithContentsOfURL:headPath 
											 usedEncoding:&encoding 
													error:&error];
	if ( headRef )
	{
		head = [[GitReference alloc] initWithName:@"HEAD"
 										  content:headRef];
		NSLog(@"HEAD: %@", [head resolve:self]);
		NSLog(@"HEAD -> %@", [head symbolicReference]);
	}
}

- (NSArray*) revisionHistoryFor:(NSData*) sha1
{
	GitHistoryVisitor *historyVisitor = [[GitHistoryVisitor alloc] init];
	[historyVisitor autorelease];
	
	[objectStore walk:sha1 with:historyVisitor];
	
	return [historyVisitor history];
}


@end





