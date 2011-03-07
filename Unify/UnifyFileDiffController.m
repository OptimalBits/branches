//
//  UnifyDiffController.m
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import "UnifyFileDiffController.h"


@implementation UnifyFileDiffController

- (id) init
{
	if ( self = [super initWithNibName:@"FileDiffView" bundle:nil] )
    {
		[self setTitle:@"DiffView"];
		
	}
	return self;
}

- (void) dealloc
{	
	[super dealloc];
}

- (void) awakeFromNib
{
	
	
}

-(void) setDiff:(NSArray*) _diff
{
	if ( diff != _diff )
	{
		diff = _diff;
		[diff retain];
	}
	
	
	
}

@end
