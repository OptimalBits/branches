//
//  gitfendController.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitfendRepositories.h"


@interface gitfendRepositoryController : NSObject {
	IBOutlet NSOutlineView *outlineView; // Repo view
	IBOutlet gitfendRepositories *repos;
	
}

- (void)awakeFromNib;

- (IBAction) addRepo: sender;

@end


