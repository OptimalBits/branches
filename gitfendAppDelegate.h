//
//  gitfendAppDelegate.h
//  gitfend
//
//  Created by Manuel Astudillo on 5/4/10.
//  Copyright 2010 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface gitfendAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

//@property (assign) IBOutlet GitFrontRepositories *repos;
@property (assign) IBOutlet NSWindow *window;


@end
