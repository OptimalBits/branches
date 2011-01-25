//
//  CCDiff.m
//  DiffMerge
//
//  Created by Manuel Astudillo on 8/20/10.
//  Copyright 2010 Optimal Bits Software AB. All rights reserved.
//

#import "CCDiff.h"


@implementation CCDiffHunk

@synthesize firstLineNumber;
@synthesize status;
@synthesize startCharIndex;
@synthesize lines;

-(id) init
{
	return [self initWithStatus:kLineEmpty];
}

-(id) initWithStatus:(LineDiffStatus) _status
{
	if ( self = [super init] )
	{
		status = _status;
		lines = [[NSMutableArray alloc] init];
	}
	
	return self;
}

-(void) dealloc
{
	[lines release];
	[super dealloc];
}

-(void) addLine:(CCDiffLine*) line
{
	[lines addObject:line];
}

-(NSUInteger) charLength
{
	NSUInteger totalLength;
	
	totalLength = 0;
	for ( CCDiffLine *line in lines )
	{
		totalLength += [line length] + 1;
	}
	
	return totalLength;
}

-(NSRange) charRange
{
	NSRange charRange = NSMakeRange( startCharIndex, [self charLength] );
	
	return charRange;
}

-(NSUInteger) startCharIndex
{
	return startCharIndex;
}

-(NSUInteger) endCharIndex
{
	return startCharIndex + [self charLength] - 1;
}

-(NSUInteger) lastLineNumber
{	
	if ( [lines count] > 1 )
	{
		return firstLineNumber + [lines count];
	}
	else
	{
		return firstLineNumber;
	}
}

@end


@implementation CCDiffLine

@synthesize line;
@synthesize status;
@synthesize number;

-(id) initWithLine:(NSString*) _line 
			status:(LineDiffStatus) _status 
			number:(NSUInteger) _number
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
								   number:_number] autorelease];
}

-(NSUInteger) length
{ 	
	if ( status != kLineEmpty )
	{
		return [line length];
	}
	else
	{
		return 0;
	}
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
	uint32_t beforeLinesCount, afterLinesCount;
	
	NSArray *trimmedBeforeLines, *trimmedAfterLines;

	DynProgTable table;
		
	uint32_t headLength, tailStart, tailLength;
	
	// trim inputs to improve performance on large almost unmodified files
	afterLinesCount = [afterLines count];
	headLength = 0;
	for ( NSString *line in beforeLines )
	{
		if ([line isEqualToString:[afterLines objectAtIndex:headLength]])
		{
			headLength ++;
			if ( headLength > afterLinesCount )
			{
				return nil;
			}
		}
		else
		{
			break;
		}
	}
	
	trimmedBeforeLines = 
		[beforeLines subarrayWithRange:NSMakeRange(headLength, 
												   [beforeLines count]-headLength)];
	trimmedAfterLines = 
		[afterLines subarrayWithRange:NSMakeRange(headLength, 
												  [afterLines count]-headLength)];
	
	i = [trimmedBeforeLines count] - 1;
	j = [trimmedAfterLines count] - 1;
	while( i > 0 && j > 0 )
	{
		if ([[trimmedBeforeLines objectAtIndex:i] isEqualToString:
			 [trimmedAfterLines objectAtIndex:j]])
		{
			i--;
			j--;
		}
		else
		{
			break;
		}
	}
	
	beforeLinesCount = i + 1;
	afterLinesCount = j + 1;
	
	tailStart = beforeLinesCount;
	tailLength = [trimmedBeforeLines count] - tailStart;
	
	// ----
	
	table.width  = beforeLinesCount + 1;
	table.height = afterLinesCount + 1;
	
	table.cells = malloc(table.width * table.height * sizeof(u_int32_t));
	
	for (j = table.height-1; j >= 0; j--)
	{
		for (i = table.width-1; i >= 0; i--)
		{
			if ( (i >= beforeLinesCount) || ( j >= afterLinesCount) )
			{
				TABLE( table, i, j ) = 0;
			}
			else if([[trimmedBeforeLines objectAtIndex:i] isEqualToString:
					 [trimmedAfterLines objectAtIndex:j]])
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
	
	u_int32_t length = TABLE( table, 0, 0 ) + headLength + tailLength;
	
	NSMutableArray *sequence = 
		[[[NSMutableArray alloc] initWithCapacity:length] autorelease];
	
	[sequence addObjectsFromArray:
		[beforeLines subarrayWithRange:NSMakeRange(0, headLength)]];
	
    i = 0;
    j = 0;
	
    while ( (i < table.width-1) && (j < table.height-1) )
    {
		if ([[trimmedBeforeLines objectAtIndex:i] isEqualToString:
			 [trimmedAfterLines objectAtIndex:j]])
		{
			[sequence addObject:[trimmedBeforeLines objectAtIndex:i]];
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
	
	[sequence addObjectsFromArray:
		[trimmedBeforeLines subarrayWithRange:NSMakeRange(tailStart, 
														  tailLength)]];
	
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
		while ( bIndex < bCount )
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
													  number:bLineNumber] 
							autorelease];
				
				
				[result addObject:diffLine];
				
				bLineNumber++;
			}
		}
		
		while ( aIndex < aCount )
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
													  number:aLineNumber]
							autorelease];
				[result addObject:diffLine];
				
				aLineNumber++;
			}
		}
		
		diffLine = [[[CCDiffLine alloc] initWithLine:s
											  status:kLineOriginal
											   number:0] autorelease];
		[result addObject:diffLine];
		bLineNumber++;
		aLineNumber++;
	}
	
	while( bIndex < bCount )
	{
		diffLine = [[[CCDiffLine alloc] initWithLine:[beforeLines objectAtIndex:bIndex]
											  status:kLineRemoved
											  number:bLineNumber] autorelease];
		[result addObject:diffLine];
		
		bIndex++;
		bLineNumber++;
	}
	
	while( aIndex < aCount )
	{		
		diffLine = [[[CCDiffLine alloc] initWithLine:[afterLines objectAtIndex:aIndex]
											  status:kLineAdded
											  number:aLineNumber] autorelease];
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
	
	return lines;
}

