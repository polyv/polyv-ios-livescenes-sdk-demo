//
//  PLVRoomLoginClient.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

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
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login live room failed with【频道类型无效】(channelType:%zd)", __FUNCTION__, channelType);
        return;
    }
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(@"频道号不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login live room failed with【频道号不可为空】(channelId:%@)", __FUNCTION__, channelId);
        return;
    }
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(@"账号信息不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login live room failed with【账号信息不可为空】(userId:%@, appId:%@, appSecret:%@)", __FUNCTION__, userId, appId, appSecret);
        return;
    }
    
    [PLVLiveVideoAPI verifyLivePermissionWithChannelId:channelId.integerValue userId:userId appId:appId appSecret:appSecret completion:^(NSDictionary * _Nonnull data) {
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        [PLVLiveVideoAPI liveStatus2:channelId completion:^(PLVChannelType apiChannelType, PLVChannelLiveStreamState liveState) {
            if ((apiChannelType & channelType) <= 0) {
                !failure ?: failure(@"频道类型出错");
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get live channel failed with【频道类型出错】(apiChannelType:%zd, channelType:%z)", __FUNCTION__, apiChannelType, channelType);
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
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get live channel failed with【%@】（获取频道类型失败）", __FUNCTION__, error);
        }];
    } failure:^(NSError * _Nonnull error) {
        !failure ?: failure(@"登陆校验失败");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify live permission failed with【%@】(登陆校验失败)", __FUNCTION__, error);
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
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【登陆校验失败】(channelType:%zd)", __FUNCTION__, channelType);
        return;
    }
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(@"频道号不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【频道号不可为空】(channelId:%@)", __FUNCTION__, channelId);
        return;
    }
    if (![PLVFdUtil checkStringUseable:vid]) {
        !failure ?: failure(@"视频vid不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【视频vid不可为空】(vid:%@)", __FUNCTION__, vid);
        return;
    }
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(@"账号信息不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【账号信息不可为空】(userId:%@, appId:%@, appSecret:%@)", __FUNCTION__, appId, appId, appSecret);
        return;
    }
    [PLVLiveVideoAPI verifyVodPermissionWithChannelId:channelId.integerValue vid:vid userId:userId appId:appId appSecret:appSecret completion:^(NSDictionary * _Nonnull data) {
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        [PLVLiveVideoAPI getVodType:vid completion:^(PLVChannelType apiChannelType) {
            if ((apiChannelType & channelType) <= 0) {
                !failure ?: failure(@"频道类型出错");
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get vod channel failed with with【频道类型出错】(apiChannelType:%zd, channelType:%zd)", __FUNCTION__, apiChannelType, channelType);

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
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get vod channel failed with【%@】（获取频道类型失败）", __FUNCTION__, error);
        }];
    } failure:^(NSError * _Nonnull error) {
        !failure ?: failure(@"登陆校验失败");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登陆校验失败)", __FUNCTION__, error);
    }];
}

+ (void)loginStreamerRoomWithChannelType:(PLVChannelType)channelType
                               channelId:(NSString *)channelId
                                password:(NSString *)password
                                nickName:(NSString *)nickName
                              completion:(void (^)(void))completion
                                 failure:(void (^)(NSString *errorMessage))failure {
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(@"频道号不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login streamer room failed with【频道号不可为空】(channelId:%@)", __FUNCTION__, channelId);

        return;
    }
    if (![PLVFdUtil checkStringUseable:password]) {
        !failure ?: failure(@"密码不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login streamer room failed with【密码不可为空】(password:%@)", __FUNCTION__, password);

        return;
    }
    if ((channelType & PLVChannelTypePPT) == 0 &&
        (channelType & PLVChannelTypeAlone) == 0) {
        !failure ?: failure(@"暂不支持该频道");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login streamer room failed with【暂不支持该频道】(channelType:%zd)", __FUNCTION__, channelType);
        return;
    }
    [PLVLiveVideoAPI loadPushInfoWithChannelId:channelId password:password channelType:channelType completion:^(NSDictionary * _Nonnull data, NSString * _Nonnull rtmpUrl) {
        // 获取频道类型
        NSString *liveScene = PLV_SafeStringForDictKey(data, @"liveScene");
        PLVChannelType apiChannelType = PLVChannelTypeUnknown;
        if ([liveScene isEqualToString:@"ppt"]) {
            apiChannelType = PLVChannelTypePPT;
        } else if ([liveScene isEqualToString:@"alone"]) {
            apiChannelType = PLVChannelTypeAlone;
        }
        
        if ((apiChannelType & channelType) <= 0) {
            !failure ?: failure(@"频道类型出错");
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login streamer room failed with【频道类型出错】(apiChannelType:%zd, channelType:%zd)", __FUNCTION__, apiChannelType, channelType);
        }
        
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        
        NSInteger rtcMaxResolution = [data[@"rtcMaxResolution"] integerValue];
        PLVResolutionType videoResolution = PLVResolutionType180P;
        if (rtcMaxResolution >= 720) {
            videoResolution = PLVResolutionType720P;
        } else if (rtcMaxResolution == 360) {
            videoResolution = PLVResolutionType360P;
        }
        
        // 初始化直播间数据
        PLVRoomData *roomData = [[PLVRoomData alloc] init];
        roomData.maxResolution = videoResolution;
        roomData.videoType = PLVChannelVideoType_Streamer;
        roomData.channelType = apiChannelType;
        roomData.channelId = PLV_SafeStringForDictKey(data, @"channelId");
        roomData.channelAccountId = PLV_SafeStringForDictKey(data, @"accountId");
        roomData.stream = PLV_SafeStringForDictKey(data, @"stream");
        roomData.currentStream = PLV_SafeStringForDictKey(data, @"currentStream");
        roomData.channelName = PLV_SafeStringForDictKey(data, @"nickname");
        roomData.rtmpUrl = rtmpUrl;
        roomData.multiplexingEnabled = PLV_SafeBoolForDictKey(data, @"multiplexingEnabled");
        roomData.channelGuestManualJoinLinkMic = [PLV_SafeStringForDictKey(data, @"colinMicType") isEqualToString:@"manual"];
        roomData.interactNumLimit = PLV_SafeIntegerForDictKey(data, @"InteractNumLimit");
        roomData.isOnlyAudio = PLV_SafeBoolForDictKey(data, @"isOnlyAudio");
        roomData.liveStatusIsLiving = PLV_SafeBoolForDictKey(data, @"liveStatus");
        
        // 初始化直播间用户数据
        NSString *teacherNickname = PLV_SafeStringForDictKey(data, @"teacherNickname");
        if (nickName && [nickName isKindOfClass:[NSString class]] && nickName.length > 0) {
            teacherNickname = nickName;
        }
        NSString *avatar = PLV_SafeStringForDictKey(data, @"teacherAvatar");
        NSString *actor = PLV_SafeStringForDictKey(data, @"teacherActor");
        NSString *role = PLV_SafeStringForDictKey(data, @"role");
        
        NSString * viewerId = channelId;
        PLVRoomUserType viewerType = PLVRoomUserTypeTeacher;
        if ([role isEqualToString:@"guest"]) {
            viewerId = PLV_SafeStringForDictKey(data, @"InteractUid");
            viewerType = PLVRoomUserTypeGuest;
        }
        PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithViewerId:viewerId viewerName:teacherNickname viewerAvatar:avatar viewerType:viewerType];
        roomUser.actor = actor;
        roomUser.role = role;
        [roomData setupRoomUser:roomUser];
        
        NSString *userId = PLV_SafeStringForDictKey(data, @"useId");
        NSString *appId = PLV_SafeStringForDictKey(data, @"appId");
        NSString *appSecret = PLV_SafeStringForDictKey(data, @"appSecret");
        
        // 登陆SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
        [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
        // 注册日志管理器
        [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:roomData.channelId productType:PLVProductTypeStreamer];
        
        // 将当前的roomData配置到PLVRoomDataManager进行管理
        [[PLVRoomDataManager sharedManager] configRoomData:roomData];
        
        NSString *pptAnimationString = PLV_SafeStringForDictKey(data, @"pptAnimationEnabled");
        BOOL pptAnimationEnable = pptAnimationString.boolValue;
        [[PLVDocumentUploadClient sharedClient] setupWithChannelId:channelId pptAnimationEnable:pptAnimationEnable];
        
        [roomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
            !completion ?: completion();
        }];
    } failure:^(NSError * _Nonnull error) {
        NSString *errorDes = error.userInfo[NSLocalizedDescriptionKey];
        !failure ?: failure(errorDes);
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s load push Info with 【%@】(登陆失败)", __FUNCTION__, error);
    }];
}

+ (void)logout {
    [[PLVRoomDataManager sharedManager] removeRoomData];
    [[PLVWLogReporterManager sharedManager] clear];
}

#pragma mark - HiClass

+ (void)teacherEnterHiClassWithViewerId:(NSString *)viewerId
                                viewerName:(NSString *)viewerName
                                  lessonId:(NSString *)lessonId
                                completion:(void (^)(void))completion
                                   failure:(void (^)(NSString *errorMessage))failure {
    if (![PLVFdUtil checkStringUseable:viewerId] ||
        ![PLVFdUtil checkStringUseable:viewerName]) {
        !failure ?: failure(@"用户ID、用户昵称不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s tacher enter hiclass room failed with【用户ID、用户昵称不可为空】(viewerId:%@, viewerName:%@)", __FUNCTION__, viewerId, viewerName);
        return;
    }
    if (![PLVFdUtil checkStringUseable:lessonId]) {
        !failure ?: failure(@"课节ID不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s tacher enter hiclass room failed with【课节ID不可为空】(lessonId:%@)", __FUNCTION__, lessonId);
        return;
    }
    [PLVLiveVClassAPI teacherLessonDetailWithLessonId:lessonId success:^(NSDictionary * _Nonnull responseDict) {
        // 解析最大推流分辨率
        NSInteger rtcMaxResolution = [responseDict[@"rtcMaxResolution"] integerValue];
        PLVResolutionType videoResolution = PLVResolutionType180P;
        if (rtcMaxResolution >= 720) {
            videoResolution = PLVResolutionType720P;
        } else if (rtcMaxResolution == 360) {
            videoResolution = PLVResolutionType360P;
        }
        
        // 解析频道号、频道名称、连麦人数、是否开启自动连麦
        NSString *channelId = PLV_SafeStringForDictKey(responseDict, @"channelId");
        NSString *channelName = PLV_SafeStringForDictKey(responseDict, @"name");
        BOOL autoLinkMic = PLV_SafeBoolForDictKey(responseDict, @"autoConnectMicroEnabled");
        NSInteger linkNumber = PLV_SafeIntegerForDictKey(responseDict, @"linkNumber");
        
        // 初始化直播间数据
        PLVRoomData *roomData = [[PLVRoomData alloc] init];
        roomData.sessionId = lessonId;
        roomData.maxResolution = videoResolution;
        roomData.videoType = PLVChannelVideoType_Streamer;
        roomData.channelId = channelId;
        roomData.channelName = channelName;
        roomData.inHiClassScene = YES;
        roomData.autoLinkMic = autoLinkMic;
        roomData.linkNumber = linkNumber;
        
        // 初始化直播间用户数据
        PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithViewerId:viewerId viewerName:viewerName viewerAvatar:@"https://s1.videocc.net/default-img/avatar/teacher.png" viewerType:PLVRoomUserTypeTeacher];
        [roomData setupRoomUser:roomUser];
        
        // 将当前的roomData配置到PLVRoomDataManager进行管理
        [[PLVRoomDataManager sharedManager] configRoomData:roomData];
        
        // 注册日志管理器
        [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:roomData.channelId productType:PLVProductTypeHiClass];
        
        // 注册课程管理器
        [[PLVHiClassManager sharedManager] setupWithLessonDetail:responseDict courseCode:nil];
        
        NSString *pptAnimationString = PLV_SafeStringForDictKey(responseDict, @"pptAnimationEnabled");
        BOOL pptAnimationEnable = pptAnimationString.boolValue;
        [[PLVDocumentUploadClient sharedClient] setupWithChannelId:channelId lessionId:lessonId pptAnimationEnable:pptAnimationEnable];
        
        !completion ?: completion();
        
    } failure:^(NSError * _Nonnull error) {
        NSString *errorDes = error.userInfo[NSLocalizedDescriptionKey];
        !failure ?: failure(errorDes);
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s tacher enter hiclass room failed with 【%@】", __FUNCTION__, errorDes);
    }];
}

+ (void)watcherEnterHiClassWithViewerId:(NSString *)viewerId
                                viewerName:(NSString *)viewerName
                                courseCode:(NSString * _Nullable)courseCode
                                  lessonId:(NSString *)lessonId
                                completion:(void (^)(void))completion
                                   failure:(void (^)(NSString *errorMessage))failure {
    if (![PLVFdUtil checkStringUseable:viewerId] ||
        ![PLVFdUtil checkStringUseable:viewerName]) {
        !failure ?: failure(@"用户ID、用户昵称不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s watcher enter hiclass room failed with【用户ID、用户昵称不可为空】(viewerId:%@, viewerName:%@)", __FUNCTION__, viewerId, viewerName);
        return;
    }
    if (![PLVFdUtil checkStringUseable:lessonId]) {
        !failure ?: failure(@"课节ID不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s watcher enter hiclass room failed with【课节ID不可为空】(lessonId:%@)", __FUNCTION__, lessonId);
        return;
    }
    [PLVLiveVClassAPI watcherLessonDetailWithCourseCode:courseCode lessonId:lessonId success:^(NSDictionary * _Nonnull responseDict) {
        // 解析最大推流分辨率
        NSInteger rtcMaxResolution = [responseDict[@"rtcMaxResolution"] integerValue];
        PLVResolutionType videoResolution = PLVResolutionType180P;
        if (rtcMaxResolution >= 720) {
            videoResolution = PLVResolutionType720P;
        } else if (rtcMaxResolution == 360) {
            videoResolution = PLVResolutionType360P;
        }
        
        // 解析频道号、频道名称、连麦人数、是否开启自动连麦
        NSString *channelId = PLV_SafeStringForDictKey(responseDict, @"channelId");
        NSString *channelName = PLV_SafeStringForDictKey(responseDict, @"name");
        NSInteger linkNumber = PLV_SafeIntegerForDictKey(responseDict, @"linkNumber");
        
        // 初始化直播间数据
        PLVRoomData *roomData = [[PLVRoomData alloc] init];
        roomData.sessionId = lessonId;
        roomData.maxResolution = videoResolution;
        roomData.videoType = PLVChannelVideoType_Streamer;
        roomData.channelId = channelId;
        roomData.channelName = channelName;
        roomData.inHiClassScene = YES;
        roomData.linkNumber = linkNumber;
        
        // 初始化直播间用户数据
        PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithViewerId:viewerId viewerName:viewerName viewerAvatar:@"https://liveimages.videocc.net/defaultImg/avatar/viewer.png" viewerType:PLVRoomUserTypeSCStudent];
        [roomData setupRoomUser:roomUser];
        
        // 将当前的roomData配置到PLVRoomDataManager进行管理
        [[PLVRoomDataManager sharedManager] configRoomData:roomData];
        
        // 注册日志管理器
        [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:roomData.channelId productType:PLVProductTypeHiClass];
        
        // 注册课程管理器
        [[PLVHiClassManager sharedManager] setupWithLessonDetail:responseDict courseCode:courseCode];
        
        NSString *pptAnimationString = PLV_SafeStringForDictKey(responseDict, @"pptAnimationEnabled");
        BOOL pptAnimationEnable = pptAnimationString.boolValue;
        [[PLVDocumentUploadClient sharedClient] setupWithChannelId:channelId lessionId:lessonId courseCode:courseCode pptAnimationEnable:pptAnimationEnable teacher:NO];
        
        !completion ?: completion();
    } failure:^(NSError * _Nonnull error) {
        NSString *errorDes = error.userInfo[NSLocalizedDescriptionKey];
        !failure ?: failure(errorDes);
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s watcher enter hiclass room failed with 【%@】", __FUNCTION__, errorDes);
    }];
}

@end
