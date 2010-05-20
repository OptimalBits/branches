//
//  gitfendController.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "gitfendController.h"
#import "ImageAndTextCell.h"

#define MAIN_COLUMN_ID	@"Main"


@implementation gitfendRepositoryController


- (void)awakeFromNib
{
	// apply our custom ImageAndTextCell for rendering the first column's cells
	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:@"Main"];
	//NSArray *columns = [outlineView tableColumns];
	//NSTableColumn *tableColumn = [columns objectAtIndex:0];
	
	ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
	
	
}


- (IBAction) deleteRepo: sender
{
	
}

- (IBAction) addRepo: sender
{
	
	// pass
}

@end
