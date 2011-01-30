//
//  UnifyAppController.h
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UnifyFileDiffController, UnifyFolderDiffController;

@interface UnifyAppController : NSObject {

	IBOutlet NSTextField *bottomInfoText;
	IBOutlet NSTextField *activityInfoText;

	IBOutlet NSProgressIndicator *progressIndicator;
	
	IBOutlet NSOutlineView *bookmarksView;
	
	IBOutlet NSBox *mainContainer;
	
	UnifyFolderDiffController *folderDiffController;
	UnifyFileDiffController   *fileDiffController;
}

- (void)awakeFromNib;

- (IBAction) startFolderDiff:(id) sender;

@end
