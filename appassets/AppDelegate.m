//
//  AppDelegate.m
//  appassets
//
//  Created by 陈曦1 on 2021/1/5.
//

#import "AppDelegate.h"

@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
//    [NSApplication sharedApplication].delegate = self;
}


/**
 app左上角关闭按钮点击询问是否关闭 app 的代理
 */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
