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
@synthesize gmtSeconds;

-(id) initWithName: _name email: _email andTime: _time
{
	if ( self = [super init] )
	{
		[self setName:_name];
		[self setEmail:_email];
		[self setTime:[NSDate dateWithTimeIntervalSince1970:[_time doubleValue]]];

		// Todo compute hourse+seconds to seconds
		[self setGmtSeconds:0];
	}
	
	return self;
}

// TODO: <TZ_OFFSET_SIGN> <TZ_OFFSET_HOURS> <TZ_OFFSET_MIN>
//
//
//  NSTimeZone ( create it using UTC value ( GMT is the same )->
//  timeZoneForSecondsFromGMT
//  NSCalender setTimeZone
//  NSDate
//
// [[[NSCalendar currentCalendar] timeZone] secondsFromGMT]

-(NSString*) encode:(NSString*) user
{
	return [NSString stringWithFormat:@"%@ %@ <%@> %d -0000\n",
									  user,
									  name,
									  email,
									  (u_int64_t)[time timeIntervalSince1970]];
}


@end


static NSString* encodeParents( NSArray *parents );

@implementation GitCommitObject

@synthesize tree;
@synthesize author;
@synthesize committer;
@synthesize parents;
@synthesize message;
@synthesize sha1;

- (id) initWithTree:(NSData*) _tree 
			parents:(NSArray*) _parents
			message:(NSString*) _message
			 author:(GitAuthor*) _author
		   commiter:(GitAuthor*) _commiter
{
	if ( self = [super initWithType:@"commit"] )
	{
		[self setTree:_tree];
		[self setParents:_parents]; 
		[self setMessage:_message];
		[self setAuthor:_author];
		[self setCommitter:_author];
	}
	return self;
}


- (id) initWithData: (NSData*) data sha1: (NSData*) key
{
	NSArray *matches;
	int count;

	if ( self = [super initWithType:@"commit"] )
    {
		const char *_sha1;
				
		// fastestEncoding?
		
		NSString *commitString = 
			[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		if ( commitString == nil ) 
		// we need a more robust algorithm to parse commit messages...
		// since Cocoa just return nil if the string is not 100% UTF8 compliant.
		{
			[self dealloc];
			return nil;
		}
		
		[self setSha1:key];
		
		_sha1 = [[commitString stringByMatching:regExpTree capture:1L] cStringUsingEncoding:NSUTF8StringEncoding];
		if ( _sha1 )
		{
			[self setTree:[NSData dataWithHexCString:_sha1]];
		}
		else
		{
			[self dealloc];
			return nil;
		}

		
		matches = [commitString arrayOfCaptureComponentsMatchedByRegex:regExpParent];
		
		NSMutableArray *mutableParents = 
			[[[NSMutableArray alloc] init] autorelease];
		for( NSArray *parentMatch in matches )
		{
			_sha1 = [[parentMatch objectAtIndex:1] cStringUsingEncoding:NSUTF8StringEncoding];
			[mutableParents addObject:[NSData dataWithHexCString:_sha1]];
		}
		[self setParents:mutableParents];
		
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
			[self setMessage:[NSString stringWithString:
							  [commitString stringByMatching:msgRegExp 
													 capture:1L]]];
		}
	}
	
	return self;
}

-(void) dealloc
{
	[parents release];
	[tree release];
	[message release];
	[author release];
	[committer release];
	
	[super dealloc];
}

-(NSData*) data
{
	NSString *format = @"tree %@\n%@%@%@\n%@";
	
	NSString *commit = [NSString stringWithFormat:format, 
												  [tree base16String],
												  encodeParents(parents),
												  [author encode:@"author"],
												  [committer encode:@"committer"],
												  message];
	
	return [commit dataUsingEncoding:NSUTF8StringEncoding];
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

static NSString* encodeParents( NSArray *parents )
{
	NSMutableString *string = [[[NSMutableString alloc] init] autorelease];
	
	for ( NSData *parent in parents )
	{
		[string appendFormat:@"parent %@\n", [parent base16String]];
	}
	
	return string;
}

						
