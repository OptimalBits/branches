//
//  CocoaCryptoHashing.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CocoaCryptoHashing.h"


/*
 2  * CocoaCryptoHashing.m
 3  * CocoaCryptoHashing
 4  */
 
 #import "CocoaCryptoHashing.h"
 
 #if TARGET_OS_MAC && (TARGET_OS_IPHONE || MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4)
 
#define COMMON_DIGEST_FOR_OPENSSL
#import <CommonCrypto/CommonDigest.h>
 
#define MD5(data, len, md)          CC_MD5(data, len, md)
#define SHA1(data, len, md)         CC_SHA1(data, len, md)
 
 #else
 
#import <openssl/md5.h>
#import <openssl/sha.h>
#endif

@implementation NSString (CocoaCryptoHashing)
 
 - (NSData *)md5Hash
 {
     	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] md5Hash];
	}

 - (NSString *)md5HexHash
 {
return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] md5HexHash];
	}

- (NSData *)sha1Hash
{
	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] sha1Hash];
}
 
 - (NSString *)sha1HexHash
 {
     	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] sha1HexHash];
	}

@end
 
@implementation NSData (CocoaCryptoHashing)

 - (NSString *)md5HexHash
{
	unsigned char digest[MD5_DIGEST_LENGTH];
    char finaldigest[2*MD5_DIGEST_LENGTH];
    int i;
     	
	MD5([self bytes],[self length],digest);
     	
	for(i=0;i<MD5_DIGEST_LENGTH;i++) sprintf(finaldigest+i*2,"%02x",digest[i]);
     	return [NSString stringWithUTF8String:finaldigest];
	}

- (NSData *)md5Hash
{
	unsigned char digest[MD5_DIGEST_LENGTH];
     	
	MD5([self bytes],[self length],digest);
     	
    return [NSData dataWithBytes:&digest length:MD5_DIGEST_LENGTH];
}

- (NSString *)sha1HexHash
{
	unsigned char digest[SHA_DIGEST_LENGTH];
    char finaldigest[2*SHA_DIGEST_LENGTH];
    int i;
     	
    SHA1([self bytes],[self length],digest);
    
	for(i=0;i<SHA_DIGEST_LENGTH;i++) sprintf(finaldigest+i*2,"%02x",digest[i]);
     	
    return [NSString stringWithUTF8String:finaldigest];
    }

- (NSData *)sha1Hash
{
    unsigned char digest[SHA_DIGEST_LENGTH];
     	
    SHA1([self bytes],[self length],digest);
	
    return [NSData dataWithBytes:&digest length:SHA_DIGEST_LENGTH];
}

@end
