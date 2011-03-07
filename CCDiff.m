//
//  CCDiff.m
//  DiffMerge
//
//  Created by Manuel Astudillo on 8/20/10.
//  Copyright 2010 Optimal Bits Sweden AB. All rights reserved.
//

#import "CCDiff.h"
#import "NSString+OBSDiff.h"

static NSArray* longestCommonSubsequence( NSArray* beforeLines, 
										  NSArray *afterLines );

static NSArray* diff( NSArray *before, 
					  NSArray *after, 
					  id (^removedBlock)(NSString *string, NSUInteger index),
					  id (^addedBlock)(NSString *string, NSUInteger index),
					  id (^originalBlock)(NSString *string, NSUInteger index) );


@implementation CCDiffChar

@synthesize charIndex;
@synthesize status;

+(id) diffChar:(NSUInteger) index status:(CharDiffStatus) _status
{
	CCDiffChar *diffChar = [[CCDiffChar alloc] init];
	
	[diffChar setCharIndex:index];
	[diffChar setStatus:_status];
	
	return [diffChar autorelease];
}

@end


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

-(NSUInteger) endCharIndex
{
	return (startCharIndex + [self charLength]) - 1;
}

-(NSUInteger) lastLineNumber
{	
	if ( [lines count] > 0 )
	{
		return firstLineNumber + [lines count] - 1;
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
@synthesize charDiffs;
//@synthesize charIndex;

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
		//charIndex = 0;
	}
	return self;
}

-(void) dealloc
{
	[line release];
	[charDiffs release];
	[super dealloc];
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

-(NSArray*) diff:(CCDiffLine*) afterLine
{
	NSArray *charactersBefore;
	NSArray *charactersAfter;
	
	charactersBefore = [line arrayWithStringCharacters];
	charactersAfter = [[afterLine line] arrayWithStringCharacters];

	return diff( charactersBefore, charactersAfter, 
				^( NSString *string, NSUInteger index )
				{
					return [CCDiffChar diffChar:index status:kCharRemoved];
				},
				^( NSString *string, NSUInteger index)
				{
					return [CCDiffChar diffChar:index status:kCharAdded];
				},
				^( NSString *string, NSUInteger index)
				{
					return [CCDiffChar diffChar:index status:kCharOriginal];
				} );
}

@end

void updateLineCharDiff(CCDiffLine* before, CCDiffLine* after)
{
	NSArray *charactersBefore;
	NSArray *charactersAfter;
	
	charactersBefore = [[before line] arrayWithStringCharacters];
	charactersAfter  = [[after line] arrayWithStringCharacters];
	
	NSArray *charDiffs = diff( charactersBefore, charactersAfter, 
				^( NSString *string, NSUInteger index )
				{
					return [CCDiffChar diffChar:index status:kCharRemoved];
				},
				^( NSString *string, NSUInteger index)
				{
					return [CCDiffChar diffChar:index status:kCharAdded];
				},
				^( NSString *string, NSUInteger index)
				{
					return [CCDiffChar diffChar:index status:kCharOriginal];
				} );
	
	NSMutableArray *beforeCharDiffs = [[NSMutableArray alloc] init];
	NSMutableArray *afterCharDiffs = [[NSMutableArray alloc] init];
	
	for ( CCDiffChar *c in charDiffs )
	{
		if ( [c status] == kCharRemoved )
		{
			[beforeCharDiffs addObject:c];
		}
		else if ( [c status] == kCharAdded )
		{
			[afterCharDiffs addObject:c];
		}
	}
	
	[before setCharDiffs:beforeCharDiffs];
	[after setCharDiffs:afterCharDiffs];
	
	[beforeCharDiffs release];
	[afterCharDiffs release];
}


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

-(NSArray*) diff
{
	return diff( beforeLines, afterLines, 
				^( NSString *string, NSUInteger index )
				{
					return [[[CCDiffLine alloc] initWithLine:string
													  status:kLineRemoved
													  number:index] 
							autorelease];
				},
				^( NSString *string, NSUInteger index)
				{
					return [[[CCDiffLine alloc] initWithLine:string
													  status:kLineAdded
													  number:index] 
							autorelease];
				},
				^( NSString *string, NSUInteger index)
				{
					return [[[CCDiffLine alloc] initWithLine:string
													  status:kLineOriginal
													  number:index] 
							autorelease];
				} );
}

@end


static NSArray *getLines( NSString *s )
{
	NSMutableArray *lines = [[[NSMutableArray alloc] init] autorelease];
	[s enumerateLinesUsingBlock:
		 ^(NSString *line, BOOL *stop){[lines addObject:line];}];
	
	return lines;
}

static NSArray* longestCommonSubsequence( NSArray* beforeLines, 
										  NSArray *afterLines )
{
	int32_t i, j;
	uint32_t beforeLinesCount, afterLinesCount;
	
	NSArray *trimmedBeforeLines, *trimmedAfterLines;
	
	DynProgTable table;
	
	uint32_t headLength, tailStart, tailLength;
	
	if ( ( [beforeLines count] == 0 ) || 
		 ( [afterLines count] == 0 ) )
	{
		return [NSArray array];
	}
	
	// trim inputs to improve performance on large almost unmodified files
	afterLinesCount = [afterLines count];
	headLength = 0;
	for ( NSString *line in beforeLines )
	{
		if ([line isEqualToString:[afterLines objectAtIndex:headLength]])
		{
			headLength ++;
			if ( headLength >= afterLinesCount )
			{
				return afterLines;
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


typedef id (*removed)(NSString *string, NSUInteger index);
typedef id (*added)(NSString *string, NSUInteger index);
typedef id (*original)(NSString *string, NSUInteger index);

NSArray* diff( NSArray *before, 
			   NSArray *after, 
			   id (^removedBlock)(NSString *string, NSUInteger index),
			   id (^addedBlock)(NSString *string, NSUInteger index),
			   id (^originalBlock)(NSString *string, NSUInteger index))
{
	NSMutableArray *result;
	
	NSArray *lcs = longestCommonSubsequence( before, after );
	
	u_int32_t bCount = [before count];
	u_int32_t aCount = [after count];
	
	result = 
	 [[[NSMutableArray alloc] initWithCapacity:MAX(bCount,aCount)] autorelease];
	
	u_int32_t bIndex = 0;
	u_int32_t aIndex = 0;
	
	u_int32_t bLineNumber = 0;
	u_int32_t aLineNumber = 0;
	
	for( NSString *s in lcs )
	{
		while ( bIndex < bCount )
		{
			NSString *b = [before objectAtIndex:bIndex];
			bIndex++;
			
			if ( [b isEqualToString:s] )
			{
				break;
			}
			else
			{				
				[result addObject:removedBlock( b, bLineNumber )];
				 
				bLineNumber++;
			}
		}
		
		while ( aIndex < aCount )
		{
			NSString *a = [after objectAtIndex:aIndex];
			aIndex++;
			
			if ( [a isEqualToString:s] )
			{
				break;
			}
			else
			{
				[result addObject:addedBlock( a, aLineNumber)];
				
				aLineNumber++;
			}
		}
		
		[result addObject:originalBlock( s, 0 )];
		bLineNumber++;
		aLineNumber++;
	}
	
	while( bIndex < bCount )
	{
		[result addObject:removedBlock([before objectAtIndex:bIndex], bLineNumber)];
		
		bIndex++;
		bLineNumber++;
	}
	
	while( aIndex < aCount )
	{
		[result addObject:addedBlock([after objectAtIndex:aIndex], aLineNumber)];
		
		aIndex++;
		aLineNumber++;
	}
	
	return result;
}


