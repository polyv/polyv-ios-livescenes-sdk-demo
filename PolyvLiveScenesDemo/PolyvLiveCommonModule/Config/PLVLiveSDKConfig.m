//
//  PLVLiveSDKConfig.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/12.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveSDKConfig.h"

/*
 history(release):
    0.2.4+200703、0.2.5+200707、0.2.6+200708、0.2.7+200709
 */
#define LiveCommonModul_version @"0.3.0+200907"

@interface PLVLiveAccount ()

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appSecret;

@end

@implementation PLVLiveAccount

+ (instancetype)accountWithUserId:(NSString *)userId appId:(NSString *)appId appSecret:(NSString *)appSecret {
    if (userId && appId && appSecret) {
        PLVLiveAccount *accout = [[PLVLiveAccount alloc] init];
        accout.userId = userId;
        accout.appId = appId;
        accout.appSecret = appSecret;
        return accout;
    } else {
        return nil;
    }
}

@end

@interface PLVLiveSDKConfig ()

@end

@implementation PLVLiveSDKConfig

static PLVLiveSDKConfig *_sdkConfig = nil;

+ (NSString *)sdkVersion {
    return LiveCommonModul_version;
}

+ (instancetype)sharedSDK {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sdkConfig = [[super allocWithZone:NULL] init];
        _sdkConfig.debugLevel = 0;
        _sdkConfig.socketDebug = NO;
    });
    return _sdkConfig;
}

+ (void)configAccountWithUserId:(NSString *)userId appId:(NSString *)appId appSecret:(NSString *)appSecret {
    PLVLiveAccount *account = [PLVLiveAccount accountWithUserId:userId appId:appId appSecret:appSecret];
    [[self sharedSDK] setAccount:account];
}

@end
