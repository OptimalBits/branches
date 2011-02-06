//
//  OBSDirectory.m
//  Unify
//
//  Created by Manuel Astudillo on 1/26/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "OBSDirectory.h"

#include <dirent.h>
#include <sys/stat.h>

@implementation OBSDirectoryEntry

@synthesize path;
@synthesize children;
@synthesize fileStatus;

-(id) initWithPath:(NSString*) _path
		  children:(NSMutableDictionary*) _children 
			  stat:(struct stat) _fileStatus
{
	if ( self = [super init] )
	{
		path = _path;
		[path retain];
		
		children = _children;
		[children retain];
		
		fileStatus = _fileStatus;
	}
	return self;
}

-(void) dealloc
{
	[path release];
	[children release];
	[super dealloc];
}


-(NSData*) contentsOfChild:(NSString*) childFilename
{
	OBSDirectoryEntry *childEntry = [children objectForKey:childFilename];
	
	if ( childEntry )
	{
		return [NSData dataWithContentsOfMappedFile:
					[path stringByAppendingPathComponent:childFilename]];
	}
	else
	{
		return nil;
	}
}

-(NSUInteger) size
{
	return fileStatus.st_size;
}

-(NSDate*) modificationDate
{
	float t = fileStatus.st_mtimespec.tv_sec;
	return [NSDate dateWithTimeIntervalSince1970:t];
}

-(void) setEntry:(OBSDirectoryEntry*) entry forPath:(NSString*) path
{
	
}

-(void) deleteEntry:(NSString*) path
{

}

@end

@implementation OBSDirectoryComparedNode

@synthesize status;
@synthesize leftEntry;
@synthesize rightEntry;

-(id) initWithLeftEntry:(OBSDirectoryEntry*) _leftEntry
				  right:(OBSDirectoryEntry*) _rightEntry
				 status:(OBSDirectoryCompareStatus) _status
{
	if ( self = [super init] )
	{
		leftEntry = _leftEntry;
		rightEntry = _rightEntry;

		[leftEntry retain];
		[rightEntry retain];

		status = _status;
	}
	return self;
}

-(void) dealloc
{
	[leftEntry release];
	[rightEntry release];
	[super dealloc];
}

@end


@interface OBSDirectory (Private)

- (void) getDirectoryContents:(NSString*) path 
					  onArray:(NSMutableArray*) subPaths;

- (NSMutableDictionary*) createDirectoryTree:(NSString*) _path;

-(void) compareDirectoryEntry:(OBSDirectoryEntry*) leftEntry
						 with:(OBSDirectoryEntry*) rightEntry
					  onArray:(NSMutableArray*) mutableChildNodes;

@end


@implementation OBSDirectory

@synthesize root;

-(id) initWithPath:(NSString*) path
{
	if ( self = [super init] )
	{
		struct stat file_stat;
				
		if ( stat( [path UTF8String], &file_stat ) == 0 )
		{
			root = [[OBSDirectoryEntry alloc] 
					initWithPath:path
						children:[self createDirectoryTree:path]
							stat:file_stat];
		}
	}
	return self;
}

-(void) dealloc
{
	[root release];
	[super dealloc];	
}

- (id)initWithCoder:(NSCoder *)decoder
{ 
	NSString *path = [decoder decodeObjectForKey:@"path"];
	return [self initWithPath:path];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:[root path] forKey:@"path"];
}


-(NSTreeNode*) compareDirectory:(OBSDirectory*) directory
{
	NSTreeNode *tree;
	OBSDirectoryComparedNode *comparedNode;
	
	comparedNode = [[OBSDirectoryComparedNode alloc] 
					initWithLeftEntry:[self root]
								right:[directory root]
							   status:kOBSFileOriginal];
	
	tree = [NSTreeNode treeNodeWithRepresentedObject:comparedNode];
	[comparedNode release];
	
	[self compareDirectoryEntry:[self root] 
						   with:[directory root] 
						onArray:[tree mutableChildNodes]];
	
	return tree;
}

// TODO: this function should return a OBSDirectoryCompareStatus
-(void) compareDirectoryEntry:(OBSDirectoryEntry*) leftEntry
						 with:(OBSDirectoryEntry*) rightEntry
					  onArray:(NSMutableArray*) mutableChildNodes
{
	NSDictionary *leftChildren = [leftEntry children];
	NSDictionary *rightChildren = [rightEntry children];
	
	NSSet *allChildren = [[NSSet setWithArray:[leftChildren allKeys]] 
						  setByAddingObjectsFromArray:[rightChildren allKeys]];
	
	for ( NSString *p in allChildren )
	{
		NSTreeNode *treeNode;
		
		OBSDirectoryCompareStatus compareStatus;
		OBSDirectoryComparedNode *comparedNode;
		
		OBSDirectoryEntry *leftEntryChild;
		OBSDirectoryEntry *rightEntryChild;
		
		leftEntryChild = [leftChildren objectForKey:p];
		rightEntryChild = [rightChildren objectForKey:p];
		
		if ( leftEntryChild == nil )
		{
			compareStatus = kOBSFileAdded;
		}
		else if ( rightEntryChild == nil )
		{
			compareStatus = kOBSFileRemoved;
		}
		else
		{
			if ( [leftEntryChild fileStatus].st_size != 
				 [rightEntryChild fileStatus].st_size )
			{
				compareStatus = kOBSFileModified;
			}
			else
			{
				// Read and compare files byte by byte
				NSData *leftFile = [leftEntry contentsOfChild:p];
				NSData *rightFile = [rightEntry contentsOfChild:p];
				
				if ( [leftFile isEqualToData:rightFile] )
				{
					compareStatus = kOBSFileOriginal;
				}
				else
				{
					compareStatus = kOBSFileModified;
				}
			}
		}
		
		comparedNode = 
			[[OBSDirectoryComparedNode alloc] initWithLeftEntry:leftEntryChild 
														  right:rightEntryChild
														 status:compareStatus];
		
		treeNode = [NSTreeNode treeNodeWithRepresentedObject:comparedNode];
		
		[self compareDirectoryEntry:leftEntryChild 
							   with:rightEntryChild 
							onArray:[treeNode mutableChildNodes]];
		
		[comparedNode release];
		[mutableChildNodes addObject:treeNode];
	}
}

-(NSMutableDictionary*) createDirectoryTree:(NSString*) _path
{	
	NSMutableDictionary *entries = nil;
	NSMutableArray *subPaths;
	
	subPaths = [NSMutableArray array];
	
	[self getDirectoryContents:_path onArray:subPaths];

	if ( [subPaths count] )
	{
		entries = [NSMutableDictionary dictionary];
	}
	
	for ( NSString *p in subPaths )
	{
		OBSDirectoryEntry *entry;
		NSMutableDictionary *children;
		struct stat file_status;
		
		children = nil;
		
		if ( stat([p UTF8String], &file_status) == 0 )
		{
			if ( file_status.st_mode & S_IFDIR )
			{
				children = [self createDirectoryTree:p];
			}
		
			entry = [[OBSDirectoryEntry alloc] initWithPath:p
												   children:children 
													   stat:file_status];
			[entries setObject:entry forKey:[p lastPathComponent]];
			
			[entry release];
		}
	}
	
	return entries;
}

-(void) getDirectoryContents:(NSString*) _path 
					 onArray:(NSMutableArray*) subPaths
{	
	struct dirent **name_list = 0;
	
	const char *string = [_path UTF8String];
	
	int (^file_select)(struct dirent *) = ^int (struct dirent *d)
	{
		char *s = d->d_name;
		
		if ( s[0] == '.' )
		{
			if ( ( s[1] == '.' ) && ( s[2] == 0 ) )
			{
				return 0;
			}
			else if ( s[1] == 0 )
			{
				return 0;
			}
			else if ( strcmp(s, ".git") == 0 )
			{
				return 0;
			}
		}
		
		NSString *filename = [[NSString alloc]initWithUTF8String:s];
		NSString *subPath = [_path stringByAppendingPathComponent:filename];
		
		[subPaths addObject:subPath];
		
		[filename release];
		
		return 0;
	};
	

	int result = scandir_b(string, &name_list, file_select, 0);
	
	if ( result < 0 )
	{
		NSLog(@"Error path: %@", _path);
	}
	
	free( name_list );
}

@end


