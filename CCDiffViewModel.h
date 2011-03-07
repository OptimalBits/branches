//
//  CCDiffViewModel.h
//  gitfend
//
//  Created by Manuel Astudillo on 1/2/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
	This class represents the model behind a Diff View.
 
 
 */
@interface CCDiffViewModel : NSObject {
	
	NSMutableArray *leftLines;
	NSMutableArray *rightLines;
}

@property (readonly) NSMutableArray* leftLines;
@property (readonly) NSMutableArray* rightLines;

-(id) initWithDiffLines:(NSArray*) lines;

@end
