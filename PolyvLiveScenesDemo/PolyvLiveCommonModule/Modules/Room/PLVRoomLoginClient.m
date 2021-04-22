//
//  PLVRoomLoginClient.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVLiveVideoAPI.h>
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>
#import <PLVLiveScenesSDK/PLVWLogReporterManager.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>

@implementation PLVRoomLoginClient

+ (void)loginLiveRoomWithChannelType:(PLVChannelType)channelType
                           channelId:(NSString *)channelId
                              userId:(NSString *)userId
                               appId:(NSString *)appId
                           appSecret:(NSString *)appSecret
                            roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                          completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                             failure:(void (^)(NSString *errorMessage))failure {
    if (channelType <= PLVChannelTypeUnknown) {
        !failure ?: failure(@"频道类型无效");
        return;
    }
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(@"频道号不可为空");
        return;
    }
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(@"账号信息不可为空");
        return;
    }
    
    [PLVLiveVideoAPI verifyLivePermissionWithChannelId:channelId.integerValue userId:userId appId:appId appSecret:appSecret completion:^(NSDictionary * _Nonnull data) {
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        [PLVLiveVideoAPI liveStatus2:channelId completion:^(PLVChannelType apiChannelType, PLVChannelLiveStreamState liveState) {
            if ((apiChannelType & channelType) <= 0) {
                !failure ?: failure(@"频道类型出错");
            } else {
                // 初始化直播间数据
                PLVRoomData *roomData = [[PLVRoomData alloc] init];
                roomData.liveState = liveState;
                roomData.channelType = apiChannelType;
                roomData.videoType = PLVChannelVideoType_Live;
                roomData.channelId = channelId;

                // 使用roomUserHandler配置用户对象
                PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:apiChannelType];
                if (roomUserHandler) {
                    roomUserHandler(roomUser);
                }
                [roomData setupRoomUser:roomUser];
                
                // 登陆SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
                [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
                // 注册日志管理器
                [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId appId:appId appSecret:appSecret userId:userId];
                
                // 将当前的roomData配置到PLVRoomDataManager进行管理
                [[PLVRoomDataManager sharedManager] configRoomData:roomData];
                
                [roomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
                    !completion ?: completion(roomData.customParam);
                }];
            }
        } failure:^(NSError * _Nonnull error) {
            !failure ?: failure(@"获取频道类型失败");
        }];
    } failure:^(NSError * _Nonnull error) {
        !failure ?: failure(@"登陆校验失败");
    }];
}

+ (void)loginPlaybackRoomWithChannelType:(PLVChannelType)channelType
                               channelId:(NSString *)channelId
                                     vid:(NSString *)vid
                                  userId:(NSString *)userId
                                   appId:(NSString *)appId
                               appSecret:(NSString *)appSecret
                                roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                              completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                                 failure:(void (^)(NSString *errorMessage))failure {
    if (channelType <= PLVChannelTypeUnknown) {
        !failure ?: failure(@"频道类型无效");
        return;
    }
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(@"频道号不可为空");
        return;
    }
    if (![PLVFdUtil checkStringUseable:vid]) {
        !failure ?: failure(@"视频vid不可为空");
        return;
    }
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(@"账号信息不可为空");
        return;
    }
    [PLVLiveVideoAPI verifyVodPermissionWithChannelId:channelId.integerValue vid:vid userId:userId appId:appId appSecret:appSecret completion:^(NSDictionary * _Nonnull data) {
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        [PLVLiveVideoAPI getVodType:vid completion:^(PLVChannelType apiChannelType) {
            if ((apiChannelType & channelType) <= 0) {
                !failure ?: failure(@"频道类型出错");
            } else {
                // 初始化直播间数据
                PLVRoomData *roomData = [[PLVRoomData alloc] init];
                roomData.videoType = PLVChannelVideoType_Playback;
                roomData.channelType = apiChannelType;
                roomData.channelId = channelId;
                roomData.vid = vid;

                // 使用roomUserHandler配置用户对象
                PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:apiChannelType];
                if (roomUserHandler) {
                    roomUserHandler(roomUser);
                }
                [roomData setupRoomUser:roomUser];
                
                // 登陆SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
                [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
                // 注册日志管理器
                [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId appId:appId appSecret:appSecret userId:userId vId:vid];
                
                // 将当前的roomData配置到PLVRoomDataManager进行管理
                [[PLVRoomDataManager sharedManager] configRoomData:roomData];
                
                [roomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
                    !completion ?: completion(roomData.customParam);
                }];
            }
        } failure:^(NSError * _Nonnull error) {
            !failure ?: failure(@"获取频道类型失败");
        }];
    } failure:^(NSError * _Nonnull error) {
        !failure ?: failure(@"登陆校验失败");
    }];
}

+ (void)logout {
    [[PLVRoomDataManager sharedManager] removeRoomData];
    [[PLVWLogReporterManager sharedManager] clear];
}

@end
