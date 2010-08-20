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

-(id) init
{
	if ( self = [super initWithNibName:@"History" bundle:nil] )
    {
		history = [[NSArray alloc] init];
		[self setTitle:@"GitFront - History"];
		
		historyView = [[self view] documentView];
		[historyView retain];
		[historyView setDataSource:self];
	}
	
	return self;
}


-(void) dealloc
{
	[history release];
	[super dealloc];
}

-(void) setHistory:(NSArray*) _history
{
	[_history retain];
	[history release];
	history = _history;

	[historyView reloadData];
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
		NSDateFormatter *outputFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[outputFormatter setDateFormat:@"MMMM d, YYYY"];
		
		// TODO: For relative new commits, format the date differently ( example: yesterday, 3 days ago, or sunday, saturday )
		// Also do not show the year if we are in the same year, etc.
		return [outputFormatter stringFromDate:[[obj author] time]];		
	}
	else if ( [[aTableColumn identifier] isEqual:@"author"] )
	{
		return [[obj author] name];
	}	

	return @"";
}

@end


