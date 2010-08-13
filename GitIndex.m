//
//  GitIndex.m
//  gitfend
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitIndex.h"

#include <sys/stat.h>

#define ENTRY_INFO_SIZE 62
#define ENTRY_NUL_SIZE 1

@implementation GitIndexEntry

@synthesize filename;


-(EntryInfo*) entryInfo
{
	return &entryInfo;
}

@end


static uint32_t parseHeader( GitIndex *index, NSFileHandle *file );
static void readStatInfo( EntryInfo *entryInfo, NSFileHandle *file );
static void readEntry( NSMutableDictionary *entries, NSFileHandle *file );
static int checkStat( struct stat *fileStat, GitIndexEntry* entry );

@implementation GitIndex

-(id) initWithUrl:(NSURL*) url
{
	if ( self = [super init] )
    {
		NSError *error;
		uint32_t numEntries;
		uint32_t i;
		
		entries = [[NSMutableDictionary alloc] init];
		
		NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL: url 
																 error:&error];
		
		numEntries = parseHeader(self, file);
		
		for ( i = 0; i < numEntries; i++ )
		{
			readEntry( entries, file );
		}
		
		// Close file.
	}
	return self;
}

-(void) dealloc
{
	[entries release];
	[super dealloc];
}

-(NSArray*) modifiedFiles:(NSURL*) workDir
{
	NSError *error;
	NSMutableArray *fileArray;
	
	fileArray = [[[NSMutableArray alloc] init] autorelease];
	
	for (GitIndexEntry *entry in entries)
	{
		NSURL *fileUrl;
		NSFileHandle *file;
		struct stat fileStat;
		
		fileUrl = [NSURL URLWithString:[entry filename] relativeToURL:workDir];
		
		file = [NSFileHandle fileHandleForReadingFromURL:fileUrl
												   error:&error];
		
		if ( fstat([file fileDescriptor], &fileStat ) == 0 )
		{
			if ( checkStat( &fileStat, entry ) )
			{
				[fileArray addObject:entry];
			}
		}
	}
	
	return fileArray;
}

-(NSArray*) status:(NSData*) tree objectStore:(GitObjectStore*) objectStore
{
	// Populate tree ( flatten filenames into a path relative to working dir
	// to match the format of the index entries, and put in a dictionary
	
	// Iterate through the entries in the index:
	// Added Status: If an entry is not in the populated tree

	// Modified status, if the Sha1 key in the index differs from the blob 
	// associated to the same file in the tree.
	
	// Removed: an populated tree entry is not in the index.
	// Note: We may find appropiate to hold the index entries in a dictionary:
	// ( filename, GitIndexEntry ).
	
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
static void readEntry( NSMutableDictionary *entries, NSFileHandle *file )
{
	uint32_t nameSize;
	uint32_t entryLength;
	uint32_t skipBytes;
	
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
		
		// skip zero padding.
		entryLength = ENTRY_INFO_SIZE + nameSize + ENTRY_NUL_SIZE;
		
		if (entryLength & 0x07)
		{
			skipBytes = 8 - ( entryLength & 0x07 ) + ENTRY_NUL_SIZE;
		}
		else
		{
			skipBytes = 1;
		}
		
		[file seekToFileOffset:[file offsetInFile] + skipBytes];
	}
}

static void readStatInfo( EntryInfo *entryInfo, NSFileHandle *file )
{
	[[file 
	  readDataOfLength:ENTRY_INFO_SIZE] 
	  getBytes:entryInfo length:ENTRY_INFO_SIZE];
	
	// Swap Data if necessary:
	entryInfo->stat.ctime = NSSwapBigLongLongToHost( entryInfo->stat.ctime );
	entryInfo->stat.mtime = NSSwapBigLongLongToHost( entryInfo->stat.mtime );
	
	entryInfo->stat.dev	  = NSSwapBigLongToHost( entryInfo->stat.dev );
	entryInfo->stat.inode = NSSwapBigLongToHost( entryInfo->stat.inode );
	entryInfo->stat.mode  = NSSwapBigLongToHost( entryInfo->stat.mode );
	entryInfo->stat.uid	  = NSSwapBigLongToHost( entryInfo->stat.uid );
	entryInfo->stat.gid	  = NSSwapBigLongToHost( entryInfo->stat.gid );
	entryInfo->stat.size  = NSSwapBigLongToHost( entryInfo->stat.size );
	
	entryInfo->flags = NSSwapBigShortToHost( entryInfo->flags );
}

static int checkStat( struct stat *fileStat, GitIndexEntry* entry )
{	
	EntryInfoStat entryStat;
	
	entryStat = [entry entryInfo]->stat;
	
	if ( entryStat.ctime != fileStat->st_ctime )
	{
		return -1;
	}

	if ( entryStat.mtime != fileStat->st_mtime )
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

	if ( entryStat.size != fileStat->st_size )
	{
		return -1;
	}	
	
	return 0;
}






