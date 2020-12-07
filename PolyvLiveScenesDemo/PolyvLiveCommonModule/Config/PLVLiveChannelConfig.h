//
//  PLVLiveChannel.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/26.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveConfigProtocol.h>
#import <PLVLiveScenesSDK/PLVVodConfigProtocol.h>
#import "PLVLiveSDKConfig.h"
#import "PLVLiveWatchUser.h"

/// 直播频道信息（初始化配置）
@interface PLVLiveChannelConfig : NSObject <PLVLiveConfigProtocol, PLVVodConfigProtocol>

/// 直播帐号
@property (nonatomic, strong, readonly) PLVLiveAccount *account;

/// 直播观看用户
@property (nonatomic, strong, readonly) PLVLiveWatchUser *watchUser;

/// 直播频道号（主频道号）
@property (nonatomic, copy, readonly) NSString *channelId;

/// 直播回放视频id（回放）
@property (nonatomic, copy, readonly) NSString *vid;

/// 播放视频优先解码方式，默认YES，硬解码
@property (nonatomic, assign) BOOL videoToolBox;

/// 是否启用 HttpDNS
@property (nonatomic, assign) BOOL enableHttpDNS;

/// 初始化一个直播频道对象
/// @param channelId 频道号
/// @param watchUser 观看用户信息
/// @param account 帐号信息
+ (instancetype)channelWithChannelId:(NSString *)channelId watchUser:(PLVLiveWatchUser *)watchUser account:(PLVLiveAccount *)account;

/// 初始化一个直播回放频道对象
/// @param channelId 频道号
/// @param vid 视频vid
/// @param watchUser 观看用户信息
/// @param account 帐号信息
+ (instancetype)channelWithChannelId:(NSString *)channelId vid:(NSString *)vid watchUser:(PLVLiveWatchUser *)watchUser account:(PLVLiveAccount *)account;

/// 初始化一个直播回放频道对象(无用户信息)
/// @param channelId 频道号
/// @param vid 视频vid
/// @param account 帐号信息
+ (instancetype)channelWithChannelId:(NSString *)channelId vid:(NSString *)vid account:(PLVLiveAccount *)account;

@end
