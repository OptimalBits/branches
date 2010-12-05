//
//  unittest1.m
//  gitfend
//
//  Created by Ulf Holmstedt on 2010-11-04.
//  Copyright 2010 CodeTonic. All rights reserved.
//




#import <GHUnit/GHUnit.h>

@interface unittest1 : GHTestCase { }
@end

@implementation unittest1

- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES
    return NO;
}

- (void)setUpClass {
    // Run at start of all tests in the class
}

- (void)tearDownClass {
    // Run at end of all tests in the class
}

- (void)setUp {
    // Run before each test method
}

- (void)tearDown {
    // Run after each test method
}

- (void)testFoo {
    // GHAssertFalse( true, @"This should be false." );
}

- (void)testBar {
    // Another test
}

@end
