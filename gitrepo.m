//
//  gitrepo.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/8/10.
//  Copyright 2010 FlipZap. All rights reserved.
//

#import "gitrepo.h"

@implementation GitRepo

@synthesize url;
@synthesize refs;

- (id) initWithUrl: (NSURL*) path
{	
    if ( self = [super init] )
    {		
		[path retain];
		url = path;
		
		refs = [[NSMutableDictionary alloc] init];

		[self parseRefs];
	}
    return self;
}

-(void) dealloc
{	
	[refs dealloc];
	[url release];
	[super dealloc];
}


- (void) parseRefs
{
	NSError *error;
	NSFileManager *fileManager;
	NSURL *packedRefsPath;
	NSURL *refsPath;
	
	//
	// Parse packed refs
	//
	
	packedRefsPath = [url URLByAppendingPathComponent:@"packed-refs"];
	if ([packedRefsPath checkResourceIsReachableAndReturnError:&error] == YES)
	{
		NSString *packedRefs;
		NSStringEncoding encoding;
		
		packedRefs = [NSString stringWithContentsOfURL:packedRefsPath usedEncoding:&encoding error:&error];
		
		NSArray *lines = [packedRefs componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		for(NSString *line in lines)
		{
			NSArray *lineElements = [line componentsSeparatedByString:@" "];
			
			NSString *sha1 = [lineElements objectAtIndex:0];
			
			if ( [lineElements count] >= 2 )
			{
				NSArray *ref = [[lineElements objectAtIndex:1] componentsSeparatedByString:@"/"];
				
				if ([ref count] > 2 )
				{
					NSString *refType = [ref objectAtIndex:1];
					NSMutableDictionary *dict = [refs objectForKey:refType];
					if ( dict == nil )
					{
						dict = [[NSMutableDictionary alloc] init];
						[refs setValue:dict forKey:refType];
					}
					
					if ( [refType isEqualToString:@"heads"] || 
						 [refType isEqualToString:@"tags"] ||
						 [refType isEqualToString:@"stash"] )
					{
						[dict setValue:[ref objectAtIndex:2] forKey:sha1];
						continue;
					}
						 
					if ( [refType isEqualToString:@"remotes"] )
					{
						NSArray *tail;
						NSRange range;
						
						range.location = 2;
						range.length = [ref count] - range.location;
						
						tail = [ref subarrayWithRange:range];
						
						NSString *remote = [tail objectAtIndex:0];
						
						NSMutableDictionary *remoteRef = [dict objectForKey:remote];
						if ( remoteRef == nil )
						{
							remoteRef = [[NSMutableDictionary alloc] init];
							[dict setValue:remoteRef forKey:remote];
						}
						
						[remoteRef setValue:[tail objectAtIndex:1] forKey:sha1];
						continue;
					}
				}
			}
		}
	}
	
	//
	// Parse un-packed refs
	//
	
	fileManager = [NSFileManager defaultManager];
	
	refsPath = [url URLByAppendingPathComponent:@"refs"];
	if ([refsPath checkResourceIsReachableAndReturnError:&error] == YES)
	{
		NSStringEncoding encoding;
		
		NSArray *urls = [fileManager contentsOfDirectoryAtURL:refsPath includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
		
		for(NSURL *u in urls)
		{
			NSMutableDictionary *dict;
			
			NSString *refType = [u lastPathComponent];
			
			NSArray *fileRefs = [fileManager contentsOfDirectoryAtURL:u includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
			
			if ( [fileRefs count] > 0 )
			{
				dict = [refs objectForKey:refType];
				if ( dict == nil )
				{
					dict = [[NSMutableDictionary alloc] init];
					[refs setValue:dict forKey:refType];
				}
			}
			
			for(NSURL *ref in fileRefs)
			{
				NSString *sha1 = [NSString stringWithContentsOfURL:ref usedEncoding:&encoding error:&error];
			
				if ( sha1 != nil ) // Otherwise we hare handling a directory.
				{
					NSString *filename = [ref lastPathComponent];
				
					[dict setValue:filename forKey:sha1];
				}
				else if ( [[u lastPathComponent] isEqualToString:@"remotes"] )
				{
					NSArray *remotePathComponents = [fileManager contentsOfDirectoryAtURL:u includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];

					for ( NSURL *remote in remotePathComponents )
					{
						NSArray *remoteSubPathComponents = [fileManager contentsOfDirectoryAtURL:remote includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
	
						if ( [remoteSubPathComponents count] > 0 )
						{
							NSDictionary *remoteRefs = [[NSMutableDictionary alloc] init];
						
							[dict setValue:remoteRefs forKey:[remote lastPathComponent]];

							for ( NSURL *subPath in remoteSubPathComponents )
							{
								NSString *sha1 = [NSString stringWithContentsOfURL:subPath usedEncoding:&encoding error:&error];
					
								if ( sha1 != nil )
								{
									NSString *filename = [subPath lastPathComponent];
						
									[remoteRefs setValue:filename forKey:sha1];
									continue;
								}
							}
						}
					}
				}
			} // for(NSURL *ref in urls)
		}
	}
}
@end


