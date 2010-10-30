//
//  GitReferenceStorage.m
//  GitLib
//
//  Created by Manuel Astudillo on 10/18/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitReferenceStorage.h"
#import "GitReference.h"
#import "NSDataExtension.h"

@interface GitReferenceStorage (Private)

- (void) parsePackedRefs:(NSURL*) path;
- (void) parseLooseRefs:(NSURL*) path;
- (void) parseHead:(NSURL*) path;

-(GitReference*) reference:(NSString*) refName;

@end

@implementation GitReferenceStorage

@synthesize head;

-(id) initWithUrl:(NSURL *)_url
{
	if ( self = [super init] )
	{
		[_url retain];
		url = _url;
		
		refs = [[NSMutableDictionary alloc] init];
		
		[self parsePackedRefs:url];
		[self parseLooseRefs:url];
		[self parseHead:url];
	}
	return self;
}

-(void) dealloc
{
	[url release];
	[refs release];
	[super dealloc];
}


-(NSDictionary*) refsDict
{
	return refs;
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
 										  content:headRef
											 path:@"HEAD"];
		
		NSLog(@"HEAD: %@",  [head resolve:self]);
		NSLog(@"HEAD -> %@", [head symbolicReference]);
	}
}


-(void) parsePackedRefs:(NSURL*) path
{
	NSError *error;
	NSURL *packedRefsPath;
	
	packedRefsPath = [path URLByAppendingPathComponent:@"packed-refs"];
	if ([packedRefsPath checkResourceIsReachableAndReturnError:&error] == YES)
	{
		NSString *packedRefs;
		NSStringEncoding encoding;
		
		packedRefs = [NSString stringWithContentsOfURL:packedRefsPath 
										  usedEncoding:&encoding 
												 error:&error];
		
		NSArray *lines = [packedRefs componentsSeparatedByCharactersInSet:
							[NSCharacterSet newlineCharacterSet]];

		// TODO: Improve parsing using regexps.
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
						[[lineElements objectAtIndex:1] componentsSeparatedByString:@"/"];
					
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
	
	NSLog([dir path], nil);
	
	NSArray *urls = 
	[fileManager contentsOfDirectoryAtURL:dir 
			   includingPropertiesForKeys:nil 
								  options:NSDirectoryEnumerationSkipsHiddenFiles 
									error:error];
	for(NSURL *u in urls)
	{
		GitReference *ref;
		NSString *component;
		
		NSLog([u path], nil);
		
		NSMutableDictionary *nextDict;
		
		component = [u lastPathComponent];
		
		NSString *sha1 = [NSString stringWithContentsOfURL:u 
											  usedEncoding:&encoding 
													 error:error];
		
		if ( sha1 )
		{			
			ref = [[[GitReference alloc] initWithName:component 
											  content:sha1
												 path:[u path]] autorelease];
			
			
			[dict setObject:ref forKey:component];
		}
		else
		{
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
}

-(void) parseLooseRefs:(NSURL*) path
{
	NSError *error;
	NSFileManager *fileManager;
	NSURL *refsPath;
	
	fileManager = [NSFileManager defaultManager];
	
	refsPath = [path URLByAppendingPathComponent:@"refs"];
	if ([refsPath checkResourceIsReachableAndReturnError:&error] == YES)
	{
		[self parseLooseRefsInDir:refsPath
							 dict:refs
					  fileManager:fileManager
							error:&error];
	}
}

-(NSData*) resolveReference:(NSString*) refName
{
	GitReference *ref;
	GitReference *prevRef;
	
	ref = [self reference:refName];
	
	while ( [ref symbolicReference] ) 
	{
		prevRef = ref;
		if ( ref )
		{
			refName = [ref name];
		}
		else
		{
			ref = prevRef;
			break;
		}
	}
		
	return [ref sha1];
}

-(GitReference*) reference:(NSString*) refName
{
	NSUInteger componentCount;
	NSArray *pathComponents = [refName pathComponents];
	
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
					return obj;
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

-(NSData*) resolveToSha1:(GitReference*) ref
{	
	ref = [self resolveToReference:ref];
	
	return [ref sha1];
}

-(NSString*) resolveToPath:(GitReference*) ref
{
	ref = [self resolveToReference:ref];
	
	return [ref path];
}

-(GitReference*) resolveToReference:(GitReference*) ref
{
	NSString *symbolicReference;
	
	symbolicReference = [ref symbolicReference];
	
	if ( symbolicReference )
	{
		return 	[self reference: symbolicReference];
	}
	
	return ref;
}


-(void) setReference:(GitReference*) ref sha1:(NSData*) sha1;
{
	GitReference *resolvedRef = [self resolveToReference:ref];
	
	if ( resolvedRef == nil )
	{
		NSError *error;
		NSString *path;
		
		path = [ref symbolicReference];
		
		// HACK, we should just write in the dictonary not to a file!.
		NSString *sha1String = [NSString stringWithFormat:@"%@\n",
								[[ref sha1] base16String]];
		
		[sha1String writeToURL:[url URLByAppendingPathComponent:path] 
					atomically:YES
					  encoding:NSUTF8StringEncoding
						 error:&error];
		
		[self parseLooseRefs:url];
	}
	else
	{
		[resolvedRef setSha1:sha1];
	}
}

-(void) updateReference:(GitReference*) ref
{
	ref = [self resolveToReference:ref];
	
	if ( [ref path] )
	{
		NSError *error;
		NSString *sha1String = [NSString stringWithFormat:@"%@\n",
							   [[ref sha1] base16String]];
		
		if ( [sha1String writeToFile:[ref path]
						  atomically:YES 
							encoding:NSUTF8StringEncoding 
							   error:&error] == NO )
		{
			NSLog([error localizedDescription], nil);
		}
	}
}


@end
