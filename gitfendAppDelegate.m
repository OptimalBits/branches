//
//  gitfendAppDelegate.m
//  GitFront
//
//  Created by Manuel Astudillo on 5/4/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gitfendAppDelegate.h"

#import "CCDiff.h"

@implementation gitfendAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	NSError *error;
	
	NSLog(@"TESTING CCDiff");
	
	NSString *srcA = [NSString stringWithContentsOfFile:@"/Users/manuel/dev/gitfend/GitFrontTree.h" 
											   encoding:NSASCIIStringEncoding
												  error:&error];
	
	NSString *srcB = [NSString stringWithContentsOfFile:@"/Users/manuel/dev/gitfend/GitFrontTree.m" 
											   encoding:NSASCIIStringEncoding
												  error:&error];
	
	CCDiff *diff = [[CCDiff alloc] initWithBefore:srcA andAfter:srcB];
	
	NSArray *lcs = [diff diff];
	
	for( CCDiffLine *line in lcs )
	{
		NSLog(@"%@ %@", [line status] == kLineRemoved? @"-":([line status] == kLineAdded?@"+":@""), [line line]);
	}
}

-(void) dealloc
{
	[super dealloc];
}

@end
