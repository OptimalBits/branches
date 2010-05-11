//
//  gitrepo.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "gitrepo.h"

@implementation GitRepo

- (id) initWithUrl: (NSURL*) path
{	
    if ( self = [super init] )
    {
		heads = [[NSMutableDictionary alloc] init];
		tags = [[NSMutableDictionary alloc] init];
		remotes = [[NSMutableDictionary alloc] init];

		
		[self parseRefs: path];
	}
    return self;
}

-(void) dealloc
{
	[heads dealloc];
	[tags dealloc];
	[remotes dealloc];
	
	
	[super dealloc];
}


- (void) parseRefs: (NSURL*) url
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
			
			if ( [lineElements count] > 2 )
			{
				NSArray *ref = [[lineElements objectAtIndex:1] componentsSeparatedByString:@"/"];
				
				if ([ref count] > 2 )
				{
					NSString *refType = [ref objectAtIndex:1];
					if ( [refType isEqualToString:@"heads"] )
					{
						[heads setValue:[ref objectAtIndex:2] forKey:sha1];
						continue;
					}
					
					if ( [refType isEqualToString:@"tags"] )
					{
						[tags setValue:[ref objectAtIndex:2] forKey:sha1];
						continue;
					}
					
					if ( [refType isEqualToString:@"stash"] )
					{
						//	[self.stash setValue:[ref objectAtIndex:2]: forKey:sha1];
					}
					
					if ( [refType isEqualToString:@"remotes"] )
					{
						NSArray *tail;
						NSRange range;
						
						range.location = 2;
						range.length = [ref count] - range.location;
						
						tail = [ref subarrayWithRange:range];
						
						[remotes setValue:tail forKey:sha1];
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
			NSLog([u absoluteString]);
			
			NSString *sha1 = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&error];
			
			if ( sha1 != nil )
			{
				NSString *filename = [u lastPathComponent];
				NSString *refType  = [[u URLByDeletingLastPathComponent] lastPathComponent];
				
				if ( [refType isEqualToString:@"heads"] )
				{
					[heads setValue:filename forKey:sha1];
					continue;
				}
				
				if ( [refType isEqualToString:@"tags"] )
				{
					[tags setValue:filename forKey:sha1];
					continue;
				}
				
				if ( [refType isEqualToString:@"stash"] )
				{
					//	[self.stash setValue:[ref objectAtIndex:2]: forKey:sha1];
				}
			}
			else if ( [[u lastPathComponent] isEqualToString:@"remotes"] )
			{
				NSArray *remotePathComponents = [fileManager contentsOfDirectoryAtURL:u includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];

				for ( NSURL *remote in remotePathComponents )
				{
					NSArray *remoteSubPathComponents = [fileManager contentsOfDirectoryAtURL:remote includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
					for ( NSURL *subPath in remoteSubPathComponents )
					{
						NSString *sha1 = [NSString stringWithContentsOfURL:subPath usedEncoding:&encoding error:&error];
					
						if ( sha1 != nil )
						{
							NSString *filename = [subPath lastPathComponent];
						
							[remotes setValue:filename forKey:sha1];
							continue;
						}
					}
				}
			}
		}
	}
}

@end


