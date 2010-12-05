//
//  unittest1.m
//  gitfend
//
//  Created by Ulf Holmstedt on 2010-11-04.
//  Copyright 2010 CodeTonic. All rights reserved.
//




#import <GHUnit/GHUnit.h>

#import "GitRepo.h"
#import "GitIndex.h"

@interface commitTest : GHTestCase {
    NSURL *url;
}
@end

@implementation commitTest

- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES
    return NO;
}

- (void)setUpClass {
    // Run at start of all tests in the class
    url = [NSURL fileURLWithPath:@"/tmp/testRepo" isDirectory:YES];
}

- (void)tearDownClass {
    // Run at end of all tests in the class
}

- (void)setUp {
    // Run before each test method
    system("/Users/ulfh/source/git/testGit.sh");
}

- (void)tearDown {
    // Run after each test method
}

- (void)testRepoValidation {
    NSURL *tmpUrl = [NSURL fileURLWithPath:@"/tmp" isDirectory:YES];
    
    GHAssertTrue([GitRepo isValidRepo:url], @"isValidRepo failed on testRepo.");
    GHAssertFalse([GitRepo isValidRepo:tmpUrl], @"isValidRepo reported true on /tmp.");
}

- (void)testSimpleCommit {
    GitRepo *repo = [[GitRepo alloc] initWithUrl:url name:@"TestRepo"];
    GitIndex *index = [repo index];

    NSSet *modified = [index modifiedFiles:url];
    for (NSString *s in modified) {
        NSLog(@"modified file: %@", s);
    }
}

@end
