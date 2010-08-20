//
//  gitfrontHistoryController.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface gitfrontHistoryController : NSViewController <NSTableViewDataSource> {
	IBOutlet NSTableView *historyView;
	
	NSArray *history;

}

-(void) setHistory:(NSArray*) _history;

- (void) awakeFromNib;

- (int) numberOfRowsInTableView:(NSTableView *) aTableView;

- (id) tableView:(NSTableView *)tableView 
	   objectValueForTableColumn:(NSTableColumn *) aTableColumn 
	   row:(int) rowIndex;




@end
