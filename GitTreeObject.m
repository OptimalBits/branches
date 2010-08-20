//
//  gittreeobject.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/25/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gittreeobject.h"


@implementation GitTreeNode

@synthesize sha1;
@synthesize mode;

- (void) dealloc
{
    [sha1 release];
    [mode release];
    [super dealloc];

}

@end


@implementation GitTreeObject

@synthesize tree;

- (id) initWithData: (NSData*) data
{
	int i, start, len;
	const uint8_t *bytes;
	
	if ( self = [super init] )
    {
		tree = [[NSMutableDictionary alloc] init];
		
		bytes = [data bytes];
		
		i = 0;
		while( i < [data length] )
		{
			NSString *modeAndName;
			NSData *sha1;
			
			start = i;
			len = 0;
			while( ( i < [data length] ) && ( bytes[i] != 0 ) )
			{
				len++;
				i++;
			}
			
			modeAndName = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(start,len)] encoding:NSUTF8StringEncoding] autorelease];

			sha1 = [data subdataWithRange:NSMakeRange(start+len+1, 20)];
			i +=21;
			
			NSArray *modeAndNameArray = [modeAndName componentsSeparatedByString:@" "];
			
			GitTreeNode *node = [[[GitTreeNode alloc] init] autorelease];
			[node setMode:[modeAndNameArray objectAtIndex:0]];
			[node setSha1:sha1];
			
			[tree setObject:node forKey:[modeAndNameArray objectAtIndex:1]];
		}
	}
	
	return self;
}

- (GitTreeObject*) treeDiff: (GitTreeObject*) prevTree
{
	GitTreeObject *resultTree = [[GitTreeObject alloc] init];
	NSMutableSet *filenameSet = [[NSMutableSet alloc] init];
	
	[filenameSet addObjectsFromArray:[tree allKeys]];
	[filenameSet addObjectsFromArray:[[prevTree tree] allKeys]];
	
	for ( NSString *filename in filenameSet )
	{
		GitTreeNode *obj = [[prevTree tree] objectForKey:filename];
		GitTreeNode *newObj = [tree objectForKey:filename];
		
		if ( obj )
		{
			if ( newObj )
			{
				if ( [[obj sha1] isEqualToData: [newObj sha1]] == NO )
				{
					// Object Modified.
					[[resultTree tree] setObject:newObj forKey: filename];
				}
			}
			else
			{
				// Object Deleted.
			}
		}
		else
		{
			// Object Added.
			[[resultTree tree] setObject:newObj forKey: filename];
		}
	}
	
	[filenameSet release];
	
	return [resultTree autorelease];
}

@end
