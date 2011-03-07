//
//  CCDiffViewModel.m
//  gitfend
//
//  Created by Manuel Astudillo on 1/2/11.
//  Copyright 2011 Optimal Bits Sweden AB. All rights reserved.
//

#import "CCDiffViewModel.h"
#import "CCDiff.h"

@interface CCDiffViewModel (Private)

-(void) processLines:(NSArray*) leftLinesTemp 
	  rightLinesTemp:(NSArray*) rightLinesTemp;

@end


@implementation CCDiffViewModel

@synthesize leftLines;
@synthesize rightLines;

-(id) initWithDiffLines:(NSArray*) lines
{
	if ( self = [super init] )
	{
		leftLines = [[NSMutableArray alloc] initWithCapacity:[lines count]];
		rightLines = [[NSMutableArray alloc] initWithCapacity:[lines count]];
		
		// Generate left and right line arrays
		if ( [lines count] > 0 )
		{
			NSMutableArray *leftLinesTemp = [NSMutableArray array];
			NSMutableArray *rightLinesTemp = [NSMutableArray array];
			
			for( CCDiffLine *line in lines )
			{
				LineDiffStatus status = [line status];
				switch (status)
				{
					case kLineAdded:
						[rightLinesTemp addObject:line];
						break;
					case kLineRemoved:
						[leftLinesTemp addObject:line];
						break;
					case kLineOriginal:
						[self processLines:leftLinesTemp 
							rightLinesTemp:rightLinesTemp];
												
						[rightLinesTemp removeAllObjects];
						[leftLinesTemp removeAllObjects];
						
						[rightLines addObject:line];
						[leftLines addObject:line];
						break;
					default:
						break;
				}
			}
			[self processLines:leftLinesTemp rightLinesTemp:rightLinesTemp];
		}
	}
	return self;
}


-(void) processLines:(NSArray*) leftLinesTemp 
	  rightLinesTemp:(NSArray*) rightLinesTemp
{
	NSUInteger rightLineCount;
	NSUInteger leftLineCount;
		
	rightLineCount = [rightLinesTemp count];
	leftLineCount = [leftLinesTemp count];
	
	NSUInteger delta;
	NSUInteger lineCount;
	
	lineCount = rightLineCount > leftLineCount ?
				leftLineCount:rightLineCount;
	
	for ( NSInteger i = 0; i < lineCount; i++ )
	{
		CCDiffLine *rightLine = [rightLinesTemp objectAtIndex:i];
		CCDiffLine *leftLine = [leftLinesTemp objectAtIndex:i];
		
		[rightLine setStatus:kLineModified];
		[leftLine setStatus:kLineModified];
		
		[rightLines addObject:rightLine];
		[leftLines addObject:leftLine];
		
		updateLineCharDiff( leftLine, rightLine );
	}
	
	if ( rightLineCount > leftLineCount )
	{
		delta = rightLineCount - leftLineCount;
		for ( NSInteger i = 0; i < delta; i++ )
		{
			[leftLines addObject:[CCDiffLine emptyLine:0]];
		}
		[rightLines addObjectsFromArray:
		 [rightLinesTemp subarrayWithRange:
		  NSMakeRange(leftLineCount,delta)]];							
	}
	else
	{
		delta = leftLineCount - rightLineCount;
		for ( NSInteger i = 0; i < delta; i++ )
		{
			[rightLines addObject:[CCDiffLine emptyLine:0]];
		}
		[leftLines addObjectsFromArray:
		 [leftLinesTemp subarrayWithRange:
		  NSMakeRange(rightLineCount,delta)]];
	}	
}

@end




