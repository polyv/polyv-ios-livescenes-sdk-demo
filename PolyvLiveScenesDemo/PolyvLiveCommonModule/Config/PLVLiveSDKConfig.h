//
//  PLVLiveSDKConfig.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/12.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 直播账号信息
@interface PLVLiveAccount : NSObject

/// 账号Id
@property (nonatomic, copy, readonly) NSString *userId;

/// 应用Id
@property (nonatomic, copy, readonly) NSString *appId;

/// 应用密匙
@property (nonatomic, copy, readonly) NSString *appSecret;

/// 初始化直播账号对象
+ (instancetype)accountWithUserId:(NSString *)userId appId:(NSString *)appId appSecret:(NSString *)appSecret;

@end

/// 直播SDK配置信息
@interface PLVLiveSDKConfig : NSObject

/// SDK 调试等级，默认 0
@property (nonatomic, assign) int debugLevel;

/// socket 调试模式，默认 NO
@property (nonatomic, assign) BOOL socketDebug;

/// SDK 帐号信息
@property (nonatomic, strong) PLVLiveAccount *account;

/// SDK 版本h号
+ (NSString *)sdkVersion;

/// 单例方法
+ (instancetype)sharedSDK;

/// 配置直播账号信息
+ (void)configAccountWithUserId:(NSString *)userId appId:(NSString *)appId appSecret:(NSString *)appSecret;

@end

NS_ASSUME_NONNULL_END
