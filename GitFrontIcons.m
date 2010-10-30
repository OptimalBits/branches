//
//  GitFrontIcons.m
//  gitfend
//
//  Created by Manuel Astudillo on 8/16/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitFrontIcons.h"

static NSImage *getBundlePngImage(NSString * pngImageName);

@implementation GitFrontIcons

+(NSDictionary*) icons
{
  static NSDictionary *iconsDict = nil;

  if ( !iconsDict )
  {
	  NSBundle *bundle = [NSBundle mainBundle];
	  
	  NSURL *remotesImageUrl  = [bundle URLForResource:@"server_database" withExtension:@"png"];
	  NSImage *remoteImage = [[[NSImage alloc] initWithContentsOfURL:remotesImageUrl] autorelease];
	  
	  NSURL *branchImageUrl  = [bundle URLForResource:@"arrow_branch" withExtension:@"png"];
	  NSImage *branchImage = [[[NSImage alloc] initWithContentsOfURL:branchImageUrl] autorelease];
	  
	  NSURL *tagsImageUrl  = [bundle URLForResource:@"tags-label" withExtension:@"png"];
	  NSImage *tagsImage = [[[NSImage alloc] initWithContentsOfURL:tagsImageUrl] autorelease];
	  
	  NSURL *tagImageUrl  = [bundle URLForResource:@"tag-label" withExtension:@"png"];
	  NSImage *tagImage = [[[NSImage alloc] initWithContentsOfURL:tagImageUrl] autorelease];
	  
	  
	  NSURL *stashImageUrl  = [bundle URLForResource:@"page_save" withExtension:@"png"];
	  NSImage *stashImage = [[[NSImage alloc] initWithContentsOfURL:stashImageUrl] autorelease];
	  
	  NSURL *folderImageUrl  = [bundle URLForResource:@"folder" withExtension:@"png"];
	  NSImage *folderImage = [[[NSImage alloc] initWithContentsOfURL:folderImageUrl] autorelease];
	  
	  NSURL *gitImageUrl  = [bundle URLForResource:@"git" withExtension:@"png"];
	  NSImage *gitImage = [[[NSImage alloc] initWithContentsOfURL:gitImageUrl] autorelease];
	  
	  NSURL *headImageUrl  = [bundle URLForResource:@"folder_go" withExtension:@"png"];
	  NSImage *headImage = [[[NSImage alloc] initWithContentsOfURL:headImageUrl] autorelease];
	  
	  NSURL *blueFolderImageUrl  = [bundle URLForResource:@"blue-folders-stack" 
											withExtension:@"png"];
	  NSImage *blueFolderImage = [[[NSImage alloc] initWithContentsOfURL:blueFolderImageUrl] autorelease];
	 
	  NSURL *addImageUrl  = [bundle URLForResource:@"add" 
									 withExtension:@"png"];
	  NSImage *addImage = [[[NSImage alloc] initWithContentsOfURL:addImageUrl] autorelease];
	  
	  NSURL *deleteImageUrl  = [bundle URLForResource:@"delete" 
									 withExtension:@"png"];
	  NSImage *deleteImage = [[[NSImage alloc] initWithContentsOfURL:deleteImageUrl] autorelease];
	 
	  NSURL *tickImageUrl  = [bundle URLForResource:@"tick" 
									 withExtension:@"png"];
	  NSImage *tickImage = [[[NSImage alloc] initWithContentsOfURL:tickImageUrl] autorelease];
	  
	  NSURL *renameImageUrl  = [bundle URLForResource:@"pencil" 
									 withExtension:@"png"];
	  NSImage *renameImage = [[[NSImage alloc] initWithContentsOfURL:renameImageUrl] autorelease];
	  
	  NSURL *exclamationImageUrl  = [bundle URLForResource:@"exclamation" 
										withExtension:@"png"];
	  NSImage *exclamationImage = [[[NSImage alloc] initWithContentsOfURL:exclamationImageUrl] autorelease];
	  
	  iconsDict = [[NSDictionary dictionaryWithObjectsAndKeys:
							 remoteImage, @"remote",
							 branchImage, @"branch",
							 tagsImage, @"tags",
						     tagImage, @"tag",
							 stashImage, @"stash",
							 folderImage, @"folder",
							 gitImage, @"git",
							 headImage, @"head",
							 blueFolderImage,@"folderStack",
							 addImage,@"add",
							 deleteImage,@"delete",
							 tickImage,@"tick",
							 renameImage,@"rename",
							 exclamationImage,@"exclamation",
							 getBundlePngImage(@"question"), @"question",
							 nil ] retain];
	  
	  //remotesIcon = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFileServerIcon)] retain];
	  //[remotesIcon setSize:NSMakeSize(16,16)];
  }
	
  return iconsDict;
}


NSImage *getBundlePngImage(NSString * pngImageName)
{
	NSBundle *bundle = [NSBundle mainBundle];
	
	NSURL *url  = [bundle URLForResource:pngImageName withExtension:@"png"];
	NSImage *image = [[[NSImage alloc] initWithContentsOfURL:url] autorelease];
	
	return image;
}



@end
