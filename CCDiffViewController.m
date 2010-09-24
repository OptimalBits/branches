//
//  CCDiffViewController.m
//  gitfend
//
//  Created by Manuel Astudillo on 9/10/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "CCDiffViewController.h"
#import "CCDiffView.h"
#import "CCDiff.h"

#import "NoodleLineNumberView.h"

// #import "NSTextView+Wrapping.h"

// references:
//	http://developer.apple.com/documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html#//apple_ref/doc/uid/20000938-164652-BCIDFBBH
//	http://www.cocoabuilder.com/archive/message/cocoa/2003/12/28/89458


@implementation CCDiffViewController


- (id) init
{
	if ( self = [super initWithNibName:@"DiffView" bundle:nil] )
    {
		[self setTitle:@"DiffView"];

	}
	return self;
}

- (void) dealloc
{
	[leftView release];
	[rightView release];

	[super dealloc];
}

- (void) awakeFromNib
{		
	// Register notifications used to keep the text views synchronized.
	[leftScrollView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:[leftScrollView contentView]];

	[rightScrollView setPostsBoundsChangedNotifications:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:[rightScrollView contentView]];
}


-(void) setStringsBefore:(NSString*) before andAfter:(NSString*) after
{
	CCDiff *diff = [[CCDiff alloc] initWithBefore:before andAfter:after];
	
	NSArray *lcs = [diff diff];
		
	leftView = [[CCDiffView alloc] initWithScrollView:leftScrollView
												 font:[NSFont fontWithName:@"Menlo-Regular" size:12.0]
												lines:lcs
												 mask:CCDiffViewLineOriginal|CCDiffViewLineRemoved];
	
	rightView =[[CCDiffView alloc] initWithScrollView:rightScrollView
												 font:[NSFont fontWithName:@"Menlo-Regular" size:12.0]
												lines:lcs
												 mask:CCDiffViewLineOriginal|CCDiffViewLineAdded];
}
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification
{
	NSScrollView *scrollView;
	NSTextView *textView;
	
    NSClipView *changedContentView = [notification object];
	
    NSPoint changedBoundsOrigin = 
		[changedContentView documentVisibleRect].origin;
	
    if ( [leftScrollView contentView] != changedContentView )
	{
		scrollView = leftScrollView;
		textView = leftView;
		NSLog(@"Synchronizing Left");
	}
	else
	{
		scrollView = rightScrollView;
		textView = rightView;
		NSLog(@"Synchronizing Right");
	}
	
	[scrollView setPostsBoundsChangedNotifications:NO];
	[scrollView setPostsFrameChangedNotifications:NO];
		
	NSPoint curOffset = [[scrollView contentView] bounds].origin;
    NSPoint newOffset = curOffset;
	
    newOffset.y = changedBoundsOrigin.y;
	
    if (!NSEqualPoints(curOffset, changedBoundsOrigin))
    {
		// note that a scroll view watching this one will
		// get notified here
		[[scrollView contentView] scrollToPoint:newOffset];

		// we have to tell the NSScrollView to update its
		// scrollers
		[scrollView reflectScrolledClipView:[scrollView contentView]];
    }
	
	//[textView setPostsBoundsChangedNotifications:YES];
}







@end
