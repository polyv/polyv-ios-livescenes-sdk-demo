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
    
    [PLVLiveVideoAPI verifyLivePermissionWithChannelId:channelId.integerValue userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        [PLVLiveVideoAPI liveStatus2:channelId appId:appId appSecret:appSecret completion:^(PLVChannelType apiChannelType, PLVChannelLiveStreamState liveState) {
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
                [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId];
                
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
    [self loginPlaybackRoomWithChannelType:channelType channelId:channelId vodList:NO vid:vid userId:userId appId:appId appSecret:appSecret roomUser:roomUserHandler completion:completion failure:failure];
}

+ (void)loginPlaybackRoomWithChannelType:(PLVChannelType)channelType
                               channelId:(NSString *)channelId
                                 vodList:(BOOL)vodList
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
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(@"账号信息不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【账号信息不可为空】(userId:%@, appId:%@, appSecret:%@)", __FUNCTION__, appId, appId, appSecret);
        return;
    }
    
    if (![PLVFdUtil checkStringUseable:vid]) {
        [PLVLiveVideoAPI requestChannelPlaybackInfoWithChannelId:channelId appId:appId appSecret:appSecret vid:nil playbackType:nil completion:^(PLVChannelPlaybackInfoModel * _Nullable channelPlaybackInfo) {
            if (channelPlaybackInfo) {
                if (!channelPlaybackInfo.enablePlayBack) {
                    !failure ?: failure(@"频道未开启回放功能");
                    PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【频道未开启回放功能】", __FUNCTION__);
                } else {
                    BOOL sectionEnabled = channelPlaybackInfo.sectionEnabled;
                    __block NSArray<PLVLivePlaybackSectionModel *> *sectionList;
                    __block PLVPlaybackListModel *playbackList;
                    NSString *videoPoolId = channelPlaybackInfo.targetPlaybackVideo.videoPoolId;
                    NSString *videoId = channelPlaybackInfo.targetPlaybackVideo.videoId;
                    NSString *playbackSessionId = channelPlaybackInfo.targetPlaybackVideo.channelSessionId;
                    
                    if (![PLVFdUtil checkStringUseable:channelPlaybackInfo.playbackOrigin]) {
                        !failure ?: failure(@"回放类型获取失败");
                        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【回放类型不可为空】", __FUNCTION__);
                    }
                    
                    if (![PLVFdUtil checkStringUseable:channelPlaybackInfo.type]) {
                        !failure ?: failure(@"回放方式获取失败");
                        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【回放方式不可为空】", __FUNCTION__);
                    } else if ([channelPlaybackInfo.type isEqualToString:@"single"]) { // 回放方式-单个视频
                        if ([channelPlaybackInfo.playbackOrigin isEqualToString:@"record"]) { // 使用最新暂存
                            if (!channelPlaybackInfo.hasRecordFile || !channelPlaybackInfo.recordFile) {
                                !failure ?: failure(@"直播暂存为空");
                                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【直播暂存不可为空】", __FUNCTION__);
                            } else {
                                PLVLiveRecordFileModel *recordFile = channelPlaybackInfo.recordFile;
                                [PLVLiveVideoAPI verifyLivePermissionWithChannelId:channelId.integerValue userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
                                    [PLVLiveVideoConfig setPrivateDomainWithData:data];
                                    if (sectionEnabled && [PLVFdUtil checkStringUseable:recordFile.fileId]) {
                                        [PLVLiveVideoAPI requestLiveRecordSectionListWithChannelId:channelId fileId:recordFile.fileId completion:^(NSArray<PLVLivePlaybackSectionModel *> * _Nonnull list, NSError * _Nullable error) {
                                            sectionList = list;
                                        }];
                                    }
                                    [PLVLiveVideoAPI liveStatus2:channelId appId:appId appSecret:appSecret completion:^(PLVChannelType apiChannelType, PLVChannelLiveStreamState liveState) {
                                        if ((apiChannelType & channelType) <= 0) {
                                            !failure ?: failure(@"频道类型出错");
                                            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get liveRecord channel failed with with【频道类型出错】(apiChannelType:%zd, channelType:%zd)", __FUNCTION__, apiChannelType, channelType);
                                        } else {
                                            // 初始化直播间数据
                                            PLVRoomData *roomData = [[PLVRoomData alloc] init];
                                            roomData.videoType = PLVChannelVideoType_Playback;
                                            roomData.channelType = apiChannelType;
                                            roomData.channelId = channelId;
                                            roomData.recordEnable = YES;
                                            roomData.recordFile = recordFile;
                                            if (apiChannelType == PLVChannelTypePPT) {
                                                roomData.sectionEnable = sectionEnabled;
                                                roomData.sectionList = sectionList;
                                            }
                                            roomData.playbackSessionId = recordFile.channelSessionId;
                                            
                                            // 使用roomUserHandler配置用户对象
                                            PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:apiChannelType];
                                            if (roomUserHandler) {
                                                roomUserHandler(roomUser);
                                            }
                                            [roomData setupRoomUser:roomUser];
                                            
                                            // 登陆SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
                                            [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
                                            // 注册日志管理器
                                            [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId];
                                            
                                            // 将当前的roomData配置到PLVRoomDataManager进行管理
                                            [[PLVRoomDataManager sharedManager] configRoomData:roomData];
                                            
                                            [roomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
                                                !completion ?: completion(roomData.customParam);
                                            }];
                                        }
                                    } failure:^(NSError * _Nonnull error) {
                                        !failure ?: failure(@"获取频道类型失败");
                                        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get liveRecord channel failed with【%@】（获取频道类型失败）", __FUNCTION__, error);
                                    }];
                                } failure:^(NSError * _Nonnull error) {
                                    !failure ?: failure(@"登陆校验失败");
                                    PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登陆校验失败)", __FUNCTION__, error);
                                }];
                            }
                        } else if ([channelPlaybackInfo.playbackOrigin isEqualToString:@"vod"] || [channelPlaybackInfo.playbackOrigin isEqualToString:@"playback"]) { // 从回放列表或者点播列表添加
                            if (!channelPlaybackInfo.hasPlaybackVideo || !channelPlaybackInfo.targetPlaybackVideo) {
                                !failure ?: failure(@"回放视频为空");
                                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【回放视频不可为空】", __FUNCTION__);
                            } else {
                                if (sectionEnabled) {
                                    [PLVLiveVideoAPI requestLivePlaybackSectionListWithChannelId:channelId videoId:videoId completion:^(NSArray<PLVLivePlaybackSectionModel *> * _Nonnull list, NSError * _Nonnull error) {
                                        sectionList = list;
                                    }];
                                }
                                [self playbackLoginWithChannelType:channelType channelId:channelId vid:videoPoolId userId:userId appId:appId appSecret:appSecret completion:^(PLVRoomData *roomData) {
                                    roomData.vid = videoPoolId;
                                    roomData.vodList = [channelPlaybackInfo.playbackOrigin isEqualToString:@"vod"];
                                    if (roomData.channelType == PLVChannelTypePPT) {
                                        roomData.sectionEnable = sectionEnabled;
                                        roomData.sectionList = sectionList;
                                    }
                                    roomData.playbackSessionId = playbackSessionId;
                                    
                                    // 使用roomUserHandler配置用户对象
                                    if (roomUserHandler) {
                                        roomUserHandler(roomData.roomUser);
                                    }
                                    [roomData setupRoomUser:roomData.roomUser];
                                    
                                    !completion ?: completion(roomData.customParam);
                                    
                                } failure:^(NSString *errorMessage) {
                                    !failure ?: failure(errorMessage);
                                }];
                            }
                        } else {
                            !failure ?: failure(@"回放类型暂不支持");
                            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【回放类型不可用】", __FUNCTION__);
                        }
                    } else if ([channelPlaybackInfo.type isEqualToString:@"list"]) { // 回放方式-列表回放
                        if (!channelPlaybackInfo.hasPlaybackVideo || !channelPlaybackInfo.targetPlaybackVideo) {
                            !failure ?: failure(@"回放视频为空");
                            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【回放视频不可为空】", __FUNCTION__);
                        } else {
                            if (sectionEnabled) {
                                [PLVLiveVideoAPI requestLivePlaybackSectionListWithChannelId:channelId videoId:videoId completion:^(NSArray<PLVLivePlaybackSectionModel *> * _Nonnull list, NSError * _Nonnull error) {
                                    sectionList = list;
                                }];
                            }
                            [PLVLiveVideoAPI requestPlaybackList:channelId listType:channelPlaybackInfo.type page:1 pageSize:10 appId:appId appSecret:appSecret completion:^(PLVPlaybackListModel * _Nonnull list, NSError * _Nonnull error) {
                                playbackList = list;
                            }];
                            [self playbackLoginWithChannelType:channelType channelId:channelId vid:videoPoolId userId:userId appId:appId appSecret:appSecret completion:^(PLVRoomData *roomData) {
                                roomData.vid = videoPoolId;
                                roomData.vodList = [channelPlaybackInfo.playbackOrigin isEqualToString:@"vod"];
                                if (roomData.channelType == PLVChannelTypePPT) {
                                    roomData.sectionEnable = sectionEnabled;
                                    roomData.sectionList = sectionList;
                                }
                                roomData.playbackList = playbackList;
                                roomData.playbackSessionId = playbackSessionId;
                                
                                // 使用roomUserHandler配置用户对象
                                if (roomUserHandler) {
                                    roomUserHandler(roomData.roomUser);
                                }
                                [roomData setupRoomUser:roomData.roomUser];
                                
                                !completion ?: completion(roomData.customParam);
                                
                            } failure:^(NSString *errorMessage) {
                                !failure ?: failure(errorMessage);
                            }];
                        }
                    } else {
                        !failure ?: failure(@"回放方式暂不支持");
                        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【回放方式不可用】", __FUNCTION__);
                    }
                }
            } else {
                !failure ?: failure(@"回放设置为空");
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【回放设置不可为空】", __FUNCTION__);
            }
        }  failure:^(NSError * _Nullable error) {
            !failure ?: failure(@"获取回放列表设置失败");
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get channel playbackList failed with【获取回放列表设置失败】", __FUNCTION__);
        }];
    } else {
        [self playbackLoginWithChannelType:channelType channelId:channelId vid:vid userId:userId appId:appId appSecret:appSecret completion:^(PLVRoomData *roomData) {
            roomData.vid = vid;
            roomData.vodList = vodList;
            
            // 使用roomUserHandler配置用户对象
            if (roomUserHandler) {
                roomUserHandler(roomData.roomUser);
            }
            [roomData setupRoomUser:roomData.roomUser];
            
            !completion ?: completion(roomData.customParam);
            
        } failure:^(NSString *errorMessage) {
            !failure ?: failure(errorMessage);
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
        !failure ?: failure(@"频道类型无效");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【登陆校验失败】(channelType:%zd)", __FUNCTION__, channelType);
        return;
    }
    if (![PLVFdUtil checkStringUseable:channelId]) {
        !failure ?: failure(@"频道号不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【频道号不可为空】(channelId:%@)", __FUNCTION__, channelId);
        return;
    }
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![PLVFdUtil checkStringUseable:appId] ||
        ![PLVFdUtil checkStringUseable:appSecret]) {
        !failure ?: failure(@"账号信息不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【账号信息不可为空】(userId:%@, appId:%@, appSecret:%@)", __FUNCTION__, appId, appId, appSecret);
        return;
    }
    
    PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
    
    if (![PLVFdUtil checkStringUseable:vid] && ![PLVFdUtil checkStringUseable:fileId]) {
        if (networkStatus == PLVNotReachable) {
            !failure ?: failure(@"当前无网络！");
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
        roomData.appBeautyEnabled = PLV_SafeBoolForDictKey(data, @"appBeautyEnabled");
        roomData.guestTranAuthEnabled = PLV_SafeBoolForDictKey(data, @"guestTranAuthEnabled");
        roomData.appWebStartResolutionRatio = PLV_SafeStringForDictKey(data, @"appWebStartResolutionRatio");
        roomData.appWebStartResolutionRatioEnabled = PLV_SafeBoolForDictKey(data, @"appWebStartResolutionRatioEnabled");
        
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
        [[PLVDocumentUploadClient sharedClient] setupWithChannelId:roomData.channelId pptAnimationEnable:pptAnimationEnable];
        
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

#pragma mark HiClass

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
        !failure ?: failure(@"视频vid不可为空");
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s login playback room failed with【视频vid不可为空】(vid:%@)", __FUNCTION__, vid);
        return;
    }
    [PLVLiveVideoAPI verifyVodPermissionWithChannelId:channelId.integerValue vid:vid userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
        [PLVLiveVideoConfig setPrivateDomainWithData:data];
        [PLVLiveVideoAPI liveStatus2:channelId appId:appId appSecret:appSecret completion:^(PLVChannelType apiChannelType, PLVChannelLiveStreamState liveState) {
            if ((apiChannelType & channelType) <= 0) {
                !failure ?: failure(@"频道类型出错");
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get vod channel failed with with【频道类型出错】(apiChannelType:%zd, channelType:%zd)", __FUNCTION__, apiChannelType, channelType);
            } else {
                // 初始化直播间数据
                PLVRoomData *roomData = [[PLVRoomData alloc] init];
                roomData.videoType = PLVChannelVideoType_Playback;
                roomData.channelType = apiChannelType;
                roomData.channelId = channelId;
                
                // 使用roomUserHandler配置用户对象
                PLVRoomUser *roomUser = [[PLVRoomUser alloc] initWithChannelType:apiChannelType];
                [roomData setupRoomUser:roomUser];
                
                // 登陆SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
                [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
                // 注册日志管理器
                [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId vId:vid];
                
                // 将当前的roomData配置到PLVRoomDataManager进行管理
                [[PLVRoomDataManager sharedManager] configRoomData:roomData];
                
                [roomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
                    !completion ?: completion(roomData);
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
        
        PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
        if (networkStatus != PLVNotReachable) {
            [PLVLiveVideoAPI verifyVodPermissionWithChannelId:channelId.integerValue vid:vid userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
                [PLVLiveVideoConfig setPrivateDomainWithData:data];
            } failure:^(NSError * _Nonnull error) {
                !failure ?: failure(@"登陆校验失败");
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登陆校验失败)", __FUNCTION__, error);
            }];
        }
        
        PLVChannelType offlineInfoChannelType = [model.liveType isEqualToString:@"ppt"] ? PLVChannelTypePPT : PLVChannelTypeAlone;
        if ((offlineInfoChannelType & channelType) <= 0) {
            !failure ?: failure(@"频道类型出错");
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get vod channel failed with with【频道类型出错】(apiChannelType:%zd, channelType:%zd)", __FUNCTION__, offlineInfoChannelType, channelType);
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
            
            // 登陆SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
            [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
            // 注册日志管理器
            [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId vId:vid];
            
            // 将当前的roomData配置到PLVRoomDataManager进行管理
            [[PLVRoomDataManager sharedManager] configRoomData:roomData];
            
            if (networkStatus != PLVNotReachable) {
                [roomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
                    !completion ?: completion(roomData.customParam);
                }];
            }else {
                roomData.noNetWorkOfflineIntroductionEnabled = YES;
                plv_dispatch_main_async_safe(^{
                    !completion ?: completion(roomData.customParam);
                })
            }
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
        
        PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
        if (networkStatus != PLVNotReachable) {
            [PLVLiveVideoAPI verifyLivePermissionWithChannelId:channelId.integerValue userId:userId appId:appId completion:^(NSDictionary * _Nonnull data) {
                [PLVLiveVideoConfig setPrivateDomainWithData:data];
                
            } failure:^(NSError * _Nonnull error) {
                !failure ?: failure(@"登陆校验失败");
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s verify vod permission with【%@】(登陆校验失败)", __FUNCTION__, error);
            }];
        }
        
        PLVChannelType offlineInfoChannelType = [model.liveType isEqualToString:@"ppt"] ? PLVChannelTypePPT : PLVChannelTypeAlone;
        if ((offlineInfoChannelType & channelType) <= 0) {
            !failure ?: failure(@"频道类型出错");
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeRoom, @"%s get liveRecord channel failed with with【频道类型出错】(apiChannelType:%zd, channelType:%zd)", __FUNCTION__, offlineInfoChannelType, channelType);
        }else {
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
            
            // 登陆SDK,一定要第一时间调用这个方法，否则会导致API接口参数为空
            [[PLVLiveVideoConfig sharedInstance] configWithUserId:userId appId:appId appSecret:appSecret];
            // 注册日志管理器
            [[PLVWLogReporterManager sharedManager] registerReporterWithChannelId:channelId userId:userId];
            
            // 将当前的roomData配置到PLVRoomDataManager进行管理
            [[PLVRoomDataManager sharedManager] configRoomData:roomData];
            
            if (networkStatus != PLVNotReachable) {
                [roomData requestChannelDetail:^(PLVLiveVideoChannelMenuInfo * channelMenuInfo) {
                    !completion ?: completion(roomData.customParam);
                }];
            }else {
                roomData.noNetWorkOfflineIntroductionEnabled = YES;
                plv_dispatch_main_async_safe(^{
                    !completion ?: completion(roomData.customParam);
                })
            }
        }
    }];
}
    
@end
