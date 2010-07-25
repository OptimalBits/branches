//
//  GitIndex.m
//  gitfend
//
//  Created by Manuel Astudillo on 6/12/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "GitIndex.h"


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

@implementation GitIndex

-(id) initWithUrl:(NSURL*) url
{
	if ( self = [super init] )
    {
		NSError *error;
		uint32_t numEntries;
		uint32_t i;
		
		entries = [[NSMutableDictionary alloc] init];
		
		NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL: url error:&error];
		
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


@end

static uint32_t parseHeader( GitIndex *index, NSFileHandle *file )
{
	char header[4];
	uint32_t version;
	uint32_t numEntries;
	
	[[file 
	  readDataOfLength:sizeof(header)] 
	  getBytes:header length:sizeof(header)];
	
	if (strncmp( header, "DIRC", 4) )
	{
		[[file 
		  readDataOfLength:sizeof(version)] 
		  getBytes:&version length:sizeof(version)];
		
		[[file 
		  readDataOfLength:sizeof(numEntries)] 
		  getBytes:&numEntries length:sizeof(numEntries)];
		
		return numEntries;
	}
	
	return 0;
}

/*
<INDEX_ENTRY>:	
	<INDEX_ENTRY_STAT_INFO>
	<ENTRY_ID>
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
	uint32_t numReadBytes;
	uint32_t skipBytes;
	
	GitIndexEntry *entry = [[GitIndexEntry alloc] init];
	
	readStatInfo( [entry entryInfo], file );
	
	// read name
	nameSize = [entry entryInfo]->flags & 0x0fff;
	
	NSString *filename = [[NSString alloc]
						 initWithData:[file readDataOfLength:nameSize] 
						 encoding: NSUTF8StringEncoding];
	[filename autorelease];
	
	[entry setFilename: filename];

	[entries setObject:entry forKey:filename];

	// skip zero padding.
	numReadBytes = ((sizeof(EntryInfo) + nameSize + 8) & ~7);
    skipBytes = ( ( numReadBytes + 8 ) & ~7 ) - numReadBytes;
	
	[file seekToFileOffset:[file offsetInFile] + skipBytes];
	
}

static void readStatInfo( EntryInfo *entryInfo, NSFileHandle *file )
{
	[[file 
	  readDataOfLength:sizeof(EntryInfo)] 
	  getBytes:entryInfo length:sizeof(EntryInfo)];
	
	// Swap Data if necessary:
	entryInfo->ctime = NSSwapBigLongLongToHost( entryInfo->ctime );
	entryInfo->mtime = NSSwapBigLongLongToHost( entryInfo->mtime );
	
	entryInfo->dev	= NSSwapBigLongToHost( entryInfo->dev );
	entryInfo->inode = NSSwapBigLongToHost( entryInfo->inode );
	entryInfo->mode	= NSSwapBigLongToHost( entryInfo->mode );
	entryInfo->uid	= NSSwapBigLongToHost( entryInfo->uid );
	entryInfo->gid	= NSSwapBigLongToHost( entryInfo->gid );
	entryInfo->size	= NSSwapBigLongToHost( entryInfo->size );
	
	entryInfo->flags = NSSwapBigShortToHost( entryInfo->flags );
}








