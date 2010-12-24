//
//  GitIndex.m
//  GitLib
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitIndex.h"
#import "GitFile.h"
#import "GitTreeObject.h"
#import "GitBlobObject.h"
#import "GitCommitObject.h"
#import "GitObjectStore.h"

#import "NSDataExtension.h"

#include <sys/stat.h>	

#define ENTRY_INFO_SIZE 62
#define ENTRY_NUL_SIZE 1

@implementation GitIndexEntry

@synthesize filename;

-(id) init
{
	if ( self = [super init] )
	{
		filename = nil;
		blob = nil;
	}
	return self;
}

- (void) dealloc
{
	[filename release];
	[super dealloc];
}

-(EntryInfo*) entryInfo
{
	return &entryInfo;
}

-(NSData*) sha1
{
	if ( blob )
	{
		return [blob sha1];
	}
	else
	{
		return [NSData dataWithBytes:entryInfo.sha1 length:20];
	}
}

-(void) setBlob:(GitBlobObject*) _blob
{
	[_blob retain];
	[blob release];
	blob = _blob;
}

-(GitBlobObject*) blob
{
	return blob;
}

@end



#define INDEX_HEADER_SIZE		12
#define INDEX_MEAN_ENTRY_SIZE	(sizeof(EntryInfo) + 16)

static uint32_t parseHeader( GitIndex *index, NSFileHandle *file );
static void readStatInfo( EntryInfo *entryInfo, NSFileHandle *file );
static void readEntry( NSMutableDictionary *entries, 
					   NSFileHandle *file );

static void setStat( struct stat *fileStat, GitIndexEntry* entry );
static int  checkStat( struct stat *fileStat, GitIndexEntry* entry );

static void writeHeader( uint32_t numEntries, NSMutableData *output );
static void writeEntry( GitIndexEntry *entry, NSMutableData *outputData );

static void writeStatInfo( EntryInfo *entryInfo, NSMutableData *outputData );

@interface GitIndex (Private)

-(GitTreeObject*) writeTreeRecur:(GitObjectStore*) objectStore
						  status:(NSDictionary*) status
						treeSha1:(NSData*) treeSha1;

@end


@implementation GitIndex

-(id) initWithUrl:(NSURL*) _url
{
	if ( self = [super init] )
    {
		NSError *error;
		uint32_t numEntries;
		uint32_t i;
	
		url = _url;
		[url retain];
		
		NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL: _url 
																 error:&error];
		numEntries = parseHeader(self, file);
		
		entries = [[NSMutableDictionary alloc] initWithCapacity:numEntries];
		
		for ( i = 0; i < numEntries; i++ )
		{
			readEntry( entries, file );
		}
		
		[file closeFile];
		
		isDirty = FALSE;
	}
	return self;
}

-(void) dealloc
{
	if ( isDirty )
	{
		[self write];
	}
	
	[url release];
	[entries release];
	[super dealloc];
}

-(void) write
{
	NSMutableData *outputData;
	
	outputData = [NSMutableData dataWithCapacity:INDEX_HEADER_SIZE +
												 INDEX_MEAN_ENTRY_SIZE *
												 [entries count]];	
	writeHeader( [entries count], outputData );
	
	NSArray *sortedKeys = [[entries allKeys] 
						   sortedArrayUsingSelector:@selector(compare:)];
	
	for ( NSString *key in sortedKeys )
	{
		writeEntry( [entries objectForKey:key], outputData );
	}
	
	[outputData writeToURL:url atomically:YES];
}


-(GitFileStatus) fileStatus:(NSURL*) fileUrl workingDir:(NSString*) workingDir
{
	NSString *filename = 
		[[fileUrl path] substringFromIndex:[workingDir length]+1];

	if ( [self isFileTracked:filename] )
	{
		if ( [self isFileModified:fileUrl filename:filename] )
		{
			return kFileStatusModified;
		}
		else
		{
			return kFileStatusTracked;
		}
	}
	else
	{
		return kFileStatusUntracked;
	}	
}

/**
	Returns a set with all the files in the working directory that have been
	modified.
 */
-(NSSet*) modifiedFiles:(NSURL*) workDir
{
	NSMutableSet *fileSet;
	
	fileSet = [[[NSMutableSet alloc] init] autorelease];
	
	for (NSString *filename in entries)
	{
		NSURL *fileUrl;
		
		fileUrl = [NSURL URLWithString:filename relativeToURL:workDir];
		
		if ( [self isFileModified:fileUrl filename:filename] )
		{
			[fileSet addObject:filename];
		}
	}
	
	return fileSet;
}

-(BOOL) isFileModified:(NSURL*) fileUrl filename:(NSString*) filename
{
	NSError *error;
	
	struct stat fileStat;
	
	NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL:fileUrl
															 error:&error];
	if ( file )
	{
		if ( fstat([file fileDescriptor], &fileStat ) == 0 )
		{
			GitIndexEntry *entry = [entries objectForKey:filename];
			
			if ( checkStat( &fileStat, entry ) )
			{
				if ( fileStat.st_mode == [entry entryInfo]->stat.mode )
				{
					GitBlobObject *blob = [[[GitBlobObject alloc] initWithData:
											[NSData dataWithContentsOfURL:fileUrl]] autorelease];
				
					if ( [[blob sha1] isEqualToData:[entry sha1]] )
					{
						setStat( &fileStat, entry );
						return NO;
					}
				}
				
				return YES;
			}
		}
	}
	else
	{
		// File is missing!
	}

	return NO;	
}


-(BOOL) isFileTracked:(NSString*) filename
{
	if ( [entries objectForKey:filename] )
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

-(NSData*) sha1ForFilename:(NSString*) filename
{
	GitIndexEntry* entry;
	
	entry = [entries objectForKey:filename];
	
	if ( entry )
	{
		return [NSData dataWithBytes:[entry entryInfo]->sha1
							  length:20];
	}
	else
	{
		return nil;
	}
}

// TODO: We need to update the stat for this file, but only if
// the content of the blob is equal to the content of the file.
-(void) addFile:(NSString*) filename blob:(GitBlobObject*) blobObject
{	
	GitIndexEntry *entry = [entries objectForKey:filename];
	
	if ( entry == nil )
	{
		entry = [[[GitIndexEntry alloc] init] autorelease];
		[entry setFilename:filename];
		
		[entries setObject:entry forKey:filename];
	}
	
	[entry setBlob:blobObject];
	
	isDirty = TRUE;
}

-(NSSet*) removedFiles
{
	return nil;
}

-(NSDictionary*) unflattenStatusTree:(NSArray*) flattenedTree
{
	NSMutableDictionary *result = 
		[[[NSMutableDictionary alloc] init] autorelease];
	
	for ( id file in flattenedTree )
	{
		NSArray *pathComponents = [[file filename] pathComponents];
		NSInteger index;
		
		NSMutableDictionary *dict = result;
		index = 0;
		while ( index < [pathComponents count] - 1 )			
		{
			NSMutableDictionary *subTree;
			
			NSString* key = [pathComponents objectAtIndex:index];
			
			if ( [dict objectForKey:key] == nil )
			{
				subTree = [[[NSMutableDictionary alloc] init] autorelease];
			
				[dict setObject:subTree forKey:key];
			}
			else
			{
				subTree = [dict objectForKey:key];
			}

			dict = subTree;
			
			index ++;
		}
		
		[dict setObject:file forKey:[pathComponents objectAtIndex:index]];
	}
	
	return result;
}

/**
 Discussion:
 
 Determining which files have been added, removed or renamed is 
 quite expensive.
 
 It requires that the HEAD tree is flattened, which will populate a tree
 with as many entries as files that are actually tracked in the repository.
 
 Flattening the tree is a time consumming operation, if many thousands of
 files are part of it. After flattening, every entry in the tree must be 
 checked against the index, to see if the entry is there or not.
 
 The same applies for detecting renames, where all added files, must search
 in the tree to see if there is another sha1 key that matches their own.
 
 I think, this is how git works internally. If we dont are required to
 save the index, then we can perform this operations much cheaper,
 putting some state variables in GitIndexEntry to express if a entry
 has been renamed, and having a separate NSSet for checking adds and deletes.
 
 */
-(NSDictionary*) stageStatus:(NSDictionary*) flattenedTree
{	
	GitFile *file;
	
	NSSet *keysUnion = [[NSSet setWithArray:[flattenedTree allKeys]]
						setByAddingObjectsFromArray:[entries allKeys]];

	NSMutableSet *updatedFiles = [[[NSMutableSet alloc] init] autorelease];
	NSMutableSet *addedFiles =   [[[NSMutableSet alloc] init] autorelease];
	NSMutableSet *removedFiles = [[[NSMutableSet alloc] init] autorelease];
	NSMutableSet *renamedFiles = [[[NSMutableSet alloc] init] autorelease];
					   	
	for ( NSString *filename in keysUnion )
	{
		GitIndexEntry *entry;
		GitTreeNode *node;
		
		entry = [entries objectForKey:filename];
		node = [flattenedTree objectForKey:filename];
		
		if ( ( entry != nil ) && ( node != nil ) )
		{
			if ( ![[node sha1] isEqualToData:[entry sha1]] )
			{
				[updatedFiles addObject:filename];
			}
		} 
		else if ( entry )
		{
			[addedFiles addObject:filename]; 
		}
		else if ( node )
		{
			[removedFiles addObject:filename];
		}
	}
	
	for ( NSString *removedFilename in removedFiles )
	{
		for ( NSString *addedFilename in addedFiles )
		{
			if ( ![renamedFiles containsObject:addedFilename] )
			{
				GitIndexEntry *entry;
				GitTreeNode *node;
				
				entry = [entries objectForKey:addedFilename];
				node = [flattenedTree objectForKey:removedFilename];
				
				if ( [[node sha1] isEqualToData:[entry sha1]] )
				{
					[renamedFiles addObject:addedFilename];
					//	[addedFiles removeObject:addedFilename];
					//	[removedFiles removeObject:removedFilename];
					break;
				}
			}
		}
	}
	
	NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
	GitFileStatus status;
	
	status = kFileStatusUpdated;
	for ( NSString *filename in updatedFiles )
	{
		file = [[[GitFile alloc] initWithName:filename 
									andStatus:status] autorelease];
		
		[result addObject:file];
	}
	
	status = kFileStatusAdded;
	for ( NSString *filename in addedFiles )
	{
		file = [[[GitFile alloc] initWithName:filename 
									andStatus:status] autorelease];
		
		[result addObject:file];
	}
	
	status = kFileStatusRemoved;
	for ( NSString *filename in removedFiles )
	{
		file = [[[GitFile alloc] initWithName:filename 
									andStatus:status] autorelease];
		
		[result addObject:file];
	}
	
	status = kFileStatusRenamed;
	for ( NSString *filename in renamedFiles )
	{
		file = [[[GitFile alloc] initWithName:filename 
									andStatus:status] autorelease];
		
		[result addObject:file];
	}
	
	return [self unflattenStatusTree:result];
}


/**
	TODO: complete Mode handling.
 
 */
-(GitTreeObject*) writeTreeRecur:(GitObjectStore*) objectStore
						  status:(NSDictionary*) status
						treeSha1:(NSData*) treeSha1
{
	GitTreeObject* tree = [objectStore getObject:treeSha1];
	
	if ( tree == nil )
	{
		tree = [[[GitTreeObject alloc] init] autorelease];
	}
	
	for ( NSString *key in status )
	{
		id statusEntry = [status objectForKey:key];
		
		if ( [statusEntry isKindOfClass:[GitFile class]] )
		{
			GitFile *file = statusEntry;
			
			if ( [file status] != kFileStatusRemoved )
			{
				GitIndexEntry *entry = 
					[entries objectForKey:[file filename]];
				
				[tree setEntry:key
						  mode:[entry entryInfo]->stat.mode
						  sha1:[entry sha1]];
				
				if ( [entry blob] )
				{
					[objectStore addObject:[entry blob]];
					
					memcpy( [entry entryInfo]->sha1, [[entry sha1] bytes], 20 );
					[entry setBlob:nil];
				}
			}
			else
			{
				[tree removeEntry:key];
				[entries removeObjectForKey:key];
			}
		}
		else
		{
			NSData *subTreeSha1 = [[tree tree] objectForKey:key];
			
			GitTreeObject *result = [self writeTreeRecur:objectStore 
												  status:statusEntry 
												treeSha1:subTreeSha1];
			
			[tree setEntry:key 
					  mode:kDirectory 
					  sha1:[result sha1]];
		}
	}
	
	[objectStore addObject:tree];
	
	return tree;
}

/**
	This function writes the staged objects in the index into the object
	database.
 
 */
-(NSData*) writeTree:(GitObjectStore*) objectStore 
		headTreeSha1:(NSData*) treeSha1
{										
	GitTreeObject *tree = [objectStore getObject:treeSha1];
	
	NSDictionary *flattenedTree = [objectStore flattenTree:tree];
	NSDictionary *status = [self stageStatus:flattenedTree];
	
	if ( [status count] > 0 )
	{
		GitTreeObject *result = [self writeTreeRecur:objectStore 
											  status:status
											treeSha1:treeSha1];
		
		return [result sha1];
	}
	
	return nil;
}
								
@end




static uint32_t parseHeader( GitIndex *index, NSFileHandle *file )
{
	char header[4];
	uint32_t version;
	uint32_t numEntries;
	
	[[file 
	  readDataOfLength:sizeof(header)] 
	  getBytes:header length:sizeof(header)];
	
	if (strncmp( header, "DIRC", 4) == 0 )
	{
		[[file 
		  readDataOfLength:sizeof(version)] 
		  getBytes:&version length:sizeof(version)];
		
		version = CFSwapInt32BigToHost( version );
		
		if ( version == 2 )
		{
			[[file 
			  readDataOfLength:sizeof(numEntries)] 
			  getBytes:&numEntries length:sizeof(numEntries)];
		
			  numEntries = CFSwapInt32BigToHost( numEntries );
		
			 return numEntries;
		}
	}
	
	return 0;
}

static void writeHeader( uint32_t numEntries, NSMutableData *output )
{
	char header[4] = "DIRC";
	
	uint32_t version = CFSwapInt32HostToBig( 2 );
	
	[output appendBytes:header length:sizeof(header)];
	[output appendBytes:&version length:sizeof(version)];
	
	numEntries = CFSwapInt32HostToBig( numEntries );
	[output appendBytes:&numEntries length:sizeof(numEntries)];
}




/*
<INDEX_ENTRY>:	
	<INDEX_ENTRY_STAT_INFO>
	<ENTRY_ID> // Sha1
	<ENTRY_FLAGS>
	<ENTRY_NAME> <NUL>
	<ENTRY_ZERO_PADDING>;
 
 
<INDEX_ENTRY_STAT_INFO>
 # These fields are used as a part of a heuristic to determine
 # if the file system entity associated with this entry has
 # changed. The names are very *nix centric but the exact
 # contents of each field have no meaning to Git, besides exact
 # match, except for the <ENTRY_MODE> and <ENTRY_SIZE> fields.
 :	<ENTRY_CTIME>
	<ENTRY_MTIME>
	<ENTRY_DEV>
	<ENTRY_INODE>
	<ENTRY_MODE>
	<ENTRY_UID>
	<ENTRY_GID>
	<ENTRY_SIZE>
 ;
 
*/


static uint32_t numSkipBytes( uint32_t nameLength )
{
	uint32_t skipBytes;
	uint32_t entryLength = ENTRY_INFO_SIZE + nameLength + ENTRY_NUL_SIZE;
	
	if (entryLength & 0x07)
	{
		skipBytes = 8 - ( entryLength & 0x07 ) + ENTRY_NUL_SIZE;
	}
	else
	{
		skipBytes = 1;
	}
	
	return skipBytes;
}

static void readEntry( NSMutableDictionary *entries,
					   NSFileHandle *file )
{
	uint32_t nameSize;
	
	GitIndexEntry *entry = [[[GitIndexEntry alloc] init] autorelease];
	
	readStatInfo( [entry entryInfo], file );
	
	// read name
	nameSize = [entry entryInfo]->flags & 0x0fff;
	
	NSString *filename = [[[NSString alloc]
						   initWithData:[file readDataOfLength:nameSize] 
						   encoding: NSUTF8StringEncoding] autorelease];
	
	if ( filename )
	{
		[entry setFilename: filename];
		
		[entries setObject:entry forKey:filename];
		
		[file seekToFileOffset:[file offsetInFile] + numSkipBytes( nameSize )];
	}
}

static void writeEntry( GitIndexEntry *entry, NSMutableData *outputData )
{
	uint32_t length = strlen( [[entry filename] UTF8String] );
	
	[entry entryInfo]->flags &= 0xf000;
	[entry entryInfo]->flags |= length;
	
 	writeStatInfo( [entry entryInfo], outputData );
	
	[outputData appendBytes:[[entry filename] UTF8String] length:length + 1];
	[outputData increaseLengthBy:numSkipBytes( length )];
}

static void readStatInfo( EntryInfo *entryInfo, NSFileHandle *file )
{
	[[file 
	  readDataOfLength:ENTRY_INFO_SIZE] 
	  getBytes:entryInfo length:ENTRY_INFO_SIZE];
	
	// Swap Data if necessary:
	entryInfo->stat.ctime = NSSwapBigLongLongToHost( entryInfo->stat.ctime );
	entryInfo->stat.mtime = NSSwapBigLongLongToHost( entryInfo->stat.mtime );
	
	entryInfo->stat.dev	  = NSSwapBigIntToHost( entryInfo->stat.dev );
	entryInfo->stat.inode = NSSwapBigIntToHost( entryInfo->stat.inode );
	entryInfo->stat.mode  = NSSwapBigIntToHost( entryInfo->stat.mode );
	entryInfo->stat.uid	  = NSSwapBigIntToHost( entryInfo->stat.uid );
	entryInfo->stat.gid	  = NSSwapBigIntToHost( entryInfo->stat.gid );
	entryInfo->stat.size  = NSSwapBigIntToHost( entryInfo->stat.size );
	
	entryInfo->flags = NSSwapBigShortToHost( entryInfo->flags );
}

static void writeStatInfo( EntryInfo *entryInfo, NSMutableData *outputData )
{
	EntryInfo info;
	
	info.stat.ctime = NSSwapHostLongLongToBig( entryInfo->stat.ctime );
	info.stat.mtime = NSSwapHostLongLongToBig( entryInfo->stat.mtime );
	
	info.stat.dev	= NSSwapHostIntToBig( entryInfo->stat.dev );
	info.stat.inode	= NSSwapHostIntToBig( entryInfo->stat.inode );
	info.stat.mode	= NSSwapHostIntToBig( entryInfo->stat.mode );
	info.stat.uid	= NSSwapHostIntToBig( entryInfo->stat.uid );
	info.stat.gid	= NSSwapHostIntToBig( entryInfo->stat.gid );
	info.stat.size	= NSSwapHostIntToBig( entryInfo->stat.size );

	info.flags = NSSwapHostShortToBig( entryInfo->flags );
	memcpy( info.sha1, entryInfo->sha1, sizeof( info.sha1 ) ); 

	[outputData appendBytes:&info length:ENTRY_INFO_SIZE];
}

static u_int64_t time64( u_int32_t tv_sec, u_int32_t tv_nsec )
{
	u_int64_t time;
	
	time = tv_sec;
	time <<= 32;
	time |= tv_nsec;
	
	return time;
}

static void setStat( struct stat *fileStat, GitIndexEntry* entry )
{
	EntryInfoStat entryStat;
	
	entryStat = [entry entryInfo]->stat;
	
	entryStat.size = fileStat->st_size;
	entryStat.ctime = time64( fileStat->st_ctimespec.tv_sec,
							  fileStat->st_ctimespec.tv_nsec);
	entryStat.mtime = time64( fileStat->st_mtimespec.tv_sec,
							  fileStat->st_mtimespec.tv_nsec);
	
	entryStat.dev = fileStat->st_dev;
	entryStat.gid = fileStat->st_gid;
	entryStat.uid = fileStat->st_uid;
	entryStat.inode = fileStat->st_ino;
	entryStat.mode = fileStat->st_mode;
}


static int checkStat( struct stat *fileStat, GitIndexEntry* entry )
{	
	EntryInfoStat entryStat;
		
	entryStat = [entry entryInfo]->stat;
	
	if ( entryStat.size != fileStat->st_size )
	{
		return -1;
	}
	
	if ( entryStat.ctime != time64( fileStat->st_ctimespec.tv_sec,
									fileStat->st_ctimespec.tv_nsec) )
	{
		return -1;
	}

	if ( entryStat.mtime != time64( fileStat->st_mtimespec.tv_sec,
								    fileStat->st_mtimespec.tv_nsec) )
	{
		return -1;
	}

	if ( entryStat.dev != fileStat->st_dev )
	{
		return -1;
	}

	if ( entryStat.gid != fileStat->st_gid )
	{
		return -1;
	}

	if ( entryStat.uid != fileStat->st_uid )
	{
		return -1;
	}

	if ( entryStat.inode != fileStat->st_ino )
	{
		return -1;
	}

	if ( entryStat.mode != fileStat->st_mode )
	{
		return -1;
	}
	
	return 0;
}
