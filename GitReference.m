//
//  GitReference.m
//  gitfend
//
//  Created by Manuel Astudillo on 8/4/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitReference.h"
#import "gitrepo.h"
#import "RegexKitLite.h"
#import "NSDataExtension.h"

NSString *regExpSym = @"ref:\\s(.+)";
NSString *regExpSha1 = @"([0-9a-f]{40})";

@implementation GitReference

@synthesize name;

-(id) initWithName:(NSString *) refName
{
	return [self initWithName:refName content:nil];
}

-(id) initWithName:(NSString *)refName content:(NSString *) refContent
{
	if (self = [super init] )
	{
		[refName retain];
		[refContent retain];
		
		name = refName;
		content = refContent;
	}
	return self;
}

-(void) dealloc
{
	[name release];
	[content release];
	[super dealloc];
}

-(void) setSymbolicReference:(GitReference*) reference
{
	[content release];
	content = [[NSString stringWithFormat:@"ref: %@", [reference name]] retain];
}

/**
 Resolves a reference and returns the resulting SHA1.
 
 Note: Only basic support for now. In the future a more complex pattern will
 be necessary.
 
 */	
-(NSData*) resolve:(GitRepo*) repo
{
	NSString *symbolicReference;
	NSString *sha1;
	
	symbolicReference = [self symbolicReference];
	
	if ( symbolicReference )
	{
		return 	[repo resolveReference: symbolicReference];
	}
	
	sha1 = [content stringByMatching:regExpSha1 capture:1L];
	
	if ( sha1 )
	{
		return [NSData dataWithHexString:sha1];
	}
	
	return nil;
}

-(NSString*) symbolicReference
{
	return  [content stringByMatching:regExpSym capture:1L];
}

-(NSString*) branch
{
	NSUInteger count;
	NSArray *pathComponents = [[self symbolicReference] pathComponents];
	
	count = [pathComponents count];
	
	if ( count )
	{
		return [pathComponents objectAtIndex:count - 1];
	}
	else
	{
		return nil;
	}
}

@end


