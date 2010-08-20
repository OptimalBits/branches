//
//  NSDataExtension.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/23/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//  

#import <Foundation/Foundation.h>

@interface NSData (NSDataExtension)

// Returns range [start, null byte), or (NSNotFound, 0).
- (NSRange) rangeOfNullTerminatedBytesFrom:(int)start;

// Canonical Base32 encoding/decoding.
+ (NSData *) dataWithBase32String:(NSString *)base32;
- (NSString *) base32String;

// Base 16 ( Hexadeciman ) encoding/decoding
+ (NSData *) dataWithHexCString:(const char *) hex;
+ (NSData *) dataWithHexString:(NSString *) hex;
- (NSString*)base16String;

+ (NSData *)dataWithZlibInflate: (const uint8_t*) bytes 
						 length: (uint32_t) length;

// COBS is an encoding that eliminates 0x00.
- (NSData *) encodeCOBS;
- (NSData *) decodeCOBS;

// ZLIB
- (NSData *) zlibInflate;
- (NSData *) zlibDeflate;

// GZIP
- (NSData *) gzipInflate;
- (NSData *) gzipDeflate;

//CRC32
- (unsigned int)crc32;

// Hash
- (NSData*)   md5Digest;
- (NSString*) md5DigestString;
- (NSData*)   sha1Digest;
- (NSString*) sha1DigestString;
- (NSData*)   ripemd160Digest;
- (NSString*) ripemd160DigestString;

@end
