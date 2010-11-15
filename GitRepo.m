//
//  gitrepo.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/8/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gitrepo.h"
#import "gitobject.h"
#import "gitcommitobject.h"
#import "GitReference.h"
#import "GitReferenceStorage.h"
#import "GitIndex.h"
#import "NSDataExtension.h"


@implementation GitHistoryVisitor

@synthesize history;

-(id) init
{
	if ( self = [super init] )
	{
		history = [[NSMutableArray alloc] init];
	}
	return self;
}

-(BOOL) visit:(GitObject *)object
{
	[history addObject: object];
	
	//NSLog( [[[object author  ]time] description] );
	return YES;
}

-(void) dealloc
{
	[history release];
	[super dealloc];
}

@end


static BOOL createPath( NSString *basePath, NSString *dir, NSError **error );

@interface GitRepo (Private)

-(void) updateHead:(NSData*) sha1;
+(NSArray *)skeletonDirectories;

@end


@implementation GitRepo

@synthesize name;
@synthesize url;
@synthesize workingDir;

@synthesize refs;
@synthesize objectStore;
@synthesize index;

+ (BOOL) isValidRepo:(NSURL*) workingDir
{
    BOOL isDir, found;
	NSURL *repoDir = [workingDir URLByAppendingPathComponent:@".git"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    found = [fileManager fileExistsAtPath:[repoDir path] isDirectory:&isDir];
    
    if (isDir && found) {
        // Perform further checks
    }

    return (isDir && found);
}

+ (NSArray *)skeletonDirectories 
{
    return [NSArray arrayWithObjects:@"branches", 
									 @"hooks", 
									 @"info", 
									 @"objects/info", 
									 @"objects/pack", 
									 @"refs/heads", 
									 @"refs/tags", 
									 nil];
}

+ (BOOL) makeRepo:(NSURL*) _workingDir
	  description:(NSString*) description
			error:(NSError**) error
{	
	NSString *baseDir = [_workingDir path];
	
	createPath( baseDir, @".git", error );
	
	NSString *repoDir = [baseDir stringByAppendingPathComponent:@".git"];
	
	for ( NSString *dir in [GitRepo skeletonDirectories])
	{
		createPath( repoDir, dir, error );
	}
	
	// create HEAD pointing to ref: /refs/heads/master
	NSString *HEADFile = [repoDir stringByAppendingPathComponent:@"HEAD"];
	[[NSString stringWithString:@"ref: refs/heads/master\n"] 
										writeToFile:HEADFile
										 atomically:TRUE
										   encoding:NSUTF8StringEncoding
											  error:error];
	
	// create description
	NSString *descriptionFile = [repoDir stringByAppendingPathComponent:@"description"];
	if ( description == nil )
	{
		description = [NSString stringWithString:
					   @"Unnamed repository; edit this file 'description' to name the repository.\n"];
	}
	[description writeToFile:descriptionFile
				  atomically:TRUE
					encoding:NSUTF8StringEncoding
					   error:error];

	// create config
	NSString *config = 
		@"[core]\n\trepositoryformatversion = 0\nfilemode = true\nbare = true\nignorecase = true\n";
	
	NSString *configFile = [repoDir stringByAppendingPathComponent:@"config"];
	[config writeToFile:configFile
				  atomically:TRUE
					encoding:NSUTF8StringEncoding
					   error:error];
	
	return YES;
}


- (id) initWithUrl: (NSURL*) _workingDir name:(NSString*) _name
{	
    if ( self = [super init] )
    {	
		[_workingDir retain];
		workingDir = _workingDir;
		
		url = [[workingDir URLByAppendingPathComponent:@".git"] retain];
		
		if ( _name != nil )
		{
			[self setName:_name];
		}
		else
		{
			NSArray *urlComponents = [url pathComponents];
			
			[self setName:
			 [urlComponents objectAtIndex:[urlComponents count]-2]];
		}
		
		objectStore = [[GitObjectStore alloc] initWithUrl:url];
		
		refs = [[GitReferenceStorage alloc] initWithUrl:url];
		
		index = [[GitIndex alloc] initWithUrl: 
				 [url URLByAppendingPathComponent:@"index"]];
	}
    return self;
}

-(void) dealloc
{	
	[index release];
	[refs release];
	[objectStore release];
	[url release];
	[super dealloc];
}

- (void) encodeWithCoder: (NSCoder *)coder
{
	[coder encodeObject: workingDir forKey:@"repo_url"];
	[coder encodeObject: name forKey:@"repo_name"];
}

- (id) initWithCoder: (NSCoder *)coder
{
	return [self initWithUrl:[coder decodeObjectForKey:@"repo_url"]
						name:[coder decodeObjectForKey:@"repo_name"]];
}

- (id) getObject:(NSData*) sha1
{	
	return [objectStore getObject:sha1];
}

-(NSDictionary*) headTree
{
	NSData *headSha1 = [[refs head] resolve:refs];
	GitTreeObject *tree = [objectStore getTreeFromCommit:headSha1];
	
	return [objectStore flattenTree:tree];
}

- (NSArray*) revisionHistoryFor:(NSData*) sha1
{
	GitHistoryVisitor *historyVisitor = [[GitHistoryVisitor alloc] init];
	[historyVisitor autorelease];
	
	[objectStore walk:sha1 with:historyVisitor];
	
	return [historyVisitor history];
}

- (BOOL) makeCommit:(NSString*) message 
			 author:(GitAuthor*) author
		   commiter:(GitAuthor*) commiter
{	
	NSData* headCommit = [[refs head] resolve:refs];
		
	GitCommitObject *headCommitObject = [objectStore getObject:headCommit];
	
	
	NSData *treeSha1 = [index writeTree:objectStore 
						headTreeSha1:[headCommitObject tree]];
	
	if ( treeSha1 )
	{
		NSArray *parents = nil;
		
		if ( headCommit )
		{
			parents = [NSArray arrayWithObject:headCommit];
		}
		
		GitCommitObject *commitObject = [[GitCommitObject alloc] 
										 initWithTree:treeSha1
										 parents:parents
										 message:message
										 author:author
										 commiter:commiter];
		
		NSData *sha1 = [objectStore addObject:commitObject];
		
		[self updateHead:sha1];
		
		[commitObject release];
		
		[index write];
		
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}

-(void) updateHead:(NSData*) sha1
{
	[refs setReference:[refs head] sha1: sha1];
	
	[refs updateReference:[refs head]];
}


-(NSData*) resolveReference:(NSString*) refName
{
	return [refs resolveReference:refName];
}

@end

static BOOL createPath( NSString *basePath, NSString *dir, NSError **error )
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	
	NSString *path = [basePath stringByAppendingPathComponent:dir];
	
	if ([mgr fileExistsAtPath:path] == NO)
	{
		return [mgr createDirectoryAtPath:path 
			  withIntermediateDirectories:YES 
							   attributes:nil
									error:error];
	}
	
	return YES;
}

