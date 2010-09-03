//
//  GitObjectStore.m
//  gitfend
//
//  Created by Manuel Astudillo on 6/13/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitObjectStore.h"
#import "gitobject.h"
#import "gittreeobject.h"
#import "gitcommitobject.h"
#import "GitBlobObject.h"
#import "NSDataExtension.h"


////////////////////////////////////////////////////////////////////////////////
@interface GitFileHistoryVisitor: NSObject <GitNodeVisitor>
{
	NSMutableArray *history;
	NSString *filename;
	uint32_t maxNumItems;
	GitObjectStore *objectStore;
	
	NSData *prevSha1;
	GitCommitObject *prevCommit;
}

@property (readonly) NSMutableArray *history;
@property (readwrite, retain) NSData *prevSha1;
@property (readwrite, retain) GitCommitObject *prevCommit;


-(id) initWithFile: (NSString*) file
			commit: (NSData*) sha1
			objectStore: (GitObjectStore*) store 
			maxItems: (uint32_t) max;

-(BOOL) visit:(GitObject *)object;

@end


@implementation GitFileHistoryVisitor

@synthesize history;
@synthesize prevSha1;
@synthesize prevCommit;

-(id) initWithFile: (NSString*) file
			commit: (NSData*) sha1
	   objectStore: (GitObjectStore*) store 
		  maxItems: (uint32_t) max
{
	if ( self = [super init] )
    {
		filename = file;
		[filename retain];
		
		objectStore = store;
		[objectStore retain];
		
		maxNumItems = max;
		
		GitTreeObject *treeObject = [objectStore getTreeFromCommit:sha1];
		GitTreeNode *treeNode = [[treeObject tree] objectForKey: filename];
		
		[self setPrevSha1:[treeNode sha1]];
		[self setPrevCommit:[objectStore getObject:sha1]];
		
		history = [[NSMutableArray alloc] init];
	}
	return self;
}


-(BOOL) visit:(GitObject *)object
{	
	GitTreeObject *treeObject = [objectStore getObject:[(GitCommitObject*)object tree]];
	GitTreeNode *treeNode = [[treeObject tree] objectForKey: filename];
	
	if ( treeNode != nil )
	{
		if ( [[treeNode sha1] isEqualToData: [self prevSha1]] == NSOrderedSame )
		{
			[history addObject:[self prevCommit]];
			[self setPrevSha1:[treeNode sha1]];
		}
		[self setPrevCommit:(GitCommitObject*) object];
	}
	
	if ( [history count] == maxNumItems )
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

-(void) dealloc
{
	[history release];
	[objectStore release];
	[filename release];
	
	[super dealloc];
}

@end
////////////////////////////////////////////////////////////////////////////////


static GitPackFile *readPackFile( NSURL *url );
static GitObject *parseObject( NSData* data, NSData* key );
static NSData *encodeObject( GitObject *object );
static BOOL writeObject( NSData *sha1,
						 NSData *object, 
						 NSURL *baseUrl );

@implementation GitObjectStore


-(id) initWithUrl:(NSURL*) _url
{
	if ( self = [super init] )
    {
		[_url retain];
		url = _url;
		
		objectsUrl = [[url URLByAppendingPathComponent:@"objects"] retain];
	
		packFile = readPackFile( url );
		[packFile retain];
	}
	return self;
}

-(void) dealloc
{
	[packFile release];
	[objectsUrl release];
	[url release];
	[super dealloc];
}


- (id) getObject:(NSData*) sha1
{	
	NSError *error;
	NSURL *objectsPath;
	NSFileManager *fileManager;
	
	if ( packFile != nil )
	{
		id obj = [packFile getObject:sha1];
		if ( obj != nil )
		{
			return obj;
		}
	}
	
	fileManager = [NSFileManager defaultManager];
	
	objectsPath = [url URLByAppendingPathComponent:@"objects"];
	if ([objectsPath checkResourceIsReachableAndReturnError:&error] == YES)
	{
		NSArray *urls = [fileManager 
						 contentsOfDirectoryAtURL:objectsPath
						 includingPropertiesForKeys:nil 
						 options:NSDirectoryEnumerationSkipsHiddenFiles 
						 error:&error];
		
		for ( NSURL *u in urls )
		{
			NSData *firstByte = [NSData dataWithHexString:[u lastPathComponent]];
			if( [firstByte isEqualToData:
				 [sha1 subdataWithRange:NSMakeRange(0, 1)] ] )
			{
				NSArray *objUrls = [fileManager 
									contentsOfDirectoryAtURL:u
									includingPropertiesForKeys:nil 
									options:NSDirectoryEnumerationSkipsHiddenFiles 
									error:&error];
				
				for ( NSURL *objUrl in objUrls )
				{
					if( [[NSData dataWithHexString:[objUrl lastPathComponent]] isEqualToData:
						 [sha1 subdataWithRange:NSMakeRange(1, 19)] ] )
					{
						NSData *object = [NSData dataWithContentsOfURL:objUrl];
						
						NSData *inflated = [object zlibInflate];
						
						GitObject *gitObject = parseObject( inflated, sha1 );
						
						return gitObject;						
					}
				}
			}
		}
	}
	
	return nil;
}

/*
- (void) walk: (NSData*) commitSha with:(id) visitor
{
	NSMutableSet *branches = [[NSMutableSet alloc] init];
	NSMutableSet *visited = [[NSMutableSet alloc] init];
	
	[branches addObject:[self getObject: commitSha]];
	
	while ( [branches count] > 0 )
	{
		NSArray *sortedBranches = [[branches allObjects] 
								   sortedArrayUsingSelector:@selector(compareDate:)];
		
		// ( sort in descent order )
		
		NSLog( @"Num branches: %d", [branches count] );
		
		[visited addObjectsFromArray:sortedBranches	];
		
		for ( GitCommitObject *obj in sortedBranches )
		{
			//GitCommitObject *obj = [sortedBranches lastObject];
			if ( [obj isKindOfClass:[GitCommitObject class]] )
			{
				if ( [visitor visit:obj] )
				{			
					for (NSData *parent in [obj parents])
					{
						id parentObject = [self getObject:parent];
						if ( parentObject != nil) 						
						{
							if ( [visited member:parentObject] == nil )
							{
								[branches addObject:parentObject];
							}
						}
					}
				}
			}
			
			[branches removeObject:obj];
		}
	}
	
	[visited release];
	[branches release];
}
*/
/*
- (void) walk: (NSData*) commitSha with:(id) visitor
{
	NSMutableSet *branches = [[NSMutableSet alloc] init];
	
	[branches addObject:[self getObject: commitSha]];
	
	while ( [branches count] > 0 )
	{
		NSArray *sortedBranches = [[branches allObjects] 
								   sortedArrayUsingSelector:@selector(compareDate:)];
		
		// ( sort in descent order )
		GitCommitObject *obj = [sortedBranches lastObject];
		[branches removeObject:obj];
		
		if ( [obj isKindOfClass:[GitCommitObject class]] )
		{
			if ( [visitor visit:obj] )
			{
				for (NSData *parent in [obj parents])
				{
					id parentObject = [self getObject:parent];
					if ( parentObject != nil) 						
					{
						[branches addObject:parentObject];
					}
				}
			}
		}
	}
	
	[branches release];
}
*/

/**
	Depth First Traversing.
 */
- (void) walk: (NSData*) commitSha with:(id) visitor
{
	NSMutableSet *visited = [[NSMutableSet alloc] init];
	NSMutableArray *nodeStack = [[NSMutableArray alloc] init];
	
	GitCommitObject *obj = [self getObject: commitSha];
	
	[nodeStack addObject:obj];
	
	while ( [nodeStack count] )
	{
		obj = [[nodeStack lastObject] retain];
		[nodeStack removeLastObject];
		
		if ( ( [obj isKindOfClass:[GitCommitObject class]] ) &&
			 ( [visited member:obj] == nil ) )
		{
			if ( [visitor visit:obj] )
			{
				[visited addObject:obj];
			
				for (NSData *parent in [obj parents])
				{
					id parentObject = [self getObject:parent];
					if ( parentObject != nil) 						
					{
						[nodeStack addObject:parentObject];
					}
					else
					{
						// bug or currupt objects database?
					}

				}
			}
		}
		
	//	NSLog([[[obj author ]time] description]);
		[obj release];
	}
	
	[nodeStack release];
	[visited release];
}

/*
- (void) walk: (NSData*) commitSha with:(id) visitor
{
	NSMutableSet *visited = [[NSMutableSet alloc] init];
	
	[self walk_recur:commitSha with:visitor visited:visited];

	[visited release];
}

- (void) walk_recur: (NSData*) commitSha with:(id) visitor visited:(NSMutableSet*) visited
{
	GitCommitObject *obj = [self getObject: commitSha];
	if ( [obj isKindOfClass:[GitCommitObject class]] )
	{
		if ( [visited member:obj] == nil )
		{
			if ( [visitor visit:obj] )
			{
				[visited addObject:obj];
		
				for (NSData *parent in [obj parents])
				{
					[self walk_recur:parent with:visitor visited:visited];
				}
			}
		}
	}
}
*/
/*
 function visit(node n)
	if n has not been visited yet then
		mark n as visited
		for each node m with an edge from n to m do
			visit(m)
		add n to L
 */


/*
 L ← Empty list that will contain the sorted elements
 S ← Set of all nodes with no incoming edges
 while S is non-empty do
	remove a node n from S
	insert n into L
	for each node m with an edge e from n to m do
		remove edge e from the graph
		if m has no other incoming edges then
			insert m into S
 
 if graph has edges then
	output error message (graph has at least one cycle)
 else 
	output message (proposed topologically sorted order: L)
*/



-(id) getTreeFromCommit:(NSData*) sha1
{	
	GitObject *object = [self getObject:sha1];
	NSLog([sha1 description], nil);
	
	if ( [object isKindOfClass:[GitCommitObject class]] )
	{
		GitCommitObject *commitObject = (GitCommitObject*) object;
		NSLog([[commitObject tree] description], nil  );
		return [self getObject:[commitObject tree]];
	}
	return nil;
}


/**
	This function is more effective than calling fileHistory for every file in the
	tree, since it traverses the history just once.
 
 */
/*
- (NSDictionary*) lastModifiedCommits:(GitTreeObject*) tree sha1: (NSData*) sha1
{
	NSMutableSet *remainingFiles;
	GitTreeObject *prevTree;
	
	// walk throught the commits and for every commit check what files in the tree 
	// have been modified.
	while ( [remainingFiles count] > 0 ) 
	{
	//	prevTree = [self getTreeFromCommit:[self getParent:sha1]];
		NSArray *changedFiles = [tree treeDiff: prevTree];		
	}
	
	// Note, use also walk with proper visitor object.
}
*/
 
-(NSArray*) fileHistory:(NSString*) filename 
			 fromCommit:(NSData*) sha1 
			   maxItems:(uint32_t) max
{
	GitFileHistoryVisitor *visitor = [GitFileHistoryVisitor alloc];
	visitor = [visitor initWithFile:filename 
							 commit:sha1 
						objectStore:self 
						   maxItems:max];
	
	[self walk:sha1 with:visitor];

	NSMutableArray *history = [visitor history];
	
	if ( [history count] == 0 )
	{
		[history addObject:[visitor prevCommit]];
	}
	
	[visitor autorelease];
	
	return history;
}

/**
	This function will add the object to the database as a loose object.
	
 */
-(NSData*) addObject: (GitObject*) object
{
	NSData *encodedObject = encodeObject( object );
	NSData *sha1 = [encodedObject sha1Digest];
	
	NSData *compressedObject = [encodedObject zlibDeflate];
	
	if ( writeObject( sha1, compressedObject, objectsUrl ) )
	{
		return sha1;
	}
	else 
	{
		return nil;
	}
}

-(void) flattenTreeRecursive:(GitTreeObject*) tree 
						path:(NSString*) path
					  result:(NSMutableDictionary*) flattenedTree
{
	NSDictionary *treeDict = [tree tree];
	
	for ( NSString* key in treeDict )
	{
		NSString *filename;
		GitTreeNode *node = [treeDict objectForKey:key];
		
		if ( path )
		{
			filename = [path stringByAppendingPathComponent:key];
		}
		else
		{
			filename = key;
		}
		
		if ( [node mode] & kDirectory )
		{
			id subtree = [self getObject:[node sha1]];
			if ( [subtree isKindOfClass:[GitTreeObject class]] )
			{
				[self flattenTreeRecursive:subtree
									  path:filename
									result:flattenedTree];
			}
		}
		else
		{
			[flattenedTree setObject:node forKey:filename];
		}
	}
}

-(NSDictionary*) flattenTree:(GitTreeObject*) tree
{
	NSMutableDictionary *flattenedTree;
	
	flattenedTree = [[[NSMutableDictionary alloc] init] autorelease];
	
	[self flattenTreeRecursive:tree 
						  path:nil 
						result:flattenedTree];
	
	return flattenedTree;
}

@end


//
// Helpers
//

static GitPackFile *readPackFile( NSURL *url )
{
	GitPackFile *packFile = nil;
	NSError *error;
	NSFileManager *fileManager;
	NSURL* objectsPath = [url URLByAppendingPathComponent:@"objects"];
	NSURL* packPath = [objectsPath URLByAppendingPathComponent:@"pack"];
	
	if ([packPath checkResourceIsReachableAndReturnError:&error] == YES)
	{
		fileManager = [NSFileManager defaultManager];
		NSArray *urls = [fileManager 
						 contentsOfDirectoryAtURL:packPath 
						 includingPropertiesForKeys:nil 
						 options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
		
		NSMutableDictionary *packSet = [[NSMutableDictionary alloc] init];
		for(NSURL *u in urls)
		{
			NSURL *baseURL = [u URLByDeletingPathExtension];
			[packSet setObject:u forKey:baseURL];
		}
		
		for ( NSURL *key in packSet )
		{
			NSURL *indexURL= [key URLByAppendingPathExtension:@"idx"];
			NSURL *packURL = [key URLByAppendingPathExtension:@"pack"];
			
			packFile = 
				[[[GitPackFile alloc] initWithIndexURL:indexURL andPackURL:packURL] autorelease];
		}
		
		[packSet release];
	}
	
	return packFile;
}

static GitObject *parseObject( NSData* data, NSData* key )
{	
	const uint8_t *bytes = [data bytes];
	
	size_t len = strlen( (char*) bytes ) + 1;
	
	NSData *objectData = 
	[data subdataWithRange:NSMakeRange( len, [data length] - len)];
	
	if ( strncmp( "commit", (char*)bytes, 6 ) == 0)
	{
		return [ [GitCommitObject alloc] 
				initWithData: objectData
				sha1: key ];
	}
	
	if ( strncmp( "blob", (char*)bytes, 4 ) == 0)
	{
		return [[GitBlobObject alloc] initWithData: objectData];
	}
	
	if ( strncmp( "tree", (char*)bytes, 4 ) == 0)
	{
		return [[GitTreeObject alloc]
				initWithData: objectData];
	}
	
	return nil;
}

static NSData *encodeObject( GitObject *object )
{	
	NSString *objectType = @"";
	NSString *header;
	
	if ( [object isKindOfClass:[GitBlobObject class]] )
	{
		objectType = @"blob";
	}
	else if ( [object isKindOfClass:[GitCommitObject class]] )
	{
		objectType = @"commit";
	}	
	else if ( [object isKindOfClass:[GitTreeObject class]] )
	{
		objectType = @"tree";
	}		
	/*	else if ( [object isKindOfClass:[GitTagObject class]] )
	 {
	 objectType = @"tag";
	 }
	 */
	
	NSData *objectData = [object data];
	header = [NSString stringWithFormat:@"\"%@\" %d",
			  objectType, 
			  [objectData length]];
	NSMutableData *result = 
	[NSMutableData dataWithCapacity:[header length]+[objectData length]+1];
	
	[result appendBytes:[header cStringUsingEncoding:NSUTF8StringEncoding]
				 length:[header length]];
	
	[result appendData:objectData];
	
	return result;
}


static BOOL writeObject( NSData *sha1,
						 NSData *object, 
						 NSURL *baseUrl )
{
	NSError *error;
	NSFileManager *fileManager;
	
	fileManager = [NSFileManager defaultManager];
	
	BOOL succeeded = NO;
	
	if ([baseUrl checkResourceIsReachableAndReturnError:&error] == YES)
	{
		NSString *fanout = [NSString stringWithFormat:@"%x",
							(u_int32_t)((u_int8_t*)[sha1 bytes])[0]];
		
		NSString *filename = 
			[[sha1 subdataWithRange:NSMakeRange( 1, 19 )] base16String];
		
		NSURL *path = [baseUrl URLByAppendingPathComponent:fanout];
		
		succeeded = [fileManager createDirectoryAtPath:[path path] 
						   withIntermediateDirectories:YES 
											attributes:nil 
												 error:&error];
		if ( succeeded == NO )
		{
			return NO;
		}
		
		NSURL *url = [path URLByAppendingPathComponent:filename];
		
		succeeded = [object writeToURL:url atomically:YES];
	}
	
	return succeeded;
} 

