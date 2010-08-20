//
//  GitFrontRepositories.h
//  GitFront
//
//  Created by Manuel Astudillo on 5/15/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GitRepo;
@class GitFrontTree;


@interface GitFrontRepositoriesLeaf : NSObject
{
	GitRepo *repo;
	NSString *name;
	
	GitFrontTree *tree;
}

@property(readwrite, copy) NSString *name;
@property(readonly) GitRepo* repo;
@property(readonly) GitFrontTree* tree;


- (id) initWithRepo:(GitRepo*) repo icons:(NSDictionary*) icons;
- (void) dealloc;

- (NSImage*) icon;

@end


/**
	GitFrontRepositories.
 
	A class that represents the respository structure, 
    organized in groups.
 */

@interface GitFrontRepositories : NSObject <NSCoding> 
{
	NSString *name;
	NSMutableArray *children;
}

@property (readwrite, copy) NSString *name;
@property (readonly) NSMutableArray *children;



- (id) initWithName:(NSString*) name;
- (void) dealloc;

- (id) initWithCoder: (NSCoder *)coder;
- (void) encodeWithCoder: (NSCoder *)coder;

- (NSImage*) icon;

/**
	Adds a repo on the specified key path.
 
	If the key path is nil, then the repo will be added to the root.
 
	Note: The path must be valid, or the repo will not be added.
 */
- (void) addRepo:(GitRepo*) repo;
- (void) insertRepo:(GitRepo*) repo atIndex:(NSUInteger) index;

- (id) addGroup:(NSString*) groupName;
- (id) insertGroup:(NSString*) groupName atIndex:(NSUInteger) index;

- (void) insertNode:(id) node atIndex:(NSUInteger) index;
- (void) addNode:(id) node;

/**
	Returns the index where this item is located. Or -1 if not found.
 */
- (NSUInteger) indexOfChild:(id) item;

@end
