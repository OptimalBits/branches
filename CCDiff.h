//
//  CCDiff.h
//  DiffMerge
//
//  Created by Manuel Astudillo on 8/20/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
	Simple diff class.
 
	Can compute the diff between two files, and some other utilities.

 */

typedef enum
{
	kLineOriginal,
	kLineAdded,
	kLineRemoved,
	kLineEmpty,
	kLineUndefined
} LineDiffStatus;

@interface CCDiffLine : NSObject
{
	NSString *line;
	LineDiffStatus status;
	NSUInteger number;
}

@property (readonly) NSString *line;
@property (readonly) LineDiffStatus status;
@property (readonly) NSUInteger number;


+(id) emptyLine:(NSUInteger) number;

-(id) initWithLine:(NSString*) line 
			status:(LineDiffStatus) status 
		 andNumber:(NSUInteger) number;

@end


@interface CCDiff : NSObject {
	
	NSArray *beforeLines;
	NSArray *afterLines;
	
}

-(id) initWithBefore:(NSString*) left andAfter:(NSString*) right;


/**
	Returns an array with the longest common subsequence. Every element in the
	array will be a common line between the before and after strings.
 */
-(NSArray*) longestCommonSubsequence;

/**
	Returns an array with CCDiffLine objects representing the diff between
	before and after.
 */
-(NSArray*) diff;

@end

