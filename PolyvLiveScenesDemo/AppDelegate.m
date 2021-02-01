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
    // 如需启用IPV6，解开注释，启用IPV6之后，将自动选择IP，取消HttpDNS
//    [PLVLiveVideoConfig sharedInstance].enableIPV6 = YES;
    
    return YES;
}

@end
