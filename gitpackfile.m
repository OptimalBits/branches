//
//  gitpack.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/20/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gitpackfile.h"
#import "gitobject.h"
#import "gitcommitobject.h"
#import "gittreeobject.h"
#import "GitBlobObject.h"
#import "NSDataExtension.h"


NSData *patch_delta( NSData *src, NSData *delta );

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
		[file closeFile];
	}
	return self;
}

-(void) dealloc
{
	free( keys );
    free( offsets );
	free( crcs );
	[super dealloc];
}

- (uint32_t) findObjectOffset:(NSData*) key
{
	int start;
	int end;
	int i;
	uint8_t idx;
	uint8_t *shaKey;
	uint32_t offset = 0;
	
	shaKey = (uint8_t*) [key bytes];
	idx = shaKey[0];
	
	if ( idx == 0 )
	{
		start = 0;
	}
	else
	{
		start = fanouts[idx-1];
    }
    
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
		
		// We may need to open this file to avoid problems if using git from
		// the command line at the same time ( fopen ).
		NSString *path = [packURL path];

		packFile = [NSData dataWithContentsOfMappedFile:path];
		[packFile retain];
	}
	return self;
}

-(void) dealloc
{
	[packFile release];
    [pack release];
	[index release];
	[super dealloc];
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
	NSData *data;
	GitObject *object = nil;
	GitRawObject rawObject;
	
	[self getRawObjectWithKey:key output:&rawObject];

	data = rawObject.data;
	if ( data == nil )
	{
		return nil;
	}
	
	switch( rawObject.type )
	{
		case OBJ_COMMIT:
			object = [[[GitCommitObject alloc] initWithData: data sha1: key] autorelease];
			break;
		case OBJ_TREE:
			object = [[[GitTreeObject alloc] initWithData: data] autorelease];
			break;
		case OBJ_BLOB:
			object = [[[GitBlobObject alloc] initWithData: data] autorelease];
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

-(void) getRawObjectWithKey:(NSData *)key output:(GitRawObject *)rawObject
{
	uint32_t offset;
	offset = [index findObjectOffset:key];
	
	[self getRawObject:offset output:rawObject];
}

-(void) getRawObject:(uint32_t) offset output: (GitRawObject*) rawObject
{
	uint8_t byte;
	uint8_t type;
	
	uint64_t objectSize;
	int i;
	
	NSData *baseSha1;
	NSData *data;
	
	
	const uint8_t *packFileData = [packFile bytes];
	
	// seek to offset
	packFileData += offset;
	
	byte = *packFileData++;
	
    type = (byte >> 4) & 0x07;
    objectSize = byte & 0x0f;
	i = 0;
	while ( byte & 0x80 )
	{
		byte = *packFileData++;
		objectSize += (byte & 0x7f) << ((i * 7 ) + 4);
	    i ++;
	}
	
	if ( type == OBJ_OFS_DELTA )
	{
		uint64_t relOffset;
		
		relOffset = *packFileData & 0x7f;
		while ( *packFileData & 0x80 ) 
		{
			packFileData ++;
			relOffset = ((relOffset + 1) << 7 ) | (*packFileData & 0x7f);
		} 
		packFileData++;
		
		data = [NSData dataWithZlibInflate: packFileData length: objectSize];
		
		if ( data )
		{
			[self getRawObject:offset-relOffset output:rawObject];
			data = patch_delta( rawObject->data, data );
		}
		type = rawObject->type;
	}
	else if ( type == OBJ_REF_DELTA )
	{
		baseSha1 = [NSData dataWithBytes:packFileData length:20];
		packFileData += 20;
		
		data = [NSData dataWithZlibInflate: packFileData length: objectSize];
		[self getRawObjectWithKey:baseSha1 output:rawObject];
		data = patch_delta( rawObject->data, data );
		type = rawObject->type;
	}
	else
	{
		data = [NSData dataWithZlibInflate: packFileData length: objectSize];
	}
	
	rawObject->data = data;
	rawObject->type = type;
}


unsigned long get_delta_hdr_size( const unsigned char **datap,
								  const unsigned char *top)
{
	const unsigned char *data = *datap;
	unsigned long cmd, size = 0;
	int i = 0;
	do {
		cmd = *data++;
		size |= (cmd & 0x7f) << i;
		i += 7;
	} while (cmd & 0x80 && data < top);
	*datap = data;
	return size;
}

NSData *patch_delta( NSData *src, NSData *delta )
{
	const void *src_buf = [src bytes];
	unsigned long src_size = [src length];
	const void *delta_buf = [delta bytes];
	unsigned long delta_size = [delta length];
	
	const unsigned char *data, *top;
	unsigned char *dst_buf, *out, cmd;
	unsigned long size;
	
	// if (delta_size < DELTA_SIZE_MIN)
	//			return NULL;
	
	data = delta_buf;
	top = (const unsigned char *) delta_buf + delta_size;
	
	// make sure the orig file size matches what we expect 
	size = get_delta_hdr_size(&data, top);
	if (size != src_size)
		return NULL;
	
	// now the result size 
	size = get_delta_hdr_size(&data, top);
	
	NSMutableData *dst = [NSMutableData dataWithLength:size];
	dst_buf = [dst mutableBytes];
	
	out = dst_buf;
	while (data < top) 
	{
		cmd = *data++;
		if (cmd & 0x80) 
		{
			unsigned long cp_off = 0, cp_size = 0;
			if (cmd & 0x01) cp_off = *data++;
			if (cmd & 0x02) cp_off |= (*data++ << 8);
			if (cmd & 0x04) cp_off |= (*data++ << 16);
			if (cmd & 0x08) cp_off |= ((unsigned) *data++ << 24);
			if (cmd & 0x10) cp_size = *data++;
			if (cmd & 0x20) cp_size |= (*data++ << 8);
			if (cmd & 0x40) cp_size |= (*data++ << 16);
			if (cp_size == 0) cp_size = 0x10000;
			if (cp_off + cp_size < cp_size ||
				cp_off + cp_size > src_size ||
				cp_size > size)
				break;
			memcpy(out, (char *) src_buf + cp_off, cp_size);
			out += cp_size;
			size -= cp_size;
		} 
		else if (cmd) 
		{
			if (cmd > size)
				break;
			memcpy(out, data, cmd);
			out += cmd;
			data += cmd;
			size -= cmd;
		} 
		else 
		{
			//
			// 	     * cmd == 0 is reserved for future encoding
			// 		 * extensions. In the mean time we must fail when
			// 	     * encountering them (might be data corruption).
			// 			
			NSLog(@"unexpected delta opcode 0");
			goto bad;
		}
	}
	
	// sanity check
	if (data != top || size != 0)
	{
		NSLog(@"delta replay has gone wild");
	bad:
		free(dst_buf);
		return NULL;
	}
	
	//*dst_size = out - dst_buf;
	return dst;
}

@end
