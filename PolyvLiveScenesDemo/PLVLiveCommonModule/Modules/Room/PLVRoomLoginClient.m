//
//  PLVRoomLoginClient.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@implementation PLVRoomLoginClient

#pragma mark - [ Public Method ]

+ (void)loginLiveRoomWithChannelType:(PLVChannelType)channelType
                           channelId:(NSString *)channelId
                              userId:(NSString *)userId
                               appId:(NSString *)appId
                           appSecret:(NSString *)appSecret
                            roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                          completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                             failure:(void (^)(NSString *errorMessage))failure {
    if (channelType <= PLVChannelTypeUnknown) {
        !failure ?: failure(PLVLocalizedString(@"频道类型无效"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login live room failed with【频道类型无效】(channelType:%zd)", __FUNCTION__, channelType);
        return;
    }
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(PLVLocalizedString(@"频道号不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login live room failed with【频道号不可为空】(channelId:%@)", __FUNCTION__, channelId);
        return;
    }
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(PLVLocalizedString(@"账号信息不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login live room failed with【账号信息不可为空】(userId:%@, appId:%@, appSecret:%@)", __FUNCTION__, userId, appId, appSecret);
        return;
    }
    
    __block NSInteger blockCount = 0;
    __block PLVRoomData *blockRoomData = [[PLVRoomData alloc] init];
    blockRoomData.channelId = channelId;
    void (^requestDataBlock) (NSInteger, PLVRoomData*) = ^(NSInteger count,PLVRoomData *roomData) {
        if (count == 2) {
            if ((roomData.channelType & channelType) <= 0) {
                !failure ?: failure(PLVLocalizedString(@"PLVCMLoginWrongChannelTypeTips"));
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get live channel failed with【频道类型出错】(apiChannelType:%zd, channelType:%z)", __FUNCTION__, roomData.channelType, channelType);
                return;
            }
            
            if (roomData.transmitMode) {
                if (roomData.channelType != PLVChannelTypePPT) {
                    !failure ?: failure(PLVLocalizedString(@"纯视频场景暂时不支持双师"));
                    PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login live room failed with【纯视频场景暂时不支持双师】", __FUNCTION__);
                    return;
                }
            }
            
            // 使用roomUserHandler配置用户对象
            PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:roomData.channelType];
            if (roomUserHandler) {
                roomUserHandler(roomUser);
            }
            [roomData setupRoomUser:roomUser];
            
            // 注册日志管理器
            [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId];
            [[PLVWLogReporterManager sharedManager] setupViewerId:roomData.roomUser.viewerId viewerName:roomData.roomUser.viewerName role:roomData.roomUser.role];
            
            // 将当前的roomData配置到PLVRoomDataManager进行管理
            [[PLVRoomDataManager sharedManager] configRoomData:roomData];
            !completion ?: completion(roomData.customParam);
        }
    };
    
    // 登录SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
    [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
    
    [blockRoomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
        if (!channelMenuInfo) {
            !failure ?: failure(PLVLocalizedString(@"获取频道类型失败"));
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get live channel menu info failed with nil（获取频道类型失败）", __FUNCTION__);
            return;
        }
        
        if (channelMenuInfo.watchEventTrackEnabled) {
            [[PLVWLogReporterManager sharedManager] enableTrackEventReport:YES];
        }

        if (channelMenuInfo.transmitMode && channelMenuInfo.mainRoom) {
            !failure ?: failure(PLVLocalizedString(@"房间已开启双师功能，限制学生登录"));
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login live room failed with【双师暂不支持大房间登录】", __FUNCTION__);
            return;
        }
        requestDataBlock(blockCount +=1, blockRoomData);
    }];
    
    [PLVLiveVideoAPI verifyLivePermissionWithChannelId:channelId.integerValue userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        blockRoomData.videoType = PLVChannelVideoType_Live;
        requestDataBlock(blockCount +=1, blockRoomData);
    } failure:^(NSError * _Nonnull error) {
        !failure ?: failure(PLVLocalizedString(@"登录校验失败"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify live permission failed with【%@】(登录校验失败)", __FUNCTION__, error);
        return;
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
    [self loginPlaybackRoomWithChannelType:channelType channelId:channelId vodList:NO vid:vid userId:userId appId:appId appSecret:appSecret roomUser:roomUserHandler completion:completion failure:failure];
}


+ (void)loginPlaybackRoomWithChannelType:(PLVChannelType)channelType channelId:(NSString *)channelId vodList:(BOOL)vodList vid:(NSString *)vid userId:(NSString *)userId appId:(NSString *)appId appSecret:(NSString *)appSecret roomUser:(void (^)(PLVRoomUser * _Nonnull))roomUserHandler completion:(void (^)(PLVViewLogCustomParam * _Nonnull))completion failure:(void (^)(NSString * _Nonnull))failure {
    if (channelType <= PLVChannelTypeUnknown) {
        !failure ?: failure(PLVLocalizedString(@"频道类型无效"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【登录校验失败】(channelType:%zd)", __FUNCTION__, channelType);
        return;
    }
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(PLVLocalizedString(@"频道号不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【频道号不可为空】(channelId:%@)", __FUNCTION__, channelId);
        return;
    }
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(PLVLocalizedString(@"账号信息不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【账号信息不可为空】(userId:%@, appId:%@, appSecret:%@)", __FUNCTION__, appId, appId, appSecret);
        return;
    }
    BOOL vidEnable = [PLVFdUtil checkStringUseable:vid];
    
    __block NSInteger blockCount = 0;
    __block PLVRoomData *blockRoomData = [[PLVRoomData alloc] init];
    blockRoomData.channelId = channelId;
    void (^requestDataBlock) (NSInteger, PLVRoomData*) = ^(NSInteger count, PLVRoomData *roomData) {
        if (count == 2) {
            if ((roomData.channelType & channelType) <= 0) {
                !failure ?: failure(PLVLocalizedString(@"PLVCMLoginWrongChannelTypeTips"));
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get live channel failed with【频道类型出错】(apiChannelType:%zd, channelType:%z)", __FUNCTION__, roomData.channelType, channelType);
                return;
            }
            if (vidEnable) {
                roomData.vid = vid;
            }
            roomData.vodList = vodList;
            roomData.videoType = PLVChannelVideoType_Playback;
            
            // 使用roomUserHandler配置用户对象
            PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:roomData.channelType];
            [roomData setupRoomUser:roomUser];
            
            // 注册日志管理器
            if (vidEnable) {
                [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId vId:vid];
            } else {
                [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId];
            }
            [[PLVWLogReporterManager sharedManager] setupViewerId:roomData.roomUser.viewerId viewerName:roomData.roomUser.viewerName role:roomData.roomUser.role];
            // 将当前的roomData配置到PLVRoomDataManager进行管理
            [[PLVRoomDataManager sharedManager] configRoomData:roomData];
            !completion ?: completion(roomData.customParam);
        }
    };
    
    // 登录SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
    [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
    
    [blockRoomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * _Nonnull channelMenuInfo) {
        if (!channelMenuInfo) {
            !failure ?: failure(PLVLocalizedString(@"获取频道类型失败"));
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get live channel menu info failed with nil（获取频道类型失败）", __FUNCTION__);
            return;
        }
        
        if (channelMenuInfo.watchEventTrackEnabled) {
            [[PLVWLogReporterManager sharedManager] enableTrackEventReport:YES];
        }
        requestDataBlock(blockCount +=1, blockRoomData);
    }];
    if (vidEnable) {
        [PLVLiveVideoAPI verifyVodPermissionWithChannelId:channelId.integerValue vid:vid userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
            [PLVLiveVideoConfig setPrivateDomainWithData:data];
            requestDataBlock(blockCount +=1, blockRoomData);
        } failure:^(NSError * _Nonnull error) {
            !failure ?: failure(PLVLocalizedString(@"登录校验失败"));
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登录校验失败)", __FUNCTION__, error);
            return;
        }];
    } else {
        [PLVLiveVideoAPI verifyLivePermissionWithChannelId:channelId.integerValue userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
            [PLVLiveVideoConfig setPrivateDomainWithData:data];
            requestDataBlock(blockCount +=1, blockRoomData);
        } failure:^(NSError * _Nonnull error) {
            !failure ?: failure(PLVLocalizedString(@"登录校验失败"));
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登录校验失败)", __FUNCTION__, error);
            return;
        }];
    }
}

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
                                        failure:(void (^)(NSString *errorMessage))failure {
    if (channelType <= PLVChannelTypeUnknown) {
        !failure ?: failure(PLVLocalizedString(@"频道类型无效"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【登录校验失败】(channelType:%zd)", __FUNCTION__, channelType);
        return;
    }
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(PLVLocalizedString(@"频道号不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【频道号不可为空】(channelId:%@)", __FUNCTION__, channelId);
        return;
    }
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(PLVLocalizedString(@"账号信息不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【账号信息不可为空】(userId:%@, appId:%@, appSecret:%@)", __FUNCTION__, appId, appId, appSecret);
        return;
    }
    
    PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
    
    if (![PLVFdUtil checkStringUseable:vid] && ![PLVFdUtil checkStringUseable:fileId]) {
        if (networkStatus == PLVNotReachable) {
            !failure ?: failure(PLVLocalizedString(@"当前无网络！"));
            return;
        }
        // 如果没有指定vid和fileId，则按照原来的回放登录逻辑
        [self loginPlaybackRoomWithChannelType:channelType channelId:channelId vodList:vodList vid:vid userId:userId appId:appId appSecret:appSecret roomUser:roomUserHandler completion:completion failure:failure];
    }
    else if ([PLVFdUtil checkStringUseable:vid]) {
        // 如果指定vid，则播放指定vid视频
        [self requestPlaybackCacheVideoWithChannelType:channelType vid:vid vodList:vodList channelId:channelId userId:userId appId:appId appSecret:appSecret roomUser:roomUserHandler completion:completion failure:failure];
    }
    else if ([PLVFdUtil checkStringUseable:fileId]) {
        // 如果指定fileId，则播放指定暂存fileId视频
        [self requestPlaybackCacheRecordWithChannelType:channelType fileId:fileId channelId:channelId userId:userId appId:appId appSecret:appSecret roomUser:roomUserHandler completion:completion failure:failure];
    }
}

+ (void)loginStreamerRoomWithChannelType:(PLVChannelType)channelType
                               channelId:(NSString *)channelId
                                password:(NSString *)password
                                nickName:(NSString *)nickName
                              completion:(void (^)(void))completion
                                 failure:(void (^)(NSString *errorMessage))failure {
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(PLVLocalizedString(@"频道号不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login streamer room failed with【频道号不可为空】(channelId:%@)", __FUNCTION__, channelId);

        return;
    }
    if (![PLVFdUtil checkStringUseable:password]) {
        !failure ?: failure(PLVLocalizedString(@"密码不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login streamer room failed with【密码不可为空】(password:%@)", __FUNCTION__, password);

        return;
    }
    if ((channelType & PLVChannelTypePPT) == 0 &&
        (channelType & PLVChannelTypeAlone) == 0) {
        !failure ?: failure(PLVLocalizedString(@"暂不支持该频道"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login streamer room failed with【暂不支持该频道】(channelType:%zd)", __FUNCTION__, channelType);
        return;
    }
    [PLVLiveVideoAPI loadPushInfoWithChannelId:channelId password:password channelType:channelType completion:^(NSDictionary * _Nonnull data, NSString * _Nonnull rtmpUrl) {
        // 获取频道类型
        NSString *liveScene = PLV_SafeStringForDictKey(data, @"liveScene");
        PLVChannelType apiChannelType = PLVChannelTypeUnknown;
        if ([liveScene isEqualToString:@"ppt"]) {
            apiChannelType = PLVChannelTypePPT;
        } else if ([liveScene isEqualToString:@"alone"] || [liveScene isEqualToString:@"topclass"]) {
            apiChannelType = PLVChannelTypeAlone;
        }
        
        if ((apiChannelType & channelType) <= 0) {
            !failure ?: failure(PLVLocalizedString(@"PLVCMLoginWrongChannelTypeTips"));
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
        
        if ([@"Y" isEqualToString:PLV_SafeStringForDictKey(data, @"appPushResolution1080Enabled")]) {
            videoResolution = PLVResolutionType1080P;
        }
        
        // 初始化直播间数据
        PLVRoomData *roomData = [[PLVRoomData alloc] init];
        roomData.maxResolution = videoResolution;
        if (videoResolution == PLVResolutionType1080P) {
            roomData.defaultResolution = PLVResolutionType720P;
        }
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
        roomData.appBeautyEnabled = PLV_SafeBoolForDictKey(data, @"appBeautyEnabled");
        roomData.appBeautyType = PLV_SafeStringForDictKey(data, @"appBeautyType");
        roomData.guestTranAuthEnabled = PLV_SafeBoolForDictKey(data, @"guestTranAuthEnabled");
        roomData.appWebStartResolutionRatio = PLV_SafeStringForDictKey(data, @"appWebStartResolutionRatio");
        roomData.appWebStartResolutionRatioEnabled = PLV_SafeBoolForDictKey(data, @"appWebStartResolutionRatioEnabled");
        roomData.appDefaultLandScapeEnabled = PLV_SafeBoolForDictKey(data, @"appDefaultLandScapeEnabled");
        roomData.sipEnabled = PLV_SafeBoolForDictKey(data, @"sipEnabled");
        roomData.appDefaultPureViewEnabled = PLV_SafeBoolForDictKey(data, @"appDefaultPureViewEnabled");
        NSString *preferenceString = PLV_SafeStringForDictKey(data, @"pushQualityPreference");
        roomData.userDefaultOpenMicLinkEnabled = PLV_SafeStringForDictKey(data, @"userDefaultOpenMicLinkEnabled");
        [roomData setupPushQualityPreference:preferenceString];
        roomData.linkmicNewStrategyEnabled = PLV_SafeBoolForDictKey(data, @"newMicEnabled");
        roomData.defaultOpenMicLinkEnabled = PLV_SafeStringForDictKey(data, @"defaultOpenMicLinkEnabled");
        
        NSDictionary *appStartConfig = PLV_SafeDictionaryForDictKey(data, @"appStartConfig");
        if ([PLVFdUtil checkDictionaryUseable:appStartConfig]) {
            roomData.appStartMemberListEnabled = PLV_SafeBoolForDictKey(appStartConfig, @"appStartMemberListEnabled");
            roomData.appStartMultiplexingLayoutEnabled = PLV_SafeBoolForDictKey(appStartConfig, @"appStartMultiplexingLayoutEnabled");
            roomData.appStartCheckinEnabled = PLV_SafeBoolForDictKey(appStartConfig, @"appStartCheckinEnabled");
            roomData.appStartGiftDonateEnabled = PLV_SafeBoolForDictKey(appStartConfig, @"appStartGiftDonateEnabled");
            roomData.appStartGiftEffectEnabled = PLV_SafeBoolForDictKey(appStartConfig, @"appStartGiftEffectEnabled");
        }
        
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
        NSInteger rtcDefaultResolution = [data[@"teacherDefaultResolution"] integerValue];
        NSString *defaultQualityLevel = [PLVLiveVideoConfig sharedInstance].teacherDefaultQualityLevel;
        if ([role isEqualToString:@"guest"]) {
            viewerId = PLV_SafeStringForDictKey(data, @"InteractUid");
            viewerType = PLVRoomUserTypeGuest;
            rtcDefaultResolution = [data[@"guestDefaultResolution"] integerValue];
            defaultQualityLevel = [PLVLiveVideoConfig sharedInstance].guestDefaultQualityLevel;
        }
        
        PLVResolutionType defaultVideoResolution = PLVResolutionType180P;
        if (rtcDefaultResolution >= 720) {
            defaultVideoResolution = PLVResolutionType720P;
        } else if (rtcDefaultResolution == 360) {
            defaultVideoResolution = PLVResolutionType360P;
        }
        roomData.defaultResolution = defaultVideoResolution;
        NSArray<PLVClientPushStreamTemplateVideoParams *> *videoParams = [PLVLiveVideoConfig sharedInstance].videoParams;
        if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled && [PLVFdUtil checkArrayUseable:videoParams] && [PLVFdUtil checkStringUseable:defaultQualityLevel]) {
            for (int i = 0; i < videoParams.count; i++) {
                NSString *qualityLevel = videoParams[i].qualityLevel;
                if ([PLVFdUtil checkStringUseable:qualityLevel] && [qualityLevel isEqualToString:defaultQualityLevel]) {
                    roomData.defaultResolution = (int)i * 4;
                    break;
                }
            }
        }
        
        PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithViewerId:viewerId viewerName:teacherNickname viewerAvatar:avatar viewerType:viewerType];
        roomUser.actor = actor;
        roomUser.role = role;
        [roomData setupRoomUser:roomUser];
        
        NSString *userId = PLV_SafeStringForDictKey(data, @"useId");
        NSString *appId = PLV_SafeStringForDictKey(data, @"appId");
        NSString *appSecret = PLV_SafeStringForDictKey(data, @"appSecret");
        
        // 登录SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
        [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
        // 注册日志管理器
        [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:roomData.channelId productType:PLVProductTypeStreamer];
        
        if (roomData.sipEnabled) {
            [PLVLiveVideoAPI requestSIPInfoWithChannelId:PLV_SafeStringForDictKey(data, @"channelId") completion:^(NSDictionary *data) {
                roomData.sipNumber = PLV_SafeStringForDictKey(data, @"ucSipPhone");
                roomData.sipPassword = PLV_SafeStringForDictKey(data, @"ucSipId");
            } failure:^(NSError *error) {
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s request SIP Info failed with 【%@】", __FUNCTION__, error);
            }];
        }
        
        // 将当前的roomData配置到PLVRoomDataManager进行管理
        [[PLVRoomDataManager sharedManager] configRoomData:roomData];
        
        NSString *pptAnimationString = PLV_SafeStringForDictKey(data, @"pptAnimationEnabled");
        BOOL pptAnimationEnable = pptAnimationString.boolValue;
        [[PLVDocumentUploadClient sharedClient] setupWithChannelId:roomData.channelId pptAnimationEnable:pptAnimationEnable];
        
        [roomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
            !completion ?: completion();
        }];
    } failure:^(NSError * _Nonnull error) {
        NSString *errorDes = error.userInfo[NSLocalizedDescriptionKey];
        !failure ?: failure(errorDes);
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s load push Info with 【%@】(登录失败)", __FUNCTION__, error);
    }];
}

+ (void)logout {
    [[PLVRoomDataManager sharedManager] removeRoomData];
    [[PLVWLogReporterManager sharedManager] clear];
}

#pragma mark HiClass

+ (void)teacherEnterHiClassWithViewerId:(NSString *)viewerId
                                viewerName:(NSString *)viewerName
                                  lessonId:(NSString *)lessonId
                                completion:(void (^)(void))completion
                                   failure:(void (^)(NSString *errorMessage))failure {
    if (![PLVFdUtil checkStringUseable:viewerId] ||
        ![PLVFdUtil checkStringUseable:viewerName]) {
        !failure ?: failure(PLVLocalizedString(@"用户ID、用户昵称不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s tacher enter hiclass room failed with【用户ID、用户昵称不可为空】(viewerId:%@, viewerName:%@)", __FUNCTION__, viewerId, viewerName);
        return;
    }
    if (![PLVFdUtil checkStringUseable:lessonId]) {
        !failure ?: failure(PLVLocalizedString(@"课节ID不可为空"));
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
        !failure ?: failure(PLVLocalizedString(@"用户ID、用户昵称不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s watcher enter hiclass room failed with【用户ID、用户昵称不可为空】(viewerId:%@, viewerName:%@)", __FUNCTION__, viewerId, viewerName);
        return;
    }
    if (![PLVFdUtil checkStringUseable:lessonId]) {
        !failure ?: failure(PLVLocalizedString(@"课节ID不可为空"));
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

#pragma mark - [ Private Method ]

+ (void)playbackLoginWithChannelType:(PLVChannelType)channelType
                          channelId:(NSString *)channelId
                                vid:(NSString *)vid
                             userId:(NSString *)userId
                              appId:(NSString *)appId
                          appSecret:(NSString *)appSecret
                         completion:(void (^)(PLVRoomData *roomData))completion
                            failure:(void (^)(NSString *errorMessage))failure {
    if (![PLVFdUtil checkStringUseable:vid]) {
        !failure ?: failure(PLVLocalizedString(@"视频vid不可为空"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【视频vid不可为空】(vid:%@)", __FUNCTION__, vid);
        return;
    }
    
    __block NSInteger blockCount = 0;
    __block PLVRoomData *blockRoomData = [[PLVRoomData alloc] init];
    blockRoomData.channelId = channelId;
    void (^requestDataBlock) (NSInteger, PLVRoomData*) = ^(NSInteger count, PLVRoomData *roomData) {
        if (count == 2) {
            if ((roomData.channelType & channelType) <= 0) {
                !failure ?: failure(PLVLocalizedString(@"PLVCMLoginWrongChannelTypeTips"));
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get live channel failed with【频道类型出错】(apiChannelType:%zd, channelType:%z)", __FUNCTION__, roomData.channelType, channelType);
                return;
            }
            
            // 使用roomUserHandler配置用户对象
            PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:roomData.channelType];
            [roomData setupRoomUser:roomUser];
            
            // 注册日志管理器
            [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId vId:vid];
            [[PLVWLogReporterManager sharedManager] setupViewerId:roomData.roomUser.viewerId viewerName:roomData.roomUser.viewerName role:roomData.roomUser.role];
            // 将当前的roomData配置到PLVRoomDataManager进行管理
            [[PLVRoomDataManager sharedManager] configRoomData:roomData];
            !completion ?: completion(roomData);
        }

    };
    
    // 登录SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
    [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
    
    [blockRoomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * _Nonnull channelMenuInfo) {
        if (!channelMenuInfo) {
            !failure ?: failure(PLVLocalizedString(@"获取频道类型失败"));
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get live channel menu info failed with nil（获取频道类型失败）", __FUNCTION__);
            return;
        }
        
        if (channelMenuInfo.watchEventTrackEnabled) {
            [[PLVWLogReporterManager sharedManager] enableTrackEventReport:YES];
        }
        requestDataBlock(blockCount +=1, blockRoomData);
    }];
    
    [PLVLiveVideoAPI verifyVodPermissionWithChannelId:channelId.integerValue vid:vid userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        blockRoomData.videoType = PLVChannelVideoType_Playback;
        requestDataBlock(blockCount +=1, blockRoomData);
    } failure:^(NSError * _Nonnull error) {
        !failure ?: failure(PLVLocalizedString(@"登录校验失败"));
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登录校验失败)", __FUNCTION__, error);
        return;
    }];
}



/// 请求缓存/在线的回放vid视频
+ (void)requestPlaybackCacheVideoWithChannelType:(PLVChannelType)channelType
                                             vid:(NSString *)vid
                                         vodList:(BOOL)vodList
                                       channelId:(NSString *)channelId
                                          userId:(NSString *)userId
                                           appId:(NSString *)appId
                                       appSecret:(NSString *)appSecret
                                        roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                                      completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                                         failure:(void (^)(NSString *errorMessage))failure {
    NSString *listType = vodList ? @"vod" : nil;
    [PLVPlaybackCacheManager playbackVideoInfoModelWithVid:vid channelId:channelId listType:listType completion:^(PLVPlaybackVideoInfoModel * _Nonnull model, NSError * _Nonnull error) {
        if (error) {
            !failure ?: failure(error.description);
            return;
        }
        
        PLVChannelType offlineInfoChannelType = [model.liveType isEqualToString:@"ppt"] ? PLVChannelTypePPT : PLVChannelTypeAlone;
        if ((offlineInfoChannelType & channelType) <= 0) {
            !failure ?: failure(PLVLocalizedString(@"PLVCMLoginWrongChannelTypeTips"));
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get vod channel failed with with【频道类型出错】(apiChannelType:%zd, channelType:%zd)", __FUNCTION__, offlineInfoChannelType, channelType);
            return;
        }
        
        PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
        
        // 登录SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
        [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
        
        if (networkStatus != PLVNotReachable) {
            __block NSInteger blockCount = 0;
            __block PLVRoomData *blockRoomData = [[PLVRoomData alloc] init];
            blockRoomData.videoType = PLVChannelVideoType_Playback;
            blockRoomData.channelType = offlineInfoChannelType;
            blockRoomData.channelId = channelId;
            blockRoomData.vid = vid;
            blockRoomData.vodList = vodList;
            void (^requestDataBlock) (NSInteger, PLVRoomData*) = ^(NSInteger count,PLVRoomData *currentRoomData) {
                if (count == 2) {
                    // 使用roomUserHandler配置用户对象
                    PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:offlineInfoChannelType];
                    if (roomUserHandler) {
                        roomUserHandler(currentRoomData.roomUser);
                    }
                    [currentRoomData setupRoomUser:roomUser];
                    
                    // 注册日志管理器
                    [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId vId:vid];
                    [[PLVWLogReporterManager sharedManager] setupViewerId:roomUser.viewerId viewerName:roomUser.viewerName role:roomUser.role];
                    
                    // 将当前的roomData配置到PLVRoomDataManager进行管理
                    [[PLVRoomDataManager sharedManager] configRoomData:currentRoomData];
                    !completion ?: completion(currentRoomData.customParam);
                }
            };
            
            [blockRoomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo *channelMenuInfo) {
                if (channelMenuInfo.watchEventTrackEnabled) {
                    [[PLVWLogReporterManager sharedManager] enableTrackEventReport:YES];
                }
                requestDataBlock(blockCount +=1, blockRoomData);
            }];
            
            [PLVLiveVideoAPI verifyVodPermissionWithChannelId:channelId.integerValue vid:vid userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
                [PLVLiveVideoConfig setPrivateDomainWithData:data];
                requestDataBlock(blockCount +=1, blockRoomData);
            } failure:^(NSError * _Nonnull error) {
                !failure ?: failure(PLVLocalizedString(@"登录校验失败"));
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登录校验失败)", __FUNCTION__, error);
                return;
            }];
            
        } else {
            // 初始化直播间数据
            PLVRoomData *roomData = [[PLVRoomData alloc] init];
            roomData.videoType = PLVChannelVideoType_Playback;
            roomData.channelType = offlineInfoChannelType;
            roomData.channelId = channelId;
            roomData.vid = vid;
            roomData.vodList = vodList;
            
            // 使用roomUserHandler配置用户对象
            PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:offlineInfoChannelType];
            if (roomUserHandler) {
                roomUserHandler(roomData.roomUser);
            }
            [roomData setupRoomUser:roomUser];
            
            // 注册日志管理器
            [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId vId:vid];
            [[PLVWLogReporterManager sharedManager] setupViewerId:roomUser.viewerId viewerName:roomUser.viewerName role:roomUser.role];
            
            // 将当前的roomData配置到PLVRoomDataManager进行管理
            [[PLVRoomDataManager sharedManager] configRoomData:roomData];
            roomData.noNetWorkOfflineIntroductionEnabled = YES;
            plv_dispatch_main_async_safe(^{
                !completion ?: completion(roomData.customParam);
            })
        }
    }];
}

/// 请求缓存/在线的回放暂存fileId视频
+ (void)requestPlaybackCacheRecordWithChannelType:(PLVChannelType)channelType
                                           fileId:(NSString *)fileId
                                        channelId:(NSString *)channelId
                                           userId:(NSString *)userId
                                      appId:(NSString *)appId
                                        appSecret:(NSString *)appSecret
                                         roomUser:(void(^ _Nullable)(PLVRoomUser *roomUser))roomUserHandler
                                       completion:(void (^)(PLVViewLogCustomParam *customParam))completion
                                          failure:(void (^)(NSString *errorMessage))failure {
    [PLVPlaybackCacheManager recordPlaybackVideoInfoModelWithFileId:fileId channelId:channelId completion:^(PLVPlaybackVideoInfoModel * _Nonnull model, NSError * _Nonnull error) {
        if (error) {
            !failure ?: failure(error.description);
            return;
        }
        PLVLiveRecordFileModel *recordFile = [[PLVLiveRecordFileModel alloc]init];
        recordFile.fileId = model.fileId;
        if ([model isKindOfClass:[PLVPlaybackLocalVideoInfoModel class]]) {
            // 本地数据
            PLVPlaybackLocalVideoInfoModel *localModel = (PLVPlaybackLocalVideoInfoModel *)model;
            recordFile.mp4 =  localModel.localVideoPath;
        }else {
            recordFile.mp4 =  model.fileUrl;
        }
        recordFile.channelSessionId = model.channelSessionId;
        recordFile.duration = model.duration;
        recordFile.originSessionId = model.originSessionId;
        
        PLVChannelType offlineInfoChannelType = [model.liveType isEqualToString:@"ppt"] ? PLVChannelTypePPT : PLVChannelTypeAlone;
        if ((offlineInfoChannelType & channelType) <= 0) {
            !failure ?: failure(PLVLocalizedString(@"PLVCMLoginWrongChannelTypeTips"));
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get liveRecord channel failed with with【频道类型出错】(apiChannelType:%zd, channelType:%zd)", __FUNCTION__, offlineInfoChannelType, channelType);
            return;
        }
        
        PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
        
        // 登录SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
        [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
        
        if (networkStatus != PLVNotReachable) {
            __block NSInteger blockCount = 0;
            __block PLVRoomData *blockRoomData = [[PLVRoomData alloc] init];
            blockRoomData.videoType = PLVChannelVideoType_Playback;
            blockRoomData.channelType = offlineInfoChannelType;
            blockRoomData.channelId = channelId;
            blockRoomData.recordEnable = YES;
            blockRoomData.recordFile = recordFile;
            blockRoomData.sectionEnable = NO;
            blockRoomData.sectionList = @[];
            blockRoomData.playbackSessionId = recordFile.channelSessionId;
            void (^requestDataBlock) (NSInteger, PLVRoomData*) = ^(NSInteger count,PLVRoomData *currentRoomData) {
                if (count == 2) {
                    // 使用roomUserHandler配置用户对象
                    PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:offlineInfoChannelType];
                    if (roomUserHandler) {
                        roomUserHandler(roomUser);
                    }
                    [currentRoomData setupRoomUser:roomUser];
                    
                    // 注册日志管理器
                    [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId];
                    [[PLVWLogReporterManager sharedManager] setupViewerId:roomUser.viewerId viewerName:roomUser.viewerName role:roomUser.role];
                    
                    // 将当前的roomData配置到PLVRoomDataManager进行管理
                    [[PLVRoomDataManager sharedManager] configRoomData:currentRoomData];
                    !completion ?: completion(currentRoomData.customParam);
                }
            };
            
            [blockRoomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
                if (channelMenuInfo.watchEventTrackEnabled) {
                    [[PLVWLogReporterManager sharedManager] enableTrackEventReport:YES];
                }
                requestDataBlock(blockCount +1, blockRoomData);
            }];
            
            [PLVLiveVideoAPI verifyLivePermissionWithChannelId:channelId.integerValue userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
                [PLVLiveVideoConfig setPrivateDomainWithData:data];
                requestDataBlock(blockCount +1, blockRoomData);
            } failure:^(NSError * _Nonnull error) {
                !failure ?: failure(PLVLocalizedString(@"登录校验失败"));
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登录校验失败)", __FUNCTION__, error);
                return;
            }];
        } else {
            // 初始化直播间数据
            PLVRoomData *roomData = [[PLVRoomData alloc] init];
            roomData.videoType = PLVChannelVideoType_Playback;
            roomData.channelType = offlineInfoChannelType;
            roomData.channelId = channelId;
            roomData.recordEnable = YES;
            roomData.recordFile = recordFile;
            roomData.sectionEnable = NO;
            roomData.sectionList = @[];
            roomData.playbackSessionId = recordFile.channelSessionId;
            
            // 使用roomUserHandler配置用户对象
            PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:offlineInfoChannelType];
            if (roomUserHandler) {
                roomUserHandler(roomUser);
            }
            [roomData setupRoomUser:roomUser];
            
            // 注册日志管理器
            [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId];
            [[PLVWLogReporterManager sharedManager] setupViewerId:roomUser.viewerId viewerName:roomUser.viewerName role:roomUser.role];
            
            // 将当前的roomData配置到PLVRoomDataManager进行管理
            [[PLVRoomDataManager sharedManager] configRoomData:roomData];
            roomData.noNetWorkOfflineIntroductionEnabled = YES;
            plv_dispatch_main_async_safe(^{
                !completion ?: completion(roomData.customParam);
            })
        }
    }];
}
    
@end
