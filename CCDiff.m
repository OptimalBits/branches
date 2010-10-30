//
//  CCDiff.m
//  DiffMerge
//
//  Created by Manuel Astudillo on 8/20/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "CCDiff.h"


@implementation CCDiffLine

@synthesize line;
@synthesize status;
@synthesize number;

-(id) initWithLine:(NSString*) _line 
			status:(LineDiffStatus) _status 
		 andNumber:(NSUInteger) _number
{
	if ( self = [super init] )
	{
		[_line retain];
		line = _line;
		status = _status;
		number = _number;
	}
	return self;
}


+(id) emptyLine:(NSUInteger) _number
{
	return 
		[[[CCDiffLine alloc] initWithLine:nil 
								   status:kLineEmpty 
								andNumber:_number] autorelease];
}

@end


typedef struct 
{
	u_int32_t width;
	u_int32_t height;
	u_int32_t *cells;
} DynProgTable;

#define TABLE( table, x, y ) table.cells[(y)*(table.width) + (x)]

static NSArray *getLines( NSString *s );

@implementation CCDiff

-(id) initWithBefore:(NSString*) before andAfter:(NSString*) after
{
	if ( self = [super init] )
	{		
		beforeLines = getLines( before );
		afterLines = getLines( after );
		
		[beforeLines retain];
		[afterLines retain];
	}
	return self;
}

-(void) dealloc
{
	[beforeLines release];
	[afterLines release];
	[super dealloc];
}

-(NSArray*) longestCommonSubsequence
{
	int32_t i, j;

	DynProgTable table;

	table.width = [beforeLines count] + 1;
	table.height = [afterLines count] + 1;
	
	table.cells = malloc(table.width * table.height * sizeof(u_int32_t));
	
	for (j = table.height-1; j >= 0; j--)
	{
		for (i = table.width-1; i >= 0; i--)
		{
			if ( (i >= [beforeLines count]) || ( j >= [afterLines count]) )
			{
				TABLE( table, i, j ) = 0;
			}
			else if([[beforeLines objectAtIndex:i] isEqualToString:
					 [afterLines objectAtIndex:j]])
			{
				u_int32_t t = TABLE( table, i+1, j+1);
				TABLE( table, i, j ) = 1 + t;
			}
			else
			{
				int32_t a, b;
				
				a = TABLE( table, i+1, j );
				b = TABLE( table, i, j+1 );
				
				TABLE( table, i, j ) = MAX( a, b );
			}
		}		
    }
	
	u_int32_t length = TABLE( table, 0, 0 );
	
	NSMutableArray *sequence = 
		[[[NSMutableArray alloc] initWithCapacity:length] autorelease];
	
    i = 0;
    j = 0;
	
    while ( (i < table.width-1) && (j < table.height-1) )
    {
		if ([[beforeLines objectAtIndex:i] isEqualToString:
			 [afterLines objectAtIndex:j]])
		{
			[sequence addObject:[beforeLines objectAtIndex:i]];
			i++; 
			j++;
		}
		else if (TABLE((table), i+1, j) >= TABLE((table),i,j+1)) 
		{
			 i++;
		}
		else 
		{
			 j++;
		}
    }
	
	free( table.cells );
	
	return sequence;
}

-(NSArray*) diff
{
	NSMutableArray *result;
	CCDiffLine *diffLine;
	
	NSArray *lcs = [self longestCommonSubsequence];
	
	u_int32_t bCount = [beforeLines count];
	u_int32_t aCount = [afterLines count];
	
	result = 
	[[[NSMutableArray alloc] initWithCapacity:MAX(bCount,aCount)] autorelease];
	
	u_int32_t bIndex = 0;
	u_int32_t aIndex = 0;
	
	u_int32_t bLineNumber = 1;
	u_int32_t aLineNumber = 1;
	
	for( NSString *s in lcs )
	{
		while(1)
		{
			if ( bIndex < bCount )
			{
				NSString *b = [beforeLines objectAtIndex:bIndex];
				bIndex++;
				
				if ( [b isEqualToString:s] )
				{
					break;
				}
				else
				{
					diffLine = [[[CCDiffLine alloc] initWithLine:b 
														 status:kLineRemoved
													  andNumber:bLineNumber] 
								autorelease];
					
					[result addObject:diffLine];
					
					bLineNumber++;
				}
			}
		}
		
		while(1)
		{
			if ( aIndex < aCount )
			{
				NSString *a = [afterLines objectAtIndex:aIndex];
				aIndex++;
				
				if ( [a isEqualToString:s] )
				{
					break;
				}
				else
				{
					diffLine = [[[CCDiffLine alloc] initWithLine:a
														 status:kLineAdded
													  andNumber:aLineNumber]
								autorelease];
					[result addObject:diffLine];
					
					aLineNumber++;
				}
			}
		}
		
		diffLine = [[[CCDiffLine alloc] initWithLine:s
											 status:kLineOriginal
										  andNumber:0] autorelease];
		[result addObject:diffLine];
		bLineNumber++;
		aLineNumber++;
	}
	
	while( bIndex < bCount )
	{
		diffLine = [[[CCDiffLine alloc] initWithLine:[beforeLines objectAtIndex:bIndex]
											  status:kLineRemoved
										   andNumber:bLineNumber] autorelease];
		[result addObject:diffLine];
		
		bIndex++;
		bLineNumber++;
	}

	while( aIndex < aCount )
	{		
		diffLine = [[[CCDiffLine alloc] initWithLine:[afterLines objectAtIndex:aIndex]
											  status:kLineAdded
										   andNumber:aLineNumber] autorelease];
		[result addObject:diffLine];
		
		aIndex++;
		aLineNumber++;
	}
	
	return result;
}


@end


static NSArray *getLines( NSString *s )
{
	NSMutableArray *lines = [[[NSMutableArray alloc] init] autorelease];
	[s enumerateLinesUsingBlock:
		 ^(NSString *line, BOOL *stop){[lines addObject:line];}];

	//	return [s componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	return lines;
}

