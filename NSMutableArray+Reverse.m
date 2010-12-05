//
//  NSMutableArray+Reverse.m
//  gitfend
//
//  Created by Manuel Astudillo on 12/4/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import "NSMutableArray+Reverse.h"


@implementation NSMutableArray (Reverse)

- (void)reverse {
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j) {
        [self exchangeObjectAtIndex:i withObjectAtIndex:j];
		
        i++;
        j--;
    }
}

@end
