//
//  AppDelegate.m
//  PLVLiveEcommerceDemo
//
//  Created by Lincal on 2020/4/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "AppDelegate.h"

/*
 SCENE = 1: 多场景通用入口
 SCENE = 2: 多场景-手机开播
 SCENE = 3: 多场景-手机观看
 SCENE = 4: 多场景-互动学堂
 */

#if SCENE == 1
#import "PLVEnteranceViewController.h"
#endif

#if SCENE == 2
#import "PLVLiveStreamerLoginViewController.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#endif

#if SCENE == 3
//场景3使用Main.storyboard进入登陆页，所以无需导入登录页ViewController类
#endif

#if SCENE == 4
#import "PLVHCTeacherLoginManager.h"
#endif

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if SCENE == 1
    // HttpDNS默认开启，如需关闭，解开注释
//    [PLVLiveVideoConfig sharedInstance].enableHttpDNS = NO;
    // 如需启用IPV6，解开注释，启用IPV6之后，将自动选择IP，取消HttpDNS
//    [PLVLiveVideoConfig sharedInstance].enableIPV6 = YES;
    
    
    PLVEnteranceViewController *vctrl = [[PLVEnteranceViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = vctrl;
    [self.window makeKeyAndVisible];
#endif
    
#if SCENE == 2
    if (@available(iOS 10.0, *)) {
        [PLVNetworkAccessibility setAlertEnable:YES];
        [PLVNetworkAccessibility start];
    }
    PLVLiveStreamerLoginViewController *vctrl = [[PLVLiveStreamerLoginViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = vctrl;
    [self.window makeKeyAndVisible];
#endif
    
#if SCENE == 3 //场景3使用Main.storyboard进入登陆页
    // HttpDNS默认开启，如需关闭，解开注释
//    [PLVLiveVideoConfig sharedInstance].enableHttpDNS = NO;
    // 如需启用IPV6，解开注释，启用IPV6之后，将自动选择IP，取消HttpDNS
//    [PLVLiveVideoConfig sharedInstance].enableIPV6 = YES;
#endif
   
#if SCENE == 4
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [PLVHCTeacherLoginManager loadMainViewController];
    [self.window makeKeyAndVisible];
#endif
    
    // DEBUG模式下控制台日志打印
    // 当logLevel为PLVFConsoleLogLevelOFF时关闭所有PLV控制台日志
    [PLVConsoleLogger defaultLogger].logLevel = PLVFConsoleLogLevelALL;
    
    return YES;
}

@end
