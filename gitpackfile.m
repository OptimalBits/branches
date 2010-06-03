//
//  gitpack.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "gitpackfile.h"
#import "gitobject.h"
#import "gitcommitobject.h"
#import "gittreeobject.h"
#import "GitBlobObject.h"
#import "NSDataExtension.h"


@implementation GitPackIndex

- (id) initWithURL:(NSURL*) index largerThan2G: (BOOL*) largePack;
{
	if ( self = [super init] )
    {
		NSError *error;
		uint32_t magic;
		uint32_t version;
		uint32_t size;
		uint32_t numObjects;
		
		NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL: index error:&error];
				
		// Check version ( only support version 2 ).
		[[file readDataOfLength:4] getBytes:&magic];
		magic = CFSwapInt32BigToHost(magic);
		
		if ( magic == 0xff744f63 ) 
		{
			[[file readDataOfLength:4] getBytes:&version];
			version = CFSwapInt32BigToHost( version );

			if ( version == 2 )
			{
				int i;
				
				[[file readDataOfLength:256*4] getBytes:&fanouts length: 256*4];
				
				for ( i = 0; i < 256; i++ )
				{
					fanouts[i] = CFSwapInt32BigToHost( fanouts[i] );
				}
				
				numObjects = fanouts[255];
				
				size = numObjects * sizeof( Sha1Key );
				keys = malloc( size );
//				if ( keys == 0 ) // handle error
								
				[[file readDataOfLength:size] getBytes:keys length:size];
				
				size = numObjects * 4;
				crcs = malloc( size );
				
				[[file readDataOfLength:size] getBytes:crcs length:size];
				
				size = numObjects * 4;
				offsets = malloc( size );
				
				[[file readDataOfLength:size] getBytes:offsets length:size];
				
				for ( i = 0; i < numObjects; i++ )
				{
					offsets[i] = CFSwapInt32BigToHost( offsets[i] );
				}
				
								
				[[file readDataOfLength:20] getBytes:&packFileChecksum];

				// TODO: Perform Sha1 checksums and compare with index checksum
				
				[[file readDataOfLength:20] getBytes:&packIndexChecksum];
			}
		}
		
	}
	return self;
}

- (uint32_t) findObjectOffset:(NSData*) key
{
	int start;
	int end;
	int i;
	uint8_t idx;
	uint8_t *shaKey = (uint8_t*) [key bytes];
	uint32_t offset;
	
	idx = shaKey[0];
	
	if ( idx == 0 )
	{
		start = 0;
	}
	else
	{
		start = fanouts[idx-1];
		end = fanouts[idx];
		
		while ( start <= end )
		{
			int c;
			i = ( start + end ) / 2;
			c = memcmp( &keys[i], shaKey, sizeof(Sha1Key) );
			if ( c < 0 )
			{
				start = i + 1;
			}
			else if ( c > 0 )
			{
				end = i - 1;
			}
			else
			{
				offset = offsets[i];
				break;
			}
		}
	}
	
	return offset;
}

@end


@implementation GitPackFile


- (id) initWithIndexURL:(NSURL*) indexURL andPackURL:(NSURL*) packURL
{
	if ( self = [super init] )
    {
		[packURL retain];
		pack = packURL;
		
		index = [[GitPackIndex alloc] initWithURL: indexURL largerThan2G:NO];
	}
	return self;
}

#define OBJ_COMMIT	1
#define OBJ_TREE	2
#define OBJ_BLOB	3
#define OBJ_TAG		4

#define OBJ_OFS_DELTA 6
#define OBJ_REF_DELTA 7

- (id) getObjectFromShaCString:(char*) key
{
	NSData *byteKey = [NSData dataWithHexCString:key];
	
	return [self getObject:byteKey];
}


- (id) getObject:(NSData*) key
{
	NSError *error;
	uint8_t byte;
	uint8_t type;
	uint32_t offset = [index findObjectOffset:key];
	uint64_t objectSize;
	uint64_t bytesToRead;
	int i;
	
	GitObject *object = nil;
	NSData *baseSha1;
	NSData *data;
	
	NSString *debug;
	
	if ( packFileHandle == nil )
	{
		packFileHandle = [NSFileHandle fileHandleForReadingFromURL: pack error:&error];
	}
	
	// seek to offset
	[packFileHandle seekToFileOffset:offset];
	
	// read type and size
	[[packFileHandle readDataOfLength:1] getBytes:&byte length:1];

    type = (byte >> 4) & 0x07;
    objectSize = byte & 0x0f;
	i = 0;
	while ( byte & 0x80 )
	{
		[[packFileHandle readDataOfLength:1] getBytes:&byte length:1];
		objectSize += (byte & 0x7f) << ((i * 7 ) + 4);
	    i ++;
	}
	
	bytesToRead = objectSize;
	bytesToRead += ( type == OBJ_OFS_DELTA ) ? 8 : 0;
	bytesToRead += ( type == OBJ_REF_DELTA ) ? 20: 0;
	
	// Lets hope that compressed data is always less than uncompressed...
	NSData *compressedData = [packFileHandle readDataOfLength:bytesToRead];
	
	if ( type == OBJ_OFS_DELTA )
	{
		const uint8_t *b = [compressedData bytes];
		uint64_t offset;
		
		i = 0;
		offset = b[0] & 0x7f;
		while ( b[i] & 0x80 ) 
		{
			i ++;
			//offset += (b[i] & 0x7f) << ((i * 7));
			offset = ((offset + 1) << 7 ) | (b[i] & 0x7f);
		} 
		
		data = [[compressedData subdataWithRange:NSMakeRange(i+1, objectSize)] zlibInflate];
	}
	else if ( type == OBJ_REF_DELTA )
	{
		baseSha1 = [compressedData subdataWithRange:NSMakeRange(0, 20)];
		data = [[compressedData subdataWithRange:NSMakeRange(20, objectSize)]zlibInflate];
	}
	else
	{
		data = [compressedData zlibInflate];
	}
	
	debug = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	switch( type )
	{
		case OBJ_COMMIT:
			object = [[GitCommitObject alloc] initWithData: data sha1: key];
			break;
		case OBJ_TREE:
			object = [[GitTreeObject alloc] initWithData: data];
			break;
		case OBJ_BLOB:
			object = [[GitBlobObject alloc] initWithData: data];
			break;
		case OBJ_TAG:
			break;
		case OBJ_OFS_DELTA:
			break;
		case OBJ_REF_DELTA:
			break;
	}
	
	return object;
}


- (void) dealloc
{
//	[packFileHandle release];
	
	free( index );
	[super dealloc];
}

/*
 
#include "git-compat-util.h"
#include "delta.h"
 
void *patch_delta( const void *src_buf, 
                   unsigned long src_size,
				   const void *delta_buf, 
				   unsigned long delta_size,
				   unsigned long *dst_size)
18 {
	19 	const unsigned char *data, *top;
	20 	unsigned char *dst_buf, *out, cmd;
	21 	unsigned long size;
	22 
	23 	if (delta_size < DELTA_SIZE_MIN)
		24 		return NULL;
	25 
	26 	data = delta_buf;
	27 	top = (const unsigned char *) delta_buf + delta_size;
	28 
	29 	// make sure the orig file size matches what we expect 
	30 	size = get_delta_hdr_size(&data, top);
	31 	if (size != src_size)
		32 		return NULL;
	33 
	34 	// now the result size 
	35 	size = get_delta_hdr_size(&data, top);
	36 	dst_buf = xmallocz(size);
	37 
	38 	out = dst_buf;
	39 	while (data < top) {
		40 		cmd = *data++;
		41 		if (cmd & 0x80) {
			42 			unsigned long cp_off = 0, cp_size = 0;
			43 			if (cmd & 0x01) cp_off = *data++;
			44 			if (cmd & 0x02) cp_off |= (*data++ << 8);
			45 			if (cmd & 0x04) cp_off |= (*data++ << 16);
			46 			if (cmd & 0x08) cp_off |= ((unsigned) *data++ << 24);
			47 			if (cmd & 0x10) cp_size = *data++;
			48 			if (cmd & 0x20) cp_size |= (*data++ << 8);
			49 			if (cmd & 0x40) cp_size |= (*data++ << 16);
			50 			if (cp_size == 0) cp_size = 0x10000;
			51 			if (cp_off + cp_size < cp_size ||
							52 			    cp_off + cp_size > src_size ||
							53 			    cp_size > size)
				54 				break;
			55 			memcpy(out, (char *) src_buf + cp_off, cp_size);
			56 			out += cp_size;
			57 			size -= cp_size;
			58 		} else if (cmd) {
				59 			if (cmd > size)
					60 				break;
				61 			memcpy(out, data, cmd);
				62 			out += cmd;
				63 			data += cmd;
				64 			size -= cmd;
				65 		} else {
					66 			//
								// 67 			 * cmd == 0 is reserved for future encoding
								// 68 			 * extensions. In the mean time we must fail when
								// 69 			 * encountering them (might be data corruption).
								// 70 			
					71 			error("unexpected delta opcode 0");
					72 			goto bad;
					73 		}
		74 	}
	75 
	76 	// sanity check
	77 	if (data != top || size != 0) {
		78 		error("delta replay has gone wild");
		79 		bad:
		80 		free(dst_buf);
		81 		return NULL;
		82 	}
	83 
	84 	*dst_size = out - dst_buf;
	85 	return dst_buf;
	86 }*/

@end
