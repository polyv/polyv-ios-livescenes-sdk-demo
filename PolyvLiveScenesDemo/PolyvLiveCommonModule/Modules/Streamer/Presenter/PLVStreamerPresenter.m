//
//  PLVStreamerPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVStreamerPresenter.h"

#import "PLVRoomDataManager.h"

static NSString *const PLVStreamerPresenter_DictValue_GuestAllowed = @"allowed";
static NSString *const PLVStreamerPresenter_DictValue_GuestAllowedWithRaiseHand = @"allowedWithRaiseHand";
static NSString *const PLVStreamerPresenter_DictValue_GuestJoined = @"joined";

@interface PLVStreamerPresenter ()<
PLVSocketManagerProtocol,
PLVRTCStreamerManagerDelegate
>

#pragma mark 状态
@property (nonatomic, assign) PLVStreamerPresenterRoomJoinStatus rtcRoomJoinStatus;
@property (nonatomic, assign) BOOL inRTCRoom;
@property (nonatomic, assign) BOOL inProgress;
@property (nonatomic, assign) BOOL classStarted;
@property (nonatomic, assign) BOOL originalIdleTimerDisabled;
@property (nonatomic, assign) BOOL micCameraGranted;

#pragma mark 数据
@property (nonatomic, copy) NSString * sessionId;
@property (nonatomic, strong) NSMutableArray <PLVLinkMicWaitUser *> * waitUserMuArray;
@property (nonatomic, strong) NSMutableArray <PLVLinkMicOnlineUser *> * onlineUserMuArray;
@property (nonatomic, weak) PLVLinkMicOnlineUser * realMainSpeakerUser;  // 注意: 弱引用
@property (nonatomic, weak) PLVLinkMicOnlineUser * localMainSpeakerUser; // 注意: 弱引用
@property (nonatomic, weak) PLVLinkMicOnlineUser * localOnlineUser; // 注意: 弱引用
@property (nonatomic, copy) NSArray <PLVLinkMicWaitUser *> * waitUserArray; // 提供外部读取的数据数组，保存最新的用户数据
@property (nonatomic, copy) NSArray <PLVLinkMicOnlineUser *> * onlineUserArray; // 提供外部读取的数据数组，保存最新的用户数据
@property (nonatomic, strong) NSMutableDictionary <NSString *,NSString *> * guestAllowLinkMicDict; // 嘉宾允许上麦状态记录字典 (value:@"allowed"-讲师已允许；value:@"allowedWithRaiseHand"-讲师已允许嘉宾已举手；value:@"joined"-嘉宾已上麦；其他情况视为讲师未同意)

#pragma mark 外部数据封装
@property (nonatomic, copy, readonly) NSString * stream;
@property (nonatomic, copy, readonly) NSString * rtmpUrl; /// 推流地址
@property (nonatomic, copy, readonly) NSString * rtcType;
@property (nonatomic, copy, readonly) NSString * channelId;
@property (nonatomic, copy, readonly) NSString * userId;
@property (nonatomic, copy, readonly) NSString * linkMicUserId;
@property (nonatomic, copy, readonly) NSString * linkMicUserNickname;
@property (nonatomic, copy, readonly) NSString * linkMicUserAvatar;
@property (nonatomic, assign, readonly) BOOL channelGuestManualJoinLinkMic;

#pragma mark 功能对象
@property (nonatomic, strong) PLVRTCStreamerManager * rtcStreamerManager;
@property (nonatomic, strong) NSTimer * linkMicTimer;
@property (nonatomic, strong) dispatch_queue_t arraySafeQueue;
@property (nonatomic, strong) dispatch_queue_t requestLinkMicOnlineListSafeQueue;
@property (nonatomic, weak) dispatch_block_t requestOnlineListBlock;
@property (nonatomic, copy) void (^startPushStreamSuccessBlock) (void);

@end

@implementation PLVStreamerPresenter{
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Period ]
- (void)dealloc{
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
- (void)setupStreamQuality:(PLVBLinkMicStreamQuality)streamQuality{
    [self.rtcStreamerManager setupStreamQuality:streamQuality];
}

- (void)joinRTCChannel{
    if (!self.rtcStreamerManager.hadJoinedRTC) {
        __weak typeof(self) weakSelf = self;
        [self prepareStreamerManagerWithCompletion:^{
            [weakSelf changeRoomJoinStatusAndCallback:PLVStreamerPresenterRoomJoinStatus_Joining];
            [weakSelf.rtcStreamerManager joinRTCChannel];
        }];
    }
}

- (void)leaveRTCChannel{
    [self.rtcStreamerManager leaveRTCChannel];
}

- (void)prepareLocalPreviewCompletion:(void (^)(BOOL))completion{
    __weak typeof(self) weakSelf = self;
    [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) { /// 申请麦克风、摄像头权限
        weakSelf.micCameraGranted = granted;
        if (granted) {
            if (weakSelf.previewType == PLVStreamerPresenterPreviewType_UserArray) {
                /// 用户数组 预览类型
                /// 需要提前 创建本地在线用户，并加入 RTC房间已在线 用户数组
                PLVLinkMicOnlineUser * localOnlineUser = [weakSelf createLocalOnlineUser];
                [self addOnlineUserIntoOnlineUserArray:localOnlineUser completion:^(BOOL added) {
                    if (completion) { plv_dispatch_main_async_safe(^{ completion(added); }) }
                }];
            }else{
                if (completion) { plv_dispatch_main_async_safe(^{ completion(YES); }) }
            }
        } else {
            UIViewController * currentVC = [PLVFdUtil getCurrentViewController];
            NSString * msg = [NSString stringWithFormat:@"需要获取您的音视频权限，请前往设置"];
            [PLVAuthorizationManager showAlertWithTitle:@"提示" message:msg viewController:currentVC];
            if (completion) { plv_dispatch_main_async_safe(^{ completion(NO); }) }
        }
    }];
}

- (void)setupLocalPreviewWithCanvaView:(UIView *)canvasView{
    if (self.previewType == PLVStreamerPresenterPreviewType_UserArray) {
        /// 用户数组 预览类型
        /// 以本地用户的rtcView，作为预览载体，并忽略传参视图
        canvasView = self.localOnlineUser.rtcView;
    }else{
        /// 未知类型 或 独立视图 预览类型
        /// 以传参视图，作为预览载体
    }
    
    if (canvasView && [canvasView isKindOfClass:UIView.class]) {
        __weak typeof(self) weakSelf = self;
        [self prepareStreamerManagerWithCompletion:^{
            if (!weakSelf.rtcStreamerManager.currentLocalPreviewCanvasModel) {
                PLVBRTCVideoViewCanvasModel * model = [[PLVBRTCVideoViewCanvasModel alloc]init];
                model.userRTCId = weakSelf.linkMicUserId;
                model.renderCanvasView = canvasView;
                model.rtcVideoVideoFillMode = PLVBRTCVideoViewFillMode_Fill;
                [weakSelf.rtcStreamerManager setupLocalPreviewWithCanvasModel:model];
            }
        }];
    }else{
        NSLog(@"PLVRTCStreamerPresenter - startLocalPreviewWithCanvaView failed, canvasView illegal %@",canvasView);
    }
}

- (void)startPushStream{
    if (self.micCameraGranted) {
        if (!self.pushStreamStarted) {
            [self.rtcStreamerManager startPushStreamWithStream:self.stream rtmpUrl:self.rtmpUrl];
        }else{
            NSLog(@"PLVRTCStreamerPresenter - startPushStream failed, stream had started push");
        }
    }else{
        NSLog(@"PLVRTCStreamerPresenter - startPushStream failed, mic Camera not be granted");
    }
}

- (void)stopPushStream{
    [self.rtcStreamerManager stopPushStream];
}

#pragma mark 课程事件管理
- (void)startClass{
    if (!self.classStarted) {
        __weak typeof(self) weakSelf = self;
        self.startPushStreamSuccessBlock = ^{
            [weakSelf startClassEmitCompleteBlock:nil];
        };
        
        [self startPushStream];
    }else{
        NSLog(@"PLVRTCStreamerPresenter - startClass failed, class had started");
    }
}

- (void)finishClass{
    [self stopPushStream];
    [self resetOnlineUserList];
    [self resetWaitUserList];
    [self closeLinkMicEmitCompleteBlock:nil];
    [self finishClassEmitCompleteBlock:nil];
    [self requestForLiveStatusEnd];
}

#pragma mark 本地硬件管理
- (void)openLocalUserMic:(BOOL)openMic{
    [self.rtcStreamerManager openLocalUserMic:openMic];
    [self.localOnlineUser updateUserCurrentMicOpen:openMic];
}

- (void)openLocalUserCamera:(BOOL)openCamera{
    [self.rtcStreamerManager openLocalUserCamera:openCamera completion:nil];
    [self.localOnlineUser updateUserCurrentCameraOpen:openCamera];
}

- (void)switchLocalUserCamera:(BOOL)frontCamera{
    [self.rtcStreamerManager switchLocalUserCamera:frontCamera];
    [self.localOnlineUser updateUserCurrentCameraFront:frontCamera];
}

- (void)switchLocalUserFrontCamera{
    BOOL frontCamera = !self.localOnlineUser.currentCameraFront;
    [self.rtcStreamerManager switchLocalUserCamera:frontCamera];
    [self.localOnlineUser updateUserCurrentCameraFront:frontCamera];
}

#pragma mark 连麦事件管理
/// 开启或关闭 ”视频连麦“
- (void)openVideoLinkMic:(BOOL)open emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    [self.rtcStreamerManager openVideoLinkMic:open emitCompleteBlock:emitCompleteBlock];
    if (!open) {
        [self removeOnlineUserButGuest];
        [self removeWaitUserButGuest];
    }
}

/// 开启或关闭 ”音频连麦“
- (void)openAudioLinkMic:(BOOL)open emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    [self.rtcStreamerManager openAudioLinkMic:open emitCompleteBlock:emitCompleteBlock];
    if (!open) {
        [self removeOnlineUserButGuest];
        [self removeWaitUserButGuest];
    }
}

/// 关闭 “连麦功能”
- (void)closeLinkMicEmitCompleteBlock:(void (^)(BOOL))emitCompleteBlock{
    [self.rtcStreamerManager closeLinkMicEmitCompleteBlock:emitCompleteBlock];
    [self removeOnlineUserButGuest];
    [self removeWaitUserButGuest];
}

/// 允许 某位远端用户 上麦
- (void)allowRemoteUserJoinLinkMic:(PLVLinkMicWaitUser *)waitUser emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    NSString * waitUserRtcId = waitUser.linkMicUserId;
    BOOL guestWaitUser = waitUser.userType == PLVSocketUserTypeGuest;
    BOOL currentRaiseHand = waitUser.currentRaiseHand;
    __weak typeof(self) weakSelf = self;
    [self.rtcStreamerManager allowRemoteUserJoinLinkMic:waitUser.originalUserDict raiseHand:currentRaiseHand emitCompleteBlock:^(BOOL emitSuccess) {
        if (emitSuccess) {
            if (guestWaitUser && [PLVFdUtil checkStringUseable:waitUserRtcId]) {
                if (weakSelf.arraySafeQueue) {
                    dispatch_async(weakSelf.arraySafeQueue, ^{
                        if (currentRaiseHand) {
                            [weakSelf updateGuestToAllowedLinkMicWithRaiseHand:waitUserRtcId];
                        }else{
                            [weakSelf updateGuestToAllowedLinkMic:waitUserRtcId];
                        }
                    });
                }
            }
        }
        if (emitCompleteBlock) { emitCompleteBlock(emitSuccess); }
    }];
}

/// 开启或关闭 某位远端用户 的麦克风
- (void)muteRemoteUserMic:(PLVLinkMicOnlineUser *)onlineUser muteMic:(BOOL)muteMic emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    [self.rtcStreamerManager muteRemoteUserMic:onlineUser.originalUserDict muteMic:muteMic emitCompleteBlock:emitCompleteBlock];
}

/// 开启或关闭 某位远端用户的 摄像头
- (void)muteRemoteUserCamera:(PLVLinkMicOnlineUser *)onlineUser muteCamera:(BOOL)muteCamera emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    [self.rtcStreamerManager muteRemoteUserCamera:onlineUser.originalUserDict muteCamera:muteCamera emitCompleteBlock:emitCompleteBlock];
}

/// 挂断某位远端用户的连麦
- (void)closeRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    __weak typeof(self) weakSelf = self;
    [self.rtcStreamerManager closeRemoteUserLinkMic:onlineUser.originalUserDict emitCompleteBlock:^(BOOL emitSuccess) {
        if (emitCompleteBlock) { emitCompleteBlock(emitSuccess); }
        [weakSelf callbackForDidCloseRemoteUserLinkMic:onlineUser];
    }];
}

/// 挂断全部连麦用户
- (void)closeAllLinkMicUser{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            PLVLinkMicOnlineUser * user;
            for (int i = 0; i < weakSelf.onlineUserMuArray.count; i++) {
                user = weakSelf.onlineUserMuArray[i];
                if (![user.linkMicUserId isEqualToString:self.linkMicUserId]) {
                    [weakSelf closeRemoteUserLinkMic:user emitCompleteBlock:nil];
                }
            }
        });
    }
}

/// 静音全部连麦用户的麦克风
- (void)muteAllLinkMicUserMic:(BOOL)muteAllMic{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            PLVLinkMicOnlineUser * user;
            for (int i = 0; i < weakSelf.onlineUserMuArray.count; i++) {
                user = weakSelf.onlineUserMuArray[i];
                if (![user.linkMicUserId isEqualToString:self.linkMicUserId]) {
                    [weakSelf muteRemoteUserMic:user muteMic:muteAllMic emitCompleteBlock:nil];
                }
            }
        });
    }
}

#pragma mark 连麦用户管理
- (NSInteger)findOnlineUserModelIndexWithFiltrateBlock:(BOOL (^)(PLVLinkMicOnlineUser * _Nonnull))filtrateBlockBlock{
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

- (PLVLinkMicOnlineUser *)getOnlineUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex{
    PLVLinkMicOnlineUser * user;
    if (targetIndex < self.onlineUserArray.count) {
        user = self.onlineUserArray[targetIndex];
    }else{
        NSLog(@"PLVStreamerPresenter - getUserModelFromOnlineUserArrayWithIndex failed, '%ld' beyond data array",(long)targetIndex);
    }
    return user;
}

- (NSInteger)findWaitUserModelIndexWithFiltrateBlock:(BOOL (^)(PLVLinkMicWaitUser * _Nonnull waitUser))filtrateBlockBlock{
    NSInteger targetIndex = -1;
    for (int i = 0; i < self.waitUserArray.count; i++) {
        PLVLinkMicWaitUser * user = self.waitUserArray[i];
        BOOL target = NO;
        if (filtrateBlockBlock) { target = filtrateBlockBlock(user); }
        if (target) {
            targetIndex = i;
            break;
        }
    }
    return targetIndex;
}

- (PLVLinkMicWaitUser *)getWaitUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex{
    PLVLinkMicWaitUser * user;
    if (targetIndex < self.waitUserArray.count) {
        user = self.waitUserArray[targetIndex];
    }else{
        NSLog(@"PLVStreamerPresenter - getWaitUserModelFromOnlineUserArrayWithIndex failed, '%ld' beyond data array",(long)targetIndex);
    }
    return user;
}

#pragma mark Setter
- (void)setMicDefaultOpen:(BOOL)micDefaultOpen{
    self.rtcStreamerManager.micDefaultOpen = micDefaultOpen;
}

- (void)setCameraDefaultOpen:(BOOL)cameraDefaultOpen{
    self.rtcStreamerManager.cameraDefaultOpen = cameraDefaultOpen;
}

- (void)setCameraDefaultFront:(BOOL)cameraDefaultFront{
    self.rtcStreamerManager.cameraDefaultFront = cameraDefaultFront;
}

#pragma mark Getter
- (BOOL)micDefaultOpen{
    return self.rtcStreamerManager.micDefaultOpen;
}

- (BOOL)cameraDefaultOpen{
    return self.rtcStreamerManager.cameraDefaultOpen;
}

- (BOOL)cameraDefaultFront{
    return self.rtcStreamerManager.cameraDefaultFront;
}

- (NSString *)sessionId{
    return self.rtcStreamerManager.sessionId;
}

- (NSTimeInterval)startPushStreamTimestamp{
    return self.rtcStreamerManager.startPushStreamTimestamp;
}

- (NSTimeInterval)pushStreamValidDuration{
    return self.rtcStreamerManager.pushStreamValidDuration;
}

- (NSTimeInterval)pushStreamTotalDuration{
    return self.rtcStreamerManager.pushStreamTotalDuration;
}

- (NSTimeInterval)reconnectingDuration{
    return self.rtcStreamerManager.reconnectingDuration;
}

- (BOOL)pushStreamStarted{
    return self.rtcStreamerManager.pushStreamStarted;
}

- (PLVBLinkMicNetworkQuality)networkQuality{
    return self.rtcStreamerManager.networkQuality;
}

- (BOOL)currentMicOpen{
    return self.localOnlineUser.currentMicOpen;
}

- (BOOL)currentCameraOpen{
    return self.localOnlineUser.currentCameraOpen;
}

- (BOOL)currentCameraShouldShow{
    return self.localOnlineUser.currentCameraShouldShow;
}

- (BOOL)currentCameraFront{
    return self.localOnlineUser.currentCameraFront;
}

- (BOOL)channelLinkMicOpen{
    return self.rtcStreamerManager.channelLinkMicOpen;
}

- (PLVChannelLinkMicSceneType)channelLinkMicMediaType{
    return self.rtcStreamerManager.channelLinkMicMediaType;
}

- (PLVBLinkMicStreamQuality)streamQuality{
    return self.rtcStreamerManager.streamQuality;
}

#pragma mark - [ Private Methods ]
- (void)setup{
    /// 初始化 数据
    self.waitUserMuArray = [[NSMutableArray<PLVLinkMicWaitUser *> alloc] init];
    self.onlineUserMuArray = [[NSMutableArray<PLVLinkMicOnlineUser *> alloc] init];
    self.guestAllowLinkMicDict = [[NSMutableDictionary <NSString *,NSString *> alloc] init];
    self.arraySafeQueue = dispatch_queue_create("PLVRTCStreamerPresenterArraySafeQueue", DISPATCH_QUEUE_SERIAL);
    self.requestLinkMicOnlineListSafeQueue = dispatch_queue_create("PLVRTCStreamerPresenterRequestLinkMicOnlineListSafeQueue", DISPATCH_QUEUE_SERIAL);

    /// 创建 获取连麦在线用户列表 定时器
    self.linkMicTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(linkMicTimerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.linkMicTimer forMode:NSRunLoopCommonModes];
    [self.linkMicTimer fire];
    
    /// 添加 socket 事件监听
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    /// 创建 推流管理器
    [self createRtcStreamerManager];
}

- (void)stopLinkMicUserListTimer{
    [_linkMicTimer invalidate];
    _linkMicTimer = nil;
}

- (void)setupScreenAlwaysOn{
    __weak typeof(self) weakSelf = self;
    plv_dispatch_main_async_safe(^{
        weakSelf.originalIdleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    });
}

- (void)resumeOriginalScreenOnStatus{
    __weak typeof(self) weakSelf = self;
    plv_dispatch_main_async_safe(^{
        [UIApplication sharedApplication].idleTimerDisabled = weakSelf.originalIdleTimerDisabled;
    });
}

- (void)changeRoomJoinStatusAndCallback:(PLVStreamerPresenterRoomJoinStatus)toRoomJoinStatus{
    BOOL roomJoinStatusChanged = (self.rtcRoomJoinStatus != toRoomJoinStatus);
    self.rtcRoomJoinStatus = toRoomJoinStatus;
    if (roomJoinStatusChanged) { [self callbackForRoomJoinStatusChanged]; }
}

/// 开始上课
- (void)startClassEmitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    NSMutableDictionary * jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"EVENT"] = @"onSliceStart";
    
    NSDictionary * documentCurrentInfo = [self callbackForGetDocumentCurrentInfoDict];
    if ([PLVFdUtil checkDictionaryUseable:documentCurrentInfo]) {
        jsonDict[@"isNoCount"] = documentCurrentInfo[@"isNoCount"] ? documentCurrentInfo[@"isNoCount"] : @(0);
        jsonDict[@"docType"] = documentCurrentInfo[@"docType"] ? documentCurrentInfo[@"docType"] : @(1);
        jsonDict[@"version"] = documentCurrentInfo[@"version"] ? documentCurrentInfo[@"version"] : @"";
        jsonDict[@"data"] = documentCurrentInfo[@"data"] ? documentCurrentInfo[@"data"] : @{};
    }
    
    jsonDict[@"sessionId"] = [NSString stringWithFormat:@"%@",self.sessionId];
    jsonDict[@"roomId"] = [NSString stringWithFormat:@"%@",self.channelId];
    jsonDict[@"userId"] = [NSString stringWithFormat:@"%@",self.channelId];
    jsonDict[@"streamName"] = [NSString stringWithFormat:@"%@",self.stream];
    jsonDict[@"pushtime"] = @(self.startPushStreamTimestamp);
    jsonDict[@"timeStamp"] = @(self.pushStreamValidDuration);

    __weak typeof(self) weakSelf = self;
    [[PLVSocketManager sharedManager] emitMessage:jsonDict timeout:5.0 callback:^(NSArray * _Nonnull ackArray) {
        if ([PLVFdUtil checkArrayUseable:ackArray]) {
            weakSelf.classStarted = YES;
            [weakSelf callbackForClassStartedDidChanged:jsonDict];
            if (emitCompleteBlock) { emitCompleteBlock(YES); }
        }else{
            NSLog(@"PLVRTCStreamerPresenter - startClass failed, ackArray illegal:%@",ackArray);
            if (emitCompleteBlock) { emitCompleteBlock(NO); }
        }
    }];
}

/// 结束上课
- (void)finishClassEmitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    NSMutableDictionary * jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"EVENT"] = @"finishClass";
    
    __weak typeof(self) weakSelf = self;
    [[PLVSocketManager sharedManager] emitMessage:jsonDict timeout:5.0 callback:^(NSArray * _Nonnull ackArray) {
        if ([PLVFdUtil checkArrayUseable:ackArray]) {
            weakSelf.classStarted = NO;
            [weakSelf callbackForClassStartedDidChanged:nil];
            if (emitCompleteBlock) { emitCompleteBlock(YES); }
        }else{
            NSLog(@"PLVRTCStreamerPresenter - finishClass failed, ackArray illegal:%@",ackArray);
            if (emitCompleteBlock) { emitCompleteBlock(NO); }
        }
    }];
}

#pragma mark Net Request
/// 更新频道直播状态至结束
- (void)requestForLiveStatusEnd{
    [PLVLiveVideoAPI requestChannelLivestatusEndWithChannelId:self.channelId stream:self.stream success:^(NSString * _Nonnull responseCont) {
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"PLVRTCStreamerPresenter - requestForLiveStatusEnd failed, error %@",error);
    }];
}

#pragma mark Prepare Streamer
- (void)prepareStreamerManagerWithCompletion:(void (^)(void))completion{
    if (!self.rtcStreamerManager.rtcTokenAvailable) {
        [self updateRTCTokenWithCompletion:^(BOOL updateResult) {
            if (updateResult) {
                if (completion) {completion(); }
            }
        }];
    }else{
        if (completion) {completion(); }
    }
}

- (PLVRTCStreamerManager *)createRtcStreamerManager{
    if (_rtcStreamerManager == nil) {
        if (![PLVFdUtil checkStringUseable:self.rtcType]) {
            NSLog(@"PLVRTCStreamerPresenter - rtcStreamerManager create failed, rtcType illegal %@",self.rtcType);
            return nil;
        }
        
        _rtcStreamerManager = [PLVRTCStreamerManager rtcStreamerManagerWithRTCType:self.rtcType channelId:self.channelId];
        _rtcStreamerManager.delegate = self;
    }
    return _rtcStreamerManager;
}

- (void)updateRTCTokenWithCompletion:(void (^)(BOOL updateResult))completion{ /// 考虑这个方法放进SDK层
    PLVLinkMicGetTokenModel * getTokenModel = [[PLVLinkMicGetTokenModel alloc]init];
    getTokenModel.channelId = self.channelId;
    getTokenModel.userId = self.linkMicUserId;
    getTokenModel.channelType = [PLVRoomDataManager sharedManager].roomData.channelType;
    getTokenModel.viewerId = self.channelId;
    getTokenModel.nickname = self.linkMicUserNickname;
    getTokenModel.sessionId = self.sessionId;

    PLVRoomUser * currentUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVRoomUserType currentUserViewerType = currentUser.viewerType;
    if (currentUserViewerType == PLVRoomUserTypeSlice || currentUserViewerType == PLVRoomUserTypeStudent) {
        getTokenModel.userType = @"audience";
    }else if(currentUserViewerType == PLVRoomUserTypeTeacher){
        getTokenModel.userType = @"teacher";
    }
    __weak typeof(self) weakSelf = self;
    [self callbackForOperationInProgress:YES];
    [self.rtcStreamerManager updateRTCTokenWith:getTokenModel completion:^(BOOL updateResult) {
        [weakSelf callbackForOperationInProgress:NO];
        if (updateResult) {
            [weakSelf callbackForOperationInProgress:YES];
        }else{

        }
        if (completion) {
            completion(updateResult);
        }
    }];
}

#pragma mark Link Mic
- (void)muteUser:(NSString *)linkMicUserId mediaType:(NSString *)mediaType mute:(BOOL)mute{
    __weak typeof(self) weakSelf = self;
    [self findLinkMicOnlineUserWithLinkMicUserId:linkMicUserId completionBlock:^(PLVLinkMicOnlineUser *resultUser) {
        if (resultUser) {
            if ([weakSelf.linkMicUserId isEqualToString:linkMicUserId]) {
                // 目标用户 是 本地用户
                plv_dispatch_main_async_safe(^{
                    if ([@"video" isEqualToString:mediaType]) {
                        [weakSelf openLocalUserCamera:!mute];
                    }else{
                        [weakSelf openLocalUserMic:!mute];
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
            //[weakSelf prerecordWithLinkMicUserId:linkMicUserId mediaType:mediaType muteStatus:mute];
        }
    }];
}

#pragma mark LinkMic User Manage
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

#pragma mark Guest User Manage
- (void)changeGuestWaitUserRaiseHandState:(NSString *)linkMicUserId raiseHand:(BOOL)raiseHand{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            for (int i = 0; i < weakSelf.waitUserArray.count; i++) {
                PLVLinkMicWaitUser * user = weakSelf.waitUserArray[i];
                if ([user.linkMicUserId isEqualToString:linkMicUserId]) {
                    [user updateUserCurrentRaiseHand:raiseHand];
                    break;
                }
            }
        });
    }
}

- (void)changeGuestWaitUserAnswerAgreeJoin:(NSString *)linkMicUserId answerAgreeJoin:(BOOL)answerAgreeJoin{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            for (int i = 0; i < weakSelf.waitUserArray.count; i++) {
                PLVLinkMicWaitUser * user = weakSelf.waitUserArray[i];
                if ([user.linkMicUserId isEqualToString:linkMicUserId]) {
                    [user updateUserCurrentAnswerAgreeJoin:answerAgreeJoin];
                    break;
                }
            }
        });
    }
}

- (void)updateGuestToAllowedLinkMic:(NSString *)guestLinkMicUserId{
    if ([PLVFdUtil checkStringUseable:guestLinkMicUserId]) {
        [self.guestAllowLinkMicDict setObject:PLVStreamerPresenter_DictValue_GuestAllowed forKey:guestLinkMicUserId];
    }
}

- (BOOL)checkGuestAllowedLinkMic:(NSString *)guestLinkMicUserId{
    NSString * value = [self.guestAllowLinkMicDict objectForKey:guestLinkMicUserId];
    return [value isEqualToString:PLVStreamerPresenter_DictValue_GuestAllowed];
}

- (void)updateGuestToAllowedLinkMicWithRaiseHand:(NSString *)guestLinkMicUserId{
    if ([PLVFdUtil checkStringUseable:guestLinkMicUserId]) {
        [self.guestAllowLinkMicDict setObject:PLVStreamerPresenter_DictValue_GuestAllowedWithRaiseHand forKey:guestLinkMicUserId];
    }
}

- (BOOL)checkGuestAllowedLinkMicWithRaiseHand:(NSString *)guestLinkMicUserId{
    NSString * value = [self.guestAllowLinkMicDict objectForKey:guestLinkMicUserId];
    return [value isEqualToString:PLVStreamerPresenter_DictValue_GuestAllowedWithRaiseHand];
}

- (void)updateGuestToJoinedLinkMic:(NSString *)guestLinkMicUserId{
    if ([PLVFdUtil checkStringUseable:guestLinkMicUserId]) {
        [self.guestAllowLinkMicDict setObject:PLVStreamerPresenter_DictValue_GuestJoined forKey:guestLinkMicUserId];
    }
}

- (BOOL)checkGuestJoinedLinkMic:(NSString *)guestLinkMicUserId{
    NSString * value = [self.guestAllowLinkMicDict objectForKey:guestLinkMicUserId];
    return [value isEqualToString:PLVStreamerPresenter_DictValue_GuestJoined];
}

#pragma mark LinkMic OnlineUser Manage
- (PLVLinkMicOnlineUser *)createLocalOnlineUser{
    PLVLinkMicOnlineUser * localOnlineUser;
    if (!_localOnlineUser) {
        localOnlineUser = [PLVLinkMicOnlineUser localUserModelWithUserId:self.userId linkMicUserId:self.linkMicUserId nickname:self.linkMicUserNickname avatarPic:self.linkMicUserAvatar userType:PLVSocketUserTypeTeacher];
        _localOnlineUser = localOnlineUser;
        
        /// 监听 本地用户 事件Block
        __weak typeof(self) weakSelf = self;
        localOnlineUser.wantOpenMicBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantOpen) {
            [weakSelf openLocalUserMic:wantOpen];
        };
        
        localOnlineUser.wantOpenCameraBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantOpen) {
            [weakSelf openLocalUserCamera:wantOpen];
        };
        
        localOnlineUser.wantSwitchFrontCameraBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantFront) {
            [weakSelf switchLocalUserCamera:wantFront];
        };
        
        /// 监听 本地用户 状态变化Block
        [localOnlineUser addMicOpenChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            [weakSelf callbackForLocalUserMicOpenChanged];
        } blockKey:self];
        
        [localOnlineUser addCameraShouldShowChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            [weakSelf callbackForLocalUserCameraShouldShowChanged];
        } blockKey:self];
        
        [localOnlineUser addCameraFrontChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            [weakSelf callbackForLocalUserCameraFrontChanged];
        } blockKey:self];
        
        /// 设置默认值
        [localOnlineUser updateUserCurrentMicOpen:self.micDefaultOpen];
        [localOnlineUser updateUserCurrentCameraOpen:self.cameraDefaultOpen];
        [localOnlineUser updateUserCurrentCameraFront:self.cameraDefaultFront];
    }else{
        NSLog(@"PLVRTCStreamerPresenter - createLocalOnlineUser failed, localOnlineUser exist %p",_localOnlineUser);
    }
    return localOnlineUser;
}

- (void)addOnlineUserIntoOnlineUserArray:(PLVLinkMicOnlineUser *)onlineUser completion:(nullable void (^)(BOOL added))completion{
    if (onlineUser && [onlineUser isKindOfClass:PLVLinkMicOnlineUser.class]) {
        if (self.arraySafeQueue) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(self.arraySafeQueue, ^{
                NSArray <NSString *> * userIdArray = [weakSelf.onlineUserMuArray valueForKeyPath:@"linkMicUserId"];
                if (![userIdArray containsObject:onlineUser.linkMicUserId]) {
                    /// 从 其他数组中 清理
                    [weakSelf removeLinkMicWaitUser:onlineUser.linkMicUserId completion:nil];
                    
                    /// 往 onlineUser 数组中添加
                    [weakSelf.onlineUserMuArray addObject:onlineUser];
                    [weakSelf updateGuestToJoinedLinkMic:onlineUser.linkMicUserId];
                    
                    if (!onlineUser.rtcRendered) {
                        PLVBRTCSubscribeStreamMediaType mediaType = PLVBRTCSubscribeStreamMediaType_Audio | PLVBRTCSubscribeStreamMediaType_Video;
                        
                        NSString * linkmicUserId = onlineUser.linkMicUserId;
                        plv_dispatch_main_async_safe(^{
                            UIView * rtcView = onlineUser.rtcView;
                            if (!rtcView.superview) {
                                [weakSelf.preRenderContainer insertSubview:rtcView atIndex:0];
                            }
                            [weakSelf.rtcStreamerManager subscribeStreamWithRTCUserId:linkmicUserId renderOnView:rtcView mediaType:mediaType];
                        })
                    }
                    
                    if (!onlineUser.localUser) {
                        /// 设置初始值
                        [onlineUser updateUserCurrentMicOpen:YES];
                        [onlineUser updateUserCurrentCameraOpen:YES];
                    }
                    
                    weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
                    [weakSelf callbackForLinkMicUserListRefresh];
                    
                    if (completion) {
                        plv_dispatch_main_async_safe(^{ completion(YES); })
                    }
                }else{
                    /// 重复加入
                    if (completion) { plv_dispatch_main_async_safe(^{ completion(NO); }) }
                }
            });
        }else{
            if (completion) { plv_dispatch_main_async_safe(^{ completion(NO); }) }
        }
    }else{
        if (completion) { plv_dispatch_main_async_safe(^{ completion(NO); }) }
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

- (void)removeLinkMicOnlineUser:(NSString *)linkMicUserId{
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
                
                if (index >= 0 && index < weakSelf.onlineUserMuArray.count && user != nil) {
                    [weakSelf.rtcStreamerManager unsubscribeStreamWithRTCUserId:linkMicUserId];
                    
                    [weakSelf.guestAllowLinkMicDict removeObjectForKey:linkMicUserId];
                    [weakSelf.onlineUserMuArray removeObject:user];
                    weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
                    [weakSelf callbackForLinkMicUserListRefresh];
                }else{
                    NSLog(@"PLVStreamerPresenter - remove link mic user(%@) failed, index(%d) not in the array",linkMicUserId,index);
                }
            });
        }
    }
}

- (void)removeOnlineUserButGuest{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            for (int i = 0; i < weakSelf.onlineUserArray.count; i++) {
                PLVLinkMicOnlineUser * user = weakSelf.onlineUserArray[i];
                if (user.userType != PLVSocketUserTypeGuest &&
                    ![user.linkMicUserId isEqualToString:weakSelf.linkMicUserId]) {
                    [weakSelf.rtcStreamerManager unsubscribeStreamWithRTCUserId:user.linkMicUserId];
                    [weakSelf.onlineUserMuArray removeObject:user];
                }
            }
            weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
            [weakSelf callbackForLinkMicUserListRefresh];
        });
    }
}

- (void)resetOnlineUserList{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            if (weakSelf.previewType == PLVStreamerPresenterPreviewType_AloneView) {
                [weakSelf.onlineUserMuArray removeAllObjects];
            }else{
                for (int i = 0; i < weakSelf.onlineUserArray.count; i++) {
                    PLVLinkMicOnlineUser * user = weakSelf.onlineUserArray[i];
                    if (![user.linkMicUserId isEqualToString:weakSelf.linkMicUserId]) {
                        [weakSelf.rtcStreamerManager unsubscribeStreamWithRTCUserId:user.linkMicUserId];
                        [weakSelf.onlineUserMuArray removeObject:user];
                    }
                }
            }
            [weakSelf.guestAllowLinkMicDict removeAllObjects];
            weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
            [weakSelf callbackForLinkMicUserListRefresh];
        });
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
                    NSLog(@"PLVStreamerPresenter - request link mic online list failed, error:%@",error);
                }];
            });
            weakSelf.requestOnlineListBlock = requestBlock;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1 + 2 * retryCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), weakSelf.requestOnlineListBlock);
        });
    }
}

/// 解析‘连麦用户列表数据’ 并 刷新用户数组
- (BOOL)refreshLinkMicOnlineUserListWithDataDictionary:(NSDictionary *)dataDictionary targetLinkMicUserId:(NSString *)targetLinkMicUserId{
    if (self.rtcRoomJoinStatus != PLVStreamerPresenterRoomJoinStatus_Joined) {
        NSLog(@"PLVStreamerPresenter - refreshLinkMicOnlineUserListWithDataDictionary failed %lu",(unsigned long)self.rtcRoomJoinStatus);
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
    master = self.channelId;
    
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
            [self removeLinkMicOnlineUser:exsitUser.linkMicUserId];
        }
    }
    
    // 添加用户
    for (NSDictionary * userInfo in linkMicUserList) {
        BOOL returnValue_includeTargetLinkMicUser = NO;
        BOOL addToOnlineArray = YES;
        
        /// 用户信息
        NSString * userLinkMicUserId = [NSString stringWithFormat:@"%@",userInfo[@"userId"]];
        returnValue_includeTargetLinkMicUser = [userLinkMicUserId isEqualToString:targetLinkMicUserId];
        
        addToOnlineArray = [self tryAddLinkMicWaitUser:userInfo];
        if (addToOnlineArray) {
            [self addLinkMicOnlineUser:userInfo mainSpeakerUserId:master];
        }
        
        if (!includeTargetLinkMicUser) {
            /// 仅在仍未找到‘目标用户’，会取本次‘添加用户’的返回值
            /// 因为若添加过程，已找到‘目标用户’，则本次方法的结果已确认，避免被覆盖
            includeTargetLinkMicUser = returnValue_includeTargetLinkMicUser;
        }
    }
    
    return includeTargetLinkMicUser;
}

- (void)addLinkMicOnlineUser:(NSDictionary *)userInfo mainSpeakerUserId:(NSString *)master{
    if ([PLVFdUtil checkDictionaryUseable:userInfo]) {
        PLVLinkMicOnlineUser * onlineUser = [PLVLinkMicOnlineUser modelWithDictionary:userInfo];
        
        // 监听事件
        __weak typeof(self) weakSelf = self;
        onlineUser.wantOpenMicBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantOpen) {
            [weakSelf muteRemoteUserMic:onlineUser muteMic:!wantOpen emitCompleteBlock:nil];
        };
        
        onlineUser.wantOpenCameraBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantOpen) {
            [weakSelf muteRemoteUserCamera:onlineUser muteCamera:!wantOpen emitCompleteBlock:nil];
        };
        
        onlineUser.wantCloseLinkMicBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            [weakSelf closeRemoteUserLinkMic:onlineUser emitCompleteBlock:nil];
        };
        
        // 若是未上麦嘉宾，则不作添加
        if (onlineUser.userType == PLVSocketUserTypeGuest &&
            !onlineUser.currentStatusVoice) {
            return;
        }
        
        // 若是本地用户，则不作解析
        if ([onlineUser.linkMicUserId isEqualToString:self.linkMicUserId]) {
            return;
        }
        
        // 设置主讲人标记
        if ([master isEqualToString:onlineUser.linkMicUserId]) {
            onlineUser.isRealMainSpeaker = YES;
        }
        
        // 添加用户
        [self addOnlineUserIntoOnlineUserArray:onlineUser completion:nil];
    }
}

#pragma mark LinkMic Wait User Manage
- (BOOL)tryAddLinkMicWaitUser:(NSDictionary *)userInfo{
    BOOL addToOnlineArray = YES;
    NSString * userType = [NSString stringWithFormat:@"%@",userInfo[@"userType"]];
    NSString * userLinkMicUserId = [NSString stringWithFormat:@"%@",userInfo[@"userId"]];
    if ([@"guest" isEqualToString:userType]){
        /// 用户类型为 ‘嘉宾’
        if (self.channelGuestManualJoinLinkMic) {
            /// ‘手动上麦’ 场景
            if ([self checkGuestJoinedLinkMic:userLinkMicUserId]) {
                addToOnlineArray = NO;
            }else{
                if ([self checkGuestAllowedLinkMicWithRaiseHand:userLinkMicUserId]) {
                    /// 已被讲师同意已举手
                    addToOnlineArray = YES;
                }else{
                    if ([self checkGuestAllowedLinkMic:userLinkMicUserId]) {
                        /// 已被讲师同意
                        NSInteger waitUserIndex = [self findWaitUserModelIndexWithFiltrateBlock:^BOOL(PLVLinkMicWaitUser * _Nonnull waitUser) {
                            if ([waitUser.linkMicUserId isEqualToString:userLinkMicUserId]) { return YES; }
                            return NO;
                        }];
                        if (waitUserIndex >= 0) {
                            PLVLinkMicWaitUser * waitUser = [self getWaitUserModelFromOnlineUserArrayWithIndex:waitUserIndex];
                            if (waitUser.currentRaiseHand || waitUser.currentAnswerAgreeJoin) {
                                /// 已同意或已举手
                                addToOnlineArray = YES;
                            }else{
                                /// 未同意未举手
                                [self addLinkMicWaitUserWithDict:userInfo completion:nil];
                                addToOnlineArray = NO;
                            }
                        }else{
                            NSLog(@"PLVRTCStreamerPresenter - add guest into onlineArray failed");
                            addToOnlineArray = NO;
                        }
                    }else{
                        /// 未被讲师同意
                        [self addLinkMicWaitUserWithDict:userInfo completion:nil];
                        addToOnlineArray = NO;
                    }
                }
            }
        }else{
            /// ‘自动上麦’ 场景
            addToOnlineArray = YES;
        }
    }
    return addToOnlineArray;
}

- (void)addLinkMicWaitUserWithDict:(NSDictionary *)userDict completion:(nullable void (^)(void))completion{
    if ([PLVFdUtil checkDictionaryUseable:userDict]) {
        /// 用户类型
        NSString * userType = [NSString stringWithFormat:@"%@",userDict[@"userType"]];
        NSString * waitUserLinkMicUserId = [PLVFdUtil checkStringUseable:userDict[@"loginId"]] ? userDict[@"loginId"] : nil;
        if ([@"guest" isEqualToString:userType]) {
            waitUserLinkMicUserId = [PLVFdUtil checkStringUseable:userDict[@"userId"]] ? userDict[@"userId"] : nil;
        }
        
        if (self.arraySafeQueue) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(self.arraySafeQueue, ^{
                NSArray <NSString *> * userIdArray = [weakSelf.waitUserMuArray valueForKeyPath:@"linkMicUserId"];
                if (![userIdArray containsObject:waitUserLinkMicUserId]) {
                    /// 创建 等待连麦模型
                    PLVLinkMicWaitUser * waitUser = [PLVLinkMicWaitUser modelWithDictionary:userDict];
                    waitUser.wantAllowJoinLinkMicBlock = ^(PLVLinkMicWaitUser * _Nonnull waitUser) {
                        [weakSelf allowRemoteUserJoinLinkMic:waitUser emitCompleteBlock:nil];
                    };
                    
                    /// 添加进数组
                    [weakSelf.waitUserMuArray addObject:waitUser];

                    weakSelf.waitUserArray = weakSelf.waitUserMuArray;
                    [weakSelf callbackForWaitUserListRefreshNewWaitUserAdded:YES];
                    
                    if (completion) { completion(); }
                }else{
                    // NSLog(@"POLYVTEST - 重复加入 %@ %@",waitUser.linkMicUserId,waitUser.nickname);
                }
            });
        }
    }else{
        NSLog(@"PLVRTCStreamerPresenter - addLinkMicWaitUserWithDict failed, userDict illegal:%@",userDict);
        if (completion) { completion(); }
    }
}

- (void)removeLinkMicWaitUser:(NSString *)linkMicUserId completion:(nullable void (^)(BOOL removeSuccess))completion{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        if ([linkMicUserId isEqualToString:self.linkMicUserId]) {
            NSLog(@"PLVRTCStreamerPresenter - removeLinkMicWaitUser failed, can not be self %@",linkMicUserId);
            if (completion) { completion(NO); }
            return;
        }
        
        if (self.arraySafeQueue) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(self.arraySafeQueue, ^{
                int index = -1;
                PLVLinkMicWaitUser * waitUser;
                for (int i = 0; i < weakSelf.waitUserMuArray.count; i++) {
                    waitUser = weakSelf.waitUserMuArray[i];
                    if ([waitUser.linkMicUserId isEqualToString:linkMicUserId]) {
                        index = i;
                        break;
                    }
                }
                
                if (index >= 0 && index < weakSelf.waitUserMuArray.count && waitUser != nil) {
                    [weakSelf.waitUserMuArray removeObject:waitUser];
                    weakSelf.waitUserArray = weakSelf.waitUserMuArray;
                    if (completion) { completion(YES); }
                    [weakSelf callbackForWaitUserListRefreshNewWaitUserAdded:NO];
                }else{
                    NSLog(@"PLVRTCStreamerPresenter - removeLinkMicWaitUser user(%@) failed, index(%d) not in the array",linkMicUserId,index);
                    if (completion) { completion(NO); }
                }
            });
        }else{
            NSLog(@"PLVRTCStreamerPresenter - removeLinkMicWaitUser failed, no safeQueue");
            if (completion) { completion(NO); }
        }
    }else{
        NSLog(@"PLVRTCStreamerPresenter - removeLinkMicWaitUser failed, linkMicUserId illegal %@",linkMicUserId);
        if (completion) { completion(NO); }
    }
}

- (void)removeWaitUserButGuest{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            for (int i = 0; i < weakSelf.waitUserArray.count; i++) {
                PLVLinkMicWaitUser * user = weakSelf.waitUserArray[i];
                if (user.userType != PLVSocketUserTypeGuest &&
                    ![user.linkMicUserId isEqualToString:weakSelf.linkMicUserId]) {
                    [weakSelf.waitUserMuArray removeObject:user];
                }
            }
            weakSelf.waitUserArray = weakSelf.waitUserMuArray;
            [weakSelf callbackForWaitUserListRefreshNewWaitUserAdded:NO];
        });
    }
}

- (void)resetWaitUserList{
    if (self.arraySafeQueue) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.arraySafeQueue, ^{
            [weakSelf.waitUserMuArray removeAllObjects];
            weakSelf.waitUserArray = weakSelf.waitUserMuArray;
            [weakSelf callbackForWaitUserListRefreshNewWaitUserAdded:NO];
        });
    }
}

#pragma mark Socket
- (void)handleSocket_TEACHER_SET_PERMISSION:(NSDictionary *)jsonDict{
    NSString * type = jsonDict[@"type"];
    NSString * userId = jsonDict[@"userId"];
    NSString * status = [NSString stringWithFormat:@"%@",jsonDict[@"status"]];
    if ([type isEqualToString:@"voice"]) {
        if ([PLVFdUtil checkStringUseable:userId]) {
            if ([status isEqualToString:@"1"]) {
                /// 嘉宾上麦
                [self linkMicUserJoined:userId retryCount:0];
            }else if ([status isEqualToString:@"0"]){
                /// 嘉宾下麦
                [self removeLinkMicOnlineUser:userId];
            }
        }
    }else if([type isEqualToString:@"specialRaiseHand"]){
        if ([PLVFdUtil checkStringUseable:userId]) {
            /// 嘉宾举手、取消举手
            [self changeGuestWaitUserRaiseHandState:userId raiseHand:[status isEqualToString:@"1"]];
        }
    }
}

- (void)handleSocket_joinAnswer:(NSDictionary *)jsonDict{
    NSString * userId = jsonDict[@"userId"];
    NSString * status = [NSString stringWithFormat:@"%@",jsonDict[@"status"]];
    BOOL answerAgreeJoin = [status isEqualToString:@"1"];
    if ([PLVFdUtil checkStringUseable:userId]) {
        /// 嘉宾同意、取消同意
        [self changeGuestWaitUserAnswerAgreeJoin:userId answerAgreeJoin:answerAgreeJoin];
        if (!answerAgreeJoin) {
            [self.guestAllowLinkMicDict removeObjectForKey:userId];
        }
    }
}

- (void)handleSocket_JOIN_REQUEST:(NSDictionary *)jsonDict{
    NSDictionary * userDict = jsonDict[@"user"];
    if ([PLVFdUtil checkDictionaryUseable:userDict]) {
        [self addLinkMicWaitUserWithDict:userDict completion:nil];
    }
}

- (void)handleSocket_JOIN_SUCCESS:(NSDictionary *)jsonDict{
    NSDictionary * userDict = jsonDict[@"user"];
    if ([PLVFdUtil checkDictionaryUseable:userDict]) {
        [self addLinkMicOnlineUser:userDict mainSpeakerUserId:nil];
    }
}

- (void)handleSocket_JOIN_LEAVE:(NSDictionary *)jsonDict{
    NSDictionary * userDict = jsonDict[@"user"];
    NSString * linkMicUserId = userDict[@"userId"];
    __weak typeof(self) weakSelf = self;
    [self removeLinkMicWaitUser:linkMicUserId completion:^(BOOL removeSuccess) {
        if (!removeSuccess) {
            /// 移除 ‘等待用户’ 失败，则可能是 ‘RTC在线用户’
            [weakSelf removeLinkMicOnlineUser:linkMicUserId];
        }
    }];
}

#pragma mark Callback
/// 房间加入状态发生改变
- (void)callbackForRoomJoinStatusChanged{
    BOOL currentInRTCRoom = (self.rtcRoomJoinStatus == PLVStreamerPresenterRoomJoinStatus_Joined);
    BOOL inRTCRoomChanged = (self.inRTCRoom != currentInRTCRoom);
    self.inRTCRoom = currentInRTCRoom;
    
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:currentRtcRoomJoinStatus:inRTCRoomChanged:inRTCRoom:)]) {
            [self.delegate plvStreamerPresenter:self currentRtcRoomJoinStatus:self.rtcRoomJoinStatus inRTCRoomChanged:inRTCRoomChanged inRTCRoom:self.inRTCRoom];
        }
    })
}

/// 连麦管理器的处理状态发生改变
- (void)callbackForOperationInProgress:(BOOL)inProgress{
    self.inProgress = inProgress;
    
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:operationInProgress:)]) {
            [self.delegate plvStreamerPresenter:self operationInProgress:self.inProgress];
        }
    })
}

- (void)callbackForWaitUserListRefreshNewWaitUserAdded:(BOOL)newWaitUserAdded{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:linkMicWaitUserListRefresh:newWaitUserAdded:)]) {
            [self.delegate plvStreamerPresenter:self linkMicWaitUserListRefresh:self.waitUserArray newWaitUserAdded:newWaitUserAdded];
        }
    })
}

- (void)callbackForLinkMicUserListRefresh{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:linkMicOnlineUserListRefresh:)]) {
            [self.delegate plvStreamerPresenter:self linkMicOnlineUserListRefresh:self.onlineUserArray];
        }
    })
}

- (void)callbackForReportAudioVolumeOfSpeakers:(NSDictionary<NSString *, NSNumber *> * _Nonnull)volumeDict{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:reportAudioVolumeOfSpeakers:)]) {
            [self.delegate plvStreamerPresenter:self reportAudioVolumeOfSpeakers:volumeDict];
        }
    })
}

- (void)callbackForReportCurrentSpeakingUsers:(NSArray<PLVLinkMicOnlineUser *> * _Nonnull)currentSpeakingUsers{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:reportCurrentSpeakingUsers:)]) {
            [self.delegate plvStreamerPresenter:self reportCurrentSpeakingUsers:currentSpeakingUsers];
        }
    })
}

- (void)callbackForMediaMute:(BOOL)mute mediaType:(NSString *)mediaType linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:didMediaMuted:mediaType:linkMicUser:)]) {
            [self.delegate plvStreamerPresenter:self didMediaMuted:mute mediaType:mediaType linkMicUser:linkMicUser];
        }
    })
}

- (void)callbackForPushStreamStartedDidChanged{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:pushStreamStartedDidChanged:)]) {
            [self.delegate plvStreamerPresenter:self pushStreamStartedDidChanged:self.pushStreamStarted];
        }
    })
}

- (void)callbackForPushStreamValidDuration{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:pushStreamValidDurationDidChanged:)]) {
            [self.delegate plvStreamerPresenter:self pushStreamValidDurationDidChanged:self.pushStreamValidDuration];
        }
    })
}

- (void)callbackForNetworkQualityDidChanged{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:networkQualityDidChanged:)]) {
            [self.delegate plvStreamerPresenter:self networkQualityDidChanged:self.networkQuality];
        }
    })
}

- (void)callbackForLocalUserMicOpenChanged{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:localUserMicOpenChanged:)]) {
            [self.delegate plvStreamerPresenter:self localUserMicOpenChanged:self.currentMicOpen];
        }
    })
}

- (void)callbackForLocalUserCameraShouldShowChanged{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:localUserCameraShouldShowChanged:)]) {
            [self.delegate plvStreamerPresenter:self localUserCameraShouldShowChanged:self.currentCameraShouldShow];
        }
    })
}

- (void)callbackForLocalUserCameraFrontChanged{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:localUserCameraFrontChanged:)]) {
            [self.delegate plvStreamerPresenter:self localUserCameraFrontChanged:self.currentCameraFront];
        }
    })
}

- (void)callbackForDidCloseRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:didCloseRemoteUserLinkMic:)]) {
            [self.delegate plvStreamerPresenter:self didCloseRemoteUserLinkMic:onlineUser];
        }
    })
}

- (void)callbackForSessionIdDidChanged{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:sessionIdDidChanged:)]) {
            [self.delegate plvStreamerPresenter:self sessionIdDidChanged:self.sessionId];
        }
    })
}

- (NSDictionary *)callbackForGetDocumentCurrentInfoDict{
    if ([self.delegate respondsToSelector:@selector(plvStreamerPresenterGetDocumentCurrentInfoDict:)]) {
        return [self.delegate plvStreamerPresenterGetDocumentCurrentInfoDict:self];
    }else{
        return nil;
    }
}

- (void)callbackForClassStartedDidChanged:(NSDictionary *)startClassInfoDict{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:classStartedDidChanged:startClassInfoDict:)]) {
            [self.delegate plvStreamerPresenter:self classStartedDidChanged:self.classStarted startClassInfoDict:startClassInfoDict];
        }
    })
}

#pragma mark Getter
- (NSString *)rtcType{
    return [PLVRoomDataManager sharedManager].roomData.menuInfo.rtcType;
}

- (NSString *)stream{
    return [PLVRoomDataManager sharedManager].roomData.stream;
}

- (NSString *)rtmpUrl{
    return [PLVRoomDataManager sharedManager].roomData.rtmpUrl;
}

- (NSString *)channelId{
    return [PLVRoomDataManager sharedManager].roomData.channelId;
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

- (BOOL)channelGuestManualJoinLinkMic{
    return [PLVRoomDataManager sharedManager].roomData.channelGuestManualJoinLinkMic;
}


#pragma mark - [ Event ]
#pragma mark Timer
- (void)linkMicTimerEvent:(NSTimer *)timer{
    if (!self.pushStreamStarted) { return; }
    
    /// Socket 断开时不作刷新请求，因连麦业务基本均依赖于 Scoket 服务
    if ([PLVSocketManager sharedManager].login) {
        __weak typeof(self) weakSelf = self;
        // 请求，刷新‘连麦在线用户列表’
        [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:self.channelId.integerValue sessionId:self.sessionId completion:^(NSDictionary *dict) {
            if (weakSelf.arraySafeQueue) {
                dispatch_async(weakSelf.arraySafeQueue, ^{
                    [weakSelf refreshLinkMicOnlineUserListWithDataDictionary:dict targetLinkMicUserId:nil];
                });
            }
        } failure:^(NSError *error) {
            NSLog(@"PLVStreamerPresenter - request linkmic online user list failed : %@",error);
        }];
    }else{
        NSLog(@"PLVStreamerPresenter - link mic status refresh failed, current socket status:%lu",(unsigned long)[PLVSocketManager sharedManager].status);
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
    if ([subEvent isEqualToString:@"TEACHER_SET_PERMISSION"]) {
        [self handleSocket_TEACHER_SET_PERMISSION:jsonDict];
    } else if ([subEvent containsString:@"LOGIN"]){ // 登录

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
    if ([event isEqualToString:PLVSocketIOLinkMic_JOIN_REQUEST_key]) { /// 用户举手
        [self handleSocket_JOIN_REQUEST:jsonDict];
    } else if ([event isEqualToString:PLVSocketIOLinkMic_JOIN_RESPONSE_key]) {
        
    } else if ([event isEqualToString:PLVSocketIOLinkMic_JOIN_SUCCESS_key]) { /// 用户成功上麦
        [self handleSocket_JOIN_SUCCESS:jsonDict];
    } else if ([event isEqualToString:PLVSocketIOLinkMic_JOIN_LEAVE_key]) { /// 用户离开连麦
        [self handleSocket_JOIN_LEAVE:jsonDict];
    }else if ([event isEqualToString:@"joinAnswer"]) {
        [self handleSocket_joinAnswer:jsonDict];
    }
}

#pragma mark PLVRTCStreamerManagerDelegate
- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager localUserJoinRTCChannelComplete:(NSString *)channelId{
    [self changeRoomJoinStatusAndCallback:PLVStreamerPresenterRoomJoinStatus_Joined];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager localUserLeaveRTCChannelComplete:(NSString *)channelId{
    [self changeRoomJoinStatusAndCallback:PLVStreamerPresenterRoomJoinStatus_NotJoin];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager didAudioMuted:(BOOL)muted byUid:(NSString *)uid{
    [self muteUser:uid mediaType:@"audio" mute:muted];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager didVideoMuted:(BOOL)muted byUid:(NSString *)uid{
    [self muteUser:uid mediaType:@"video" mute:muted];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager reportAudioVolumeOfSpeakers:(NSDictionary<NSString *,NSNumber *> *)volumeDict{
    [self updateLinkMicUserVolumeWithVolumeDictionary:volumeDict];
    [self callbackForReportAudioVolumeOfSpeakers:volumeDict];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager pushStreamStartedDidChanged:(BOOL)pushStreamStarted{
    if (pushStreamStarted) {
        if (self.startPushStreamSuccessBlock) {
            self.startPushStreamSuccessBlock();
            self.startPushStreamSuccessBlock = nil;
        }
    }
    [self callbackForPushStreamStartedDidChanged];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager pushStreamValidDurationDidChanged:(NSTimeInterval)pushStreamValidDuration{
    [self callbackForPushStreamValidDuration];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager networkQualityDidChanged:(PLVBLinkMicNetworkQuality)networkQuality{
    [self callbackForNetworkQualityDidChanged];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager sessionIdDidChanged:(NSString *)sessionId{
    [self callbackForSessionIdDidChanged];
}

@end
