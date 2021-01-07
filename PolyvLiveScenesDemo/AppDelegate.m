//
//  AppDelegate.m
//  PolyvLiveEcommerceDemo
//
//  Created by Lincal on 2020/4/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "AppDelegate.h"
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // HttpDNS默认开启，如需关闭，解开注释
//    [PLVLiveVideoConfig sharedInstance].enableHttpDNS = NO;
    
    return YES;
}

@end
