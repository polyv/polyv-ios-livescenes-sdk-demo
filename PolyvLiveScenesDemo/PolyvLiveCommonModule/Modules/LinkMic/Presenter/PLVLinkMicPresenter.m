//
//  PLVLinkMicPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/7/22.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLinkMicPresenter.h"

#import "PLVRoomDataManager.h"
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

/// 默认值
/// (注意:此处为默认值，最终以外部的设置为准。若外部未设置，才使用此默认值)
static const BOOL PLVLinkMicPresenterMicDefaultOpen = YES;     // 麦克风按钮 默认开关值
static const BOOL PLVLinkMicPresenterCameraDefaultOpen = NO;   // 摄像头按钮 默认开关值
static const BOOL PLVLinkMicPresenterCameraDefaultFront = YES; // 摄像头 默认前置值

/// 连麦事件
typedef NS_ENUM(NSUInteger, PLVLinkMicEventType) {
    /// 讲师发起或结束连麦功能；讲师单独挂断学生连麦
    PLVLinkMicEventType_OPEN_MICROPHONE = 0,
    
    /// 学生举手申请连麦
    PLVLinkMicEventType_JOIN_REQUEST,
    /// 讲师同意学生连麦
    PLVLinkMicEventType_JOIN_RESPONSE,
    /// 学生加入连麦频道成功
    PLVLinkMicEventType_JOIN_SUCCESS,
    /// 学生已退出连麦频道
    PLVLinkMicEventType_JOIN_LEAVE,
    
    /// 讲师信息
    PLVLinkMicEventType_TEACHER_INFO,
    /// 讲师打开或关闭，讲师或学生的摄像头或麦克风
    PLVLinkMicEventType_MuteUserMedia,
    /// 讲师切换连麦人的主副屏位置
    PLVLinkMicEventType_SwitchView,
    /// 讲师设置连麦人权限
    PLVLinkMicEventType_TEACHER_SET_PERMISSION,
    /// 讲师主动切换PPT和播放器的位置
    PLVLinkMicEventType_changeVideoAndPPTPosition,
    /// 讲师允许某连麦人上麦
    PLVLinkMicEventType_switchJoinVoice,
};

@interface PLVLinkMicPresenter () <
PLVSocketManagerProtocol,
PLVLinkMicManagerDelegate
>

#pragma mark 状态
@property (nonatomic, assign) PLVLinkMicPresenterRoomJoinStatus rtcRoomJoinStatus;
@property (nonatomic, assign) BOOL inRTCRoom;
@property (nonatomic, assign) BOOL linkMicOpen;
@property (nonatomic, assign) PLVChannelLinkMicSceneType linkMicSceneType;
@property (nonatomic, assign) PLVLinkMicMediaType linkMicMediaType;
@property (nonatomic, assign) PLVLinkMicStatus linkMicStatus;
@property (nonatomic, assign) BOOL inLinkMic;
@property (nonatomic, assign) BOOL inProgress;
@property (nonatomic, assign) BOOL watchingNoDelay;
@property (nonatomic, assign) int originalIdleTimerDisabled; // 0 表示未记录；负值小于0 对应NO状态；正值大于0 对应YES状态；

#pragma mark 数据
@property (nonatomic, copy) NSString * linkMicSocketToken; // 当前连麦 SocketToken (不为空时重连后需发送 reJoinMic)
@property (nonatomic, strong) NSMutableArray <PLVLinkMicOnlineUser *> * onlineUserMuArray;
@property (nonatomic, copy) NSString * teacherLinkMicUserId;
@property (nonatomic, weak) PLVLinkMicOnlineUser * realMainSpeakerUser;
@property (nonatomic, weak) PLVLinkMicOnlineUser * localMainSpeakerUser;
@property (nonatomic, weak) PLVLinkMicOnlineUser * currentLocalLinkMicUser;
@property (nonatomic, copy) NSArray <PLVLinkMicOnlineUser *> * onlineUserArray; // 提供外部读取的数据数组，保存最新的用户数据
@property (nonatomic, assign) NSTimeInterval socketRefreshOpenStatusDate;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSDictionary*> * prerecordUserMediaStatusDict; // 用于提前记录用户媒体状态的字典

#pragma mark 外部数据封装
@property (nonatomic, copy, readonly) NSString * rtcType;
@property (nonatomic, copy, readonly) NSString * channelId;
@property (nonatomic, copy, readonly) NSString * sessionId;
@property (nonatomic, copy, readonly) NSString * userId;
@property (nonatomic, copy, readonly) NSString * linkMicUserId;
@property (nonatomic, copy, readonly) NSString * linkMicUserNickname;
@property (nonatomic, copy, readonly) NSString * linkMicUserAvatar;
@property (nonatomic, assign, readonly) BOOL rtcAudioSubEnabled; /// 只读，是否只订阅第一画面的视频

#pragma mark 功能对象
@property (nonatomic, strong) PLVLinkMicManager * linkMicManager; // 连麦管理器
@property (nonatomic, strong) NSTimer * linkMicTimer;
@property (nonatomic, strong) dispatch_queue_t arraySafeQueue;
@property (nonatomic, strong) dispatch_queue_t requestLinkMicOnlineListSafeQueue;
@property (nonatomic, weak) dispatch_block_t requestOnlineListBlock;
@property (nonatomic, copy) void (^addLocalUserBlock) (void); // 本地用户添加事件 (本地用户添加应该在’连麦在线列表‘请求后执行，以保证所处位置在’已进入连麦‘的观众之后)

@end

@implementation PLVLinkMicPresenter {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Period ]
- (void)dealloc{
    if (self.inRTCRoom) { [self resumeOriginalScreenOnStatus]; }
    [self stopLinkMicUserListTimer];
    [self leaveRTCChannel];
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}


#pragma mark - [ Public Methods ]
#pragma mark Getter
- (BOOL)localMainSpeakerUserByLocalOperation{
    if (!self.localMainSpeakerUser) {
        return NO;
    } else if (self.localMainSpeakerUser != self.realMainSpeakerUser){
        return YES;
    } else{
        return NO;
    }
}

#pragma mark 业务
- (void)startWatchNoDelay{
    if (!self.watchingNoDelay) {
        self.watchingNoDelay = YES;
        __weak typeof(self) weakSelf = self;
        [self updateLinkMicSceneTypeWithSuccessBlock:^{
            [weakSelf joinRTCChannel:nil];
        }];
    }else{
        NSLog(@"PLVLinkMicPresenter - startWatchNoDelay failed, watchNoDelay already 'YES'");
    }
}

- (void)stopWatchNoDelay{
    if (self.watchingNoDelay) {
        [self leaveLinkMic];
        [self leaveRTCChannel];
        self.watchingNoDelay = NO; /// 必需在最后置NO
    }
}

/// 举手
- (void)requestJoinLinkMic{
    if (self.linkMicStatus == PLVLinkMicStatus_Open) {
        __weak typeof(self) weakSelf = self;
        [self updateLinkMicSceneTypeWithSuccessBlock:^{
            [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) { /// 申请麦克风、摄像头权限
                if (granted) {
                    [weakSelf emitJoinRequest];
                } else {
                    [weakSelf callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedNoAuth];
                }
            }];
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

- (void)leaveLinkMic{
    if (self.linkMicStatus == PLVLinkMicStatus_Joining || self.linkMicStatus == PLVLinkMicStatus_Joined) {
        if (!self.watchingNoDelay) { [self resumeOriginalScreenOnStatus]; }
        [self changeLinkMicStatusAndCallback:PLVLinkMicStatus_Leaving];
        if (self.watchingNoDelay) {
            [self emitSocketMessge_JoinLeave];
        }else{
            [self leaveRTCChannel];
        }
    }else{
        NSLog(@"PLVLinkMicPresenter - leave join linkmic failed, status error, current status :%lu",(unsigned long)self.linkMicStatus);
    }
}

- (void)changeMainSpeakerInLocalWithLinkMicUserIndex:(NSInteger)nowMainSpeakerLinkMicUserIndex{
    if (nowMainSpeakerLinkMicUserIndex < self.onlineUserMuArray.count) {
        PLVLinkMicOnlineUser * nowMainSpeakerLinkMicUser = self.onlineUserMuArray[nowMainSpeakerLinkMicUserIndex];
        [self changeMainSpeakerWithLinkMicUser:nowMainSpeakerLinkMicUser byLocalOperation:YES forceSynchronLocal:NO];
    }
}

- (NSInteger)findUserModelIndexWithFiltrateBlock:(BOOL (^)(PLVLinkMicOnlineUser * _Nonnull))filtrateBlockBlock{
    NSInteger targetIndex = -1;
    for (int i = 0; i < self.onlineUserArray.count; i++) {
        PLVLinkMicOnlineUser * user = self.onlineUserArray[i];
        BOOL target = NO;
        if (filtrateBlockBlock) { target = filtrateBlockBlock(user); }
        if (target) {
            targetIndex = i;
            break;
        }
    }
    return targetIndex;
}

- (PLVLinkMicOnlineUser *)getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex{
    PLVLinkMicOnlineUser * user;
    if (targetIndex < self.onlineUserArray.count) {
        user = self.onlineUserArray[targetIndex];
    }else{
        NSLog(@"PLVLinkMicPresenter - getUserModelFromOnlineUserArrayWithIndex failed, '%ld' beyond data array",(long)targetIndex);
    }
    return user;
}

#pragma mark 设备控制
- (void)micOpen:(BOOL)open{
    int enableResult = [self.linkMicManager enableLocalAudio:open];
    int muteResult = [self.linkMicManager muteLocalAudioStream:!open];
    if (enableResult == 0 && muteResult == 0) {
        [self.currentLocalLinkMicUser updateUserCurrentMicOpen:open];
    }else{
        NSLog(@"PLVLinkMicPresenter - micOpen failed, enableResult %u, muteResult %u",enableResult,muteResult);
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


#pragma mark - [ Private Methods ]
- (void)setup{
    /// 初始化 数据
    self.inLinkMic = NO;
    self.inRTCRoom = NO;
    self.linkMicSceneType = PLVChannelLinkMicSceneType_Unknown;
    self.originalIdleTimerDisabled = 0;
    [PLVRoomDataManager sharedManager].roomData.linkMicSceneType = self.linkMicSceneType; /// 同步值

    self.onlineUserMuArray = [[NSMutableArray<PLVLinkMicOnlineUser *> alloc] init];
    self.onlineUserArray = self.onlineUserMuArray;
    self.arraySafeQueue = dispatch_queue_create("PLVLinkMicPresenterArraySafeQueue", DISPATCH_QUEUE_SERIAL);
    self.requestLinkMicOnlineListSafeQueue = dispatch_queue_create("PLVLinkMicPresenterRequestLinkMicOnlineListSafeQueue", DISPATCH_QUEUE_SERIAL);
    self.prerecordUserMediaStatusDict = [[NSMutableDictionary alloc] init];
    
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
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
}

- (void)stopLinkMicUserListTimer{
    [_linkMicTimer invalidate];
    _linkMicTimer = nil;
}

#pragma mark Setter
- (void)setLinkMicStatus:(PLVLinkMicStatus)linkMicStatus{
    _linkMicStatus = linkMicStatus;
    /// @note 为了让使用者在阅读代码时，更加“显式”地，感知到 “回调被调用”
    ///       此 Setter 方法将不再附带 “回调的调用”
    ///       而将回调调用，直接跟随在 self.linkMicStatus = linkMicStatus_xxx; 之后
}

#pragma mark Getter
- (NSString *)rtcType{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.menuInfo.rtcType;
}

- (NSString *)channelId{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.channelId;
}

- (NSString *)sessionId{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.channelInfo.sessionId;
}

- (NSString *)userId{
    return [PLVSocketManager sharedManager].viewerId;
}

- (NSString *)linkMicUserId{
    return [PLVSocketManager sharedManager].linkMicId;
}

- (NSString *)linkMicUserNickname{
    return [PLVSocketManager sharedManager].viewerName;
}

- (NSString *)linkMicUserAvatar{
    return [PLVSocketManager sharedManager].avatarUrl;
}

- (BOOL)rtcAudioSubEnabled{
    return [PLVRoomDataManager sharedManager].roomData.menuInfo.rtcAudioSubEnabled;
}

#pragma mark Callback
/// 房间加入状态发生改变
- (void)callbackForRoomJoinStatusChanged{
    BOOL currentInRTCRoom = (self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_Joined);
    BOOL inRTCRoomChanged = (self.inRTCRoom != currentInRTCRoom);
    self.inRTCRoom = currentInRTCRoom;
    
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:currentRtcRoomJoinStatus:inRTCRoomChanged:inRTCRoom:)]) {
            [self.delegate plvLinkMicPresenter:self currentRtcRoomJoinStatus:self.rtcRoomJoinStatus inRTCRoomChanged:inRTCRoomChanged inRTCRoom:self.inRTCRoom];
        }
    })
}

/// 连麦状态发生改变
- (void)callbackForLinkMicStatusChanged{
    BOOL currentInLinkMic = (self.linkMicStatus == PLVLinkMicStatus_Joined);
    BOOL inLinkMicChanged = (self.inLinkMic != currentInLinkMic);
    self.inLinkMic = currentInLinkMic;
    
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:currentLinkMicStatus:inLinkMicChanged:inLinkMic:)]) {
            [self.delegate plvLinkMicPresenter:self currentLinkMicStatus:self.linkMicStatus inLinkMicChanged:inLinkMicChanged inLinkMic:self.inLinkMic];
        }
    })
}

/// 连麦管理器的处理状态发生改变
- (void)callbackForOperationInProgress:(BOOL)inProgress{
    self.inProgress = inProgress;
    
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:operationInProgress:)]) {
            [self.delegate plvLinkMicPresenter:self operationInProgress:self.inProgress];
        }
    })
}

- (void)callbackForMediaMute:(BOOL)mute mediaType:(NSString *)mediaType linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:didMediaMuted:mediaType:linkMicUser:)]) {
            [self.delegate plvLinkMicPresenter:self didMediaMuted:mute mediaType:mediaType linkMicUser:linkMicUser];
        }
    })
}

- (void)callbackForLinkMicUserListRefresh{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:linkMicOnlineUserListRefresh:)]) {
            [self.delegate plvLinkMicPresenter:self linkMicOnlineUserListRefresh:self.onlineUserArray];
        }
    })
}

- (void)callbackForMainSpeaker:(NSString *)linkMicUserId mainSpeakerToMainScreen:(BOOL)mainSpeakerToMainScreen{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:mainSpeakerLinkMicUserId:mainSpeakerToMainScreen:)]) {
            [self.delegate plvLinkMicPresenter:self mainSpeakerLinkMicUserId:linkMicUserId mainSpeakerToMainScreen:mainSpeakerToMainScreen];
        }
    })
}

- (void)callbackForMainSpeakerChangedToLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser {
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:mainSpeakerChangedToLinkMicUser:)]) {
            [self.delegate plvLinkMicPresenter:self
                   mainSpeakerChangedToLinkMicUser:linkMicUser];
        }
    })
}

- (void)callbackForDidOccurError:(PLVLinkMicErrorCode)errorCode{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:didOccurError:extraCode:)]) {
            [self.delegate plvLinkMicPresenter:self didOccurError:errorCode extraCode:0];
        }
    })
}

- (void)callbackForDidOccurError:(PLVLinkMicErrorCode)errorCode extraCode:(NSInteger)extraCode{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:didOccurError:extraCode:)]) {
            [self.delegate plvLinkMicPresenter:self didOccurError:errorCode extraCode:extraCode];
        }
    })
}

- (void)callbackForReportAudioVolumeOfSpeakers:(NSDictionary<NSString *, NSNumber *> * _Nonnull)volumeDict{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:reportAudioVolumeOfSpeakers:)]) {
            [self.delegate plvLinkMicPresenter:self reportAudioVolumeOfSpeakers:volumeDict];
        }
    })
}

- (void)callbackForReportCurrentSpeakingUsers:(NSArray<PLVLinkMicOnlineUser *> * _Nonnull)currentSpeakingUsers{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvLinkMicPresenter:reportCurrentSpeakingUsers:)]) {
            [self.delegate plvLinkMicPresenter:self reportCurrentSpeakingUsers:currentSpeakingUsers];
        }
    })
}

#pragma mark RTC Prepare
- (void)updateLinkMicSceneTypeWithSuccessBlock:(void (^)(void))successBlock{
    if (self.linkMicSceneType != PLVChannelLinkMicSceneType_Unknown) {
        if (successBlock) { successBlock(); }
        return;
    }
    
    BOOL cloudClassLinkMicScene = ([PLVRoomDataManager sharedManager].roomData.channelType == PLVChannelTypePPT);
    self.linkMicSceneType = cloudClassLinkMicScene ? PLVChannelLinkMicSceneType_PPT_PureRtc : self.linkMicSceneType;
    [PLVRoomDataManager sharedManager].roomData.linkMicSceneType = self.linkMicSceneType; /// 同步值
    
    if (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc) {
        if (successBlock) { successBlock(); }
    } else {
        [self callbackForOperationInProgress:YES];
        __weak typeof(self) weakSelf = self;
        [PLVLiveVideoAPI rtcEnabled:[PLVRoomDataManager sharedManager].roomData.channelId.integerValue completion:^(BOOL rtcEnabled) {
            [weakSelf callbackForOperationInProgress:NO];
            if (rtcEnabled) {
                weakSelf.linkMicSceneType = PLVChannelLinkMicSceneType_Alone_PureRtc;
            } else {
                weakSelf.linkMicSceneType = PLVChannelLinkMicSceneType_Alone_PartRtc;
            }
            [PLVRoomDataManager sharedManager].roomData.linkMicSceneType = weakSelf.linkMicSceneType; /// 同步值

            if (successBlock) { successBlock(); }
        } failure:^(NSError *error) {
            [weakSelf callbackForOperationInProgress:NO];
            NSLog(@"PLVLinkMicPresenter - request rtcEnabled failed, error: %@", error);
            [weakSelf callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedRtcEnabledGetFail];
        }];
    }
}

- (PLVLinkMicManager *)createLinkMicManager{
    if (![PLVFdUtil checkStringUseable:self.rtcType]) {
        NSLog(@"PLVLinkMicPresenter - linkMicManager create failed, rtcType illegal %@",self.rtcType);
        [self callbackForOperationInProgress:NO];
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

- (void)setScreenAlwaysOn{
    plv_dispatch_main_async_safe(^{
        if (![UIApplication sharedApplication].idleTimerDisabled) {
            self.originalIdleTimerDisabled = -1;
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        }
    });
}

- (void)resumeOriginalScreenOnStatus{
    if (self.originalIdleTimerDisabled != 0) {
        plv_dispatch_main_async_safe(^{
            [UIApplication sharedApplication].idleTimerDisabled = self.originalIdleTimerDisabled < 0 ? NO : YES;
            self.originalIdleTimerDisabled = 0;
        });
    }
}

#pragma mark Join RTC Room
/// 加入RTC频道
- (void)joinRTCChannel:(void(^)(int resultCode))completion{
    [self changeRoomJoinStatusAndCallback:PLVLinkMicPresenterRoomJoinStatus_Joining];
    
    if ([self createLinkMicManager]) {
        PLVLinkMicGetTokenModel * getTokenModel = [[PLVLinkMicGetTokenModel alloc]init];
        getTokenModel.channelId = self.channelId;
        getTokenModel.userId = self.linkMicUserId;
        getTokenModel.channelType = [PLVRoomDataManager sharedManager].roomData.channelType;
        getTokenModel.viewerId = self.userId;
        getTokenModel.nickname = self.linkMicUserNickname;
        getTokenModel.sessionId = self.sessionId;

        PLVRoomUser * currentUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
        PLVRoomUserType currentUserViewerType = currentUser.viewerType;
        if (currentUserViewerType == PLVRoomUserTypeSlice || currentUserViewerType == PLVRoomUserTypeStudent) {
            getTokenModel.userType = @"audience";
        }
        __weak typeof(self) weakSelf = self;
        [self callbackForOperationInProgress:YES];
        [self.linkMicManager updateLinkMicTokenWith:getTokenModel completion:^(BOOL updateResult) {
            [weakSelf callbackForOperationInProgress:NO];
            if (updateResult) {
                [weakSelf callbackForOperationInProgress:YES];
                int res = [weakSelf.linkMicManager joinRtcChannelWithChannelId:weakSelf.channelId userLinkMicId:weakSelf.linkMicUserId];
                if(res != 0){
                    [weakSelf changeRoomJoinStatusAndCallback:PLVLinkMicPresenterRoomJoinStatus_NotJoin];
                    [weakSelf callbackForDidOccurError:PLVLinkMicErrorCode_JoinChannelFailed extraCode:res];
                }
                if (completion) { completion(res); }
            }else{
                [weakSelf changeRoomJoinStatusAndCallback:PLVLinkMicPresenterRoomJoinStatus_NotJoin];
                [weakSelf callbackForDidOccurError:PLVLinkMicErrorCode_RequestJoinFailedNoToken];
                if (completion) {
                    completion(-3); /// -3返回值表示更新Token失败
                }
            }
        }];
    }else{
        [self changeRoomJoinStatusAndCallback:PLVLinkMicPresenterRoomJoinStatus_NotJoin];

        NSLog(@"PLVLinkMicPresenter - joinRTCChannel failed, manager create failed");
        if (completion) {
            completion(-2); /// -2返回值表示连麦管理器创建失败
        }
    }
}

/// 离开RTC频道
- (void)leaveRTCChannel{
    if (self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_Joined ||
        self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_Joining) {
        [self changeRoomJoinStatusAndCallback:PLVLinkMicPresenterRoomJoinStatus_Leaving];
        [self callbackForOperationInProgress:YES];
        plv_dispatch_main_async_safe(^{
            [self.linkMicManager leaveRtcChannel]; /// 注意勿使用 weakSelf
        })
    }else{
        // NSLog(@"PLVLinkMicPresenter - leaveRTCChannel failed %lu",(unsigned long)self.rtcRoomJoinStatus);
    }
}

#pragma mark LinkMic
- (void)emitJoinRequest{
    if ([self createLinkMicManager]) {
        [self emitSocketMessge_JoinRequest];
    }
}

- (void)changeRoomJoinStatusAndCallback:(PLVLinkMicPresenterRoomJoinStatus)toRoomJoinStatus{
    BOOL roomJoinStatusChanged = (self.rtcRoomJoinStatus != toRoomJoinStatus);
    self.rtcRoomJoinStatus = toRoomJoinStatus;
    if (roomJoinStatusChanged) { [self callbackForRoomJoinStatusChanged]; }
}

- (void)changeLinkMicStatusAndCallback:(PLVLinkMicStatus)toLinkMicStatus{
    BOOL linkMicStatusChanged = (self.linkMicStatus != toLinkMicStatus);
    self.linkMicStatus = toLinkMicStatus;
    if (linkMicStatusChanged) { [self callbackForLinkMicStatusChanged]; }
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
            [self changeLinkMicStatusAndCallback:PLVLinkMicStatus_Open];
        }else{  // 讲师 结束 连麦功能
            self.linkMicOpen = NO;
            
            if (self.linkMicStatus == PLVLinkMicStatus_Joined || self.linkMicStatus == PLVLinkMicStatus_Joining) {
                [self callbackForOperationInProgress:YES];
                [self leaveLinkMic];
            }
            self.linkMicMediaType = PLVLinkMicMediaType_Unknown;
            [self changeLinkMicStatusAndCallback:PLVLinkMicStatus_NotOpen];
        }
    }
}

- (void)muteUser:(NSString *)linkMicUserId mediaType:(NSString *)mediaType mute:(BOOL)mute{
    __weak typeof(self) weakSelf = self;
    [self findLinkMicOnlineUserWithLinkMicUserId:linkMicUserId completionBlock:^(PLVLinkMicOnlineUser *resultUser) {
        if (resultUser) {
            if ([weakSelf.linkMicUserId isEqualToString:linkMicUserId]) {
                // 目标用户 是 本地用户
                plv_dispatch_main_async_safe(^{
                    if ([@"video" isEqualToString:mediaType]) {
                        [weakSelf cameraOpen:!mute];
                    }else{
                        [weakSelf micOpen:!mute];
                    }
                })
            }else{
                // 目标用户 是 远端用户
                if ([@"video" isEqualToString:mediaType]) {
                    [resultUser updateUserCurrentCameraOpen:!mute];
                }else{
                    [resultUser updateUserCurrentMicOpen:!mute];
                }
            }
            [weakSelf callbackForMediaMute:mute mediaType:mediaType linkMicUser:resultUser];
        } else {
            [weakSelf prerecordWithLinkMicUserId:linkMicUserId mediaType:mediaType muteStatus:mute];
        }
    }];
}

- (BOOL)readPrerecordWithLinkMicUserId:(NSString *)linkMicUserId mediaType:(NSString *)mediaType defaultMuteStatus:(BOOL)status{
    BOOL resultStatus = status;
    if ([PLVFdUtil checkStringUseable:linkMicUserId] && [PLVFdUtil checkStringUseable:mediaType]) {
        NSDictionary * lastMediaStatusDict = [self.prerecordUserMediaStatusDict objectForKey:linkMicUserId];
        if ([PLVFdUtil checkDictionaryUseable:lastMediaStatusDict]) {
            NSNumber * mediaStatusNumber = [lastMediaStatusDict objectForKey:mediaType];
            if (mediaStatusNumber && [mediaStatusNumber isKindOfClass:NSNumber.class]) {
                resultStatus = mediaStatusNumber.boolValue;
            }
        }
    }
    return resultStatus;
}

- (void)prerecordWithLinkMicUserId:(NSString *)linkMicUserId mediaType:(NSString *)mediaType muteStatus:(BOOL)mute{
    if ([PLVFdUtil checkStringUseable:linkMicUserId] && [PLVFdUtil checkStringUseable:mediaType]) {
        NSDictionary * lastMediaStatusDict = [self.prerecordUserMediaStatusDict objectForKey:linkMicUserId];
        NSMutableDictionary * updateMediaStatusDict;
        if ([PLVFdUtil checkDictionaryUseable:lastMediaStatusDict]) {
            updateMediaStatusDict = [[NSMutableDictionary alloc] initWithDictionary:lastMediaStatusDict];
        } else {
            updateMediaStatusDict = [[NSMutableDictionary alloc] init];
        }
        [updateMediaStatusDict setObject:@(mute) forKey:mediaType];
        [self.prerecordUserMediaStatusDict setObject:updateMediaStatusDict forKey:linkMicUserId];
    }
}

- (void)removePrerecordWithLinkMicUserId:(NSString *)linkMicUserId{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        [self.prerecordUserMediaStatusDict removeObjectForKey:linkMicUserId];
    }
}

- (void)linkMicUserJoined:(NSString *)linkMicUserId retryCount:(NSInteger)retryCount{
    if (self.requestLinkMicOnlineListSafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.requestLinkMicOnlineListSafeQueue, ^{
            if (weakSelf.requestOnlineListBlock) {
                dispatch_block_cancel(weakSelf.requestOnlineListBlock);
            }
            dispatch_block_t requestBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
                [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:weakSelf.channelId.integerValue sessionId:weakSelf.sessionId completion:^(NSDictionary *dict) {
                    if (weakSelf.arraySafeQueue) {
                        dispatch_async(weakSelf.arraySafeQueue, ^{
                            BOOL includeTargetLinkMicUser = [weakSelf refreshLinkMicOnlineUserListWithDataDictionary:dict targetLinkMicUserId:linkMicUserId];
                            
                            /**
                             若此次请求回来的连麦在线列表，不包含Rtc回调的新增用户，则启动重试逻辑。
                             重试过程中，每次重试的延时，递增 2 秒，尽量确保接口数据更新。
                             若重试过程中，有新连麦人加入，则本次重试中断，以新连麦人的请求为准。
                             */
                            if (!includeTargetLinkMicUser && retryCount < 3) {
                                [weakSelf linkMicUserJoined:linkMicUserId retryCount:retryCount + 1];
                            }
                        });
                    }
                } failure:^(NSError *error) {
                    NSLog(@"PLVLinkMicPresenter - request link mic online list failed, error:%@",error);
                }];
            });
            weakSelf.requestOnlineListBlock = requestBlock;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1 + 2 * retryCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), weakSelf.requestOnlineListBlock);
        });
    }
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
        if (self.arraySafeQueue) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(self.arraySafeQueue, ^{
                NSArray <NSString *> * userIdArray = [weakSelf.onlineUserMuArray valueForKeyPath:@"linkMicUserId"];
                if (![userIdArray containsObject:user.linkMicUserId]) {
                    if (user.isRealMainSpeaker) {
                        /// 更新 真实主讲
                        [weakSelf changeMainSpeakerWithLinkMicUser:user byLocalOperation:NO forceSynchronLocal:NO];
                        if (!weakSelf.localMainSpeakerUserByLocalOperation) {
                            [weakSelf.onlineUserMuArray insertObject:user atIndex:0];
                        } else {
                            [weakSelf.onlineUserMuArray addObject:user];
                        }
                    }else{
                        [weakSelf.onlineUserMuArray addObject:user];
                    }
                    
                    if (!user.rtcRendered) {
                        PLVBRTCSubscribeStreamMediaType mediaType = PLVBRTCSubscribeStreamMediaType_Audio | PLVBRTCSubscribeStreamMediaType_Video;
                        if (weakSelf.rtcAudioSubEnabled && !user.isRealMainSpeaker) { mediaType = PLVBRTCSubscribeStreamMediaType_Audio; }
                        
                        NSString * linkmicUserId = user.linkMicUserId;
                        plv_dispatch_main_async_safe(^{
                            UIView * rtcView = user.rtcView;
                            if (!rtcView.superview) {
                                [weakSelf.preRenderContainer insertSubview:rtcView atIndex:0];
                            }
                            [weakSelf.linkMicManager subscribeStreamWithRTCUserId:linkmicUserId renderOnView:rtcView mediaType:mediaType];
                        })
                    }
                    
                    if (user.localUser) {
                        weakSelf.currentLocalLinkMicUser = user;
                        /// 设置初始值
                        [user updateUserCurrentMicOpen:weakSelf.micDefaultOpen];
                        [user updateUserCurrentCameraOpen:weakSelf.cameraDefaultOpen];
                    }else{
                        BOOL micOpen = ![weakSelf readPrerecordWithLinkMicUserId:user.linkMicUserId mediaType:@"audio" defaultMuteStatus:NO];
                        BOOL cameraOpen = ![weakSelf readPrerecordWithLinkMicUserId:user.linkMicUserId mediaType:@"video" defaultMuteStatus:NO];
                        
                        /// 设置初始值
                        [user updateUserCurrentMicOpen:micOpen];
                        [user updateUserCurrentCameraOpen:cameraOpen];
                        
                        [weakSelf removePrerecordWithLinkMicUserId:user.linkMicUserId];
                        [weakSelf removePrerecordWithLinkMicUserId:user.linkMicUserId];
                    }
                    
                    //[weakSelf sortOnlineUserList];
                    weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
                    [weakSelf callbackForLinkMicUserListRefresh];
                }else{
                    if (user.isRealMainSpeaker) {
                        [weakSelf changeMainSpeakerWithLinkMicUserId:user.linkMicUserId byLocalOperation:NO forceSynchronLocal:NO];
                    }
                    //NSLog(@"POLYVTEST - 重复加入 %@ %@",user.linkMicUserId,user.nickname);
                }
            });
        }
    }
}

- (void)removeUserFromOnlineUserList:(NSString *)linkMicUserId{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        if (self.arraySafeQueue) {
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
                
                if (![user.linkMicUserId isEqualToString:weakSelf.teacherLinkMicUserId]) {
                    NSString * nextMainSpeakerLinkMicUserId;
                    if (user.isRealMainSpeaker) {
                        nextMainSpeakerLinkMicUserId = weakSelf.teacherLinkMicUserId;
                    } else if (user.isLocalMainSpeaker){
                        nextMainSpeakerLinkMicUserId = weakSelf.realMainSpeakerUser.linkMicUserId;
                    }
                    if ([PLVFdUtil checkStringUseable:nextMainSpeakerLinkMicUserId]) {
                        [weakSelf changeMainSpeakerWithLinkMicUserId:nextMainSpeakerLinkMicUserId byLocalOperation:NO forceSynchronLocal:NO];
                    }
                }
                
                if (index >= 0 && index < weakSelf.onlineUserMuArray.count && user != nil) {
                    [weakSelf.linkMicManager unsubscribeStreamWithRTCUserId:linkMicUserId];
                    
                    [weakSelf.onlineUserMuArray removeObject:user];
                    weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
                    [weakSelf callbackForLinkMicUserListRefresh];
                }else{
                    NSLog(@"PLVLinkMicPresenter - remove link mic user(%@) failed, index(%d) not in the array",linkMicUserId,index);
                }
            });
        }
    }
}

- (void)resetOnlineUserList{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            [weakSelf.onlineUserMuArray removeAllObjects];
            weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
            [weakSelf callbackForLinkMicUserListRefresh];
        });
    }
}

- (void)changeMainSpeakerWithLinkMicUserId:(NSString *)nowMainSpeakerLinkMicUserId byLocalOperation:(BOOL)byLocalOperation forceSynchronLocal:(BOOL)forceSynchronLocal{
    if ([PLVFdUtil checkStringUseable:nowMainSpeakerLinkMicUserId]) {
        if (![self.localMainSpeakerUser.linkMicUserId isEqualToString:nowMainSpeakerLinkMicUserId] ||
            (!byLocalOperation && ![self.realMainSpeakerUser.linkMicUserId isEqualToString:nowMainSpeakerLinkMicUserId])) {
            __weak typeof(self) weakSelf = self;
            [self findLinkMicOnlineUserWithLinkMicUserId:nowMainSpeakerLinkMicUserId completionBlock:^(PLVLinkMicOnlineUser *resultUser) {
                [weakSelf changeMainSpeakerWithLinkMicUser:resultUser byLocalOperation:byLocalOperation forceSynchronLocal:forceSynchronLocal];
            }];
        }
    }
}

/// 改变 “主讲”
///
/// @note 该方法会判断是否需要同步至 “本地主讲”
///
/// @param nowMainSpeakerUser 当前要成为 “主讲” 的用户
/// @param byLocalOperation 是否本地操作
/// @param forceSynchronLocal 是否强制同步至 “本地主讲” (仅在非本地操作时 会使用此值；若 forceSynchronLocal 为 YES 代表不管 “本地操作变更”)
- (void)changeMainSpeakerWithLinkMicUser:(PLVLinkMicOnlineUser *)nowMainSpeakerUser byLocalOperation:(BOOL)byLocalOperation forceSynchronLocal:(BOOL)forceSynchronLocal{
    if (byLocalOperation) {
        [self changeLocalMainSpeakerWithLinkMicUser:nowMainSpeakerUser];
    } else {
        [self changeRealMainSpeakerWithLinkMicUser:nowMainSpeakerUser forceSynchronLocal:forceSynchronLocal];
    }
}

- (void)changeLocalMainSpeakerWithLinkMicUser:(PLVLinkMicOnlineUser *)nowLocalMainSpeakerUser{
    if (self.localMainSpeakerUser != nowLocalMainSpeakerUser) {
        // “本地主讲” 发生变更
        self.localMainSpeakerUser.isLocalMainSpeaker = NO;
        self.localMainSpeakerUser = nowLocalMainSpeakerUser;
        self.localMainSpeakerUser.isLocalMainSpeaker = YES;
        self.localMainSpeakerUser.isRealMainSpeaker = (self.localMainSpeakerUser == self.realMainSpeakerUser);
        
        // “真实主讲” 更新值
        self.realMainSpeakerUser.isLocalMainSpeaker = (self.localMainSpeakerUser == self.realMainSpeakerUser);
        
        // “本地主讲” 移至第一位
        [self linkMicUserBecomeFirstSiteInArray:nowLocalMainSpeakerUser];
    }
}

- (void)changeRealMainSpeakerWithLinkMicUser:(PLVLinkMicOnlineUser *)nowRealMainSpeakerUser forceSynchronLocal:(BOOL)forceSynchronLocal{
    if (self.realMainSpeakerUser != nowRealMainSpeakerUser) {
        // “真实主讲” 发生变更
        BOOL needSwitchSubscribeStreamMediaType = (self.rtcAudioSubEnabled && ![nowRealMainSpeakerUser.linkMicUserId isEqualToString:self.realMainSpeakerUser.linkMicUserId]);
        self.realMainSpeakerUser.isRealMainSpeaker = NO;
        if (needSwitchSubscribeStreamMediaType) {
            [self.linkMicManager switchSubscribeStreamMediaTypeWithRTCUserId:self.realMainSpeakerUser.linkMicUserId mediaType:PLVBRTCSubscribeStreamMediaType_Audio];
        }
        self.realMainSpeakerUser = nowRealMainSpeakerUser;
        self.realMainSpeakerUser.isRealMainSpeaker = YES;
        if (needSwitchSubscribeStreamMediaType) {
            [self.linkMicManager switchSubscribeStreamMediaTypeWithRTCUserId:self.realMainSpeakerUser.linkMicUserId mediaType:PLVBRTCSubscribeStreamMediaType_Audio | PLVBRTCSubscribeStreamMediaType_Video];
        }
        
        // ”本地主讲“ 更新值
        self.localMainSpeakerUser.isRealMainSpeaker = (self.localMainSpeakerUser == self.realMainSpeakerUser);
        
        if (!self.localMainSpeakerUserByLocalOperation || forceSynchronLocal) {
            // 若没有 本地操作变更过 或 需要强制同步，则同步更新 “本地主讲”
            [self changeLocalMainSpeakerWithLinkMicUser:nowRealMainSpeakerUser];
        }
    }
}

- (void)linkMicUserBecomeFirstSiteInArray:(PLVLinkMicOnlineUser *)linkMicUser{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            if ([weakSelf.onlineUserMuArray containsObject:linkMicUser]) {
                NSInteger targetUserIndex = [weakSelf.onlineUserMuArray indexOfObject:linkMicUser];
                if (targetUserIndex < weakSelf.onlineUserMuArray.count) {
                    if (targetUserIndex > 0) {
                        [weakSelf.onlineUserMuArray exchangeObjectAtIndex:targetUserIndex withObjectAtIndex:0];
                        weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
                        [weakSelf callbackForLinkMicUserListRefresh];
                    }
                } else {
                    NSLog(@"PLVLinkMicPresenter - linkMicUserBecomeFirstSiteInArray failed, index(%ld) beyond bounds for empty array",(long)targetUserIndex);
                }
            }
        });
    }
}

- (void)findLinkMicOnlineUserWithLinkMicUserId:(NSString *)linkMicUserId
                                                 completionBlock:(void(^)(PLVLinkMicOnlineUser * resultUser))completionBlock{
    [self findLinkMicOnlineUserWithJudgeBlock:^BOOL(PLVLinkMicOnlineUser *user) {
        if ([user.linkMicUserId isEqualToString:linkMicUserId]) {
            return YES;
        }
        return NO;
    } completionBlock:completionBlock];
}

- (void)findLinkMicOnlineUserWithJudgeBlock:(BOOL(^)(PLVLinkMicOnlineUser * user))judgeBlock
                            completionBlock:(void(^)(PLVLinkMicOnlineUser * resultUser))completionBlock{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            PLVLinkMicOnlineUser * user;
            for (int i = 0; i < weakSelf.onlineUserMuArray.count; i++) {
                user = weakSelf.onlineUserMuArray[i];
                BOOL target = NO;
                if (judgeBlock) { target = judgeBlock(user); }
                if (target) {
                    break;
                }else{
                    user = nil;
                }
            }
            if (completionBlock) { completionBlock(user); }
        });
    }
}

/// 解析‘连麦用户列表数据’ 并 刷新用户数组
- (BOOL)refreshLinkMicOnlineUserListWithDataDictionary:(NSDictionary *)dataDictionary targetLinkMicUserId:(NSString *)targetLinkMicUserId{
    if (self.rtcRoomJoinStatus != PLVLinkMicPresenterRoomJoinStatus_Joined) {
        return NO;
    }
    
    BOOL includeTargetLinkMicUser = NO;
    
    // 检查数组是否合法
    NSArray * linkMicUserList = dataDictionary[@"joinList"];
    if (![PLVFdUtil checkArrayUseable:linkMicUserList]) {
        return includeTargetLinkMicUser;
    }
    
    // 读取当前主讲人
    NSString * master = dataDictionary[@"master"];
    if (![PLVFdUtil checkStringUseable:master] && !self.localMainSpeakerUserByLocalOperation) {
        // 若 master 为空
        master = self.channelId;
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
                [self leaveLinkMic];
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
        
        // 更新讲师连麦Id
        if (![PLVFdUtil checkStringUseable:self.teacherLinkMicUserId] && onlineUser.userType == PLVLinkMicOnlineUserType_Teacher && [PLVFdUtil checkStringUseable:onlineUser.linkMicUserId]) {
            self.teacherLinkMicUserId = onlineUser.linkMicUserId;
        }
        
        // 若是本地用户，则不作解析
        if ([onlineUser.linkMicUserId isEqualToString:self.linkMicUserId]) {
            return includeTargetLinkMicUser;
        }
        
        // 判断是否包含目标新增连麦人
        if ([onlineUser.linkMicUserId isEqualToString:targetLinkMicUserId]) {
            includeTargetLinkMicUser = YES;
        }
        
        // 设置主讲人标记
        if ([master isEqualToString:onlineUser.linkMicUserId]) {
            onlineUser.isRealMainSpeaker = YES;
        }
        
        // 添加用户
        [self addUserIntoOnlineUserList:onlineUser];
        
        if (self.addLocalUserBlock) {
            self.addLocalUserBlock();
            self.addLocalUserBlock = nil;
        }
    }
    return includeTargetLinkMicUser;
}

- (void)updateLinkMicUserVolumeWithVolumeDictionary:(NSDictionary<NSString *,NSNumber *> *)volumeDict{
    if (self.arraySafeQueue) {
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
                [weakSelf changeLinkMicStatusAndCallback:PLVLinkMicStatus_Waiting];
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
                    [weakSelf changeLinkMicStatusAndCallback:PLVLinkMicStatus_Joined];

                    [weakSelf addLocalUserIntoOnlineUserList];
                }else{
                    NSLog(@"PLVLinkMicPresenter - 'joinSuccess' ackArray decode failed, error:%@",error);
                }
            }
        }
    } failedErrorCode:PLVLinkMicErrorCode_JoinChannelFailedSocketCannotSend];
}

- (void)emitSocketMessge_JoinLeave{
    // 重置处理
    [self removeUserFromOnlineUserList:self.currentLocalLinkMicUser.linkMicUserId];
    self.currentLocalLinkMicUser = nil;
    self.linkMicSocketToken = nil;

    [self changeLinkMicStatusAndCallback:(self.linkMicOpen ? PLVLinkMicStatus_Open : PLVLinkMicStatus_NotOpen)];
    
    __weak typeof(self) weakSelf = self;
    [weakSelf callbackForOperationInProgress:YES];
    [self emitSocketMessageEventType:@"joinLeave" callback:^(NSArray *ackArray) {
        [weakSelf callbackForOperationInProgress:NO];
    } failedErrorCode:PLVLinkMicErrorCode_LeaveChannelFailedSocketCannotSend];
}

- (void)emitSocketMessageEventType:(NSString *)eventType callback:(void (^)(NSArray * _Nonnull))callback failedErrorCode:(PLVLinkMicErrorCode)failedErrorCode{
    if ([PLVSocketManager sharedManager].login &&
        [PLVSocketManager sharedManager].status == PLVSocketConnectStatusConnected) {
        NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
        NSString *roomId = [PLVSocketManager sharedManager].roomId; // 此处不可使用频道号，因存在分房间的可能
        PLVBSocketUserType bUserType = (PLVBSocketUserType)[PLVSocketManager sharedManager].userType;
        NSString *userTypeString = [PLVBSocketUser userTypeStringWithUserType:bUserType english:YES];
        if (![PLVFdUtil checkStringUseable:userTypeString]) {
            userTypeString = [PLVSocketManager sharedManager].userType == PLVSocketUserTypeStudent ? @"student" : @"slice";
        }
        jsonDict[@"roomId"]  = [NSString stringWithFormat:@"%@",roomId];
        jsonDict[@"user"]    = @{@"nick" : [NSString stringWithFormat:@"%@",self.linkMicUserNickname],
                                 @"pic" : [NSString stringWithFormat:@"%@",self.linkMicUserAvatar],
                                 @"userId" : [NSString stringWithFormat:@"%@",self.linkMicUserId],
                                 @"userType" : userTypeString};
        if ([eventType isEqualToString:@"joinLeave"] && [PLVFdUtil checkStringUseable:self.linkMicSocketToken]) {
            jsonDict[@"token"] = self.linkMicSocketToken;
        }
        
        [[PLVSocketManager sharedManager] emitEvent:eventType content:jsonDict timeout:5.0 callback:^(NSArray *ackArray) {
            callback(ackArray);
        }];
    }else{
        [self callbackForOperationInProgress:NO];
        [self callbackForDidOccurError:failedErrorCode];
        NSLog(@"PLVLinkMicPresenter - link mic msg send failed, current status:%lu",(unsigned long)[PLVSocketManager sharedManager].status);
    }
}

- (void)emitSocketMessge_reJoinMic{
    if ([PLVFdUtil checkStringUseable:self.linkMicSocketToken]) {
        [[PLVSocketManager sharedManager] emitEvent:@"reJoinMic" content:self.linkMicSocketToken timeout:5.0 callback:^(NSArray *ackArray) {
        }];
    }else{
        NSLog(@"PLVLinkMicPresenter - reJoinMic msg send failed, linkMicSocketToken illegal %@",self.linkMicSocketToken);
    }
}

- (void)handleSocketEvent:(PLVLinkMicEventType)eventType jsonDict:(NSDictionary *)jsonDict {
    switch (eventType) {
        // 讲师信息
        case PLVLinkMicEventType_TEACHER_INFO: {
            NSString *teacherId = (NSString *)jsonDict[@"data"][@"userId"];
            // 更新讲师连麦Id
            if (![PLVFdUtil checkStringUseable:self.teacherLinkMicUserId] && [PLVFdUtil checkStringUseable:teacherId]) {
                self.teacherLinkMicUserId = teacherId;
            }
        } break;
            
        // 讲师发起或结束连麦功能；讲师单独挂断学生连麦（广播消息 broadcast）
        case PLVLinkMicEventType_OPEN_MICROPHONE: {
            NSString *teacherId = jsonDict[@"teacherId"];
            if (teacherId) { /// 讲师发起或结束连麦功能
                // 更新讲师连麦Id
                if (![PLVFdUtil checkStringUseable:self.teacherLinkMicUserId] && [PLVFdUtil checkStringUseable:teacherId]) {
                    self.teacherLinkMicUserId = teacherId;
                }
                
                self.socketRefreshOpenStatusDate = [NSDate date].timeIntervalSince1970;
                [self refreshLinkMicOpenStatus:jsonDict[@"status"] mediaType:jsonDict[@"type"]];
            } else if ([jsonDict[@"userId"] isEqualToString:self.linkMicUserId]) {  /// 讲师单独挂断学生连麦
                [self callbackForOperationInProgress:YES];
                [self leaveLinkMic];
            }
        } break;
            
        // 讲师同意学生连麦（单播消息 unicast）
        case PLVLinkMicEventType_JOIN_RESPONSE: {
            if (self.linkMicStatus == PLVLinkMicStatus_Waiting) {
                if (self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_NotJoin) { /// 未加入RTC频道
                    [self changeLinkMicStatusAndCallback:PLVLinkMicStatus_Joining];

                    __weak typeof(self) weakSelf = self;
                    [self joinRTCChannel:^(int resultCode) {
                        if (resultCode == 0) {
                            [PLVLiveVideoAPI requestViewerIdLinkMicIdRelate:[NSString stringWithFormat:@"%@",weakSelf.channelId] viewerId:weakSelf.userId linkMicId:weakSelf.linkMicUserId completion:nil failure:^(NSError * _Nonnull error) {
                                NSLog(@"PLVLinkMicPresenter - id relate failed %@",error);
                            }];
                        } else {
                            /// 重置连麦状态
                            [weakSelf changeLinkMicStatusAndCallback:(weakSelf.linkMicOpen ? PLVLinkMicStatus_Open : PLVLinkMicStatus_NotOpen)];
                        }
                    }];
                }else if (self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_Joined){ /// 已加入RTC频道
                    [self changeLinkMicStatusAndCallback:PLVLinkMicStatus_Joining];

                    [PLVLiveVideoAPI requestViewerIdLinkMicIdRelate:[NSString stringWithFormat:@"%@",self.channelId] viewerId:self.userId linkMicId:self.linkMicUserId completion:nil failure:^(NSError * _Nonnull error) {
                        NSLog(@"PLVLinkMicPresenter - id relate failed %@",error);
                    }];
                    
                    [self emitSocketMessge_JoinSuccess];
                }else { /// 其他状态
                    NSLog(@"PLVLinkMicPresenter - will not join rtc channel, rtcRoomJoinStatus illegal, current status:%lu",(unsigned long)self.rtcRoomJoinStatus);
                }
            }else{
                NSLog(@"PLVLinkMicPresenter - will not join rtc channel, not in waiting status, current status:%lu",(unsigned long)self.linkMicStatus);
                [self callbackForDidOccurError:PLVLinkMicErrorCode_JoinChannelFailedStatusIllegal];
                [self leaveLinkMic];
            }
        } break;
            
        // 讲师允许某连麦人上麦（非观众类型的角色，在讲师允许后，才会上麦）
        case PLVLinkMicEventType_switchJoinVoice: {
        } break;
    
        // 讲师打开或关闭，你的摄像头或麦克风（单播消息 unicast）
        case PLVLinkMicEventType_MuteUserMedia: {
            BOOL mute = ((NSNumber *)jsonDict[@"mute"]).boolValue;
            [self muteUser:self.linkMicUserId mediaType:jsonDict[@"type"] mute:mute];
        } break;
            
        // 讲师让某位连麦人成为’主讲‘，即第一画面
        case PLVLinkMicEventType_SwitchView: {
            NSString * nowMainSpeakerLinkMicUserId = [NSString stringWithFormat:@"%@",jsonDict[@"userId"]];
            [self changeMainSpeakerWithLinkMicUserId:nowMainSpeakerLinkMicUserId byLocalOperation:NO forceSynchronLocal:YES];
        } break;
            
        // 讲师设置连麦人权限
        case PLVLinkMicEventType_TEACHER_SET_PERMISSION: {
        } break;
        
        // 讲师主动切换PPT和播放器的位置（非连麦中，是否应该处理此事件）
        // TODO：此事件不应归于“linkMic”模块
        case PLVLinkMicEventType_changeVideoAndPPTPosition: {
            BOOL mainSpeakerToMainScreen = ((NSNumber *)jsonDict[@"status"]).boolValue;
            [self callbackForMainSpeaker:self.localMainSpeakerUser.linkMicUserId mainSpeakerToMainScreen:mainSpeakerToMainScreen];
        } break;
            
        default:
            break;
    }
}


#pragma mark - [ Event ]
#pragma mark Timer
- (void)linkMicTimerEvent:(NSTimer *)timer{
    /// Socket 断开时不作刷新请求，因连麦业务基本均依赖于 Scoket 服务
    if ([PLVSocketManager sharedManager].login) {
        __weak typeof(self) weakSelf = self;

        // 请求，刷新‘讲师端连麦开启状态’
        [PLVLiveVideoAPI requestLinkMicStatusWithRoomId:self.channelId.integerValue completion:^(NSString *status, NSString *type) {
            if ([NSDate date].timeIntervalSince1970 - self.socketRefreshOpenStatusDate > 10) {
                [weakSelf refreshLinkMicOpenStatus:status mediaType:type];
            }
        } failure:^(NSError *error) {
            NSLog(@"PLVLinkMicPresenter - request linkmic status failed : %@",error);
        }];
        
        if (self.linkMicStatus == PLVLinkMicStatus_Joined ||
            self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_Joined) {
            // 请求，刷新‘连麦在线用户列表’
            [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:self.channelId.integerValue sessionId:self.sessionId completion:^(NSDictionary *dict) {
                if (weakSelf.arraySafeQueue) {
                    dispatch_async(weakSelf.arraySafeQueue, ^{
                        [weakSelf refreshLinkMicOnlineUserListWithDataDictionary:dict targetLinkMicUserId:nil];
                    });
                }
            } failure:^(NSError *error) {
                NSLog(@"PLVLinkMicPresenter - request linkmic online user list failed : %@",error);
            }];
        }
    }else{
        NSLog(@"PLVLinkMicPresenter - link mic status refresh failed, current socket status:%lu",(unsigned long)[PLVSocketManager sharedManager].status);
    }
}


#pragma mark - [ Delegate ]
#pragma mark PLVSocketManagerProtocol
/// socket 接收到 "message" 事件
- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([subEvent isEqualToString:@"OPEN_MICROPHONE"]) {
        [self handleSocketEvent:PLVLinkMicEventType_OPEN_MICROPHONE jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"O_TEACHER_INFO"]) {
        [self handleSocketEvent:PLVLinkMicEventType_TEACHER_INFO jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"TEACHER_SET_PERMISSION"]) {
        [self handleSocketEvent:PLVLinkMicEventType_TEACHER_SET_PERMISSION jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"changeVideoAndPPTPosition"]) {
        [self handleSocketEvent:PLVLinkMicEventType_changeVideoAndPPTPosition jsonDict:jsonDict];
    } else if ([subEvent isEqualToString:@"switchJoinVoice"]) {
        [self handleSocketEvent:PLVLinkMicEventType_switchJoinVoice jsonDict:jsonDict];
    } else if ([subEvent containsString:@"SEND_CUP"]) {   // 奖杯事件

    } else if ([subEvent containsString:@"LOGIN"]){ // 登录事件
        NSString * loginUserId = (NSString *)jsonDict[@"user"][@"userId"];
        if ([PLVFdUtil checkStringUseable:self.linkMicSocketToken] && [PLVFdUtil checkStringUseable:loginUserId] && [loginUserId isEqualToString:self.userId]) {
            // 连麦Token不为空，需发送 reJoinMic 进行重连
            [self emitSocketMessge_reJoinMic];
        }
    } else if ([subEvent containsString:@"finishClass"]){ // 下课事件
        if (self.watchingNoDelay) {
            [self resumeOriginalScreenOnStatus];
            [self stopWatchNoDelay];
        }
    }
}

/// socket 接收到 "主动监听" 事件（不包含 "message" 事件）
- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([event isEqualToString:PLVSocketIOLinkMic_JOIN_REQUEST_key]) {
        [self handleSocketEvent:PLVLinkMicEventType_JOIN_REQUEST jsonDict:jsonDict];
    } else if ([event isEqualToString:PLVSocketIOLinkMic_JOIN_RESPONSE_key]) {
        [self handleSocketEvent:PLVLinkMicEventType_JOIN_RESPONSE jsonDict:jsonDict];
    } else if ([event isEqualToString:PLVSocketIOLinkMic_JOIN_SUCCESS_key]) {
        [self handleSocketEvent:PLVLinkMicEventType_JOIN_SUCCESS jsonDict:jsonDict];
    } else if ([event isEqualToString:PLVSocketIOLinkMic_JOIN_LEAVE_key]) {
        [self handleSocketEvent:PLVLinkMicEventType_JOIN_LEAVE jsonDict:jsonDict];
    } else if ([event isEqualToString:PLVSocketLinkMicEventType_MuteUserMedia_key]) {
        [self handleSocketEvent:PLVLinkMicEventType_MuteUserMedia jsonDict:jsonDict];
    } else if ([event isEqualToString:PLVSocketLinkMicEventType_SwitchView_key]) {
        [self handleSocketEvent:PLVLinkMicEventType_SwitchView jsonDict:jsonDict];
    }
}

#pragma mark PLVLinkMicManagerDelegate
- (void)plvLinkMicManager:(PLVLinkMicManager *)manager joinRTCChannelComplete:(NSString *)channelID uid:(NSString *)uid{
    [self callbackForOperationInProgress:NO];
    [self changeRoomJoinStatusAndCallback:PLVLinkMicPresenterRoomJoinStatus_Joined];
    
    if (self.linkMicStatus == PLVLinkMicStatus_Joining) {
        [self emitSocketMessge_JoinSuccess];
    }
    
    /// 允许2秒内外部模块作最终的“常亮”配置
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf setScreenAlwaysOn];
    });
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager leaveRTCChannelComplete:(NSString * _Nonnull)channelID{
    [self callbackForOperationInProgress:NO];
    [self changeRoomJoinStatusAndCallback:PLVLinkMicPresenterRoomJoinStatus_NotJoin];
    
    BOOL linkMicInNotWatchNoDelay = (!self.watchingNoDelay && (self.linkMicStatus == PLVLinkMicStatus_Leaving));
    if (linkMicInNotWatchNoDelay) {
        [self emitSocketMessge_JoinLeave];
    }
    
    [self resetOnlineUserList];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didOccurError:(NSInteger)errorCode{
    [self callbackForDidOccurError:PLVLinkMicErrorCode_JoinedOccurError extraCode:errorCode];
    if (self.linkMicStatus == PLVLinkMicStatus_Waiting) {
        [self cancelRequestJoinLinkMic];
    }else if (self.linkMicStatus == PLVLinkMicStatus_Joining || self.linkMicStatus == PLVLinkMicStatus_Joined){
        [self leaveLinkMic];
    }
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didJoinedOfUid:(NSString *)uid{
    if (self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_Joined) {
        [self linkMicUserJoined:uid retryCount:0];
    }
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didOfflineOfUid:(NSString *)uid{
    if (self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_Joined) {
        [self removeUserFromOnlineUserList:uid];
    }
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didAudioMuted:(BOOL)muted byUid:(NSString *)uid{
    [self muteUser:uid mediaType:@"audio" mute:muted];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didVideoMuted:(BOOL)muted byUid:(NSString *)uid{
    [self muteUser:uid mediaType:@"video" mute:muted];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager remoteUserTotalStreamsDidLeaveRoom:(NSString *)uid{
    if (self.rtcRoomJoinStatus == PLVLinkMicPresenterRoomJoinStatus_Joined) {
        [self removeUserFromOnlineUserList:uid];
    }
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager reportAudioVolumeOfSpeakers:(NSDictionary<NSString *,NSNumber *> *)volumeDict{
    [self updateLinkMicUserVolumeWithVolumeDictionary:volumeDict];
    [self callbackForReportAudioVolumeOfSpeakers:volumeDict];
}

@end
