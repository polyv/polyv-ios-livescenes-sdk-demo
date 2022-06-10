//
//  PLVRoomLoginClient.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
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
/// @param vodList 是否请求点播列表视频，默认NO
/// @param vid 视频id（可不填，不填时加载回放/点播列表）
/// @param userId 用户id
/// @param appId 应用id
/// @param appSecret 应用secret
/// @param roomUserHandler 返回带有默认值的观看用户实例对象，可在block中配置viewerId、viewerName、viewerAvatar属性
/// @param completion 登录成功，带上自定义参数对象，用户可在回调里面设置后台统计所需的自定义参数
/// @param failure 登录失败
+ (void)loginPlaybackRoomWithChannelType:(PLVChannelType)channelType
                               channelId:(NSString *)channelId
                                 vodList:(BOOL)vodList
                                     vid:(NSString * _Nullable)vid
                                  userId:(NSString *)userId
                                   appId:(NSString *)appId
                               appSecret:(NSString *)appSecret
                                roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                              completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                                 failure:(void (^)(NSString *errorMessage))failure;

/// 登录离线回放直播间
/// @param channelType 频道类型，若支持多种类型，可对多个频道类型枚举值使用 | 进行位或
/// @param channelId 频道号
/// @param vodList 是否请求点播列表视频，默认NO
/// @param vid 视频id（可不填，不填时加载回放/点播列表）
/// @param fileId 暂存视频的fileId（可不填，不填时加载最新暂存视频）
/// @param userId 用户id
/// @param appId 应用id
/// @param appSecret 应用secret
/// @param roomUserHandler 返回带有默认值的观看用户实例对象，可在block中配置viewerId、viewerName、viewerAvatar属性
/// @param completion 登录成功，带上自定义参数对象，用户可在回调里面设置后台统计所需的自定义参数
/// @param failure 登录失败
+ (void)loginOfflinePlaybackRoomWithChannelType:(PLVChannelType)channelType
                                      channelId:(NSString *)channelId
                                        vodList:(BOOL)vodList
                                            vid:(NSString * _Nullable)vid
                                   recordFileId:(NSString * _Nullable)fileId
                                         userId:(NSString *)userId
                                          appId:(NSString *)appId
                                      appSecret:(NSString *)appSecret
                                       roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                                     completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                                        failure:(void (^)(NSString *errorMessage))failure;

/// 登录回放直播间（已废弃）
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
                                 failure:(void (^)(NSString *errorMessage))failure __deprecated_msg("use [+loginPlaybackRoomWithChannelType:channelId:vodList:vid:userId:appId:appSecret:roomUser:completion:failure:] instead.");

/// 登录开播直播间
/// @param channelType 频道类型，目前只支持 PLVChannelTypeAlone 或者 PLVChannelTypePPT
/// @param channelId 频道号
/// @param password 频道密码
/// @param nickName 教师昵称
/// @param completion 登录成功
/// @param failure 登录失败
+ (void)loginStreamerRoomWithChannelType:(PLVChannelType)channelType
                               channelId:(NSString *)channelId
                                password:(NSString *)password
                                nickName:(NSString * _Nullable)nickName
                              completion:(void (^)(void))completion
                                 failure:(void (^)(NSString *errorMessage))failure;

/// 离开直播间时调用，包括离开互动学堂教室
+ (void)logout;

#pragma mark - HiClass

/// 讲师端进入互动学堂教室
/// @param viewerId 用户ID
/// @param viewerName 用户昵称
/// @param lessonId 课节ID
/// @param completion 登录成功
/// @param failure 登录失败
+ (void)teacherEnterHiClassWithViewerId:(NSString *)viewerId
                                viewerName:(NSString *)viewerName
                                  lessonId:(NSString *)lessonId
                                completion:(void (^)(void))completion
                                   failure:(void (^)(NSString *errorMessage))failure;

/// 观看端进入互动学堂教室
/// @param viewerId 用户ID
/// @param viewerName 用户昵称 
/// @param courseCode 课程号
/// @param lessonId 课节ID
/// @param completion 登录成功
/// @param failure 登录失败
+ (void)watcherEnterHiClassWithViewerId:(NSString *)viewerId
                                viewerName:(NSString *)viewerName
                                courseCode:(NSString * _Nullable)courseCode
                                  lessonId:(NSString *)lessonId
                                completion:(void (^)(void))completion
                                   failure:(void (^)(NSString *errorMessage))failure;

@end

NS_ASSUME_NONNULL_END
