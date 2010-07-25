//
//  gittreeobject.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/25/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "gittreeobject.h"


@implementation GitTreeNode

@synthesize sha1;
@synthesize mode;

@end


@implementation GitTreeObject

@synthesize tree;

- (id) initWithData: (NSData*) data
{
	int i, start, len;
	const uint8_t *bytes;
	
	if ( self = [super init] )
    {
		tree = [[NSMutableDictionary alloc] init];
		
		bytes = [data bytes];
		
		i = 0;
		while( i < [data length] )
		{
			NSString *modeAndName;
			NSData *sha1;
			
			start = i;
			len = 0;
			while( ( i < [data length] ) && ( bytes[i] != 0 ) )
			{
				len++;
				i++;
			}
			
			modeAndName = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(start,len)] encoding:NSUTF8StringEncoding];
			
			sha1 = [data subdataWithRange:NSMakeRange(start+len+1, 20)];
			i +=21;
			
			[tree setObject:[modeAndName componentsSeparatedByString:@" "] forKey:sha1];
		}
	}
	
	return self;
}

/*
def parse_tree(text):
 ret = {}
 count = 0
 l = len(text)
 while count < l:
	mode_end = text.index(' ', count)
	mode = int(text[count:mode_end], 8)

	name_end = text.index('\0', mode_end)
	name = text[mode_end+1:name_end]

	count = name_end+21

	sha = text[name_end+1:count]

	ret[name] = (mode, sha_to_hex(sha))

return ret
*/

@end
