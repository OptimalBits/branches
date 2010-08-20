//
//  gitcommitobject.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/22/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gitcommitobject.h"
#import "RegexKitLite.h"
#import "NSDataExtension.h"

NSString *msgRegExp = @"\n\n((?s:.*))";
NSString *regExpTree = @"tree\\s([0-9a-f]{40})";
NSString *regExpParent = @"parent\\s([0-9a-f]{40})";
NSString *regExpAuthor = @"author\\s(.*)\\s(<(.*)>)\\s([0-9]+)\\s(((\\+)|(\\-))[0-9]+)";
NSString *regExpCommitter = @"committer\\s(.*)\\s(<(.*)>)\\s([0-9]+)\\s(((\\+)|(\\-))[0-9]+)";


@implementation GitAuthor

@synthesize name;
@synthesize email;
@synthesize time;
@synthesize offutc;

-(id) initWithName: _name email: _email andTime: _time
{
	if ( self = [super init] )
	{
		[self setName:_name];
		[self setEmail:_email];
		[self setTime:[NSDate dateWithTimeIntervalSince1970:[_time doubleValue]]];
	}
	
	return self;
}


@end

@implementation GitCommitObject

@synthesize tree;
@synthesize author;
@synthesize committer;
@synthesize parents;
@synthesize message;
@synthesize sha1;

- (id) initWithData: (NSData*) data sha1: (NSData*) key
{
	NSArray *matches;
	int count;

	if ( self = [super init] )
    {
		const char *_sha1;
				
		// fastestEncoding?
		
		NSString *commitString = 
			[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		if ( commitString == nil ) 
		// we need a more robust algorythm to parse commit messages...
		// since Cocoa just return nil if the string is not 100% UTF8 compliant.
		{
			[self dealloc];
			return nil;
		}
		
		[self setSha1:key];
		
		_sha1 = [[commitString stringByMatching:regExpTree capture:1L] cStringUsingEncoding:NSUTF8StringEncoding];
		tree = [NSData dataWithHexCString:_sha1];
		
		matches = [commitString arrayOfCaptureComponentsMatchedByRegex:regExpParent];
		
		parents = [[NSMutableArray alloc] init];
		for( NSArray *parentMatch in matches )
		{
			_sha1 = [[parentMatch objectAtIndex:1] cStringUsingEncoding:NSUTF8StringEncoding];
			[parents addObject:[NSData dataWithHexCString:_sha1]];
		}
		
		matches = [commitString arrayOfCaptureComponentsMatchedByRegex:regExpAuthor];
		count = [matches count];
		if ( count > 0 )
		{
			NSString *name = [[matches objectAtIndex:0] objectAtIndex:1];
			NSString *email = [[matches objectAtIndex:0] objectAtIndex:3];
			NSString *time = [[matches objectAtIndex:0] objectAtIndex:4];
		//	NSString *offutc = [[matches objectAtIndex:0] objectAtIndex:5];
			
			author = [[GitAuthor alloc] initWithName: name email: email andTime: time];
		}
		
		matches = [commitString arrayOfCaptureComponentsMatchedByRegex:regExpCommitter];
		count = [matches count];
		if ( count > 0 )
		{
			NSString *name = [[matches objectAtIndex:0] objectAtIndex:1];
			NSString *email = [[matches objectAtIndex:0] objectAtIndex:3];
			NSString *time = [[matches objectAtIndex:0] objectAtIndex:4];
		//	NSString *offutc = [[matches objectAtIndex:0] objectAtIndex:5];
			
			committer = [[GitAuthor alloc] initWithName: name email: email andTime: time];
		}
		
		matches = [commitString arrayOfCaptureComponentsMatchedByRegex:msgRegExp];
		count = [matches count];
		if ( count > 0 )
		{
			[self setMessage:[NSString stringWithString:[commitString stringByMatching:msgRegExp capture:1L]]];
		}
	}
	
	return self;
}

- (BOOL) isEqual:(id)object
{
	return [[self sha1] isEqualToData: [object sha1]];
}

-(NSUInteger) hash
{
	return *((NSUInteger*)[[self sha1] bytes]);
}

-(NSComparisonResult) compareDate:(GitCommitObject*) obj
{
	return [[[obj author] time] compare:[[self author] time]];
}

@end
