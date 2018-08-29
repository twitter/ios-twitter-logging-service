//
//  ExampleAppDelegate.m
//  ExampleLogger
//
//  Created on 12/24/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#import <TwitterLoggingService/TLSLog.h>
#import <TwitterLoggingService/TLSLoggingService+Advanced.h>

#import "ExampleAppConsoleViewController.h"
#import "ExampleAppDelegate.h"
#import "ExampleConfigureViewController.h"
#import "ExampleMakeLogsViewController.h"
#import "TLSLoggingService+ExampleAdditions.h"

@implementation ExampleAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TLSLoggingService prepareExample];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[ [[ExampleMakeLogsViewController alloc] init],
                                               [[ExampleAppConsoleViewController alloc] init],
                                               [[ExampleConfigureViewController alloc] init] ];

    self.window.rootViewController = self.tabBarController;
    self.window.backgroundColor = [UIColor orangeColor];
    if ([self.window respondsToSelector:@selector(setTintColor:)]) {
        self.window.tintColor = [UIColor blueColor];
    }
    [self.window makeKeyAndVisible];

    TLSLogInformation(TLSLogChannelDefault, @"%@", NSStringFromSelector(_cmd));
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    TLSLogInformation(TLSLogChannelDefault, @"%@", NSStringFromSelector(_cmd));
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    TLSLogInformation(TLSLogChannelDefault, @"%@", NSStringFromSelector(_cmd));
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    TLSLogInformation(TLSLogChannelDefault, @"%@", NSStringFromSelector(_cmd));
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    TLSLogInformation(TLSLogChannelDefault, @"%@", NSStringFromSelector(_cmd));
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    TLSLogWarning(TLSLogChannelDefault, @"%@", NSStringFromSelector(_cmd));
    [[TLSLoggingService sharedInstance] flush];
}

@end
