//
//  GitReference.m
//  gitfend
//
//  Created by Manuel Astudillo on 8/4/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitReference.h"
#import "GitReferenceStorage.h"
#import "RegexKitLite.h"
#import "NSDataExtension.h"

NSString *regExpSym = @"ref:\\s(.+)";
NSString *regExpSha1 = @"([0-9a-f]{40})";

@implementation GitReference

@synthesize name;
@synthesize path;
@synthesize sha1;
@synthesize symbolicReference;

-(id) initWithName:(NSString *) refName
{
	return [self initWithName:refName content:nil];
}

-(id) initWithName:(NSString *)refName 
		   content:(NSString *)refContent
{
	return [self initWithName:refName content:refContent path:nil];
}

-(id) initWithName:(NSString *) refName 
		   content:(NSString *) content 
			  path:(NSString*) _path
{
	if (self = [super init] )
	{		
		NSString *sha1String = [content stringByMatching:regExpSha1 capture:1L];
		
		if ( sha1String )
		{
			sha1 =  [NSData dataWithHexString:sha1String];
		}
		else
		{
			sha1 = nil;
		}

		symbolicReference = [content stringByMatching:regExpSym capture:1L];
		
		name = refName;
		path = _path;
		
		[name retain];
		[path retain];
		[sha1 retain];
		[symbolicReference retain];
	}
	return self;
}

-(void) dealloc
{
	[name release];
	[path release];
	[sha1 release];
	[symbolicReference release];
	[super dealloc];
}

/*
-(void) writeSymbolicReference:(GitReference*) reference
{
	[[NSString stringWithFormat:@"ref: %@", [reference name]] retain];
}
*/


-(void) setSymbolicReference:(GitReference*) reference
{
	
}

/**
 Resolves a reference and returns the resulting SHA1.
 
 Note: Only basic support for now. In the future a more complex pattern will
 be necessary.
 
 */	
-(NSData*) resolve:(GitReferenceStorage*) refStorage
{	
	if ( symbolicReference )
	{
		return 	[refStorage resolveReference: symbolicReference];
	}
	
	return [self sha1];
}


-(NSString*) branch
{
	NSUInteger count;
	NSArray *pathComponents = [symbolicReference pathComponents];
	
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


