//
//  CCDiffViewModel.m
//  gitfend
//
//  Created by Manuel Astudillo on 1/2/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "CCDiffViewModel.h"
#import "CCDiff.h"

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
					NSUInteger rightLineCount;
					NSUInteger leftLineCount;
						
					case kLineAdded:
						[rightLinesTemp addObject:line];
						break;
					case kLineRemoved:
						[leftLinesTemp addObject:line];
						break;
					case kLineOriginal:
						 rightLineCount = [rightLinesTemp count];
						 leftLineCount = [leftLinesTemp count];
						
						if ( rightLineCount && 
						   ( rightLineCount == leftLineCount ) )
						{
							for ( CCDiffLine *rightLine in rightLinesTemp )
							{
								[rightLine setStatus:kLineModified];
								[rightLines addObject:rightLine];
							}
							for ( CCDiffLine *leftLine in leftLinesTemp )
							{
								[leftLine setStatus:kLineModified];
								[leftLines addObject:leftLine];
							}
						}
						else
						{
							if ( rightLineCount > leftLineCount )
							{
								NSInteger delta = rightLineCount - 
												  leftLineCount;
								
								for ( NSInteger i = 0; i < leftLineCount; i++ )
								{
									CCDiffLine *rightLine = 
										[rightLinesTemp objectAtIndex:i];
									[rightLine setStatus:kLineModified];
									
									CCDiffLine *leftLine = 
										[leftLinesTemp objectAtIndex:i];
									[leftLine setStatus:kLineModified];
									
									[rightLines addObject:rightLine];
									[leftLines addObject:rightLine];
								}
								
								for ( NSInteger i = 0; i < delta; i++ )
								{
									[leftLines addObject:[CCDiffLine emptyLine:0]];
								}
								
								[rightLines addObjectsFromArray:
								 [rightLinesTemp subarrayWithRange:
									NSMakeRange(leftLineCount,delta)]];
							}
							else if ( leftLineCount > rightLineCount )
							{
								NSInteger delta = leftLineCount - 
												  rightLineCount;
								
								for ( NSInteger i = 0; i < rightLineCount; i++ )
								{
									CCDiffLine *rightLine = 
									[rightLinesTemp objectAtIndex:i];
									[rightLine setStatus:kLineModified];
									
									CCDiffLine *leftLine = 
									[leftLinesTemp objectAtIndex:i];
									[leftLine setStatus:kLineModified];
									
									[rightLines addObject:rightLine];
									[leftLines addObject:rightLine];
								}
								for ( NSInteger i = 0; i < delta; i++ )
								{
									[rightLines addObject:[CCDiffLine emptyLine:0]];
								}
								
								[leftLines addObjectsFromArray:
								 [leftLinesTemp subarrayWithRange:
								  NSMakeRange(rightLineCount,delta)]];
							}
						}
						
						[rightLinesTemp removeAllObjects];
						[leftLinesTemp removeAllObjects];
						
						[rightLines addObject:line];
						[leftLines addObject:line];
						break;
				}
			}
		}
	}
	return self;
}

@end




