//
//  GitIgnore.m
//  gitfend
//
//  Created by Manuel Astudillo on 11/29/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import  "GitIgnore.h"
#include "fnmatch.h"
#include "glob.h"


@interface GitIgnore(Private)

-(BOOL) ignoreCheck:(NSString*) filename beingIgnored:(BOOL) ignored;

@end


@implementation GitIgnore

-(id) init
{
	return [self initWithUrl:nil];
}

-(id) initWithUrl:(NSURL*) _url
{
	if ( self = [super init] )
	{
		NSError *error;
		
		if ( _url )
		{
			url = _url;
			[url retain];
		
			path = [[url URLByDeletingLastPathComponent] path];
			[path retain];
		}
		
		patterns = [[NSMutableArray alloc] init];
		stack = [[NSMutableArray alloc] init];
		
		NSCharacterSet *newLineCharSet = [NSCharacterSet newlineCharacterSet];
		
		if ( url )
		{
			NSString *content = [NSString stringWithContentsOfURL:url 
														 encoding:NSUTF8StringEncoding
															error:&error];
			NSArray *lines = 
			[content componentsSeparatedByCharactersInSet:newLineCharSet];
			
			// Remove comments and empty lines.
			for ( NSString *line in lines )
			{
				NSString *s;
				
				s = [line stringByTrimmingCharactersInSet:
					 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				if ( ([s length] > 0) && ( [s hasPrefix:@"#"] == NO ) )
				{
					[patterns addObject:s];
				}
			}
		}
	}

	return self;
}
				
-(void) dealloc
{
	[patterns release];
	[stack release];
	[super dealloc];
}

/**
 Patterns have the following format:
 
 - A blank line matches no files, so it can serve as a separator for 
   readability.
 
 - A line starting with # serves as a comment.
 
 - An optional prefix ! which negates the pattern; any matching file excluded 
   by a previous pattern will become included again. If a negated pattern 
   matches, this will override lower precedence patterns sources.
 
 - If the pattern ends with a slash, it is removed for the purpose of the 
   following description, but it would only find a match with a directory. 
   In other words, foo/ will match a directory foo and paths underneath it, 
   but will not match a regular file or a symbolic link foo (this is consistent 
   with the way how pathspec works in general in git).
 
 - A leading slash matches the beginning of the pathname. For example, "/*.c"
   matches "cat-file.c" but not "mozilla-sha1/sha1.c".
 
 - If the pattern does not contain a slash /, git treats it as a shell glob 
   pattern and checks for a match against the pathname relative to the location 
   of the .gitignore file (relative to the toplevel of the work tree if not 
   from a .gitignore file).
 
 - Otherwise, git treats the pattern as a shell glob suitable for consumption 
   by fnmatch(3) with the FNM_PATHNAME flag: wildcards in the pattern will not 
   match a / in the pathname. For example, "Documentation/*.html" matches
   "Documentation/git.html" but not "Documentation/ppc/ppc.html" or 
   "tools/perf/Documentation/perf.html".
  
 */

-(BOOL) isFileIgnored:(NSString*) filename
{
	BOOL ignored = NO;

	if ( [patterns count] )
	{
		ignored = [self ignoreCheck:filename beingIgnored:NO];
	}
	
	for ( GitIgnore *ignoreFile in stack )
	{
		ignored = [ignoreFile ignoreCheck:filename beingIgnored:ignored];
	}
	
	return ignored;
}

/**
	Checks if given filename should be ignored. 
 
	@param filename
	@param ignored If the file has already been ignored or not.
 
 */
-(BOOL) ignoreCheck:(NSString*) filename beingIgnored:(BOOL) ignored
{
	BOOL isDirectory;
	const char* pathNameString;
	const char* nameString;
	
	uint32_t start = [path length]+1;
	uint32_t length= [filename length] - start;
	
	if ( [filename hasSuffix:@"/"] )
	{
		isDirectory = YES;
		length --;
	}
	else
	{
		isDirectory = NO;
	}
	
	NSString *pathname = [filename substringWithRange:NSMakeRange(start, length)];
	pathNameString = [pathname UTF8String];
	
	NSString *name = [filename lastPathComponent];
	nameString = [name UTF8String];

	for ( NSString *pattern in patterns )
	{		
		BOOL useName;
		BOOL negated;
		
		useName = YES;
		negated = NO;
		
		if ( [pattern hasSuffix:@"/"] )
		{
			if ( isDirectory == YES )
			{
				pattern = [pattern substringToIndex:[pattern length]-1];
			}
			else
			{
				continue;
			}
		}
		
		if ( ignored )
		{
			if ( [pattern hasPrefix:@"!"] )
			{
				pattern = [pattern substringFromIndex:1];
				negated = YES;
			}
			else
			{
				continue;
			}
		}

		if ( [pattern hasPrefix:@"/"] )
		{
			useName = NO;
			pattern = [pattern substringFromIndex:1];
		}
			
		if ( fnmatch([pattern UTF8String], pathNameString, FNM_PATHNAME) != FNM_NOMATCH )
		{
			if ( negated )
			{
				ignored = NO;
			}
			else
			{
				ignored = YES;
			}
		}
		else if ( useName )
		{
			if ( fnmatch([pattern UTF8String], nameString, FNM_PATHNAME) != FNM_NOMATCH )
			{
				if ( negated )
				{
					ignored = NO;
				}
				else
				{
					ignored = YES;
				}
			}
		}
	}
	
	return ignored;
}

-(void) push:(GitIgnore*) gitIgnore
{
	[stack addObject:gitIgnore];
}

-(void) pop
{
	if ( [stack count] )
	{
		[stack removeLastObject];
	}
	else 
	{
		[self release];
	}
}

@end



