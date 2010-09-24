//
//  CCDiffView.m
//  gitfend
//
//  Created by Manuel Astudillo on 9/18/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "CCDiffView.h"
#import "CCDiff.h"
#import "NoodleLineNumberView.h"

@implementation CCDiffView


- (id) initWithScrollView:(NSScrollView*) view 
					 font:(NSFont*) _font
					lines:(NSArray*) lcs
					 mask:(CCDiffViewLineMask) mask
{
	NSSize contentSize = [view contentSize];
	
	self = [super initWithFrame:NSMakeRect( 0, 0, 
										    contentSize.width, 
										    contentSize.height)];
	if ( self )
	{
		lines = [[NSMutableArray alloc] init];
		
		font = _font;
		[font retain];
		
		[self setMinSize:NSMakeSize(0.0, contentSize.height)];
		[self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		
		[self setVerticallyResizable:YES];
		
		[view setDocumentView:self];
		
		
		// Disable word wrap
		NSSize bigSize = NSMakeSize(FLT_MAX, FLT_MAX);
		
		[[self enclosingScrollView] setHasHorizontalScroller:YES];
		[self setHorizontallyResizable:YES];
		[self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		
		[[self textContainer] setContainerSize:bigSize];
		[[self textContainer] setWidthTracksTextView:NO];
		
		//
		NoodleLineNumberView *lineNumberView = 
			[[NoodleLineNumberView alloc] initWithScrollView:view];
		
		[view setVerticalRulerView:lineNumberView];		
		[view setRulersVisible:YES];
		
		// Compute all the following rect arrays:
		fontBoundingRect = [font boundingRectForFont];
				
		NSDictionary *textAttr = 
		[NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
		nil];
		
		NSAttributedString *newLine = 
		   [[NSAttributedString alloc]initWithString:@"\n" attributes:textAttr];
		
		NSTextStorage *storage = [self textStorage];
		
		for( CCDiffLine *line in lcs )
		{
			NSAttributedString *attributedString;
			
			attributedString = 
				[[NSAttributedString alloc] initWithString:[line line] 
												attributes:textAttr];
			
			LineDiffStatus status = [line status];
			switch (status) 
			{
				case kLineAdded:
					if ( mask & CCDiffViewLineAdded )
					{
						[storage appendAttributedString:attributedString];
						[lines addObject: line];
					}
					else
					{
						[lines addObject:[CCDiffLine emptyLine:0]];
					}

					break;
				case kLineRemoved:
					if ( mask & CCDiffViewLineRemoved )
					{
						[storage appendAttributedString:attributedString];
						[lines addObject: line];
					}
					else
					{
						[lines addObject:[CCDiffLine emptyLine:0]];
					}
					break;
				default:
					if ( mask & CCDiffViewLineOriginal )
					{
						[storage appendAttributedString:attributedString];
						[lines addObject: line];
					}
					else
					{
						[lines addObject:[CCDiffLine emptyLine:0]];
					}
					break;
			}
			
			[storage appendAttributedString:newLine];
		}
		
		// Add
		// Remove
		// Original
		// Empty
		
		// use rect = [font boundingRectForFont];
	}
	return self;
}

-(void) dealloc
{
	[lines release];
	[font release];
	[super dealloc];
}

-(void) drawViewBackgroundInRect:(NSRect) rect
{
	[super drawViewBackgroundInRect:rect];
	
	NSUInteger startLine;
	NSUInteger endLine;
	NSUInteger index;
	
	NSUInteger charIndex;
/*
	startLine = rect.origin.y / fontBoundingRect.size.height;
	if ( startLine > 0 )
	{
		startLine --;
	}
	endLine = startLine + ( rect.size.height / fontBoundingRect.size.height );
	
//	[layoutManager boundingRectForGlyphRange:inTextContainer:]
*/	
	charIndex = 0;
		
//	for ( index = startLine; index < endLine; index ++ )
	for ( index = 0; index < [lines count]; index ++ )
	{
		CCDiffLine *line = [lines objectAtIndex:index];
		
		LineDiffStatus status = [line status];
				
		if ( ( status == kLineAdded ) || 
			 ( status == kLineRemoved ) || 
			 ( status == kLineEmpty ) )
		{
			NSRect rect = [[self layoutManager] 
				lineFragmentRectForGlyphAtIndex:charIndex effectiveRange:nil];
			
		
			NSBezierPath* path = [NSBezierPath bezierPath];
		
			[path appendBezierPathWithRoundedRect:rect xRadius:1.0 yRadius:1.0];
			
			
			if ( status == kLineAdded )
			{
				[[NSColor greenColor] set];
				[path fill];
			}
			else if ( status  == kLineRemoved )
			{
				[[NSColor redColor] set];
				[path fill];
			}
			else if ( status  == kLineEmpty )
			{
				[[NSColor grayColor] set];
				[path fill];
			}
		}
		 
		charIndex += [[line line] length] + 1;
	}
	
	// Draw a rounded corned box around the diff hunk.
	// Colors should be configurable.
/*	
	NSRect newRect = NSMakeRect(0, 0, rect.size.width, 100);
	
    [thePath appendBezierPathWithRoundedRect:newRect xRadius:15.0 yRadius:15.0];

	[[NSColor blackColor] set];
	[thePath stroke];

	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor greenColor] 
														 endingColor:[NSColor grayColor]];
	
	[gradient drawInBezierPath:thePath angle:90.0f];
//    [thePath fill];	
 */
}


@end
