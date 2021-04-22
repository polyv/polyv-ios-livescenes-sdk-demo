//
//  PLVRoomLoginClient.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveDefine.h>

@class PLVRoomUser, PLVViewLogCustomParam;

NS_ASSUME_NONNULL_BEGIN

@interface PLVRoomLoginClient : NSObject

/// 登录直播间
/// @param channelType 频道类型，若支持多种类型，可对多个频道类型枚举值使用 | 进行位或
/// @param channelId 频道号
/// @param userId 用户id
/// @param appId 应用id
/// @param appSecret 应用secret
/// @param roomUserHandler 返回带有默认值的观看用户实例对象，可在block中配置viewerId、viewerName、viewerAvatar属性
/// @param completion 登录成功，带上自定义参数对象，用户可在回调里面设置后台统计所需的自定义参数
/// @param failure 登录失败
+ (void)loginLiveRoomWithChannelType:(PLVChannelType)channelType
                           channelId:(NSString *)channelId
                              userId:(NSString *)userId
                               appId:(NSString *)appId
                           appSecret:(NSString *)appSecret
                            roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                          completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                             failure:(void (^)(NSString *errorMessage))failure;

/// 登录回放直播间
/// @param channelType 频道类型，若支持多种类型，可对多个频道类型枚举值使用 | 进行位或
/// @param channelId 频道号
/// @param vid 视频id
/// @param userId 用户id
/// @param appId 应用id
/// @param appSecret 应用secret
/// @param roomUserHandler 返回带有默认值的观看用户实例对象，可在block中配置viewerId、viewerName、viewerAvatar属性
/// @param completion 登录成功，带上自定义参数对象，用户可在回调里面设置后台统计所需的自定义参数
/// @param failure 登录失败
+ (void)loginPlaybackRoomWithChannelType:(PLVChannelType)channelType
                               channelId:(NSString *)channelId
                                     vid:(NSString *)vid
                                  userId:(NSString *)userId
                                   appId:(NSString *)appId
                               appSecret:(NSString *)appSecret
                                roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                              completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                                 failure:(void (^)(NSString *errorMessage))failure;

/// 离开直播间时调用
+ (void)logout;

@end

NS_ASSUME_NONNULL_END
