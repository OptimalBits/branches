//
//  main.m
//  gitfend
//
//  Created by Manuel Astudillo on 5/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitrepo.h"

int main(int argc, char *argv[])
{
	GitRepo *repo;
	
	repo = [[GitRepo alloc] initWithUrl:[NSURL fileURLWithPath:@"/Users/manuel/dev/git/cpp-gpengine/.git" isDirectory:YES]];
	
	[repo dealloc];
	
    return NSApplicationMain(argc,  (const char **) argv);
}
