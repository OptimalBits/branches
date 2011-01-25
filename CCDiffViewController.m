//
//  CCDiffViewController.m
//  gitfend
//
//  Created by Manuel Astudillo on 9/10/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "CCDiffViewController.h"
#import "CCDiffViewModel.h"
#import "CCDiffView.h"
#import "CCDiff.h"

#include <Carbon/Carbon.h>

#import "OBSScrollViewAnimation.h"

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
	[leftScrollView release];
	[rightScrollView release];

	[super dealloc];
}

- (void) awakeFromNib
{
	leftScrollViewAnimator = 
		[[OBSScrollViewAnimation alloc] initWithScrollView:leftScrollView
												  duration:0.3
											animationCurve:NSAnimationEaseInOut];
	[leftScrollViewAnimator setDelegate:self];

	rightScrollViewAnimator = 
		[[OBSScrollViewAnimation alloc] initWithScrollView:rightScrollView
												  duration:0.3
											animationCurve:NSAnimationEaseInOut];
	[rightScrollViewAnimator setDelegate:self];
	
	//[self gotoDiff];
}

-(void) animationDidEnd:(NSAnimation*) animation
{
	[self bindScrollViews];
}

-(void) animationDidStop:(NSAnimation*) animation
{
	[self bindScrollViews];
}

-(void) bindScrollViews
{
	// Register notifications used to keep the text views synchronized.
	[leftScrollView setPostsBoundsChangedNotifications:YES];
	[rightScrollView setPostsBoundsChangedNotifications:YES];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:[leftScrollView contentView]];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:[rightScrollView contentView]];	
}

-(void) unbindScrollViews
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSViewBoundsDidChangeNotification 
												  object:[leftScrollView contentView]];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSViewBoundsDidChangeNotification 
												  object:[rightScrollView contentView]];	
}


-(void) setStringsBefore:(NSString*) before andAfter:(NSString*) after
{
	CCDiff *diff = 
		[[[CCDiff alloc] initWithBefore:before andAfter:after] autorelease];
	
	diffViewModel = [[CCDiffViewModel alloc] initWithDiffLines:[diff diff]];
	
	leftView = [[CCDiffView alloc] initWithScrollView:leftScrollView
												 font:[NSFont fontWithName:@"Menlo-Regular" size:11.0]
												lines:[diffViewModel leftLines]
												 mask:CCDiffViewLineOriginal|CCDiffViewLineRemoved
										   controller:self];
	
	rightView =[[CCDiffView alloc] initWithScrollView:rightScrollView
												 font:[NSFont fontWithName:@"Menlo-Regular" size:11.0]
								 				lines:[diffViewModel rightLines]
												 mask:CCDiffViewLineOriginal|CCDiffViewLineAdded
										   controller:self];
	[self bindScrollViews];

}


-(void) keyDown:(NSEvent *)theEvent
{
	unsigned short keyCode = [theEvent keyCode];
	
	switch( keyCode )
	{
		case kVK_DownArrow:
			
 			[leftView moveToNextDiff];
			
			 break;
			
		case kVK_UpArrow:
			[leftView moveToPreviousDiff];

			break;
	}
}

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification
{
	NSScrollView *scrollView;
	NSTextView *textView;
	
	if ( NSEqualPoints( [[leftScrollView contentView] bounds].origin,
						[[rightScrollView contentView] bounds].origin ) )
	{
		return;
	}
	
    NSClipView *changedContentView = [notification object];
	
    NSPoint changedBoundsOrigin = 
		[changedContentView documentVisibleRect].origin;
	
    if ( [leftScrollView contentView] != changedContentView )
	{
		scrollView = leftScrollView;
		textView = leftView;
	}
	else
	{
		scrollView = rightScrollView;
		textView = rightView;
	}

	[[scrollView contentView] scrollToPoint:changedBoundsOrigin];
	[scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (IBAction) mergeToLeft:(id) sender
{
	NSRange leftCharRange;
	NSRange rightCharRange;
	
	NSInteger leftBias;
	NSInteger rightBias;
	
	CCDiffHunk *leftHunk  = [leftView selectedHunk];
	CCDiffHunk *rightHunk = [rightView selectedHunk];
	
	NSTextStorage *leftStorage = [leftView textStorage];
	NSTextStorage *rightStorage = [rightView textStorage];
	
	NSAttributedString *string;
	
	rightCharRange = [rightHunk charRange];
	leftCharRange = [leftHunk charRange];
	
	if ( [rightHunk status] == kLineEmpty )
	{
		string = [[NSAttributedString alloc] initWithString:@""];
		
		[rightStorage replaceCharactersInRange:rightCharRange
						  withAttributedString:string];

		rightBias = -rightCharRange.length;
	}
	else
	{ 
		string = 
			[rightStorage attributedSubstringFromRange:rightCharRange];
		rightBias = 0;
	}
	
	[leftStorage replaceCharactersInRange:leftCharRange
					 withAttributedString:string];
	
	leftBias = [string length] - leftCharRange.length;
	
	[leftView removeSelectedHunk:leftBias];
	[rightView removeSelectedHunk:rightBias];
	
	[leftView moveToDiff];
	[rightView moveToDiff];
	
	//[rightView setNeedsDisplayInRect:[rightScrollView documentVisibleRect] 
	//		   avoidAdditionalLayout:NO];
	//[leftView setNeedsDisplayInRect:[leftScrollView documentVisibleRect] 
	//		   avoidAdditionalLayout:NO];
		
	[rightView setNeedsDisplay:YES];
	[leftView setNeedsDisplay:YES];
}

- (IBAction) stageDiff:(id) sender
{
	[self mergeToLeft:sender];
	
	// Update stage area
}

-(void) gotoDiff
{
	NSInteger index;
	
	if ( [leftScrollViewAnimator isAnimating] )
	{
		[leftScrollViewAnimator stopAnimation];
	}
	if ( [rightScrollViewAnimator isAnimating] )
	{
		[rightScrollViewAnimator stopAnimation];
	}
	
	index = [leftView selectedHunkIndex];
	[leftScrollViewAnimator scrollToPoint:[leftView hunkOrigin:index]];
	
	
	index = [rightView selectedHunkIndex];
	[rightScrollViewAnimator scrollToPoint:[leftView hunkOrigin:index]];
}

-(void) gotoDiffIndex:(NSUInteger) index
{
	if ( [leftScrollViewAnimator isAnimating] )
	{
		[leftScrollViewAnimator stopAnimation];
	}
	if ( [rightScrollViewAnimator isAnimating] )
	{
		[rightScrollViewAnimator stopAnimation];
	}
	
	[leftScrollViewAnimator scrollToPoint:[leftView hunkOrigin:index]];		
	[rightScrollViewAnimator scrollToPoint:[leftView hunkOrigin:index]];
}

- (IBAction) nextDiff:(id) sender
{
	[leftView moveToNextDiff];
	[rightView moveToNextDiff];
	
	[self unbindScrollViews];
	[self gotoDiff];
}

- (IBAction) prevDiff:(id) sender
{
	[leftView moveToPreviousDiff];
	[rightView moveToPreviousDiff];
	
	[self unbindScrollViews];
	[self gotoDiff];
}




@end

