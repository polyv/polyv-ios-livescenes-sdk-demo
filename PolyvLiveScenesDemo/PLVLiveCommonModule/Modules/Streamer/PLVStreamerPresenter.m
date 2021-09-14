//
//  PLVStreamerPresenter.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVStreamerPresenter.h"

#import "PLVRoomDataManager.h"

static NSString *const PLVStreamerPresenter_DictValue_GuestAllowed = @"allowed";
static NSString *const PLVStreamerPresenter_DictValue_GuestAllowedWithRaiseHand = @"allowedWithRaiseHand";
static NSString *const PLVStreamerPresenter_DictValue_GuestJoined = @"joined";

@interface PLVStreamerPresenter ()<
PLVSocketManagerProtocol,
PLVRTCStreamerManagerDelegate,
PLVChannelClassManagerDelegate
>

#pragma mark 状态
@property (nonatomic, assign) PLVStreamerPresenterRoomJoinStatus rtcRoomJoinStatus;
@property (nonatomic, assign) BOOL inRTCRoom;
@property (nonatomic, assign) BOOL inProgress;
@property (nonatomic, assign) BOOL classStarted;
@property (nonatomic, assign) int originalIdleTimerDisabled; // 0 表示未记录；负值小于0 对应NO状态；正值大于0 对应YES状态；
@property (nonatomic, assign) BOOL micCameraGranted;
@property (nonatomic, assign) BOOL localVideoPreviewSameAsRemoteWatch;
@property (nonatomic, assign) BOOL roomAllMicMute; // 当前是否‘房间全体静音’

#pragma mark 数据
@property (nonatomic, copy) NSString * linkMicUserId;
@property (nonatomic, strong) NSMutableArray <PLVLinkMicWaitUser *> * waitUserMuArray;
@property (nonatomic, strong) NSMutableArray <PLVLinkMicOnlineUser *> * onlineUserMuArray;
@property (nonatomic, weak) PLVLinkMicOnlineUser * realMainSpeakerUser;  // 注意: 弱引用
@property (nonatomic, weak) PLVLinkMicOnlineUser * localMainSpeakerUser; // 注意: 弱引用
@property (nonatomic, weak) PLVLinkMicOnlineUser * localOnlineUser; // 注意: 弱引用
@property (nonatomic, copy) NSArray <PLVLinkMicWaitUser *> * waitUserArray; // 提供外部读取的数据数组，保存最新的用户数据
@property (nonatomic, copy) NSArray <PLVLinkMicOnlineUser *> * onlineUserArray; // 提供外部读取的数据数组，保存最新的用户数据
@property (nonatomic, strong) NSMutableDictionary <NSString *,NSString *> * guestAllowLinkMicDict; // 嘉宾允许上麦状态记录字典 (value:@"allowed"-讲师已允许；value:@"allowedWithRaiseHand"-讲师已允许嘉宾已举手；value:@"joined"-嘉宾已上麦；其他情况视为讲师未同意)
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSDictionary*> * prerecordUserMediaStatusDict; // 用于提前记录用户媒体状态的字典

#pragma mark 外部数据封装
@property (nonatomic, copy, readonly) NSString * stream;
@property (nonatomic, copy, readonly) NSString * currentStream;
@property (nonatomic, copy, readonly) NSString * rtmpUrl;
@property (nonatomic, copy, readonly) NSString * rtcType;
@property (nonatomic, copy, readonly) NSString * channelId;
@property (nonatomic, copy, readonly) NSString * channelAccountId;
@property (nonatomic, copy, readonly) NSString * userId;
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;
@property (nonatomic, copy, readonly) NSString * linkMicUserNickname;
@property (nonatomic, copy, readonly) NSString * linkMicUserAvatar;
@property (nonatomic, copy, readonly) NSString * linkMicUserActor;
@property (nonatomic, assign, readonly) BOOL channelGuestManualJoinLinkMic;

#pragma mark 功能对象
@property (nonatomic, strong) PLVRTCStreamerManager * rtcStreamerManager;
@property (nonatomic, strong) NSTimer * linkMicTimer;
@property (nonatomic, strong) dispatch_queue_t arraySafeQueue;
@property (nonatomic, strong) dispatch_queue_t requestLinkMicOnlineListSafeQueue;
@property (nonatomic, weak) dispatch_block_t requestOnlineListBlock;
@property (nonatomic, copy) void (^startPushStreamSuccessBlock) (void);
@property (nonatomic, strong) PLVChannelClassManager * channelClassManager;

@end

@implementation PLVStreamerPresenter{
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Period ]
- (void)dealloc{
    [self stopLinkMicUserListTimer];
    [self leaveRTCChannelReal];
    [self resumeOriginalScreenOnStatus];
    PLV_LOG_DEBUG(PLVConsoleLogModuleTypeStreamer, @"%s",__FUNCTION__);
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

#pragma mark - [ Public Methods ]
#pragma mark 基础调用
- (void)prepareLocalMicCameraPreviewCompletion:(void (^)(BOOL, BOOL))completion {
    __weak typeof(self) weakSelf = self;
    [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) { /// 申请麦克风、摄像头权限
        weakSelf.micCameraGranted = granted;
        if (granted) {
            if (weakSelf.previewType == PLVStreamerPresenterPreviewType_UserArray) {
                /// 用户数组 预览类型
                /// 需要提前 创建本地在线用户，并加入 RTC房间已在线 用户数组 (因本地需要即刻预览)
                PLVLinkMicOnlineUser * localOnlineUser = [weakSelf createLocalOnlineUser];
                [self addOnlineUserIntoOnlineUserArray:localOnlineUser completion:^(BOOL added) {
                    if (completion) { plv_dispatch_main_async_safe(^{ completion(YES, added); }) }
                }];
            }else{
                if (completion) { plv_dispatch_main_async_safe(^{ completion(YES, YES); }) }
            }
        } else {
            if (completion) { plv_dispatch_main_async_safe(^{ completion(NO, NO); }) }
        }
    }];
}

- (void)setupLocalPreviewWithCanvaView:(nullable UIView *)canvasView setupCompletion:(nullable void (^)(BOOL setupResult))setupCompletion{
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
        [self updateRTCTokenWithCompletion:^(BOOL updateResult) {
            if (updateResult) {
                if (!weakSelf.rtcStreamerManager.currentLocalPreviewCanvasModel) {
                    PLVBRTCVideoViewCanvasModel * model = [[PLVBRTCVideoViewCanvasModel alloc]init];
                    model.userRTCId = weakSelf.linkMicUserId;
                    model.renderCanvasView = canvasView;
                    model.rtcVideoVideoFillMode = PLVBRTCVideoViewFillMode_Fill;
                    [weakSelf.rtcStreamerManager setupLocalPreviewWithCanvasModel:model];
                    if (setupCompletion) { setupCompletion(YES); }
                }else{
                    PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"startLocalPreviewWithCanvaView failed, currentLocalPreviewCanvasModel already exist");
                    if (setupCompletion) { setupCompletion(NO); }
                }
            }else{
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"setupLocalPreviewWithCanvaView failed, update RTC Token failed");
                if (setupCompletion) { setupCompletion(NO); }
            }
        }];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"startLocalPreviewWithCanvaView failed, canvasView illegal %@",canvasView);
        if (setupCompletion) { setupCompletion(NO); }
    }
}

- (void)startLocalMicCameraPreviewByDefault{
    if (!self.micCameraGranted) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"startLocalMicCameraPreviewByDefault failed, micCameraGranted is 'NO', should call [prepareLocalPreviewCompletion:] before");
        return;
    }
    
    if (!self.rtcStreamerManager.currentLocalPreviewCanvasModel) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"startLocalMicCameraPreviewByDefault failed, currentLocalPreviewCanvasModel is 'nil', should call [setupLocalPreviewWithCanvaView:] before");
        return;
    }
    /// 响应默认配置
    [self.rtcStreamerManager startLocalMicCameraPreviewByDefault];
    
    /// 更新为默认值
    [self.localOnlineUser updateUserCurrentMicOpen:self.micDefaultOpen];
    [self.localOnlineUser updateUserCurrentCameraOpen:self.cameraDefaultOpen];
    [self.localOnlineUser updateUserCurrentCameraFront:self.cameraDefaultFront];
    [self updateMixUserList];
}

- (void)joinRTCChannel{
    if (self.viewerType == PLVRoomUserTypeTeacher) {
        [self joinRTCChannelReal];
    }else if(self.viewerType == PLVRoomUserTypeGuest) {
        /// 开始监听 ‘直播流’ 状态变化
        __weak typeof(self) weakSelf = self;
        [self.channelClassManager startObserveStreamStateWithStream:self.currentStream completion:^(PLVChannelLiveStreamState streamState, BOOL streamStateDidChanged) {
            if (streamStateDidChanged) {
                BOOL currentClassStarted = (streamState == PLVChannelLiveStreamState_Live ? YES : NO);
                BOOL classStartedChanged = (weakSelf.classStarted != currentClassStarted);
                weakSelf.classStarted = currentClassStarted;
                if (streamState == PLVChannelLiveStreamState_Live && classStartedChanged) {
                    [weakSelf joinRTCChannelReal];
                }else if((streamState == PLVChannelLiveStreamState_End ||
                         streamState == PLVChannelLiveStreamState_Stop) &&
                         classStartedChanged){
                    [weakSelf guestLeaveRTCChannel];
                }
            }
            [weakSelf callbackForStreamStateUpdate:streamState streamStateDidChanged:streamStateDidChanged];
        } failure:^(NSError * _Nonnull error) {
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"joinRTCChannel failed, StreamState request failed");
        }];
    }
}

- (void)leaveRTCChannel{
    if (self.viewerType == PLVRoomUserTypeGuest) {
        /// 停止监听 ‘直播流’ 状态变化
        [self.channelClassManager stopObserveStreamState];
    }
    [self leaveRTCChannelReal];
    [self resetOnlineUserList];
    [self resetWaitUserList];
}

#pragma mark 课程事件管理
- (int)startClass{
    if (self.viewerType != PLVRoomUserTypeTeacher) { return -1; }
    if (!self.classStarted) {
        __weak typeof(self) weakSelf = self;
        self.startPushStreamSuccessBlock = ^{
            [weakSelf startClassEmitCompleteBlock:^(BOOL emitSuccess) {
                if (!emitSuccess) {
                    NSError * finalError = [weakSelf errorWithCode:PLVStreamerPresenterErrorCode_StartClassFailedEmitFailed errorDescription:nil];
                    [weakSelf callbackForDidOccurError:finalError];
                }
            }];
        };
        
        int resultCode = [self startPushStream];
        if (resultCode < 0) {
            return resultCode * 10;
        }else{
            return 0;
        }
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"startClass failed, class had started");
        return -2;
    }
}

- (void)finishClass{
    [self resetOnlineUserList];
    [self resetWaitUserList];
    if (self.viewerType == PLVRoomUserTypeTeacher) {
        [self stopPushStream];
        [self closeLinkMicEmitCompleteBlock:nil];
        [self finishClassEmitCompleteBlock:nil];
        [self requestForLiveStatusEnd];
    }
}

#pragma mark 流管理
- (void)setupStreamScale:(PLVBLinkMicStreamScale)streamScale{
    [self.rtcStreamerManager setupStreamScale:streamScale];
}

- (void)setupStreamQuality:(PLVBLinkMicStreamQuality)streamQuality{
    [self.rtcStreamerManager setupStreamQuality:streamQuality];
}

- (void)setupLocalVideoPreviewSameAsRemoteWatch:(BOOL)localSameAsRemote{
    _localVideoPreviewSameAsRemoteWatch = localSameAsRemote;
    if (localSameAsRemote) {
        [self.rtcStreamerManager setupLocalVideoStreamMirrorMode:self.localVideoMirrorMode];
    }else{
        [self.rtcStreamerManager setupLocalVideoStreamMirrorMode:PLVBRTCVideoMirrorMode_Disabled];
    }
}

#pragma mark CDN流管理
- (int)startPushStream{
    if (self.micCameraGranted) {
        if (!self.pushStreamStarted) {
            [self.rtcStreamerManager startPushStreamWithStream:self.stream rtmpUrl:self.rtmpUrl];
            return 0;
        }else{
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"startPushStream failed, stream had started push");
            return -4;
        }
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"startPushStream failed, mic Camera not be granted");
        return -2;
    }
}

- (void)stopPushStream{
    [self.rtcStreamerManager stopPushStream];
}

- (void)setupMixLayoutType:(PLVRTCStreamerMixLayoutType)mixLayoutType{
    [self.rtcStreamerManager setupMixLayoutType:mixLayoutType];
}

#pragma mark 本地硬件管理
- (void)openLocalUserMic:(BOOL)openMic{
    [self.rtcStreamerManager openLocalUserMic:openMic];
    [self.localOnlineUser updateUserCurrentMicOpen:openMic];
}

- (void)openLocalUserCamera:(BOOL)openCamera{
    [self.rtcStreamerManager openLocalUserCamera:openCamera completion:nil];
    [self.localOnlineUser updateUserCurrentCameraOpen:openCamera];
    [self updateMixUserList];
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

- (void)openLocalUserCameraTorch:(BOOL)openCameraTorch{
    [self.rtcStreamerManager openLocalUserCameraTorch:openCameraTorch];
    [self.localOnlineUser updateUserCurrentCameraTorchOpen:openCameraTorch];
}

- (void)setupLocalVideoPreviewMirrorMode:(PLVBRTCVideoMirrorMode)mirrorMode{
    [self.rtcStreamerManager setupLocalVideoPreviewMirrorMode:mirrorMode];
    
    if (self.localVideoPreviewSameAsRemoteWatch) {
        [self.rtcStreamerManager setupLocalVideoStreamMirrorMode:self.localVideoMirrorMode];
    }
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
- (void)closeLinkMicEmitCompleteBlock:(void (^)(BOOL emitSuccess))emitCompleteBlock{
    [self.rtcStreamerManager closeLinkMicEmitCompleteBlock:emitCompleteBlock];
    [self removeOnlineUserButGuest];
    [self removeWaitUserButGuest];
}

/// 允许 某位远端用户 上麦
- (void)allowRemoteUserJoinLinkMic:(PLVLinkMicWaitUser *)waitUser emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    NSString * waitUserRtcId = waitUser.linkMicUserId;
    BOOL guestWaitUser = waitUser.userType == PLVSocketUserTypeGuest;
    NSString * currentRaiseHand = guestWaitUser ? (waitUser.currentRaiseHand ? @"1" : @"0") : nil;
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
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"getUserModelFromOnlineUserArrayWithIndex failed, '%ld' beyond data array",(long)targetIndex);
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
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"getWaitUserModelFromOnlineUserArrayWithIndex failed, '%ld' beyond data array",(long)targetIndex);
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
    if (self.viewerType == PLVRoomUserTypeGuest) {
        return self.channelClassManager.sessionId;
    }else{
        return self.rtcStreamerManager.sessionId;
    }
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

- (NSTimeInterval)currentRemotePushDuration{
    return self.channelClassManager.currentPushDuration;
}

- (NSTimeInterval)reconnectingThisTimeDuration{
    return self.rtcStreamerManager.reconnectingThisTimeDuration;
}

- (NSTimeInterval)reconnectingTotalDuration{
    return self.rtcStreamerManager.reconnectingTotalDuration;
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

- (BOOL)currentCameraTorchOpen{
    return self.localOnlineUser.currentCameraTorchOpen;
}

- (PLVBRTCVideoMirrorMode)localVideoMirrorMode{
    return self.rtcStreamerManager.localVideoMirrorMode;
}

- (BOOL)channelLinkMicOpen{
    return self.rtcStreamerManager.channelLinkMicOpen;
}

- (PLVChannelLinkMicMediaType)channelLinkMicMediaType{
    return self.rtcStreamerManager.channelLinkMicMediaType;
}

- (PLVBLinkMicStreamScale)streamScale{
    return self.rtcStreamerManager.streamScale;
}

- (PLVBLinkMicStreamQuality)streamQuality{
    return self.rtcStreamerManager.streamQuality;
}

- (PLVChannelLiveStreamState)currentStreamState{
    return self.channelClassManager.currentStreamState;
}

#pragma mark - [ Private Methods ]
- (void)setup{
    /// 初始化 数据
    self.originalIdleTimerDisabled = 0;
    self.waitUserMuArray = [[NSMutableArray<PLVLinkMicWaitUser *> alloc] init];
    self.onlineUserMuArray = [[NSMutableArray<PLVLinkMicOnlineUser *> alloc] init];
    self.guestAllowLinkMicDict = [[NSMutableDictionary <NSString *,NSString *> alloc] init];
    self.arraySafeQueue = dispatch_queue_create("PLVStreamerPresenterArraySafeQueue", DISPATCH_QUEUE_SERIAL);
    self.requestLinkMicOnlineListSafeQueue = dispatch_queue_create("PLVStreamerPresenterRequestLinkMicOnlineListSafeQueue", DISPATCH_QUEUE_SERIAL);
    self.prerecordUserMediaStatusDict = [[NSMutableDictionary alloc] init];

    /// 创建 获取连麦在线用户列表 定时器
    self.linkMicTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(linkMicTimerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.linkMicTimer forMode:NSRunLoopCommonModes];
    [self.linkMicTimer fire];
    
    /// 添加 socket 事件监听
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    /// 创建 推流管理器
    [self createRtcStreamerManager];
    
    /// 设置常亮
    /// 允许2秒内外部模块作最终的“常亮”配置
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf setScreenAlwaysOn];
    });
}

- (void)stopLinkMicUserListTimer{
    [_linkMicTimer invalidate];
    _linkMicTimer = nil;
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
    int currentOriginalIdleTimerDisabled = self.originalIdleTimerDisabled;
    if (currentOriginalIdleTimerDisabled != 0) {
        plv_dispatch_main_async_safe(^{
            [UIApplication sharedApplication].idleTimerDisabled = currentOriginalIdleTimerDisabled < 0 ? NO : YES;
        });
        self.originalIdleTimerDisabled = 0;
    }
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
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"startClass failed, ackArray illegal:%@",ackArray);
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
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"finishClass failed, ackArray illegal:%@",ackArray);
            if (emitCompleteBlock) { emitCompleteBlock(NO); }
        }
    }];
}

- (NSError *)errorWithCode:(NSInteger)code errorDescription:(NSString *)errorDes{
    return PLVErrorCreate(@"net.plv.PLVStreamerPresenter", code, errorDes);
}

#pragma mark Net Request
/// 更新频道直播状态至结束
- (void)requestForLiveStatusEnd{
    [PLVLiveVideoAPI requestChannelLivestatusEndWithChannelId:self.channelId stream:self.stream success:^(NSString * _Nonnull responseCont) {
    } failure:^(NSError * _Nonnull error) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"requestForLiveStatusEnd failed, error %@",error);
    }];
}

#pragma mark Prepare Streamer
- (PLVRTCStreamerManager *)createRtcStreamerManager{
    if (_rtcStreamerManager == nil) {
        if (![PLVFdUtil checkStringUseable:self.rtcType]) {
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"rtcStreamerManager create failed, rtcType illegal %@",self.rtcType);
            return nil;
        }
        
        _rtcStreamerManager = [PLVRTCStreamerManager rtcStreamerManagerWithRTCType:self.rtcType channelId:self.channelId];
        _rtcStreamerManager.delegate = self;
    }
    return _rtcStreamerManager;
}

- (void)joinRTCChannelReal{
    if (!self.rtcStreamerManager.hadJoinedRTC) {
        __weak typeof(self) weakSelf = self;
        [self updateRTCTokenWithCompletion:^(BOOL updateResult) {
            if (updateResult) {
                [weakSelf changeRoomJoinStatusAndCallback:PLVStreamerPresenterRoomJoinStatus_Joining];
                /// 讲师角色，则默认为 ‘主播’ 类型；
                /// 否则，默认为‘观众’ 类型
                PLVBLinkMicRoleType roleType = (weakSelf.viewerType == PLVRoomUserTypeTeacher ? PLVBLinkMicRoleBroadcaster : PLVBLinkMicRoleAudience);
                [weakSelf.rtcStreamerManager switchRoleTypeTo:roleType];
                [weakSelf.rtcStreamerManager joinRTCChannelWithUserRTCId:weakSelf.linkMicUserId];
            }else{
                PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"joinRTCChannel failed, update RTC Token failed");
            }
        }];
    }
}

- (void)leaveRTCChannelReal{
    if (self.rtcStreamerManager.hadJoinedRTC) {
        [self.rtcStreamerManager leaveRTCChannel];
    }
}

- (void)updateRTCTokenWithCompletion:(void (^)(BOOL updateResult))completion{ /// 考虑这个方法放进SDK层
    if (self.rtcStreamerManager.rtcTokenAvailable) {
        if (completion) { completion(YES); }
        return;
    }
    
    PLVLinkMicGetTokenModel * getTokenModel = [[PLVLinkMicGetTokenModel alloc]init];
    getTokenModel.channelId = self.channelId;
    getTokenModel.userId = self.linkMicUserId;
    getTokenModel.channelType = [PLVRoomDataManager sharedManager].roomData.channelType;
    getTokenModel.viewerId = self.channelId;
    getTokenModel.nickname = self.linkMicUserNickname;
    getTokenModel.sessionId = self.sessionId;

    if (self.viewerType == PLVRoomUserTypeSlice || self.viewerType == PLVRoomUserTypeStudent) {
        getTokenModel.userType = @"audience";
    }else if(self.viewerType == PLVRoomUserTypeTeacher){
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
                    [weakSelf updateMixUserList];
                }else{
                    [resultUser updateUserCurrentMicOpen:!mute];
                }
            }
            if ([mediaType isEqualToString:@"audio"]) {
                [weakSelf callbackForLinkMicUser:resultUser audioMuted:mute];
            }else if([mediaType isEqualToString:@"video"]){
                [weakSelf callbackForLinkMicUser:resultUser videoMuted:mute];
            }
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
            BOOL shouldIgnore = NO;
            NSNumber * lastLeaveLinkMicTimeObj = [lastMediaStatusDict objectForKey:@"LastLeaveLinkMicTime"];
            if (lastLeaveLinkMicTimeObj && [lastLeaveLinkMicTimeObj isKindOfClass:NSNumber.class]) {
                NSTimeInterval lastLeaveLinkMicTime = lastLeaveLinkMicTimeObj.doubleValue;
                shouldIgnore = ([[NSDate date] timeIntervalSince1970] - lastLeaveLinkMicTime) < 2;
            }
            if (!shouldIgnore) { updateMediaStatusDict = [[NSMutableDictionary alloc] initWithDictionary:lastMediaStatusDict]; }
        } else {
            updateMediaStatusDict = [[NSMutableDictionary alloc] init];
        }
        [updateMediaStatusDict setObject:@(mute) forKey:mediaType];
        if (updateMediaStatusDict) { [self.prerecordUserMediaStatusDict setObject:updateMediaStatusDict forKey:linkMicUserId]; }
    }
}

/// 仅‘远端嘉宾角色’适用该方法
- (void)prerecordGuestLeaveLinkMicTimeWithLinkMicUserId:(NSString *)linkMicUserId{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        NSDictionary * lastMediaStatusDict = [self.prerecordUserMediaStatusDict objectForKey:linkMicUserId];
        NSMutableDictionary * updateMediaStatusDict;
        if ([PLVFdUtil checkDictionaryUseable:lastMediaStatusDict]) {
            updateMediaStatusDict = [[NSMutableDictionary alloc] initWithDictionary:lastMediaStatusDict];
        } else {
            updateMediaStatusDict = [[NSMutableDictionary alloc] init];
        }
        NSInteger timeInterval = (NSInteger)[[NSDate date] timeIntervalSince1970];
        [updateMediaStatusDict setObject:@(timeInterval) forKey:@"LastLeaveLinkMicTime"];
        if (updateMediaStatusDict) { [self.prerecordUserMediaStatusDict setObject:updateMediaStatusDict forKey:linkMicUserId]; }
    }
}

- (void)removePrerecordWithLinkMicUserId:(NSString *)linkMicUserId{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        [self.prerecordUserMediaStatusDict removeObjectForKey:linkMicUserId];
    }
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

- (void)updateMixUserList{
    NSMutableArray * mixUserList = [[NSMutableArray alloc] init];
    for (PLVLinkMicOnlineUser * onlineUser in self.onlineUserArray) {
        if ([PLVFdUtil checkStringUseable:onlineUser.linkMicUserId]) {
            PLVRTCStreamerMixUser * mixUser = [[PLVRTCStreamerMixUser alloc] init];
            mixUser.userRTCId = onlineUser.linkMicUserId;
            mixUser.renderMode = PLVRTCStreamerMixUserRenderMode_Fill;
            mixUser.inputType = onlineUser.currentCameraOpen ? PLVRTCStreamerMixUserInputType_AudioVideo : PLVRTCStreamerMixUserInputType_Audio;
            [mixUserList addObject:mixUser];
        }else{
            continue;
        }
    }
    
    if ([PLVFdUtil checkArrayUseable:mixUserList]) {
        [self.rtcStreamerManager setupMixUserList:mixUserList];
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

- (void)emitLocalGuestJoinResponse:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock{
    PLVSocketManager * socketManager = [PLVSocketManager sharedManager];
    PLVBSocketUserType bUserType = (PLVBSocketUserType)socketManager.userType;
    NSString * userTypeEnglishString = [PLVBSocketUser userTypeStringWithUserType:bUserType english:YES];
    NSString * userTypeChineseString = [PLVBSocketUser userTypeStringWithUserType:bUserType english:NO];
    NSString * roomId = socketManager.roomId; // 此处不可使用频道号，因存在分房间的可能
    NSDictionary * jsonDict = @{@"actor" : [NSString stringWithFormat:@"%@",userTypeChineseString],
                                @"userType" : [NSString stringWithFormat:@"%@",userTypeEnglishString],
                                @"channelId" : [NSString stringWithFormat:@"%@",self.channelAccount],
                                @"nick" : [NSString stringWithFormat:@"%@",self.linkMicUserNickname],
                                @"pic" : [NSString stringWithFormat:@"%@",self.linkMicUserAvatar],
                                @"userId" : [NSString stringWithFormat:@"%@",self.userId], /// 聊天室用户Id
                                @"roomId" : [NSString stringWithFormat:@"%@",roomId],
                                @"banned" : @NO};
    [self.rtcStreamerManager allowRemoteUserJoinLinkMic:jsonDict raiseHand:nil emitCompleteBlock:emitCompleteBlock];
}

- (void)guestLeaveRTCChannel{
    [self.localOnlineUser updateUserCurrentStatusVoice:NO];

    [self leaveRTCChannelReal];
    [self resetOnlineUserList];
    [self resetWaitUserList];
    
    /// 重新启动本地预览
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.rtcStreamerManager setupLocalPreviewWithCanvasModel:self.rtcStreamerManager.currentLocalPreviewCanvasModel];
        [self startLocalMicCameraPreviewByDefault];
    });
}

#pragma mark LinkMic OnlineUser Manage
- (PLVLinkMicOnlineUser *)createLocalOnlineUser{
    PLVLinkMicOnlineUser * localOnlineUser;
    if (!_localOnlineUser) {
        PLVSocketUserType userType = [PLVRoomUser sockerUserTypeWithRoomUserType:self.viewerType];
        localOnlineUser = [PLVLinkMicOnlineUser localUserModelWithUserId:self.userId linkMicUserId:self.linkMicUserId nickname:self.linkMicUserNickname avatarPic:self.linkMicUserAvatar userType:userType actor:self.linkMicUserActor];
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
        
        [localOnlineUser addCameraTorchOpenChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            [weakSelf callbackForLocalUserCameraTorchOpenChanged];
        } blockKey:self];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"createLocalOnlineUser failed, localOnlineUser exist %p",_localOnlineUser);
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
                                        
                    if (!onlineUser.localUser && !onlineUser.rtcRendered) {
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
                        BOOL micOpen = ![weakSelf readPrerecordWithLinkMicUserId:onlineUser.linkMicUserId mediaType:@"audio" defaultMuteStatus:NO];
                        BOOL cameraOpen = ![weakSelf readPrerecordWithLinkMicUserId:onlineUser.linkMicUserId mediaType:@"video" defaultMuteStatus:NO];
                        
                        /// 设置初始值
                        [onlineUser updateUserCurrentMicOpen:micOpen];
                        [onlineUser updateUserCurrentCameraOpen:cameraOpen];
                        
                        [weakSelf removePrerecordWithLinkMicUserId:onlineUser.linkMicUserId];
                    }
                    
                    [weakSelf sortOnlineUserList];
                    weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
                    [weakSelf callbackForLinkMicUserListRefresh];
                    [weakSelf updateMixUserList];
                    
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
    if ([linkMicUserId isEqualToString:self.linkMicUserId]) { // 断网之后重连，获取到的在线列表一开始可能会缺少本地用户，防止在这时候删除本地用户数据
        return;
    }
    
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
                    [weakSelf updateMixUserList];
                }else{
                    PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"remove link mic user(%@) failed, index(%d) not in the array",linkMicUserId,index);
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
                    /// 非本地用户
                    [weakSelf.rtcStreamerManager unsubscribeStreamWithRTCUserId:user.linkMicUserId];
                    [weakSelf.onlineUserMuArray removeObject:user];
                }
            }
            weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
            [weakSelf callbackForLinkMicUserListRefresh];
            [weakSelf updateMixUserList];
        });
    }
}

/// 重置 ‘连麦在线User 列表’
///
/// @note PLVStreamerPresenterPreviewType_AloneView 类型下，全部用户被移除
///       PLVStreamerPresenterPreviewType_AloneView 以外的类型，全部‘非自己用户’被移除
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
                        /// 非本地用户
                        [weakSelf.rtcStreamerManager unsubscribeStreamWithRTCUserId:user.linkMicUserId];
                        [weakSelf.onlineUserMuArray removeObject:user];
                    }
                }
            }
            [weakSelf.guestAllowLinkMicDict removeAllObjects];
            weakSelf.onlineUserArray = weakSelf.onlineUserMuArray;
            [weakSelf callbackForLinkMicUserListRefresh];
            [weakSelf updateMixUserList];
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
                    PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"request link mic online list failed, error:%@",error);
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
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"refreshLinkMicOnlineUserListWithDataDictionary failed %lu",(unsigned long)self.rtcRoomJoinStatus);
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

- (void)sortOnlineUserList{
    __weak typeof(self) weakSelf = self;
    NSArray * sortArray = [self.onlineUserMuArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PLVLinkMicOnlineUser * user1 = (PLVLinkMicOnlineUser *)obj1;
        PLVLinkMicOnlineUser * user2 = (PLVLinkMicOnlineUser *)obj2;

        /// 此处不再依赖于‘枚举制定’来确定排序；
        /// 角色排序逻辑，直接根据以下逻辑为准
        NSComparisonResult result1 = [weakSelf compareLinkMicOnlineUser1:user1 user2:user2 highPriorityType:PLVSocketUserTypeTeacher];
        if (result1 != -2) { return result1; }
        
        NSComparisonResult result2 = [weakSelf compareLinkMicOnlineUser1:user1 user2:user2 highPriorityType:PLVSocketUserTypeManager];
        if (result2 != -2) { return result2; }
        
        NSComparisonResult result3 = [weakSelf compareLinkMicOnlineUser1:user1 user2:user2 highPriorityType:PLVSocketUserTypeAssistant];
        if (result3 != -2) { return result3; }
        
        NSComparisonResult result4 = [weakSelf compareLinkMicOnlineUser1:user1 user2:user2 highPriorityType:PLVSocketUserTypeGuest];
        if (result4 != -2) { return result4; }
        
        return NSOrderedSame;
    }];
    [self.onlineUserMuArray removeAllObjects];
    self.onlineUserMuArray = [NSMutableArray arrayWithArray:sortArray];
}

- (NSComparisonResult)compareLinkMicOnlineUser1:(PLVLinkMicOnlineUser *)user1 user2:(PLVLinkMicOnlineUser *)user2 highPriorityType:(PLVSocketUserType)highPriorityType{
    if (user1.userType == highPriorityType ||
        user2.userType == highPriorityType) {
        if (user1.userType == highPriorityType &&
            user2.userType == highPriorityType) {
            return [user1.linkMicUserId compare:user2.linkMicUserId];
        }else{
            return (user1.userType == highPriorityType ? NSOrderedAscending : NSOrderedDescending);
        }
    }else{
        return -2;
    }
}

#pragma mark LinkMic WaitUser Manage
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
                            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"add guest into onlineArray failed");
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
                    // NSLog(@"PLVTEST - 重复加入 %@ %@",waitUser.linkMicUserId,waitUser.nickname);
                }
            });
        }
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"addLinkMicWaitUserWithDict failed, userDict illegal:%@",userDict);
        if (completion) { completion(); }
    }
}

- (void)removeLinkMicWaitUser:(NSString *)linkMicUserId completion:(nullable void (^)(BOOL removeSuccess))completion{
    if ([PLVFdUtil checkStringUseable:linkMicUserId]) {
        if ([linkMicUserId isEqualToString:self.linkMicUserId]) {
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"removeLinkMicWaitUser failed, can not be self %@",linkMicUserId);
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
                    PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"removeLinkMicWaitUser user(%@) failed, index(%d) not in the array",linkMicUserId,index);
                    if (completion) { completion(NO); }
                }
            });
        }else{
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"removeLinkMicWaitUser failed, no safeQueue");
            if (completion) { completion(NO); }
        }
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"removeLinkMicWaitUser failed, linkMicUserId illegal %@",linkMicUserId);
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
    if (self.arraySafeQueue && self.waitUserMuArray.count > 0) {
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
    if (!self.classStarted) { return; }
    
    NSString * type = jsonDict[@"type"];
    NSString * userId = jsonDict[@"userId"];
    NSString * status = [NSString stringWithFormat:@"%@",jsonDict[@"status"]];
    BOOL localUser = [userId isEqualToString:self.linkMicUserId];
    if ([type isEqualToString:@"voice"]) {
        if ([PLVFdUtil checkStringUseable:userId]) {
            if ([status isEqualToString:@"1"]) {
                /// 嘉宾上麦
                if (self.viewerType == PLVRoomUserTypeTeacher){
                    [self linkMicUserJoined:userId retryCount:0];
                }else if (self.viewerType == PLVRoomUserTypeGuest){
                    if (localUser) {
                        [self.rtcStreamerManager switchRoleTypeTo:PLVBLinkMicRoleBroadcaster];
                        [self.localOnlineUser updateUserCurrentStatusVoice:YES];
                        
                        /// 响应‘全体静音’房间开关
                        if (self.roomAllMicMute && self.currentMicOpen) {
                            [self openLocalUserMic:NO];
                            [self muteUser:userId mediaType:@"audio" mute:YES];
                        }
                    }else{
                        [self linkMicUserJoined:userId retryCount:0];
                    }
                }
            }else if ([status isEqualToString:@"0"]){
                /// 嘉宾下麦
                if (self.viewerType == PLVRoomUserTypeTeacher){
                    [self prerecordGuestLeaveLinkMicTimeWithLinkMicUserId:userId];
                    [self removeLinkMicOnlineUser:userId];
                }else if (self.viewerType == PLVRoomUserTypeGuest){
                    if (localUser) {
                        [self.rtcStreamerManager switchRoleTypeTo:PLVBLinkMicRoleAudience];
                        [self.localOnlineUser updateUserCurrentStatusVoice:NO];
                        
                        /// 重新启动本地预览
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self.rtcStreamerManager setupLocalPreviewWithCanvasModel:self.rtcStreamerManager.currentLocalPreviewCanvasModel];
                            [self startLocalMicCameraPreviewByDefault];
                        });
                    }else{
                        [self prerecordGuestLeaveLinkMicTimeWithLinkMicUserId:userId];
                        [self removeLinkMicOnlineUser:userId];
                    }
                }
            }
        }
    }else if([type isEqualToString:@"specialRaiseHand"]){
        if ([PLVFdUtil checkStringUseable:userId]) {
            /// 嘉宾举手、取消举手
            [self changeGuestWaitUserRaiseHandState:userId raiseHand:[status isEqualToString:@"1"]];
        }
    }
}

- (void)handleSocket_MUTE_USER_MICRO:(NSDictionary *)jsonDict{
    BOOL mute = ((NSNumber *)jsonDict[@"mute"]).boolValue;
    if (![PLVFdUtil checkStringUseable:jsonDict[@"userId"]]) { /// 全体静音处理
        self.roomAllMicMute = mute;
    }
    [self muteUser:self.linkMicUserId mediaType:jsonDict[@"type"] mute:mute];
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
- (void)callbackForRoomJoinStatusChanged{
    BOOL currentInRTCRoom = (self.rtcRoomJoinStatus == PLVStreamerPresenterRoomJoinStatus_Joined);
    BOOL inRTCRoomChanged = (self.inRTCRoom != currentInRTCRoom);
    self.inRTCRoom = currentInRTCRoom;
    
    [PLVRoomDataManager sharedManager].roomData.inRTCRoom = self.inRTCRoom; /// 同步至房间数据管理
    
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:currentRtcRoomJoinStatus:inRTCRoomChanged:inRTCRoom:)]) {
            [self.delegate plvStreamerPresenter:self currentRtcRoomJoinStatus:self.rtcRoomJoinStatus inRTCRoomChanged:inRTCRoomChanged inRTCRoom:self.inRTCRoom];
        }
    })
}

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

- (void)callbackForLinkMicUser:(PLVLinkMicOnlineUser *)linkMicOnlineUser audioMuted:(BOOL)audioMuted{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:linkMicOnlineUser:audioMuted:)]) {
            [self.delegate plvStreamerPresenter:self linkMicOnlineUser:linkMicOnlineUser audioMuted:audioMuted];
        }
    })
}

- (void)callbackForLinkMicUser:(PLVLinkMicOnlineUser *)linkMicOnlineUser videoMuted:(BOOL)videoMuted{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:linkMicOnlineUser:videoMuted:)]) {
            [self.delegate plvStreamerPresenter:self linkMicOnlineUser:linkMicOnlineUser videoMuted:videoMuted];
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

- (void)callbackForCurrentPushStreamValidDuration{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:currentPushStreamValidDuration:)]) {
            [self.delegate plvStreamerPresenter:self currentPushStreamValidDuration:self.pushStreamValidDuration];
        }
    })
}

- (void)callbackForCurrentReconnectingThisTimeDuration{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:currentReconnectingThisTimeDuration:)]) {
            [self.delegate plvStreamerPresenter:self currentReconnectingThisTimeDuration:self.reconnectingThisTimeDuration];
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

- (void)callbackForLocalUserCameraTorchOpenChanged{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:localUserCameraTorchOpenChanged:)]) {
            [self.delegate plvStreamerPresenter:self localUserCameraTorchOpenChanged:self.currentCameraTorchOpen];
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

- (void)callbackForStreamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:streamStateUpdate:streamStateDidChanged:)]) {
            [self.delegate plvStreamerPresenter:self streamStateUpdate:newestStreamState streamStateDidChanged:streamStateDidChanged];
        }
    })
}

- (void)callbackForCurrentRemotePushDuration{
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:currentRemotePushDuration:)]) {
            [self.delegate plvStreamerPresenter:self currentRemotePushDuration:self.currentRemotePushDuration];
        }
    })
}

- (void)callbackForDidOccurError:(NSError *)error{
    if (!error) { return; }
    NSString * fullErrorCodeString = [NSString stringWithFormat:@"SP%ld",(long)error.code];
    NSError * underlyingError = error.userInfo[NSUnderlyingErrorKey];
    int count = 0;
    while ((underlyingError && [underlyingError isKindOfClass:NSError.class] && count < 5)) {
        fullErrorCodeString = [fullErrorCodeString stringByAppendingFormat:@",%ld",(long)underlyingError.code];
        underlyingError = underlyingError.userInfo[NSUnderlyingErrorKey];
        count ++;
    }
    plv_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(plvStreamerPresenter:didOccurError:fullErrorCode:)]) {
            [self.delegate plvStreamerPresenter:self didOccurError:error fullErrorCode:fullErrorCodeString];
        }
    })
}

#pragma mark Getter
- (NSString *)linkMicUserId{
    if (!_linkMicUserId) {
        if (self.viewerType == PLVRoomUserTypeTeacher) { // 若是讲师，则linkMicId为channelId
            _linkMicUserId = self.channelId;
        }else if (self.viewerType == PLVRoomUserTypeGuest){ // 若是嘉宾，则linkMicId为聊天室Id
            _linkMicUserId = self.userId;
        }else{
            NSInteger timeInterval = (NSInteger)[[NSDate date] timeIntervalSince1970];
            _linkMicUserId = @(timeInterval).stringValue;
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"create linkMicUserId failed, will use timeInterval");
        }
    }
    return _linkMicUserId;
}

- (NSString *)rtcType{
    return [PLVRoomDataManager sharedManager].roomData.menuInfo.rtcType;
}

- (NSString *)stream{
    return [PLVRoomDataManager sharedManager].roomData.stream;
}

- (NSString *)currentStream{
    return [PLVRoomDataManager sharedManager].roomData.currentStream;
}

- (NSString *)rtmpUrl{
    return [PLVRoomDataManager sharedManager].roomData.rtmpUrl;
}

- (NSString *)channelId{
    return [PLVRoomDataManager sharedManager].roomData.channelId;
}

- (NSString *)channelAccount{
    return [PLVRoomDataManager sharedManager].roomData.channelAccountId;
}

- (NSString *)userId{
    return [PLVSocketManager sharedManager].viewerId;
}

- (PLVRoomUserType)viewerType{
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
}

- (NSString *)linkMicUserNickname{
    return [PLVSocketManager sharedManager].viewerName;
}

- (NSString *)linkMicUserAvatar{
    return [PLVSocketManager sharedManager].avatarUrl;
}

- (NSString *)linkMicUserActor {
    return [PLVSocketManager sharedManager].actor;
}

- (BOOL)channelGuestManualJoinLinkMic{
    return [PLVRoomDataManager sharedManager].roomData.channelGuestManualJoinLinkMic;
}

- (PLVChannelClassManager *)channelClassManager{
    if (!_channelClassManager) {
        _channelClassManager = [[PLVChannelClassManager alloc] init];
        _channelClassManager.delegate = self;
    }
    return _channelClassManager;
}


#pragma mark - [ Event ]
#pragma mark Timer
- (void)linkMicTimerEvent:(NSTimer *)timer{
    if (self.viewerType == PLVRoomUserTypeTeacher && !self.pushStreamStarted) { return; }
    if (self.viewerType == PLVRoomUserTypeGuest && (self.currentStreamState != PLVChannelLiveStreamState_Live)) { return; }
    if (self.rtcRoomJoinStatus != PLVStreamerPresenterRoomJoinStatus_Joined) { return; }
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
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"request linkmic online user list failed : %@",error);
        }];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeStreamer, @"link mic status refresh failed, current socket status:%lu",(unsigned long)[PLVSocketManager sharedManager].status);
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

    } else if ([subEvent containsString:@"finishClass"]){ // 下课事件
        if (self.viewerType == PLVRoomUserTypeGuest) {
            self.classStarted = NO;
            [self guestLeaveRTCChannel];
        }
    }else if ([subEvent isEqualToString:@"onSliceID"]) { // 是否开启全体静音
        NSString * avConnectMode = jsonDict[@"data"][@"avConnectMode"];
        if ([PLVFdUtil checkStringUseable:avConnectMode] &&
            [avConnectMode isEqualToString:@"audio"]) {
            self.roomAllMicMute = YES;
        }
    } else if ([subEvent containsString:@"MUTE_USER_MICRO"]){
        [self handleSocket_MUTE_USER_MICRO:jsonDict];
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
    } else if ([event isEqualToString:@"joinAnswer"]) {
        [self handleSocket_joinAnswer:jsonDict];
    }
}

#pragma mark PLVRTCStreamerManagerDelegate
- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager localUserJoinRTCChannelComplete:(NSString *)channelId{
    [self changeRoomJoinStatusAndCallback:PLVStreamerPresenterRoomJoinStatus_Joined];
    
    if (self.viewerType == PLVRoomUserTypeGuest) {
        [self emitLocalGuestJoinResponse:nil];
    }
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager localUserLeaveRTCChannelComplete:(NSString *)channelId{
    [self changeRoomJoinStatusAndCallback:PLVStreamerPresenterRoomJoinStatus_NotJoin];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager sessionIdDidChanged:(NSString *)sessionId{
    [self callbackForSessionIdDidChanged];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager networkQualityDidChanged:(PLVBLinkMicNetworkQuality)networkQuality{
    [self callbackForNetworkQualityDidChanged];
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

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager currentPushStreamValidDuration:(NSTimeInterval)pushStreamValidDuration{
    [self callbackForCurrentPushStreamValidDuration];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager currentReconnectingThisTimeDuration:(NSInteger)reconnectingThisTimeDuration{
    [self callbackForCurrentReconnectingThisTimeDuration];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager remoteUser:(NSString *)userRTCId audioMuted:(BOOL)audioMuted{
    [self muteUser:userRTCId mediaType:@"audio" mute:audioMuted];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager remoteUser:(NSString *)userRTCId videoMuted:(BOOL)videoMuted{
    [self muteUser:userRTCId mediaType:@"video" mute:videoMuted];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager reportAudioVolumeOfSpeakers:(NSDictionary<NSString *,NSNumber *> *)volumeDict{
    [self updateLinkMicUserVolumeWithVolumeDictionary:volumeDict];
    [self callbackForReportAudioVolumeOfSpeakers:volumeDict];
}

- (void)plvRTCStreamerManager:(PLVRTCStreamerManager *)manager didOccurError:(NSError *)error{
    PLVStreamerPresenterErrorCode finalErrorCode = PLVStreamerPresenterErrorCode_UnknownError;
    if (error.code >= PLVRTCStreamerManagerErrorCode_PushStreamFailedSetupStreamError &&
        error.code <= PLVRTCStreamerManagerErrorCode_PushStreamFailedSessionIllegal) {
        finalErrorCode = PLVStreamerPresenterErrorCode_StartClassFailedNetError;
    }
    
    if (error.code == PLVRTCStreamerManagerErrorCode_UpdateRTCTokenFailedAuthError) {
        finalErrorCode = PLVStreamerPresenterErrorCode_UpdateRTCTokenFailedNetError;
    }
    
    NSError * finalError = [self errorWithCode:finalErrorCode errorDescription:nil];
    finalError = PLVErrorWithUnderlyingError(finalError, error);
    [self callbackForDidOccurError:finalError];
}

#pragma mark PLVChannelClassManagerDelegate
- (void)plvChannelClassManager:(PLVChannelClassManager *)manager currentPushDuration:(NSTimeInterval)currentPushDuration{
    [self callbackForCurrentRemotePushDuration];
}

@end
