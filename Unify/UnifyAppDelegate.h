//
//  UnifyAppDelegate.h
//  Unify
//
//  Created by Manuel Astudillo on 1/25/11.
//  Copyright 2011 CodeTonic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UnifyAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
