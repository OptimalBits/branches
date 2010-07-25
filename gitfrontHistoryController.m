//
//  gitfrontHistoryController.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/31/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gitfrontHistoryController.h"
#import "gitrepo.h"
#import "gitpackfile.h"
#import "gitcommitobject.h"

#import "NSDataExtension.h"

@implementation gitfrontHistoryController

- (id) init
{
	if ( self = [super init] )
    {
		GitRepo *repo;
		NSURL *indexUrl = [NSURL fileURLWithPath:@"/Users/manuel/dev/git/cpp-gpengine/.git/objects/pack/pack-cfc7f4eb1d3e31966376a206af5f31c6e4546b49.idx" isDirectory:NO];
		NSURL *packUrl = [NSURL fileURLWithPath:@"/Users/manuel/dev/git/cpp-gpengine/.git/objects/pack/pack-cfc7f4eb1d3e31966376a206af5f31c6e4546b49.pack" isDirectory:NO];
		
		GitPackFile *packFile = [GitPackFile alloc];
		packFile = [packFile initWithIndexURL:indexUrl andPackURL:packUrl];
		
		repo = [[GitRepo alloc] initWithUrl:[NSURL fileURLWithPath:@"/Users/manuel/dev/gitfend/.git" isDirectory:YES]];
		
		history = [repo revisionHistoryFor:[NSData dataWithHexCString:"e5d78ba749356f01066eb9d7ec149da27e6d55c8"] withPackFile:packFile];
		[history retain];
	}
    return self;
}

-(void) dealloc
{
	[history release];
	[super dealloc];
}

- (void) awakeFromNib
{

}

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
	return [history count];
}

- (id) tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *) aTableColumn 
			 row:(int) rowIndex
{
	GitCommitObject *obj = [history objectAtIndex:rowIndex];

	if ( [[aTableColumn identifier] isEqual:@"description"] )
	{
		return [obj message];
	}
	else if ( [[aTableColumn identifier] isEqual:@"commit"] )
	{
		return [[[obj sha1] description] substringWithRange:NSMakeRange(1, 8)];
	}
	else if ( [[aTableColumn identifier] isEqual:@"date"] )
	{		
		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateFormat:@"MMMM d, YYYY"];
		
		// TODO: For relative new commits, format the date differently ( example: yesterday, 3 days ago, or sunday, saturday )
		
		return [outputFormatter stringFromDate:[[obj author] time]];		
	}
	else if ( [[aTableColumn identifier] isEqual:@"author"] )
	{
		return [[obj author] name];
	}	

	return @"";
}




@end
