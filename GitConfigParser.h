//
//  GitConfigParser.h
//  gitfend
//
//  Created by Manuel Astudillo on 8/1/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/**
 BNF:
 
 start ::= section*
 section ::= '[' section_name subsection_name? ']' key_value*
 key_values ::= ( key '=' value ) | key 
 
 
 
 */


@interface GitConfigParser : NSObject {

}

@end
