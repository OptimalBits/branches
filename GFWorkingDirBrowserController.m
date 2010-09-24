//
//  GFWorkingDirBrowserController.m
//  GitFront
//
//  Created by Manuel Astudillo on 8/17/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GFWorkingDirBrowserController.h"
#import "CCDiffViewController.h"

#import "GitRepo.h"
#import "GitReference.h"
#import "GitIndex.h"
#import "GitBlobObject.h"
#import "GitFile.h"
#import "GitFrontIcons.h"

#import "ImageAndTextCell.h"

@implementation GFWorkingDirBrowserController

- (id) init
{
	if ( self = [super initWithNibName:@"WorkingDirBrowser" bundle:nil] )
    {
		fileManager = [[NSFileManager alloc] init];

		[self setTitle:@"GitFront - Browser"];
		
		icons = [GitFrontIcons icons];
		
	}
	return self;
}

- (void) dealloc
{
	[fileManager release];
	[repo release];
}


- (void) awakeFromNib
{
	NSTableColumn *tableColumn;
	ImageAndTextCell *imageAndTextCell;
		
	tableColumn = [workingDirBrowseView tableColumnWithIdentifier:@"Status"];
	
	imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
	
	tableColumn = [stageAreaBrowseView tableColumnWithIdentifier:@"Main"];
	
	imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
}


-(NSTreeNode*) treeFromStatus:(NSDictionary*) tree object:(id) object
{
	if ( object == nil )
	{
		object = @"furls";
	}
	
	NSTreeNode *result = [NSTreeNode treeNodeWithRepresentedObject:object];

	NSMutableArray *children = [result mutableChildNodes];
	
	for ( NSString *key in tree )
	{
		NSTreeNode *child;
		id node = [tree objectForKey:key];
	
		if ( [node isKindOfClass:[NSDictionary class]] )
		{
			child = [self treeFromStatus:node object:key];
		}
		else
		{
			GitFile *file = node;
			
			child = [NSTreeNode treeNodeWithRepresentedObject:file];
		}
		
		[children addObject:child];
	}
	
	return result;
}


- (void) setRepo:(GitRepo*) _repo
{
	[_repo retain];
	repo = _repo;
	
	GitIndex *index = [repo index];
		
	modifiedFiles = [[index modifiedFiles:[repo workingDir]] retain];

	[workingDirBrowseView reloadData];

	///
	
	NSData *headSha1 = [[repo head] resolve:repo];
	GitTreeObject *tree = [[repo objectStore] getTreeFromCommit:headSha1];
	
	headTree = [[[repo objectStore] flattenTree:tree] retain];
	
	// Update status
	statusTree = [[self treeFromStatus:[index status:headTree] 
								object:nil] retain];
	
	[stageAreaBrowseView reloadData];
}

- (IBAction) addFile:(id) sender
{
	NSURL *url = 
		[workingDirBrowseView itemAtRow:[workingDirBrowseView selectedRow]];
	
	NSString *filename = 
		[[url path] substringFromIndex:[[[repo workingDir] path] length]+1];
	
//	if ( [modifiedFiles containsObject:filename] )
	{
		NSData *fileContents = [NSData dataWithContentsOfURL:url];
	
		GitBlobObject *object = 
			[[[GitBlobObject alloc] initWithData:fileContents] autorelease];
	
		NSData *sha1 = [[repo objectStore] addObject:object];
	
		if ( sha1 == nil )
		{
			// Show alert window!
		}
		else
		{
			[[repo index] addFile:filename sha1:sha1];
		}
		
		[modifiedFiles release];
		modifiedFiles = [[[repo index] modifiedFiles:[repo workingDir]] retain];
		
		[workingDirBrowseView reloadData];
		
		// Update status
		statusTree = [[self treeFromStatus:[[repo index] status:headTree] 
								   object:nil] retain];
		
		[stageAreaBrowseView reloadData];
	}
}


- (void) setDiffView:(CCDiffViewController*) _diffView
{
	diffView = _diffView;
}


//
// OutlineView datasource.
//

- (id)outlineView:(NSOutlineView *)outlineView 
			child:(NSInteger)index 
		   ofItem:(id)item
{
	if ( repo == nil )
	{
		return nil;
	}
	
	if ( outlineView == workingDirBrowseView )
	{
		NSError *error;
		NSURL *url;
		NSArray *subPaths;
		
		if ( item == nil )
		{
			url = [repo workingDir];
		}
		else
		{
			url = item;
		}
		
		subPaths = 
		[fileManager contentsOfDirectoryAtURL:url 
				   includingPropertiesForKeys:nil 
									  options:NSDirectoryEnumerationSkipsHiddenFiles 
										error:&error];
		if ( subPaths )
		{
			NSURL *u = [[subPaths objectAtIndex:index] retain];
			return u;
		}
	}
	else if ( outlineView == stageAreaBrowseView )
	{
		if ( item == nil )
		{
			return [[statusTree childNodes] objectAtIndex:index];
		}		
		else
		{
			return [[item childNodes] objectAtIndex:index];
		}
	}
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
	if ( outlineView == workingDirBrowseView )
	{
		if ( item )
		{
			NSError *error;
			NSURL *url = item;
			NSArray *subPaths = 
			[fileManager contentsOfDirectoryAtURL:url 
					   includingPropertiesForKeys:nil 
										  options:NSDirectoryEnumerationSkipsHiddenFiles 
											error:&error];
			
			NSLog(@"Path: %@", [url description]);
			
			if ( subPaths )
			{
				if ( [subPaths count] > 0)
				{
					return YES;
				}
			}
		}
	}
	else if ( outlineView == stageAreaBrowseView )
	{
		if ( item == nil )
		{
			if ( [[statusTree childNodes] count] > 0 )
			{
				return YES;
			}
		}
		
		if ([[item childNodes] count] > 0 )
		{
			return YES;
		}
	}
	
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView 
  numberOfChildrenOfItem:(id)item
{
	if ( repo == nil )
	{
		return 0;
	}	
	
	if ( outlineView == workingDirBrowseView )
	{
		NSError *error;
		NSURL *url;
		NSArray *subPaths;
		
		if ( item == nil )
		{
			url = [repo workingDir];
		}
		else
		{
			url = item;
		}
		
		subPaths = 
		[fileManager contentsOfDirectoryAtURL:url 
				   includingPropertiesForKeys:nil 
									  options:NSDirectoryEnumerationSkipsHiddenFiles 
										error:&error];
		if ( subPaths )
		{
			return [subPaths count];
		}
	}
	else if( outlineView == stageAreaBrowseView )
	{
		if ( item == nil )
		{
			return [[statusTree childNodes] count];
		}
		else
		{
			return [[item childNodes] count];
		}
	}
	
	return 0;
}

- (void)outlineView:(NSOutlineView *)olv 
	willDisplayCell:(NSCell*)cell 
	 forTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{	 
	ImageAndTextCell* iconCell = (ImageAndTextCell*) cell;
	
	if( olv == workingDirBrowseView )
	{
		if ([[[tableColumn headerCell] stringValue] compare:@"Status"] == NSOrderedSame) 
		{
			NSString *filename = 
			[[item path] substringFromIndex:[[[repo workingDir] path] length]+1];
			
			if ( [modifiedFiles containsObject:filename] )
			{
				[iconCell setImage:[icons objectForKey:@"exclamation"]];
			}
			else if ( [[repo index] isFileTracked: filename] )
			{
				//return @"T";
				[iconCell setImage:[icons objectForKey:@"tick"]];
			}
			else
			{
				[iconCell setImage:nil];
			}
		}
	}
	else if( olv == stageAreaBrowseView )
	{
		if ([[tableColumn identifier] isEqualToString:@"Main"])
		{
			if ([cell isKindOfClass:[ImageAndTextCell class]])
			{
				id obj = [item representedObject];
				
				if ( [obj isKindOfClass:[GitFile class]] )
				{
					GitFile *gitFile = obj;
					
					if ( [gitFile status] == kFileStatusAdded )
					{
						[iconCell setImage:[icons objectForKey:@"add"]];
					}
					else if ( [gitFile status] == kFileStatusRemoved )
					{
						[iconCell setImage:[icons objectForKey:@"delete"]];
					}
					else if ( [gitFile status] == kFileStatusUpdated )
					{
						[iconCell setImage:[icons objectForKey:@"tick"]];
					}
					else if ( [gitFile status] == kFileStatusRenamed )
					{
						[iconCell setImage:[icons objectForKey:@"rename"]];
					}
					else
					{
						[iconCell setImage:nil];
					}

				}
			}
		}
	}
}


- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
		   byItem:(id)item
{
	if ( outlineView == workingDirBrowseView )
	{
		if ([[[tableColumn headerCell] stringValue] compare:@"Name"] == NSOrderedSame) 
		{
			return [item lastPathComponent];
		}
		
		if ([[[tableColumn headerCell] stringValue] compare:@"Status"] == NSOrderedSame) 
		{
			/*NSString *filename = 
			[[item path] substringFromIndex:[[[repo workingDir] path] length]+1];
			
			return @"U";*/
		}
	}
	else if( outlineView == stageAreaBrowseView )
	{
		if ([[[tableColumn headerCell] stringValue] compare:@"Staged files"] == NSOrderedSame) 
		{
			NSString *text;
			id obj = [item representedObject];
			
			if ( [obj isKindOfClass:[GitFile class]] )
			{
				GitFile *gitFile = obj;
				text = [gitFile filename];
			}
			else
			{
				text = obj;
			}
			
			return text;
		}
	}
	
	return @"";
}

- (void)outlineView:(NSOutlineView *)outlineView 
	 setObjectValue:(id)object 
	 forTableColumn:(NSTableColumn *)tableColumn 
			 byItem:(id)item
{
	// pass
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	id item = [workingDirBrowseView itemAtRow:[workingDirBrowseView selectedRow]];
	
	NSLog(@"Selection did change");
	NSLog(@"Selected: %@", item);
	
	BOOL isDirectory;
	
	[fileManager fileExistsAtPath:[item path] isDirectory:&isDirectory];
	
	if (isDirectory == NO)
	{
		NSError *error;
		NSString *contents = [NSString stringWithContentsOfFile:[item path]
													   encoding:NSUTF8StringEncoding
														  error:&error];
		NSString *filename = 
			[[item path] substringFromIndex:[[[repo workingDir] path] length]+1];
		
		GitIndex *index = [repo index];
		if ( [index isFileTracked:filename] &&
			 [modifiedFiles containsObject:filename] )
		{
			GitBlobObject *obj = 
				[repo getObject:[index sha1ForFilename:filename]];

			NSString *before = [[NSString alloc ] initWithBytes:[[obj data] bytes]
														 length:[[obj data] length]
													   encoding:NSUTF8StringEncoding];
			
			[diffView setStringsBefore:before andAfter:contents];
			NSLog(@"niaaadasd",nil);
		}
	}
}

@end


