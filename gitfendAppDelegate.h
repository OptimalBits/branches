//
//  gitfendAppDelegate.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gitfendRepositories.h"

@interface gitfendAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	GitFrontRepositories *repos;
}

@property (assign) IBOutlet GitFrontRepositories *repos;
@property (assign) IBOutlet NSWindow *window;

@end
