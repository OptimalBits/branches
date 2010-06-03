//
//  CocoaCryptoHashing.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*
   * CocoaCryptoHashing.h
   * CocoaCryptoHashing
*/

#import <Foundation/Foundation.h>
 
@interface NSString (CocoaCryptoHashing)
 
/*!
	* @method md5Hash
    * @abstract Calculates the MD5 hash from the UTF-8 representation of the specified string  and returns the binary representation
    * @result A NSData object containing the binary representation of the MD5 hash
*/
- (NSData *)md5Hash;
/*!
    18  * @method md5HexHash
    19  * @abstract Calculates the MD5 hash from the UTF-8 representation of the specified string and returns the hexadecimal representation
    20  * @result A NSString object containing the hexadecimal representation of the MD5 hash
    21  */
- (NSString *)md5HexHash;
 
 /*!
    25  * @method sha1Hash
    26  * @abstract Calculates the SHA-1 hash from the UTF-8 representation of the specified string  and returns the binary representation
    27  * @result A NSData object containing the binary representation of the SHA-1 hash
    28  */
 - (NSData *)sha1Hash;
/*!
    32  * @method sha1HexHash
    33  * @abstract Calculates the SHA-1 hash from the UTF-8 representation of the specified string and returns the hexadecimal representation
    34  * @result A NSString object containing the hexadecimal representation of the SHA-1 hash
    35  */
- (NSString *)sha1HexHash;
@end

@interface NSData (CocoaCryptoHashing)

/*!
      * @method md5Hash
      * @abstract Calculates the MD5 hash from the data in the specified NSData object  and returns the binary representation
      * @result A NSData object containing the binary representation of the MD5 hash
      */
 - (NSData *)md5Hash;
 
 /*!
      * @method md5HexHash
      * @abstract Calculates the MD5 hash from the data in the specified NSData object and returns the hexadecimal representation
      * @result A NSString object containing the hexadecimal representation of the MD5 hash
      */
- (NSString *)md5HexHash;
 
/*!
      * @method sha1Hash
      * @abstract Calculates the SHA-1 hash from the data in the specified NSData object  and returns the binary representation
      * @result A NSData object containing the binary representation of the SHA-1 hash
      */
- (NSData *)sha1Hash;
 
/*!
      * @method sha1HexHash
      * @abstract Calculates the SHA-1 hash from the data in the specified NSData object and returns the hexadecimal representation
      * @result A NSString object containing the hexadecimal representation of the SHA-1 hash
      */
- (NSString *)sha1HexHash;
 
@end

