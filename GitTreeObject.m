//
//  gittreeobject.m
//  GitLib
//
//  Created by Manuel Astudillo on 5/25/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitTreeObject.h"


@implementation GitTreeNode

@synthesize sha1;
@synthesize mode;

- (void) dealloc
{
    [sha1 release];
    [super dealloc];

}

@end


static uint32 modeToInt( NSString* str );


@implementation GitTreeObject

@synthesize tree;

- (id) init
{
	return [self initWithData:nil];	
}

- (id) initWithData: (NSData*) data
{
	int i, start, len;
	const uint8_t *bytes;
	
	if ( self = [super initWithType:@"tree"] )
    {
		tree = [[NSMutableDictionary alloc] init];
		
		if ( data )
		{
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
				
				modeAndName = [[[NSString alloc] initWithData:
								[data subdataWithRange:NSMakeRange(start,len)] 
													 encoding:NSUTF8StringEncoding] 
							   autorelease];
				if ( modeAndName )
				{
					sha1 = [data subdataWithRange:NSMakeRange(start+len+1, 20)];
					i +=21;
				
					NSArray *modeAndNameArray = [modeAndName componentsSeparatedByString:@" "];
				
					GitTreeNode *node = [[[GitTreeNode alloc] init] autorelease];
					[node setMode:modeToInt([modeAndNameArray objectAtIndex:0])];
					[node setSha1:sha1];
				
					[tree setObject:node forKey:[modeAndNameArray objectAtIndex:1]];
				}
			}
		}
	}
	
	return self;
}


-(void) dealloc
{
	[tree release];
	[super dealloc];
}

-(void) setEntry:(NSString*) filename
			mode:(uint32) mode
			sha1:(NSData*) sha1
{
	GitTreeNode *node = [[[GitTreeNode alloc] init] autorelease];
	
	[node setMode:mode];
	[node setSha1:sha1];
	
	[tree setObject:node forKey:filename];
}

-(void) removeEntry:(NSString*) filename
{
	[tree removeObjectForKey:filename];
}

-(void) addTree:(uint32) mode sha1:(NSData*) sha1
{
	
}


-(NSData*) data
{
	NSMutableData *result = [[NSMutableData alloc] init];
	
	NSArray* sortedKeys = 
		[[tree allKeys] sortedArrayUsingSelector:@selector(compare:)];

	for ( NSString *key in sortedKeys )
	{
		NSString *treeEntry;
		GitTreeNode *node;
		
		node = [tree objectForKey:key];
		treeEntry = [NSString stringWithFormat:@"%06o %@", [node mode], key];

		const char* cString = [treeEntry UTF8String];
		
		// note, the length is not in bytes, so it is wrong!. 
		// you have to use the length of the UTF8string by searching the
		// trailing zero.
		[result appendData:[NSData dataWithBytes:cString
										  length:[treeEntry length] + 1]];
		[result appendData:[node sha1]];
	}
	
	return result;
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


static uint32 modeToInt( NSString* str )
{
	const char *cstring = [str UTF8String];
	
	u_int32_t mode = 0;
	
	for ( int i = 0; i < strlen( cstring ); i++ )
	{
		mode = (mode<<3) | (cstring[i] - '0');
	}

	return mode;
}



