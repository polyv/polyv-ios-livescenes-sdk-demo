//
//  PLVLinkMicPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/7/22.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLinkMicPresenter.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif

/// 默认值
/// (注意:此处为默认值，最终以外部的设置为准。若外部未设置，才使用此默认值)
static const BOOL PLVLinkMicPresenterMicDefaultOpen = YES;     // 麦克风按钮 默认开关值
static const BOOL PLVLinkMicPresenterCameraDefaultOpen = NO;   // 摄像头按钮 默认开关值
static const BOOL PLVLinkMicPresenterCameraDefaultFront = YES; // 摄像头 默认前置值

@interface PLVLinkMicPresenter () <PLVSocketListenerProtocol,PLVLinkMicManagerDelegate>

#pragma mark 状态
/// 当前连麦状态
@property (nonatomic, assign) PLVLinkMicStatus linkMicStatus;

/// 当前连麦媒体类型
@property (nonatomic, assign) PLVLinkMicMediaType linkMicMediaType;

/// 当前连麦场景类型
@property (nonatomic, assign) PLVLinkMicScenesType linkMicScenesType;

/// 当前讲师是否发起连麦 (YES:讲师已开启连麦 NO:讲师未开启连麦)
@property (nonatomic, assign) BOOL linkMicOpen;

/// 当前‘主讲’是否为本地用户手动选定
@property (nonatomic, assign) BOOL currentMainSpeakerByLocalUser;

#pragma mark 数据
/// 设置当前直播间(频道)信息
@property (nonatomic, strong) PLVLiveRoomData *roomData;

/// 当前连麦 SocketToken (不为空时重连后要发送reJoinMic事件)
@property (nonatomic, copy) NSString *linkMicSocketToken;

/// 当前连麦 在线用户列表 (包含全部角色，包含自己) 内部使用
@property (nonatomic, strong) NSMutableArray <PLVLinkMicOnlineUser *>*onlineUserMuArray;

/// 讲师连麦Id (若此值非空，则代表讲师已在频道中)
@property (nonatomic, copy) NSString * teacherLinkMicUserId;

#pragma mark 外部数据封装
@property (nonatomic, copy, readonly) NSString * rtcType;
@property (nonatomic, copy, readonly) NSString * channelId;
@property (nonatomic, copy, readonly) NSString * sessionId;

@property (nonatomic, copy, readonly) NSString * userId;
@property (nonatomic, copy, readonly) NSString * linkMicUserId;
@property (nonatomic, copy, readonly) NSString * linkMicUserNickname;
@property (nonatomic, copy, readonly) NSString * linkMicUserAvatar;

#pragma mark 功能对象
@property (nonatomic, strong) PLVLinkMicManager * linkMicManager; // 连麦管理器

@property (nonatomic, strong) NSTimer * linkMicTimer;

@property (nonatomic, strong) dispatch_queue_t arraySafeQueue;
@property (nonatomic, strong) dispatch_queue_t requestLinkMicOnlineListSafeQueue;

@property (nonatomic, weak) dispatch_block_t requestOnlineListBlock;

@property (nonatomic, copy) void (^addLocalUserBlock) (void); // 本地用户添加事件 (本地用户添加应该在’连麦在线列表‘请求后执行，以保证所处位置在’已进入连麦‘的观众之后)

@end

@implementation PLVLinkMicPresenter

@synthesize listenEvents;

#pragma mark - [ Life Period ]
- (void)dealloc{
    [self stopLinkMicUserListTimer];
    [self quitLinkMicWithCheckIllegalStatus];
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData{
    if (self = [super init]) {
        self.roomData = roomData;
        [self setup];
    }
    return self;
}


#pragma mark - [ Public Methods ]
#pragma mark LinkMic
- (void)requestJoinLinkMic{
    if (self.linkMicStatus == PLVLinkMicStatus_Open) {
        __weak typeof(self) weakSelf = self;
        [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) { /// 申请麦克风、摄像头权限
            if (granted) {
                [self callbackForOperationInProgress:YES];
                if (weakSelf.linkMicScenesType == PLVLinkMicScenesType_CloudClass) {
                    [weakSelf createLinkMicManagerAndEmitJoinRequest];
                } else {
                    [PLVLiveVideoAPI rtcEnabled:[PLVLiveVideoConfig sharedInstance].channelId.integerValue completion:^(BOOL rtcEnabled) {
                        if (rtcEnabled) {
                            weakSelf.linkMicScenesType = PLVLinkMicScenesType_NormalLive;
                        } else {
                            weakSelf.linkMicScenesType = PLVLinkMicScenesType_BeforeLive;
                        }
                        [weakSelf createLinkMicManagerAndEmitJoinRequest];
                    } failure:^(NSError *error) {
                        [self callbackForOperationInProgress:NO];
                        NSLog(@"PLVLinkMicPresenter - request rtcEnabled failed, error: %@", error);
                        [weakSelf callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedRtcEnabledGetFail];
                    }];
                }
            } else {
                [self callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedNoAuth];
            }
        }];
    }else{
        NSLog(@"PLVLinkMicPresenter - request join linkmic failed, status error, current status :%lu",(unsigned long)self.linkMicStatus);
        [self callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedStatusIllegal extraCode:self.linkMicStatus];
    }
}

- (void)cancelRequestJoinLinkMic{
    if (self.linkMicStatus == PLVLinkMicStatus_Waiting) {
        [self emitSocketMessge_JoinLeave];
    }else{
        NSLog(@"PLVLinkMicPresenter - cancel request join linkmic failed, status error, current status :%lu",(unsigned long)self.linkMicStatus);
        [self callbackForDidOccurError:PLVLinkMicErrorCode_CancelRequestJoinFailedStatusIllegal extraCode:self.linkMicStatus];
    }
}

- (void)quitLinkMic{
    if ([self quitLinkMicWithCheckIllegalStatus]) {
        NSLog(@"PLVLinkMicPresenter - leave join linkmic failed, status error, current status :%lu",(unsigned long)self.linkMicStatus);
        [self callbackForDidOccurError:PLVLinkMicErrorCode_LeaveChannelFailedStatusIllegal extraCode:self.linkMicStatus];
    }
}

- (void)cameraOpen:(BOOL)open{
    int enableResult = [self.linkMicManager enableLocalVideo:open];
    int muteResult = [self.linkMicManager muteLocalVideoStream:!open];
    if (enableResult == 0 && muteResult == 0) {
        [self.currentLocalLinkMicUser updateUserCurrentCameraOpen:open];
    }else{
        NSLog(@"PLVLinkMicPresenter - cameraOpen failed, enableResult %u, muteResult %u",enableResult,muteResult);
    }
}

- (void)cameraSwitch:(BOOL)front{
    [self.linkMicManager switchCamera];
}

- (void)micOpen:(BOOL)open{
    int enableResult = [self.linkMicManager enableLocalAudio:open];
    int muteResult = [self.linkMicManager muteLocalAudioStream:!open];
    if (enableResult == 0 && muteResult == 0) {
        [self.currentLocalLinkMicUser updateUserCurrentMicOpen:open];
    }else{
        NSLog(@"PLVLinkMicPresenter - micOpen failed, enableResult %u, muteResult %u",enableResult,muteResult);
    }
}

- (void)changeMainSpeakerWithLinkMicUserIndex:(NSInteger)nowMainSpeakerLinkMicUserIndex{
    if (nowMainSpeakerLinkMicUserIndex < self.onlineUserMuArray.count) {
        PLVLinkMicOnlineUser * nowMainSpeakerLinkMicUser = self.onlineUserMuArray[nowMainSpeakerLinkMicUserIndex];
        [self changeMainSpeakerWithLinkMicUser:nowMainSpeakerLinkMicUser];
        self.currentMainSpeakerByLocalUser = YES;
    }
}

#pragma mark - [ Private Methods ]
- (void)setup{
    /// 初始化 数据
    self.onlineUserMuArray = [[NSMutableArray<PLVLinkMicOnlineUser *> alloc] init];
    self.arraySafeQueue = dispatch_queue_create("PLVLinkMicPresenterArraySafeQueue", DISPATCH_QUEUE_SERIAL);
    self.requestLinkMicOnlineListSafeQueue = dispatch_queue_create("PLVLinkMicPresenterRequestLinkMicOnlineListSafeQueue", DISPATCH_QUEUE_SERIAL);

    /// 初始化 默认值
    /// (注意:此处为默认值，最终以外部的设置为准)
    self.micDefaultOpen = PLVLinkMicPresenterMicDefaultOpen;
    self.cameraDefaultOpen = PLVLinkMicPresenterCameraDefaultOpen;
    self.cameraDefaultFront = PLVLinkMicPresenterCameraDefaultFront;
    
    /// 创建 获取连麦在线用户列表 定时器
    self.linkMicTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(linkMicTimerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.linkMicTimer forMode:NSRunLoopCommonModes];
    [self.linkMicTimer fire];
    
    /// 添加 socket 事件监听
    self.listenEvents = @[kPLVBSocketEvent_joinRequest,kPLVBSocketEvent_joinResponse,
                          kPLVBSocketEvent_joinSuccess,kPLVBSocketEvent_joinLeave,
                          kPLVBSocketEvent_MuteUserMedia,kPLVBSocketEvent_switchView];
    [[PLVSocketWrapper sharedSocketWrapper] addListener:self];
}

- (void)stopLinkMicUserListTimer{
    [_linkMicTimer invalidate];
    _linkMicTimer = nil;
}

- (BOOL)quitLinkMicWithCheckIllegalStatus{
    BOOL quitLinkMicStatusIllegal = NO;
    if (self.linkMicStatus == PLVLinkMicStatus_Joining || self.linkMicStatus == PLVLinkMicStatus_Joined) {
        [self.linkMicManager leaveRtcChannel];
    }else{
        /// 退出连麦的状态 非法
        quitLinkMicStatusIllegal = YES;
    }
    return quitLinkMicStatusIllegal;
}

#pragma mark Setter
- (void)setLinkMicStatus:(PLVLinkMicStatus)linkMicStatus{
    _linkMicStatus = linkMicStatus;
    /// @note 为了让使用者在阅读代码时，更加“显式”地，感知到 “回调被调用”
    ///       此 Setter 方法将不再附带 “回调的调用”
    ///       而将回调调用，跟随在每一句 self.linkMicStatus = linkMicStatus_xxx; 之后
}

#pragma mark Getter
- (NSString *)rtcType{
    return self.roomData.channelMenuInfo.rtcType;
}

- (NSString *)channelId{
    return self.roomData.channelId;
}

- (NSString *)sessionId{
    return self.roomData.sessionId;
}

- (NSString *)userId{
    return [PLVSocketWrapper sharedSocketWrapper].loginUser.userId;
}

- (NSString *)linkMicUserId{
    return [PLVSocketWrapper sharedSocketWrapper].loginUser.linkMicId;
}

- (NSString *)linkMicUserNickname{
    return [PLVSocketWrapper sharedSocketWrapper].loginUser.nickName;
}

- (NSString *)linkMicUserAvatar{
    return [PLVSocketWrapper sharedSocketWrapper].loginUser.avatarUrl;
}

#pragma mark Callback
/// 连麦状态发生改变
- (void)callbackForLinkMicStatusChanged{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:linkMicStatusChanged:)]) {
            [self.viewDelegate plvLinkMicPresenter:self linkMicStatusChanged:self.linkMicStatus];
        }
    })
}

/// 连麦管理器的处理状态发生改变
- (void)callbackForOperationInProgress:(BOOL)inProgress{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:operationInProgress:)]) {
            [self.viewDelegate plvLinkMicPresenter:self operationInProgress:inProgress];
        }
    })
}

- (void)callbackForMediaMute:(BOOL)mute mediaType:(NSString *)mediaType linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:didMediaMuted:mediaType:linkMicUser:)]) {
            [self.viewDelegate plvLinkMicPresenter:self didMediaMuted:mute mediaType:mediaType linkMicUser:linkMicUser];
        }
    })
}

- (void)callbackForLinkMicUserJoin{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:linkMicOnlineUserListRefresh:)]) {
            [self.viewDelegate plvLinkMicPresenter:self linkMicOnlineUserListRefresh:self.onlineUserMuArray];
        }
    })
}

- (void)callbackForMainSpeaker:(NSString *)linkMicUserId toFirstSite:(BOOL)toFirstSite{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:mainSpeakerLinkMicUserId:wannaBecomeFirstSite:)]) {
            [self.viewDelegate plvLinkMicPresenter:self mainSpeakerLinkMicUserId:linkMicUserId wannaBecomeFirstSite:toFirstSite];
        }
    })
}

- (void)callbackForMainSpeakerChangedToLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser {
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:mainSpeakerChangedToLinkMicUser:)]) {
            [self.viewDelegate plvLinkMicPresenter:self
                   mainSpeakerChangedToLinkMicUser:linkMicUser];
        }
    })
}

- (void)callbackForDidOccurError:(PLVLinkMicErrorCode)errorCode{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:didOccurError:extraCode:)]) {
            [self.viewDelegate plvLinkMicPresenter:self didOccurError:errorCode extraCode:0];
        }
    })
}

- (void)callbackForLocalUserDidInOutLinkMicRoom:(BOOL)InOut{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:localUserDidInOutLinkMicRoom:)]) {
            [self.viewDelegate plvLinkMicPresenter:self localUserDidInOutLinkMicRoom:InOut];
        }
    })
}

- (void)callbackForDidOccurError:(PLVLinkMicErrorCode)errorCode extraCode:(NSInteger)extraCode{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:didOccurError:extraCode:)]) {
            [self.viewDelegate plvLinkMicPresenter:self didOccurError:errorCode extraCode:extraCode];
        }
    })
}

- (void)callbackForReportAudioVolumeOfSpeakers:(NSDictionary<NSString *, NSNumber *> * _Nonnull)volumeDict{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:reportAudioVolumeOfSpeakers:)]) {
            [self.viewDelegate plvLinkMicPresenter:self reportAudioVolumeOfSpeakers:volumeDict];
        }
    })
}

- (void)callbackForReportCurrentSpeakingUsers:(NSArray<PLVLinkMicOnlineUser *> * _Nonnull)currentSpeakingUsers{
    dispatch_main_async_safe(^{
        if ([self.viewDelegate respondsToSelector:@selector(plvLinkMicPresenter:reportCurrentSpeakingUsers:)]) {
            [self.viewDelegate plvLinkMicPresenter:self reportCurrentSpeakingUsers:currentSpeakingUsers];
        }
    })
}

#pragma mark LinkMic
- (PLVLinkMicManager *)createLinkMicManager{
    if (![PLVFdUtil checkStringUseable:self.rtcType]) {
        NSLog(@"PLVLinkMicPresenter - linkMicManager create failed, rtcType illegal %@",self.rtcType);
        [self callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedNoRtcType];
        return nil;
    }
    if (_linkMicManager == nil) {
        _linkMicManager = [PLVLinkMicManager linkMicManagerWithRTCType:self.rtcType];
        _linkMicManager.delegate = self;
        _linkMicManager.linkMicOnAudio = self.linkMicMediaType == PLVLinkMicMediaType_Audio;
        _linkMicManager.micDefaultOpen = self.micDefaultOpen;
        _linkMicManager.cameraDefaultOpen = self.cameraDefaultOpen;
        _linkMicManager.cameraDefaultFront = self.cameraDefaultFront;
    }
    return _linkMicManager;
}

- (void)createLinkMicManagerAndEmitJoinRequest{
    if ([self createLinkMicManager]) {
        __weak typeof(self) weakSelf = self;
        [self.linkMicManager updateLinkMicTokenWithChannelId:self.channelId userLinkMicId:self.linkMicUserId completion:^(BOOL updateResult) {
            if (updateResult) {
                [weakSelf emitSocketMessge_JoinRequest];
            }else{
                [self callbackForOperationInProgress:NO];
                [self callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedNoToken];
            }
        }];
    }else{
        [self callbackForOperationInProgress:NO];
        [self callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedNoRtcType];
    }
}

/// 加入RTC频道
- (void)joinRTCChannel{
    [self callbackForOperationInProgress:YES];
    int code = [self.linkMicManager joinRtcChannelWithChannelId:self.channelId userLinkMicId:self.linkMicUserId];
    if (code == 0 && self.linkMicManager) {
        self.linkMicStatus = PLVLinkMicStatus_Joining;
        [self callbackForLinkMicStatusChanged];
        [PLVLiveVideoAPI requestViewerIdLinkMicIdRelate:[NSString stringWithFormat:@"%@",self.channelId] viewerId:self.userId linkMicId:self.linkMicUserId completion:nil failure:^(NSError * _Nonnull error) {
            NSLog(@"PLVLinkMicPresenter - id relate failed %@",error);
        }];
    }else if(self.linkMicManager){
        [self callbackForOperationInProgress:NO];
        [self callbackForDidOccurError:PLVLinkMicErrorCode_JoinChannelFailed extraCode:code];
    }
}

/// 解析数据，并刷新‘讲师端连麦开启状态’
- (void)refreshLinkMicOpenStatus:(NSString *)openStatus mediaType:(NSString *)mediaType{
    BOOL open = NO;
    if ([PLVFdUtil checkStringUseable:openStatus] && [openStatus isEqualToString:@"open"]) { open = YES; }
    BOOL diff = (open != self.linkMicOpen);
    if (diff) {
        if (open) { // 讲师 发起 连麦功能
            self.linkMicOpen = YES;
            
            if ([PLVFdUtil checkStringUseable:mediaType]) {
                if ([mediaType isEqualToString:@"audio"]) {
                    self.linkMicMediaType = PLVLinkMicMediaType_Audio; // 音频连麦
                }else if ([mediaType isEqualToString:@"video"]) {
                    self.linkMicMediaType = PLVLinkMicMediaType_Video; // 视频连麦
                }
            }
            self.linkMicStatus = PLVLinkMicStatus_Open;
            [self callbackForLinkMicStatusChanged];
        }else{  // 讲师 结束 连麦功能
            self.linkMicOpen = NO;
            
            if (self.linkMicStatus == PLVLinkMicStatus_Joined || self.linkMicStatus == PLVLinkMicStatus_Joining) {
                [self callbackForOperationInProgress:YES];
                [self.linkMicManager leaveRtcChannel];
            }
            self.linkMicMediaType = PLVLinkMicMediaType_Unknown;
            self.linkMicStatus = PLVLinkMicStatus_NotOpen;
            [self callbackForLinkMicStatusChanged];
        }
    }
}

- (void)muteUser:(NSString *)linkMicUserId mediaType:(NSString *)mediaType mute:(BOOL)mute{
    PLVLinkMicOnlineUser * targetLinkMicUser = [self findLinkMicOnlineUserWithLinkMicUserId:linkMicUserId];
    if (targetLinkMicUser) {
        if ([self.linkMicUserId isEqualToString:linkMicUserId]) {
            // 目标用户 是 本地用户
            if ([@"video" isEqualToString:mediaType]) {
                [self cameraOpen:!mute];
            }else{
                [self micOpen:!mute];
            }
        }else{
            // 目标用户 是 远端用户
            if ([@"video" isEqualToString:mediaType]) {
                [targetLinkMicUser updateUserCurrentCameraOpen:!mute];
            }else{
                [targetLinkMicUser updateUserCurrentMicOpen:!mute];
            }
        }
        [self callbackForMediaMute:mute mediaType:mediaType linkMicUser:targetLinkMicUser];
    }
}

- (void)linkMicUserJoined:(NSString *)linkMicUserId retryCount:(NSInteger)retryCount{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.requestLinkMicOnlineListSafeQueue, ^{
        if (weakSelf.requestOnlineListBlock) {
            dispatch_block_cancel(weakSelf.requestOnlineListBlock);
        }
        dispatch_block_t requestBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
            [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:weakSelf.channelId.integerValue sessionId:weakSelf.sessionId completion:^(NSDictionary *dict) {
                dispatch_async(weakSelf.arraySafeQueue, ^{
                    BOOL includeTargetLinkMicUser = [weakSelf refreshLinkMicOnlineUserListWithDataDictionary:dict targetLinkMicUserId:linkMicUserId];
                    
                    /**
                     若此次请求回来的连麦在线列表，不包含Rtc回调的新增用户，则启动重试逻辑。
                     重试过程中，每次重试的延时，递增 2 秒，尽量确保接口数据更新。
                     若重试过程中，有新连麦人加入，则本次重试中断，以新连麦人的请求为准。 // ??? 有可能进来后 1秒内就退出，这样重试很多次都找不到
                     */
                    if (!includeTargetLinkMicUser && retryCount < 3) {
                        [weakSelf linkMicUserJoined:linkMicUserId retryCount:retryCount + 1];
                    }
                });
            } failure:^(NSError *error) {
                NSLog(@"PLVLinkMicPresenter - request link mic online list failed, error:%@",error);
            }];
        });
        weakSelf.requestOnlineListBlock = requestBlock;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1 + 2 * retryCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), weakSelf.requestOnlineListBlock);
    });
}

/// 连麦用户列表管理
#pragma mark LinkMic User Manage
- (void)sortOnlineUserList{
    NSArray * sortArray = [self.onlineUserMuArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PLVLinkMicOnlineUser * user1 = (PLVLinkMicOnlineUser *)obj1;
        PLVLinkMicOnlineUser * user2 = (PLVLinkMicOnlineUser *)obj2;

        if (user1.userType > user2.userType) return NSOrderedAscending;
        
        return NSOrderedDescending;
    }];
    [self.onlineUserMuArray removeAllObjects];
    self.onlineUserMuArray = [NSMutableArray arrayWithArray:sortArray];
}

- (void)addLocalUserIntoOnlineUserList{
    __weak typeof(self) weakSelf = self;
    self.addLocalUserBlock = ^{
        PLVLinkMicOnlineUser * localUser = [PLVLinkMicOnlineUser localUserModelWithUserId:weakSelf.linkMicUserId nickname:weakSelf.linkMicUserNickname avatarPic:weakSelf.linkMicUserAvatar];
        [weakSelf addUserIntoOnlineUserList:localUser];
    };
    
    if (self.onlineUserMuArray.count > 0) {
        self.addLocalUserBlock();
        self.addLocalUserBlock = nil;
    }
}

- (void)addUserIntoOnlineUserList:(PLVLinkMicOnlineUser *)user{
    if (user && [user isKindOfClass:PLVLinkMicOnlineUser.class]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            NSArray <NSString *> * userIdArray = [weakSelf.onlineUserMuArray valueForKeyPath:@"linkMicUserId"];
            if (![userIdArray containsObject:user.linkMicUserId]) {
                if (!user.rtcRendered) {
                    NSString * linkmicUserId = user.linkMicUserId;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIView * rtcView = user.rtcView;
                        [weakSelf.linkMicManager addRTCCanvasAtSuperView:rtcView uid:linkmicUserId];
                    });
                }
                
                if (user.mainSpeaker) {
                    weakSelf.currentMainSpeaker.mainSpeaker = NO;
                    weakSelf.currentMainSpeaker = user;
                    [weakSelf.onlineUserMuArray insertObject:user atIndex:0];
                }else{
                    [weakSelf.onlineUserMuArray addObject:user];
                }
                
                if (user.localUser) {
                    weakSelf.currentLocalLinkMicUser = user;
                    /// 设置初始值
                    [user updateUserCurrentMicOpen:weakSelf.micDefaultOpen];
                    [user updateUserCurrentCameraOpen:weakSelf.cameraDefaultOpen];
                }else{
                    /// 设置初始值
                    [user updateUserCurrentMicOpen:YES];
                    [user updateUserCurrentCameraOpen:YES];
                }
                
                //[weakSelf sortOnlineUserList];
                [weakSelf callbackForLinkMicUserJoin];
            }else{
                //NSLog(@"POLYVTEST - 重复加入 %@ %@",user.linkMicUserId,user.nickname);
            }
        });
    }
}

- (void)removeUserFromOnlineUserList:(NSString *)linkMicUserId{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            int index = -1;
            PLVLinkMicOnlineUser * user;
            for (int i = 0; i < weakSelf.onlineUserMuArray.count; i++) {
                user = weakSelf.onlineUserMuArray[i];
                if ([user.linkMicUserId isEqualToString:linkMicUserId]) {
                    index = i;
                    break;
                }
            }
            
            if (index >= 0 && index < weakSelf.onlineUserMuArray.count && user != nil) {
                [weakSelf.onlineUserMuArray removeObject:user];
                [weakSelf callbackForLinkMicUserJoin];
            }else{
                NSLog(@"PLVLinkMicPresenter - remove link mic user(%@) failed, index(%d) not in the array",linkMicUserId,index);
            }
        });
    }
}

- (void)resetOnlineUserList{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.arraySafeQueue, ^{
        [weakSelf.onlineUserMuArray removeAllObjects];
        [weakSelf callbackForLinkMicUserJoin];
    });
}

- (void)changeMainSpeakerWithLinkMicUserId:(NSString *)nowMainSpeakerLinkMicUserId{
    if ([self.currentMainSpeaker.linkMicUserId isEqualToString:nowMainSpeakerLinkMicUserId] == NO) {
        PLVLinkMicOnlineUser * nowMainSpeakerUser = [self findLinkMicOnlineUserWithLinkMicUserId:nowMainSpeakerLinkMicUserId];
        [self changeMainSpeakerWithLinkMicUser:nowMainSpeakerUser];
    }
}

- (void)changeMainSpeakerWithLinkMicUser:(PLVLinkMicOnlineUser *)nowMainSpeakerUser{
    if (self.currentMainSpeaker != nowMainSpeakerUser) {
        // “主讲” 发生变更
        self.currentMainSpeaker.mainSpeaker = NO;
        nowMainSpeakerUser.mainSpeaker = YES;
        self.currentMainSpeaker = nowMainSpeakerUser;
        
        // “主讲” 移至第一位
        [self linkMicUserBecomeFirstSiteInArray:nowMainSpeakerUser];
    }
}

- (void)linkMicUserBecomeFirstSiteInArray:(PLVLinkMicOnlineUser *)linkMicUser{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.arraySafeQueue, ^{
        if ([weakSelf.onlineUserMuArray containsObject:linkMicUser]) {
            NSInteger targetUserIndex = [weakSelf.onlineUserMuArray indexOfObject:linkMicUser];
            if (targetUserIndex < weakSelf.onlineUserMuArray.count) {
                if (targetUserIndex > 0) {
                    [weakSelf.onlineUserMuArray exchangeObjectAtIndex:targetUserIndex withObjectAtIndex:0];
                    [weakSelf callbackForLinkMicUserJoin];
                }
            }else{
                NSLog(@"PLVLinkMicPresenter - linkMicUserBecomeFirstSiteInArray failed, index(%ld) beyond bounds for empty array",(long)targetUserIndex);
            }
        }
    });
}

- (PLVLinkMicOnlineUser *)findLinkMicOnlineUserWithLinkMicUserId:(NSString *)linkMicUserId{
    return [self findLinkMicOnlineUserWithJudgeBlock:^BOOL(PLVLinkMicOnlineUser *user) {
        if ([user.linkMicUserId isEqualToString:linkMicUserId]) {
            return YES;
        }
        return NO;
    }];
}

- (PLVLinkMicOnlineUser *)findLinkMicOnlineUserWithJudgeBlock:(BOOL(^)(PLVLinkMicOnlineUser * user))judgeBlock{
    PLVLinkMicOnlineUser * user;
    for (int i = 0; i < self.onlineUserMuArray.count; i++) {
        user = self.onlineUserMuArray[i];
        BOOL target = NO;
        if (judgeBlock) { target = judgeBlock(user); }
        if (target) {
            return user;
        }else{
            user = nil;
        }
    }
    return user;
}

/// 解析‘连麦用户列表数据’ 并 刷新用户数组
- (BOOL)refreshLinkMicOnlineUserListWithDataDictionary:(NSDictionary *)dataDictionary targetLinkMicUserId:(NSString *)targetLinkMicUserId{
    BOOL includeTargetLinkMicUser = NO;
    
    // 检查数组是否合法
    NSArray * linkMicUserList = dataDictionary[@"joinList"];
    if (![PLVFdUtil checkArrayUseable:linkMicUserList]) {
        return includeTargetLinkMicUser;
    }
    
    // 读取当前主讲人
    NSString * master = dataDictionary[@"master"];
    if (![PLVFdUtil checkStringUseable:master]) {
        master = self.channelId;
        // 更新当前主讲人
        [self changeMainSpeakerWithLinkMicUserId:master];
    }
    
    // 删除用户
    NSArray * currentOnlineUserArray = [self.onlineUserMuArray copy];
    for (PLVLinkMicOnlineUser * exsitUser in currentOnlineUserArray) {
        BOOL inCurrentLinkMicList = NO;
        for (NSDictionary * userInfo in linkMicUserList) {
            NSString * userId = userInfo[@"userId"];
            if ([PLVFdUtil checkStringUseable:userId]) {
                if ([userId isEqualToString:exsitUser.linkMicUserId]) {
                    inCurrentLinkMicList = YES;
                    break;
                }
            }
        }
        if (!inCurrentLinkMicList) {
            if ([exsitUser.linkMicUserId isEqualToString:self.linkMicUserId]) {
                [self quitLinkMic];
            }else{
                [self removeUserFromOnlineUserList:exsitUser.linkMicUserId];
            }
        }
    }
    
    // 添加用户
    for (NSDictionary * userInfo in linkMicUserList) {
        BOOL returnValue_includeTargetLinkMicUser = [self addLinkMicOnlineUser:userInfo mainSpeakerUserId:master targetLinkMicUserId:targetLinkMicUserId];
        if (!includeTargetLinkMicUser) {
            /// 仅在仍未找到‘目标用户’，会取本次‘添加用户’的返回值
            /// 因为若添加过程，已找到‘目标用户’，则本次方法的结果已确认，避免被覆盖
            includeTargetLinkMicUser = returnValue_includeTargetLinkMicUser;
        }
    }
    
    return includeTargetLinkMicUser;
}

- (BOOL)addLinkMicOnlineUser:(NSDictionary *)userInfo mainSpeakerUserId:(NSString *)master targetLinkMicUserId:(NSString *)targetLinkMicUserId{
    BOOL includeTargetLinkMicUser = NO;
    if ([PLVFdUtil checkDictionaryUseable:userInfo]) {
        PLVLinkMicOnlineUser * onlineUser = [PLVLinkMicOnlineUser modelWithDictionary:userInfo];
        
        // 若是本地用户，则不作解析
        if ([onlineUser.linkMicUserId isEqualToString:self.linkMicUserId]) {
            return includeTargetLinkMicUser;
        }
        
        // 更新讲师连麦Id
        if (![PLVFdUtil checkStringUseable:self.teacherLinkMicUserId] && onlineUser.userType == PLVLinkMicOnlineUserType_Teacher && [PLVFdUtil checkStringUseable:onlineUser.linkMicUserId]) {
            self.teacherLinkMicUserId = onlineUser.linkMicUserId;
        }
        
        // 判断是否包含目标新增连麦人
        if ([onlineUser.linkMicUserId isEqualToString:targetLinkMicUserId]) {
            includeTargetLinkMicUser = YES;
        }
        
        // 设置主讲人标记
        if ([master isEqualToString:onlineUser.linkMicUserId] && !self.currentMainSpeakerByLocalUser) {
            onlineUser.mainSpeaker = YES;
        }
        
        // 添加用户
        [self addUserIntoOnlineUserList:onlineUser];
        
        // 更新当前主讲人
        if ([master isEqualToString:onlineUser.linkMicUserId] && !self.currentMainSpeakerByLocalUser) {
            [self changeMainSpeakerWithLinkMicUserId:master];
        }
        
        if (self.addLocalUserBlock) {
            self.addLocalUserBlock();
            self.addLocalUserBlock = nil;
        }
    }
    return includeTargetLinkMicUser;
}

- (void)requestLinkMicOnlineListInQueue{

}

- (void)updateLinkMicUserVolumeWithVolumeDictionary:(NSDictionary<NSString *,NSNumber *> *)volumeDict{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.arraySafeQueue, ^{
        NSMutableArray <PLVLinkMicOnlineUser*> * currentSpeakingUser = [[NSMutableArray<PLVLinkMicOnlineUser *> alloc] init];
        for (int i = 0; i < weakSelf.onlineUserMuArray.count; i++) {
            PLVLinkMicOnlineUser * user = weakSelf.onlineUserMuArray[i];
            NSNumber * volumeNumber = [volumeDict objectForKey:user.linkMicUserId];
            if (volumeNumber) {
                [user updateUserCurrentVolume:volumeNumber.floatValue];
                if (volumeNumber.floatValue > 0.13) {
                    /// 大于 0.13 可认为处于‘能被听到的音量’，则可认为是属于 ‘正在发言’
                    [currentSpeakingUser addObject:user];
                }
            }else{
                [user updateUserCurrentVolume:0.0];
            }
        }
        if ([PLVFdUtil checkArrayUseable:currentSpeakingUser]) {
            [weakSelf callbackForReportCurrentSpeakingUsers:currentSpeakingUser];
        }
    });
}

#pragma mark Socket
- (BOOL)checkSocketMessageAckIsTimeOut:(NSArray *)ackArray{
    if ([PLVFdUtil checkArrayUseable:ackArray]) {
          NSString *ack = ackArray.firstObject;
          if ([PLVFdUtil checkStringUseable:ack]) { if ([ack isEqualToString:@"NO ACK"]) { return YES; } }
    }
    return NO;
}

- (void)emitSocketMessge_JoinRequest {
    __weak typeof(self) weakSelf = self;
    [self emitSocketMessageEventType:@"joinRequest" callback:^(NSArray *ackArray) {
        [weakSelf callbackForOperationInProgress:NO];
        if ([weakSelf checkSocketMessageAckIsTimeOut:ackArray]) {
            // 消息发送超时
            [weakSelf callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedSocketTimeout];
        }else{
            // 消息正常返回
            if (ackArray.count > 0 && [@"joinRequest" isEqualToString:ackArray.firstObject]) {
                weakSelf.linkMicStatus = PLVLinkMicStatus_Waiting;
                [weakSelf callbackForLinkMicStatusChanged];
            }
        }
    } failedErrorCode:PLVLinkMicErrorCode_RequestJoinFailedSocketCannotSend];
}

- (void)emitSocketMessge_JoinSuccess{
    __weak typeof(self) weakSelf = self;
    [self emitSocketMessageEventType:@"joinSuccess" callback:^(NSArray * ackArray) {
        [weakSelf callbackForOperationInProgress:NO];
        if ([weakSelf checkSocketMessageAckIsTimeOut:ackArray]) {
            // 消息发送超时
            [weakSelf callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedSocketTimeout];
        }else{
            // 消息正常返回
            if (ackArray.count > 0) {
                NSString *jsonString = ackArray[0];
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
                if (error == nil && jsonObject) {
                    NSDictionary *responseDict = jsonObject;
                    weakSelf.linkMicSocketToken = responseDict[@"token"];
                    weakSelf.linkMicStatus = PLVLinkMicStatus_Joined;
                    [weakSelf callbackForLinkMicStatusChanged];

                    [weakSelf callbackForLocalUserDidInOutLinkMicRoom:YES];
                    [weakSelf addLocalUserIntoOnlineUserList];
                }else{
                    NSLog(@"PLVLinkMicPresenter - 'joinSuccess' ackArray decode failed, error:%@",error);
                }
            }
        }
    } failedErrorCode:PLVLinkMicErrorCode_JoinChannelFailedSocketCannotSend];
}

- (void)emitSocketMessge_JoinLeave{
    __weak typeof(self) weakSelf = self;
    [self emitSocketMessageEventType:@"joinLeave" callback:^(NSArray *ackArray) {
        [weakSelf callbackForOperationInProgress:NO];
        [weakSelf callbackForLocalUserDidInOutLinkMicRoom:NO];
        
        // 重置处理
        [weakSelf resetOnlineUserList];
        weakSelf.linkMicSocketToken = nil;

        if (weakSelf.linkMicOpen) {
            weakSelf.linkMicStatus = PLVLinkMicStatus_Open;
            [weakSelf callbackForLinkMicStatusChanged];
        }else{
            weakSelf.linkMicStatus = PLVLinkMicStatus_NotOpen;
            [weakSelf callbackForLinkMicStatusChanged];
        }
    } failedErrorCode:PLVLinkMicErrorCode_LeaveChannelFailedSocketCannotSend];
}

- (void)emitSocketMessageEventType:(NSString *)eventType callback:(void (^)(NSArray * _Nonnull))callback failedErrorCode:(PLVLinkMicErrorCode)failedErrorCode{
    PLVSocketStatus socketStatus = PLVSocketWrapper.sharedSocketWrapper.status;
    if (socketStatus == PLVSocketStatusLoginSuccess) {
        NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
        NSString *roomId = PLVSocketWrapper.sharedSocketWrapper.roomId; // 此处不可使用频道号，因存在分房间的可能
        jsonDict[@"roomId"]  = [NSString stringWithFormat:@"%@",roomId];
        jsonDict[@"user"]    = @{@"nick" : [NSString stringWithFormat:@"%@",self.linkMicUserNickname],
                                 @"pic" : [NSString stringWithFormat:@"%@",self.linkMicUserAvatar],
                                 @"userId" : [NSString stringWithFormat:@"%@",self.linkMicUserId],
                                 @"userType" : kPLVBSocketUserTypeSlice};
        if ([eventType isEqualToString:@"joinLeave"] && [PLVFdUtil checkStringUseable:self.linkMicSocketToken]) {
            jsonDict[@"token"] = self.linkMicSocketToken;
        }
        
        [[PLVSocketWrapper sharedSocketWrapper] emitMessage:eventType content:jsonDict timeout:5.0 callback:^(NSArray *ackArray) {
            callback(ackArray);
        }];
    }else{
        [self callbackForOperationInProgress:NO];
        [self callbackForDidOccurError:failedErrorCode];
        NSLog(@"PLVLinkMicPresenter - link mic msg send failed, current status:%lu",(unsigned long)socketStatus);
    }
}

- (void)emitSocketMessge_reJoinMic{
    if ([PLVFdUtil checkStringUseable:self.linkMicSocketToken]) {
        __weak typeof(self) weakSelf = self;
        [[PLVSocketWrapper sharedSocketWrapper] emitMessage:@"reJoinMic" content:self.linkMicSocketToken timeout:5.0 callback:^(NSArray *ackArray) {
        }];
    }else{
        NSLog(@"PLVLinkMicPresenter - reJoinMic msg send failed, linkMicSocketToken illegal %@",self.linkMicSocketToken);
    }
}

- (void)handleSocketEvent:(PLVSocketLinkMicEventType)eventType jsonDict:(NSDictionary *)jsonDict {
    switch (eventType) {
        // 讲师信息
        case PLVSocketLinkMicEventType_TEACHER_INFO: {
            NSString *teacherId = (NSString *)jsonDict[@"data"][@"userId"];
            // 更新讲师连麦Id
            if (![PLVFdUtil checkStringUseable:self.teacherLinkMicUserId] && [PLVFdUtil checkStringUseable:teacherId]) {
                self.teacherLinkMicUserId = teacherId;
            }
        } break;
            
        // 讲师发起或结束连麦功能；讲师单独挂断学生连麦（广播消息 broadcast）
        case PLVSocketLinkMicEventType_OPEN_MICROPHONE: {
            NSString *teacherId = jsonDict[@"teacherId"];
            if (teacherId) { /// 讲师发起或结束连麦功能
                // 更新讲师连麦Id
                if (![PLVFdUtil checkStringUseable:self.teacherLinkMicUserId] && [PLVFdUtil checkStringUseable:teacherId]) {
                    self.teacherLinkMicUserId = teacherId;
                }
                
                [self refreshLinkMicOpenStatus:jsonDict[@"status"] mediaType:jsonDict[@"type"]];
            } else if ([jsonDict[@"userId"] isEqualToString:self.linkMicUserId]) {  /// 讲师单独挂断学生连麦
                [self callbackForOperationInProgress:YES];
                [self.linkMicManager leaveRtcChannel];
            }
        } break;
            
        // 讲师同意学生连麦（单播消息unicast）
        case PLVSocketLinkMicEventType_JOIN_RESPONSE: {
            if (self.linkMicStatus == PLVLinkMicStatus_Waiting) {
                [self joinRTCChannel];
            }else{
                NSLog(@"PLVLinkMicPresenter - will not join rtc channel, not in waiting status, current status:%lu",(unsigned long)self.linkMicStatus);
                [self callbackForDidOccurError:PLVLinkMicErrorCode_JoinChannelFailedStatusIllegal];
                [self quitLinkMic];
            }
        } break;
            
        // 讲师允许某连麦人上麦（非观众类型的角色，在讲师允许后，才会上麦）
        case PLVSocketLinkMIcEventType_switchJoinVoice: {
        } break;
    
        // 讲师打开或关闭，你的摄像头或麦克风（单播消息 unicast）
        case PLVSocketLinkMicEventType_MuteUserMedia: {
            BOOL mute = ((NSNumber *)jsonDict[@"mute"]).boolValue;
            [self muteUser:self.linkMicUserId mediaType:jsonDict[@"type"] mute:mute];
        } break;
            
        // 讲师让某位连麦人成为’主讲‘，即第一画面
        case PLVSocketLinkMicEventType_SwitchView: {
            self.currentMainSpeakerByLocalUser = NO;
            NSString * nowMainSpeakerLinkMicUserId = [NSString stringWithFormat:@"%@",jsonDict[@"userId"]];
            [self changeMainSpeakerWithLinkMicUserId:nowMainSpeakerLinkMicUserId];
        } break;
            
        // 讲师设置连麦人权限
        case PLVSocketLinkMIcEventType_TEACHER_SET_PERMISSION: {
        } break;
        
        // 讲师主动切换PPT和播放器的位置（非连麦中，是否应该处理此事件）
        // TODO：此事件不应归于“linkMic”模块
        case PLVSocketLinkMIcEventType_changeVideoAndPPTPosition: {
            BOOL mainSpeakerBecomeFirstSite = ((NSNumber *)jsonDict[@"status"]).boolValue;
            [self callbackForMainSpeaker:self.currentMainSpeaker.linkMicUserId toFirstSite:mainSpeakerBecomeFirstSite];
        } break;
            
        default:
            break;
    }
}


#pragma mark - [ Event ]
#pragma mark Timer
- (void)linkMicTimerEvent:(NSTimer *)timer{
    /// Socket 断开时不作刷新请求，因连麦业务基本均依赖于 Scoket 服务
    PLVSocketStatus socketStatus = PLVSocketWrapper.sharedSocketWrapper.status;
    if (socketStatus == PLVSocketStatusLoginSuccess) {
        __weak typeof(self) weakSelf = self;

        // 请求，刷新‘讲师端连麦开启状态’
        [PLVLiveVideoAPI requestLinkMicStatusWithRoomId:self.channelId.integerValue completion:^(NSString *status, NSString *type) {
            [weakSelf refreshLinkMicOpenStatus:status mediaType:type];
        } failure:^(NSError *error) {
            NSLog(@"PLVLinkMicPresenter - request linkmic status failed : %@",error);
        }];
        
        if (self.linkMicStatus == PLVLinkMicStatus_Joined) {
            // 请求，刷新‘连麦在线用户列表’
            [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:self.channelId.integerValue sessionId:self.sessionId completion:^(NSDictionary *dict) {
                dispatch_async(weakSelf.arraySafeQueue, ^{
                    [weakSelf refreshLinkMicOnlineUserListWithDataDictionary:dict targetLinkMicUserId:nil];
                });
            } failure:^(NSError *error) {
                NSLog(@"PLVLinkMicPresenter - request linkmic online user list failed : %@",error);
            }];
        }
    }else{
        NSLog(@"PLVLinkMicPresenter - link mic status refresh failed, current socket status:%lu",(unsigned long)socketStatus);
    }
}


#pragma mark - [ Delegate ]
#pragma mark PLVSocketListenerProtocol
/// socket 接收到 "message" 事件
- (void)socket:(id<PLVSocketIOProtocol>)socket didReceiveMessage:(NSString *)string jsonDict:(NSDictionary *)jsonDict{
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:@"OPEN_MICROPHONE"]) {
        [self handleSocketEvent:PLVSocketLinkMicEventType_OPEN_MICROPHONE jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"O_TEACHER_INFO"]) {
        [self handleSocketEvent:PLVSocketLinkMicEventType_TEACHER_INFO jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"TEACHER_SET_PERMISSION"]) {
        [self handleSocketEvent:PLVSocketLinkMIcEventType_TEACHER_SET_PERMISSION jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"changeVideoAndPPTPosition"]) {
        [self handleSocketEvent:PLVSocketLinkMIcEventType_changeVideoAndPPTPosition jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"switchJoinVoice"]) {
        [self handleSocketEvent:PLVSocketLinkMIcEventType_switchJoinVoice jsonDict:jsonDict];
    } else if ([subEvent containsString:@"SEND_CUP"]) {   // 奖杯事件

    } else if ([subEvent containsString:@"LOGIN"]){ // 登录事件
        NSString * loginUserId = (NSString *)jsonDict[@"user"][@"userId"];
        if ([PLVFdUtil checkStringUseable:self.linkMicSocketToken] && [PLVFdUtil checkStringUseable:loginUserId] && [loginUserId isEqualToString:self.userId]) {
            // 连麦Token不为空，需发送 reJoinMic 进行重连
            [self emitSocketMessge_reJoinMic];
        }
    }
}

/// socket 接收到 "主动监听" 事件（不包含 "message" 事件）
- (void)socket:(id<PLVSocketIOProtocol>)socket didReceiveEvent:(NSString *)event jsonDict:(NSDictionary *)jsonDict{
    if ([event isEqualToString:kPLVBSocketEvent_joinRequest]) {
        [self handleSocketEvent:PLVSocketLinkMicEventType_JOIN_REQUEST jsonDict:jsonDict];
    } else if ([event isEqualToString:kPLVBSocketEvent_joinResponse]) {
        [self handleSocketEvent:PLVSocketLinkMicEventType_JOIN_RESPONSE jsonDict:jsonDict];
    } else if ([event isEqualToString:kPLVBSocketEvent_joinSuccess]) {
        [self handleSocketEvent:PLVSocketLinkMicEventType_JOIN_SUCCESS jsonDict:jsonDict];
    } else if ([event isEqualToString:kPLVBSocketEvent_joinLeave]) {
        [self handleSocketEvent:PLVSocketLinkMicEventType_JOIN_LEAVE jsonDict:jsonDict];
    } else if ([event isEqualToString:kPLVBSocketEvent_MuteUserMedia]) {
        [self handleSocketEvent:PLVSocketLinkMicEventType_MuteUserMedia jsonDict:jsonDict];
    } else if ([event isEqualToString:kPLVBSocketEvent_switchView]) {
        [self handleSocketEvent:PLVSocketLinkMicEventType_SwitchView jsonDict:jsonDict];
    }
}

#pragma mark PLVLinkMicManagerDelegate
- (void)plvLinkMicManager:(PLVLinkMicManager *)manager joinRTCChannelComplete:(NSString *)channelID uid:(NSString *)uid{
    [self emitSocketMessge_JoinSuccess];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager leaveRTCChannelComplete:(NSString * _Nonnull)channelID{
    [self emitSocketMessge_JoinLeave];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didOccurError:(NSInteger)errorCode{
    [self callbackForDidOccurError:PLVLinkMicErrorCode_JoinedOccurError extraCode:errorCode];
    if (self.linkMicStatus == PLVLinkMicStatus_Waiting) {
        [self cancelRequestJoinLinkMic];
    }else if (self.linkMicStatus == PLVLinkMicStatus_Joining || self.linkMicStatus == PLVLinkMicStatus_Joined){
        [self quitLinkMic];
    }
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didJoinedOfUid:(NSString *)uid{
    [self linkMicUserJoined:uid retryCount:0];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didOfflineOfUid:(NSString *)uid{
    [self removeUserFromOnlineUserList:uid];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didAudioMuted:(BOOL)muted byUid:(NSString *)uid{
    [self muteUser:uid mediaType:@"audio" mute:muted];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didVideoMuted:(BOOL)muted byUid:(NSString *)uid{
    [self muteUser:uid mediaType:@"video" mute:muted];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager reportAudioVolumeOfSpeakers:(NSDictionary<NSString *,NSNumber *> *)volumeDict{
    [self updateLinkMicUserVolumeWithVolumeDictionary:volumeDict];
    [self callbackForReportAudioVolumeOfSpeakers:volumeDict];
}

@end
