//
//  OBSDiffSession.m
//  Unify
//
//  Created by Manuel Astudillo on 1/31/11.
//  Copyright 2011 Optimal Bits Software AB. All rights reserved.
//

#import "OBSDiffSession.h"
#import "OBSDirectory.h"

@implementation OBSDiffSession

@synthesize leftSource, rightSource;

-(id) init
{
	if ( self = [super init] )
	{
		name = nil;
		leftSource = nil;
		rightSource = nil;
	}
	return self;
}

-(void) dealloc
{
	[leftSource release];
	[rightSource release];
	[name release];
	[super dealloc];
}

- (void) setName:(NSString*) _name
{
	name = _name;
}

-(NSString*) name
{
	if ( name )
	{
		return name;
	}
	else
	{
		NSString *left = [[[leftSource root] path] lastPathComponent];
		NSString *right = [[[rightSource root] path] lastPathComponent];
		
		return [[left stringByAppendingString:@":"] stringByAppendingString:right];
	}
}

- (NSTreeNode*) diffTree
{
	return [leftSource compareDirectory:rightSource];
}

- (id)initWithCoder:(NSCoder *)decoder
{ 
	self = [super init];
	
	name = [[decoder decodeObjectForKey:@"name"] retain];
	leftSource = [[decoder decodeObjectForKey:@"leftSource"] retain];
	rightSource = [[decoder decodeObjectForKey:@"rightSource"] retain];

	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	if ( name ) 
	{
		[encoder encodeObject:name forKey:@"name"];
	}

	[encoder encodeObject:leftSource forKey:@"leftSource"];
	[encoder encodeObject:rightSource forKey:@"rightSource"];
}

/*
-(BOOL) isEqual:(id)object
{
	if ( [[self leftSource] isEqual:[object leftSource]] &&
		 [[self rightSource] isEqual:[object rightSource]] )
	{
		return YES;
	}
	else
	{
		return NO;
	}
}
*/
@end
