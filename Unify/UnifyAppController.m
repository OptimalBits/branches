//
//  UnifyAppController.m
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "UnifyAppController.h"
#import "UnifyFolderDiffController.h"
#import "UnifyFileDiffController.h"
#import "NSBox+OBSDisplay.h"


@implementation UnifyAppController


- (void)awakeFromNib
{
	[[bottomInfoText cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[bottomInfoText setStringValue:@"Ready"];

	folderDiffController = [[UnifyFolderDiffController alloc] init];
	[mainContainer displayViewController:folderDiffController];
}

-(void) dealloc
{
	[folderDiffController release];
	[super dealloc];
}

- (IBAction) startFolderDiff:(id) sender
{
	
}

@end
