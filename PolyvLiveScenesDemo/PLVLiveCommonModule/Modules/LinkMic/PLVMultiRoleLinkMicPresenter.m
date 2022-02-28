//
//  PLVMultiRoleLinkMicPresenter.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVMultiRoleLinkMicPresenter.h"

/// 模块
#import "PLVRoomDataManager.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

/// 默认值
/// (注意:此处为默认值，最终以外部的设置为准。若外部未设置，才使用此默认值)
static const BOOL kMicDefaultOpen = NO;      // 麦克风按钮 默认开关值
static const BOOL kCameraDefaultOpen = NO;   // 摄像头按钮 默认开关值
static const BOOL kCameraDefaultFront = YES; // 摄像头 默认前置值

/// 上课不超过30秒，此时收到所有学员的login消息均要发送joinResponse消息
static const NSTimeInterval kAllJoinResponseInterval = 30.0;

@interface PLVMultiRoleLinkMicPresenter ()<
PLVSocketManagerProtocol,
PLVLinkMicManagerDelegate
>

#pragma mark 状态
@property (nonatomic, assign) BOOL micDefaultOpen; // 麦克风是否开启 YES-开启 NO-关闭，默认值 NO
@property (nonatomic, assign) BOOL cameraDefaultOpen; // 摄像头是否开启 YES-开启 NO-关闭，默认值 NO
@property (nonatomic, assign) BOOL cameraDefaultFront; // 摄像头是否前置 YES-前置 NO-后置，默认值 YES
@property (nonatomic, assign) BOOL inRTCRoom; // 是否已进入RTC频道中
@property (nonatomic, assign) BOOL linkingMic; // 是否已连麦
@property (nonatomic, assign) BOOL delayResponse; // 是否需要响应joinResponse消息，用于学生端尚未加入频道即收到joinResponse消息的情况
@property (nonatomic, assign) int originalIdleTimerDisabled; // 是否修改过系统的常亮状态（0 表示未记录；负值对应NO状态；正值对应YES状态）
@property (nonatomic, assign) PLVBLinkMicNetworkQuality lastNotifyNetworkQuality; /// 上次回调通知的网络状态

#pragma mark 对象
@property (nonatomic, strong) UIView *rtcScreenStreamView; // RTC屏幕流渲染画布

#pragma mark 数据
@property (nonatomic, strong) PLVLinkMicOnlineUser *teacherLinkMicUser; // 讲师连麦用户，当前用户即为讲师时，该属性与localUser等同
@property (nonatomic, strong) PLVLinkMicOnlineUser *groupLeaderLinkMicUser; // 分组时，当前用户所在分组的组长连麦用户，当前用户即为组长时，该属性与localUser等同
@property (nonatomic, strong) PLVLinkMicOnlineUser *localUser; // 当前连麦用户
@property (nonatomic, strong) NSMutableArray <PLVLinkMicOnlineUser *> *linkMicUserArray; // 当前连麦用户数组
@property (nonatomic, assign) BOOL startClassInHalfMin; // YES：上课不超过30秒，此时收到所有学员的login消息均要发送joinResponse消息
@property (nonatomic, strong) NSMutableArray <NSString *> *emitedJoinResponseUserIdArray; // startClassInHalfMin为YES时，记录已发送joinRsponse消息的用户ID
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSDictionary *> *prerecordUserMediaStatusDict; // 用于提前记录用户媒体状态的字典
@property (nonatomic, strong) NSMutableArray <NSString *> *unsubscribeScreenStreamArray; // 用于记录尚未订阅的加入房间的远端屏幕流<连麦ID>

#pragma mark 外部数据封装
@property (nonatomic, copy, readonly) NSString *roomId;
@property (nonatomic, copy, readonly) NSString *channelId;
@property (nonatomic, copy, readonly) NSString *sessionId;
@property (nonatomic, copy, readonly) NSString *userId;
@property (nonatomic, copy, readonly) NSString *linkMicUserId;
@property (nonatomic, copy, readonly) NSString *linkMicUserNickname;
@property (nonatomic, copy, readonly) NSString *linkMicUserAvatar;
@property (nonatomic, copy, readonly) NSString *linkMicUserActor;
@property (nonatomic, assign, readonly) PLVSocketUserType userType;

#pragma mark 功能对象
@property (nonatomic, strong) PLVLinkMicManager *linkMicManager; // 连麦管理器
@property (nonatomic, strong) NSTimer *linkMicTimer;

@end

@implementation PLVMultiRoleLinkMicPresenter {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
    // 操作数组执行队列
    dispatch_queue_t linkMicUserArrayQueue;
    /// 读写unsubscribeScreenStreamArray数组的信号量
    dispatch_semaphore_t _unsubscribeScreenStreamArrayLock;
}

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    if (self = [super init]) {
        self.originalIdleTimerDisabled = 0;
        self.prerecordUserMediaStatusDict = [[NSMutableDictionary <NSString *, NSDictionary *> alloc] init];
        
        self.micDefaultOpen = kMicDefaultOpen;
        self.cameraDefaultOpen = kCameraDefaultOpen;
        self.cameraDefaultFront = kCameraDefaultFront;
        
        // 连麦成员数组操作、读写队列
        linkMicUserArrayQueue = dispatch_queue_create("com.PLVLiveScenesDemo.PLVMultiRoleLinkMicPresenter", DISPATCH_QUEUE_CONCURRENT);
        self.linkMicUserArray = [[NSMutableArray<PLVLinkMicOnlineUser *> alloc] init];
        
        /// 添加 socket 事件监听
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    }
    return self;
}

- (void)dealloc {
    [self leaveRTCChannel];
    _linkMicManager.delegate = nil;
}

#pragma mark - [ Public Method ]

#pragma mark Getter

- (BOOL)currentMicOpen {
    return self.localUser.currentMicOpen;
}

- (BOOL)currentCameraOpen {
    return self.localUser.currentCameraOpen;
}

- (BOOL)currentCameraShouldShow {
    return self.localUser.currentCameraShouldShow;
}

- (BOOL)currentCameraFront {
    return self.localUser.currentCameraFront;
}

- (UIView *)rtcScreenStreamView {
    if (!_rtcScreenStreamView) {
        _rtcScreenStreamView = [[UIView alloc] init];
        _rtcScreenStreamView.frame = CGRectMake(0, 0, 1, 1);
        _rtcScreenStreamView.clipsToBounds = YES;
    }
    return _rtcScreenStreamView;
}

#pragma mark RTC房间管理（通用）

- (void)joinRTCChannel {
    if (self.inRTCRoom) {
        return;
    }
    
    // 启动获取连麦列表计时器
    [self startLinkMicListTimer];
    
    // 获取连麦Token
    __weak typeof(self) weakSelf = self;
    [self updateLinkMicTokenWithSuccessHandler:^{ // 加入 RTC 频道
        int res = [weakSelf.linkMicManager joinRtcChannelWithChannelId:weakSelf.roomId userLinkMicId:weakSelf.linkMicUserId];
        
        if (res == 0) {
            if (weakSelf.userType == PLVSocketUserTypeTeacher) {
                [weakSelf autoLinkMic];
            }
        } else { // 加入 RTC 频道失败
            [weakSelf notifyJoinRTCChannelFailure];
        }
    }];
}

- (void)leaveRTCChannel {
    if (!self.inRTCRoom) {
        return;
    }
    // 停止计时器
    [self stopLinkMicListTimer];
    // 取消订阅所有在线用户的 RTC 流
    [self unsubscribeStreamAllLinkMicUser];
    // 清空在线用户数组
    [self removeAllLinkMicUser];
    // 退出 RTC 频道
    [self.linkMicManager leaveRtcChannel];
    // 状态位恢复
    self.delayResponse = NO;
    self.linkingMic = NO;
    self.localUser = nil;
    self.teacherLinkMicUser = nil;
    self.groupLeaderLinkMicUser = nil;
    self.linkMicManager = nil;
    self.startClassInHalfMin = NO;
    [self.emitedJoinResponseUserIdArray removeAllObjects];
    [self.prerecordUserMediaStatusDict removeAllObjects];
    [self.unsubscribeScreenStreamArray removeAllObjects];
}

- (void)changeChannel {
    // 取消订阅所有在线用户的 RTC 流
    [self unsubscribeStreamAllLinkMicUser];
    // 清空在线用户数组
    [self removeAllLinkMicUser];
    // 退出 RTC 频道
    [self.linkMicManager leaveRtcChannel];
    
    // 状态位恢复
    self.delayResponse = NO;
    self.linkingMic = NO;
    self.localUser = nil;
    self.groupLeaderLinkMicUser = nil;
    self.startClassInHalfMin = NO;
    [self.emitedJoinResponseUserIdArray removeAllObjects];
    [self.prerecordUserMediaStatusDict removeAllObjects];
    [self.unsubscribeScreenStreamArray removeAllObjects];
    
    // 获取连麦Token
    __weak typeof(self) weakSelf = self;
    [self updateLinkMicTokenWithSuccessHandler:^{ // 加入 RTC 频道
        int res = [weakSelf.linkMicManager joinRtcChannelWithChannelId:weakSelf.roomId userLinkMicId:weakSelf.linkMicUserId];
        if (res != 0) { // 加入 RTC 频道失败
            [weakSelf notifyJoinRTCChannelFailure];
        }
    }];
}

#pragma mark 本地用户管理（通用）

- (void)openLocalUserMic:(BOOL)open {
    self.micDefaultOpen = open;
    
    if (self.linkMicManager) {
        self.linkMicManager.micDefaultOpen = open;
        [self.linkMicManager openLocalUserMic:open];
    }
    
    if (self.localUser) {
        [self.localUser updateUserCurrentMicOpen:open];
    }
}

- (void)openLocalUserCamera:(BOOL)open {
    self.cameraDefaultOpen = open;
    
    if (self.linkMicManager) {
        self.linkMicManager.cameraDefaultOpen = open;
        [self.linkMicManager openLocalUserCamera:open];
    }
    
    if (self.localUser) {
        [self.localUser updateUserCurrentCameraOpen:open];
    }
}

- (void)switchLocalUserCamera:(BOOL)front {
    self.cameraDefaultFront = front;
    
    if (self.linkMicManager) {
        self.linkMicManager.cameraDefaultFront = front;
        [self.linkMicManager switchLocalUserCamera:front];
    }
    
    if (self.localUser) {
        [self.localUser updateUserCurrentCameraFront:front];
    }
}

- (void)setupStreamQuality:(PLVBLinkMicStreamQuality)streamQuality {
    [self.linkMicManager setupStreamQuality:streamQuality];
}

- (void)answerForJoinResponse {
    [[PLVSocketManager sharedManager] emitEvent:@"joinAnswer" content:@{@"status": @(1)}];
    if (self.inRTCRoom) {
        [self localUserJoinLinkMic];
    } else {
        self.delayResponse = YES;
    }
}

#pragma mark 连麦用户数组管理（通用）

- (NSArray <PLVLinkMicOnlineUser *> *)currentLinkMicUserArray {
    __block NSArray *linkMicUserArray = @[];
    dispatch_sync(linkMicUserArrayQueue, ^{
        linkMicUserArray = [self.linkMicUserArray copy];
    });
    return linkMicUserArray;
}

- (NSInteger)linkMicUserIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlock {
    if (!filtrateBlock) {
        return -1;
    }
    
    __block NSInteger targetIndex = -1;
    [self.currentLinkMicUserArray enumerateObjectsUsingBlock:^(PLVLinkMicOnlineUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (filtrateBlock(obj)) {
            targetIndex = idx;
            *stop = YES;
        }
    }];
    return targetIndex;
}

- (PLVLinkMicOnlineUser *)linkMicUserWithIndex:(NSInteger)index {
    __block PLVLinkMicOnlineUser *user = nil;
    dispatch_sync(linkMicUserArrayQueue, ^{
        if (index < self.linkMicUserArray.count) {
            user = self.linkMicUserArray[index];
        }
    });
    return user;
}

- (PLVLinkMicOnlineUser *)linkMicUserWithLinkMicId:(NSString *)linkMicId {
    if (![PLVFdUtil checkStringUseable:linkMicId]) {
        return nil;
    }
    
    __block PLVLinkMicOnlineUser *linkMicUser = nil;
    [self.currentLinkMicUserArray enumerateObjectsUsingBlock:^(PLVLinkMicOnlineUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.linkMicUserId isEqualToString:linkMicId]) {
            linkMicUser = obj;
            *stop = YES;
        }
    }];
    return linkMicUser;
}

- (void)updateGroudLeader {
    NSString *groupLeaderId = [PLVHiClassManager sharedManager].groupLeaderId;
    if (![PLVFdUtil checkStringUseable:groupLeaderId]) {
        return;
    }
    
    self.groupLeaderLinkMicUser.groupLeader = NO;
    PLVLinkMicOnlineUser *updateGroupLeader = [self linkMicUserWithLinkMicId:groupLeaderId];
    if (updateGroupLeader) { // 对新的组长数据对象重新排序，将其插入到数组前面（具体的业务逻辑已在[-addLinkMicUser:]里面处理了
        [self removeLinkMicUserWithLinkMicId:groupLeaderId];
        [self addLinkMicUser:updateGroupLeader];
    }
}

#pragma mark 连麦用户操作管理（以下API仅讲师身份时有效）

- (void)allowUserLinkMic:(PLVChatUser *)chatUser {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅在当前用户为讲师或组长时该方法才有效
        return;
    }
    
    if (!chatUser ||
        ![chatUser isKindOfClass:[PLVChatUser class]]) {
        return;
    }
    
    if (!chatUser.userId ||
        [chatUser.userId isEqualToString:self.userId] ||
        chatUser.userType == PLVRoomUserTypeTeacher) { // user 为自己或讲师时无需发送 joinResponse 消息
        return;
    }
    
    NSDictionary *userDict = [self userDictionayWithChatUser:chatUser];
    if ([PLVFdUtil checkDictionaryUseable:userDict]) {
        __weak typeof(self) weakSelf = self;
        [self emitJoinResponseEventWithUserDict:userDict needAnswer:YES success:^(PLVLinkMicOnlineUser *linkMicUser) {
            [weakSelf notifyDidJoinUserLinkMic:linkMicUser];
        }];
    }
}

- (void)closeUserLinkMic:(PLVLinkMicOnlineUser *)linkMicUser {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅在当前用户为讲师或组长时该方法才有效
        return;
    }
    
    if (!linkMicUser ||
        ![linkMicUser isKindOfClass:[PLVLinkMicOnlineUser class]]) {
        return;
    }
    
    if (!linkMicUser.linkMicUserId ||
        [linkMicUser.linkMicUserId isEqualToString:self.linkMicUserId] ||
        linkMicUser.userType == PLVSocketUserTypeTeacher) { // user 为自己或讲师时无需发送’挂断‘消息
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self emitCloseLinkMicEventWithLinkMicId:linkMicUser.linkMicUserId success:^{
        [weakSelf notifyDidCloseUserLinkMic:linkMicUser];
    }];
}

- (BOOL)closeAllLinkMicUser {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅在当前用户为讲师或组长时该方法才有效
        return NO;
    }
    
    BOOL success = [[PLVSocketManager sharedManager] emitPermissionMessageForCloseAllLinkMicWithTimeout:5.0 callback:nil];
    if (success) {
        [self removeAllLinkMicUserExceptTeacherAndGroupLeader];
        [self unsubscribeStreamAllLinkMicUserExceptTeacherAndGroupLeader];
    }
    return success;
}

/// 开启或关闭‘某位远端用户’的麦克风
- (void)muteMicrophoneWithLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser mute:(BOOL)mute {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅在当前用户为讲师或组长时该方法才有效
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.linkMicManager muteMicrophoneWithRemoteUserId:linkMicUser.linkMicUserId mute:mute completed:^(BOOL success) {
        if (success) {
            [weakSelf notifyDidLinkMicUser:linkMicUser audioMuted:mute];
        }
    }];
}

/// 开启或关闭’某位远端用户的‘摄像头
- (void)muteCameraWithLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser mute:(BOOL)mute {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅在当前用户为讲师或组长时该方法才有效
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.linkMicManager muteCameraWithRemoteUserId:linkMicUser.linkMicUserId mute:mute completed:^(BOOL success) {
        if (success) {
            [weakSelf notifyDidLinkMicUser:linkMicUser videoMuted:mute];
        }
    }];
}

/// 关闭/开启‘全部连麦用户’的麦克风
- (void)muteAllLinkMicUserMicrophone:(BOOL)mute {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅在当前用户为讲师或组长时该方法才有效
        return;
    }
    
    for (PLVLinkMicOnlineUser *linkMicUser in self.currentLinkMicUserArray) {
        [self.linkMicManager muteMicrophoneWithRemoteUserId:linkMicUser.linkMicUserId mute:mute completed:nil];
    }
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (NSString *)roomId {
    if ([PLVHiClassManager sharedManager].groupState == PLVHiClassGroupStateInGroup) {
        return [PLVHiClassManager sharedManager].groupId;
    } else {
        return self.channelId;
    }
}

- (NSString *)channelId {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.channelId;
}

- (NSString *)sessionId {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.sessionId;
}

- (PLVSocketUserType)userType {
    return [PLVSocketManager sharedManager].userType;
}

- (NSString *)userId {
    return [PLVSocketManager sharedManager].viewerId;
}

- (NSString *)linkMicUserId {
    return [PLVSocketManager sharedManager].linkMicId;
}

- (NSString *)linkMicUserNickname {
    return [PLVSocketManager sharedManager].viewerName;
}

- (NSString *)linkMicUserAvatar {
    return [PLVSocketManager sharedManager].avatarUrl;
}

- (NSString *)linkMicUserActor {
    return [PLVSocketManager sharedManager].actor;
}

#pragma mark RTC房间管理（通用）

- (void)updateLinkMicTokenWithSuccessHandler:(void (^)(void))successHandler {
    self.linkMicManager = [PLVLinkMicManager linkMicManagerWithRTCType:@"urtc"];
    self.linkMicManager.delegate = self;
    self.linkMicManager.micDefaultOpen = self.micDefaultOpen;
    self.linkMicManager.cameraDefaultOpen = self.cameraDefaultOpen;
    self.linkMicManager.cameraDefaultFront = self.cameraDefaultFront;
    
    PLVLinkMicGetTokenModel *getTokenModel = [self createGetLinkMicTokenModel];
    
    __weak typeof(self) weakSelf = self;
    [self.linkMicManager updateVClassRTCTokenWith:getTokenModel completion:^(BOOL updateResult) {
        if (updateResult) {
            if (successHandler) {
                successHandler();
            }
        } else { // 触发获取连麦token失败回调
            [weakSelf notifyJoinRTCChannelFailure];
        }
    }];
}

- (PLVLinkMicGetTokenModel *)createGetLinkMicTokenModel {
    PLVLinkMicGetTokenModel *getTokenModel = [[PLVLinkMicGetTokenModel alloc] init];
    getTokenModel.channelType = PLVChannelTypePPT;
    getTokenModel.courseCode = [PLVHiClassManager sharedManager].courseCode;
    getTokenModel.lessonId = [PLVHiClassManager sharedManager].lessonId;
    getTokenModel.channelId = self.channelId;
    getTokenModel.sessionId = self.sessionId;
    getTokenModel.viewerId = getTokenModel.userId = self.userId;
    getTokenModel.nickname = self.linkMicUserNickname;
    
    if ([PLVHiClassManager sharedManager].groupState == PLVHiClassGroupStateInGroup) {
        getTokenModel.groupId = [PLVHiClassManager sharedManager].groupId;
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    getTokenModel.userType = [PLVRoomUser userTypeStringWithUserType:roomUser.viewerType];
    return getTokenModel;
}

#pragma mark RTC流管理（通用）

- (void)subscribeStreamWithLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser
                      streamSourceType:(PLVBRTCSubscribeStreamSourceType)streamSourceType {
    if (!linkMicUser ||
        ![linkMicUser isKindOfClass:[PLVLinkMicOnlineUser class]]) {
        return;
    }
    
    PLVBRTCSubscribeStreamMediaType mediaType = PLVBRTCSubscribeStreamMediaType_Audio | PLVBRTCSubscribeStreamMediaType_Video;
    BOOL isAddUserTeacher = linkMicUser.userType == PLVBSocketUserTypeTeacher;
    PLVHiClassManager *manager = [PLVHiClassManager sharedManager];
    BOOL isAddUserGroupLeader = (manager.groupState == PLVHiClassGroupStateInGroup && [linkMicUser.userId isEqualToString:manager.groupLeaderId]);
    BOOL isTeacherInGroup = manager.teacherInGroup;
    if (isAddUserTeacher || (isAddUserGroupLeader && !isTeacherInGroup)) { // 讲师身份\讲师不在时的组长身份，使用单一的流订阅方式
        if (streamSourceType == -1) { // 检查连麦列表数据发现的未订阅流用户，未知流类型
            BOOL prerecord = [self readUnsubscribeScreenStreamRecordWithLinkMicId:linkMicUser.linkMicUserId];
            streamSourceType = prerecord ? PLVBRTCSubscribeStreamSourceType_Screen : PLVBRTCSubscribeStreamSourceType_Camera;
            [self removeRecordUnsubscribeScreenStreamWihtLinkMicId:linkMicUser.linkMicUserId];
            if (!prerecord && isAddUserTeacher) { // 未收到讲师的流加入教室，标注streamLeaveRoom为YES用于UI显示讲师流不在教室时的占位图
                linkMicUser.streamLeaveRoom = YES;
            }
        }
        
        if (streamSourceType == PLVBRTCSubscribeStreamSourceType_Screen) { // 屏幕流应订阅在 rtcScreenStreamView 视图上
            plv_dispatch_main_async_safe(^{
                if (self.rtcScreenStreamView &&
                    (self.rtcScreenStreamView.subviews.count > 0 || self.rtcScreenStreamView.layer.sublayers.count > 0)) {
                    return;
                }
                [self.linkMicManager subscribeStreamWithRTCUserId:linkMicUser.linkMicUserId
                                                     renderOnView:self.rtcScreenStreamView
                                                        mediaType:mediaType
                                                    subscribeMode:PLVBRTCSubscribeStreamSubscribeMode_Screen];
            })
            [self notifyDidTeacherScreenStreamRenderd];
        } else { // 摄像头流订阅在 linkMicUser.rtcView 上
            plv_dispatch_main_async_safe(^{
                if (linkMicUser.rtcRendered) {
                    return;
                }
                [self.linkMicManager subscribeStreamWithRTCUserId:linkMicUser.linkMicUserId
                                                     renderOnView:linkMicUser.rtcView
                                                        mediaType:mediaType
                                                    subscribeMode:PLVBRTCSubscribeStreamSubscribeMode_Camera];
            })
        }
    } else { // 学员身份使用屏幕流优先的混合流订阅方式
        plv_dispatch_main_async_safe(^{
            if (linkMicUser.rtcRendered) {
                return;
            }
            [self.linkMicManager subscribeStreamWithRTCUserId:linkMicUser.linkMicUserId
                                                 renderOnView:linkMicUser.rtcView
                                                    mediaType:mediaType];
        })
    }
}

- (void)unsubscribeStreamWithRTCUserId:(NSString *)linkMicId {
    if (![PLVFdUtil checkStringUseable:linkMicId]) {
        return;
    }
    
    plv_dispatch_main_async_safe(^{
        [self.linkMicManager unsubscribeStreamWithRTCUserId:linkMicId];
    })
}

- (void)unsubscribeStreamAllLinkMicUserExceptTeacherAndGroupLeader {
    for (PLVLinkMicOnlineUser *linkMicUser in self.currentLinkMicUserArray) {
        if (linkMicUser.userType != PLVSocketUserTypeTeacher &&
            ![linkMicUser.linkMicUserId isEqualToString:[PLVHiClassManager sharedManager].groupLeaderId]) {
            [self unsubscribeStreamWithRTCUserId:linkMicUser.linkMicUserId];
        }
    }
}

- (void)unsubscribeStreamAllLinkMicUser {
    for (PLVLinkMicOnlineUser *linkMicUser in self.currentLinkMicUserArray) {
        [self unsubscribeStreamWithRTCUserId:linkMicUser.linkMicUserId];
    }
}

- (void)recordUnsubscribeScreenStreamWithLinkMicId:(NSString *)linkMicId {
    if (![PLVFdUtil checkStringUseable:linkMicId]) {
        return;
    }
    
    if (!self.unsubscribeScreenStreamArray) {
        self.unsubscribeScreenStreamArray = [[NSMutableArray alloc] init];
    }
    
    dispatch_semaphore_wait(_unsubscribeScreenStreamArrayLock, DISPATCH_TIME_FOREVER);
    [self.unsubscribeScreenStreamArray addObject:linkMicId];
    dispatch_semaphore_signal(_unsubscribeScreenStreamArrayLock);
}

- (BOOL)readUnsubscribeScreenStreamRecordWithLinkMicId:(NSString *)linkMicId {
    if (![PLVFdUtil checkArrayUseable:self.unsubscribeScreenStreamArray]) {
        return NO;
    }
    
    dispatch_semaphore_wait(_unsubscribeScreenStreamArrayLock, DISPATCH_TIME_FOREVER);
    __block BOOL prerecord = NO;
    [self.unsubscribeScreenStreamArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:linkMicId]) {
            prerecord = YES;
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_unsubscribeScreenStreamArrayLock);
    
    return prerecord;
}

- (void)removeRecordUnsubscribeScreenStreamWihtLinkMicId:(NSString *)linkMicId {
    if (![PLVFdUtil checkStringUseable:linkMicId] ||
        ![PLVFdUtil checkArrayUseable:self.unsubscribeScreenStreamArray]) {
        return;
    }
    
    dispatch_semaphore_wait(_unsubscribeScreenStreamArrayLock, DISPATCH_TIME_FOREVER);
    [[self.unsubscribeScreenStreamArray copy] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:linkMicId]) {
            [self.unsubscribeScreenStreamArray removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    dispatch_semaphore_signal(_unsubscribeScreenStreamArrayLock);
}

#pragma mark 本地用户管理（通用）

/// 创建本地用户，新增状态监听 block
- (void)createLocalUser {
    self.localUser = [PLVLinkMicOnlineUser localUserModelWithUserId:self.userId
                                                      linkMicUserId:self.linkMicUserId
                                                           nickname:self.linkMicUserNickname
                                                          avatarPic:self.linkMicUserAvatar
                                                           userType:self.userType
                                                              actor:self.linkMicUserActor];
    
    __weak typeof(self) weakSelf = self;
    
    /// 监听’本地用户‘摄像头开关、麦克风开关、前后置摄像头切换请求
    self.localUser.wantOpenMicBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantOpen) {
        [weakSelf openLocalUserMic:wantOpen];
    };
    self.localUser.wantOpenCameraBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantOpen) {
        [weakSelf openLocalUserCamera:wantOpen];
    };
    self.localUser.wantSwitchFrontCameraBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantFront) {
        [weakSelf switchLocalUserCamera:wantFront];
    };
    
    /// 监听‘本地用户’摄像头、麦克风状态变化
    [self.localUser addMicOpenChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [weakSelf notifyLocalUserMicOpenChanged];
    } blockKey:self];
    [self.localUser addCameraShouldShowChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [weakSelf notifyLocalUserCameraShouldShowChanged];
    } blockKey:self];
    [self.localUser addCameraFrontChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [weakSelf notifyLocalUserCameraFrontChanged];
    } blockKey:self];
    
    // 初始化‘本地用户’摄像头、麦克风状态
    [self.localUser updateUserCurrentCameraOpen:self.cameraDefaultOpen];
    [self.localUser updateUserCurrentCameraFront:self.cameraDefaultFront];
    [self.localUser updateUserCurrentMicOpen:self.micDefaultOpen];
}

- (void)localUserJoinLinkMic {
    if (!self.localUser) {
        [self createLocalUser];
    }
    if ([PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
        self.localUser.groupLeader = YES;
    }
    
    self.linkingMic = YES;
    BOOL add = [self addLinkMicUser:self.localUser];
    [self subscribeStreamWithLinkMicUser:self.localUser streamSourceType:PLVBRTCSubscribeStreamSourceType_Camera];
    if (add && self.userType == PLVSocketUserTypeSCStudent && ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 触发当前用户（学员）被上台回调
        [self notifyLocalUserLinkMicStatusChanged];
    }
}

- (void)localUserLeaveLinkMic {
    if (self.userType == PLVSocketUserTypeTeacher) { // 仅在当前用户为学员时该方法才有效
        return;
    }
    
    self.linkingMic = NO;
    [self.linkMicManager closeLinkMicWithRemoteUserId:self.linkMicUserId completed:nil];
    BOOL exist = [self removeLinkMicUserWithLinkMicId:self.linkMicUserId];
    [self unsubscribeStreamWithRTCUserId:self.linkMicUserId];
    if (exist && ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 触发当前用户（学员）被下台回调
        [self notifyLocalUserLinkMicStatusChanged];
    }
}

#pragma mark 连麦用户数组管理（通用）

/// 新增连麦用户到连麦用户数组中
- (BOOL)addLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser {
    if (!linkMicUser ||
        ![linkMicUser isKindOfClass:[PLVLinkMicOnlineUser class]]) { // 确保参数合法
        return NO;
    }
    
    // 待插入数据已存在数组 linkMicUserArray 中
    if ([self linkMicUserWithLinkMicId:linkMicUser.linkMicUserId]) {
        if (linkMicUser.streamLeaveRoom) { // 讲师流重新进入教室时，标注streamLeaveRoom为NO用于UI移除讲师流不在教室时的占位图
            linkMicUser.streamLeaveRoom = NO;
            [self notifyLinkMicUserArrayChanged];
        }
        return NO;
    }
    
    BOOL local = [linkMicUser.linkMicUserId isEqualToString:self.linkMicUserId];
    if (local) { // 新加入用户为当前用户时
        if (!self.localUser) {
            [self createLocalUser];
        }
    } else { // 新加入用户为其他远端用户时，增加事件监听
        if (self.userType == PLVSocketUserTypeTeacher ||
            [PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 讲师特有事件
            __weak typeof(self) weakSelf = self;
            linkMicUser.wantCloseLinkMicBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) { // 将用户下台
                [weakSelf closeUserLinkMic:onlineUser];
            };
            
            linkMicUser.wantBrushAuthBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL auth) { // 授予/取消授予画笔权限
                [weakSelf notifyDidAuthUserBrush:onlineUser auth:auth];
            };
            
            linkMicUser.wantGrantCupBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) { // 授予奖杯
                [weakSelf notifyDidGrantUserCup:onlineUser];
            };
            
            linkMicUser.wantOpenMicBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantOpen) { // 静音/取消静音
                [weakSelf muteMicrophoneWithLinkMicUser:onlineUser mute:!wantOpen];
            };
            
            linkMicUser.wantOpenCameraBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser, BOOL wantOpen) { // 关闭/取消关闭摄像头
                [weakSelf muteCameraWithLinkMicUser:onlineUser mute:!wantOpen];
            };
        }

        // 初始化该用户摄像头、麦克风状态
        [self updateUserMediaStatusWithLinkMicUser:linkMicUser];
    }
    
    if (linkMicUser.userType == PLVSocketUserTypeTeacher) {
        self.teacherLinkMicUser = linkMicUser;
    } else if ([linkMicUser.linkMicUserId isEqualToString:[PLVHiClassManager sharedManager].groupLeaderId]) {
        linkMicUser.groupLeader = YES;
        self.groupLeaderLinkMicUser = linkMicUser;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(linkMicUserArrayQueue, ^{
        PLVLinkMicOnlineUser *addUser = local ? weakSelf.localUser : linkMicUser;
        if (addUser.userType == PLVSocketUserTypeTeacher) { // 将用户加入连麦数组
            [weakSelf.linkMicManager setTeacherUserId:linkMicUser.linkMicUserId];
            [weakSelf.linkMicUserArray insertObject:addUser atIndex:0];
        } else if (addUser.groupLeader) {
            if ([weakSelf.linkMicUserArray count] > 0) {
                PLVLinkMicOnlineUser *firstUser = weakSelf.linkMicUserArray.firstObject;
                NSInteger insertIndex = (firstUser.userType == PLVSocketUserTypeTeacher) ? 1 : 0;
                [weakSelf.linkMicUserArray insertObject:addUser atIndex:insertIndex];
            } else {
                [weakSelf.linkMicUserArray addObject:addUser];
            }
        } else {
            [weakSelf.linkMicUserArray addObject:addUser];
        }
    });
    
    [self notifyLinkMicUserArrayChanged];
    return YES;
}

/// 从连麦用户数组移除指定ID的连麦用户
- (BOOL)removeLinkMicUserWithLinkMicId:(NSString *)linkMicId {
    if (![PLVFdUtil checkStringUseable:linkMicId]) { // 检查参数是否合法
        return NO;
    }
    
    // 待删除数据不存在数组 linkMicUserArray 中
    PLVLinkMicOnlineUser *linkMicUser = [self linkMicUserWithLinkMicId:linkMicId];
    if (!linkMicUser) {
        return NO;
    }
    
    PLVHiClassManager *manager = [PLVHiClassManager sharedManager];
    if (manager.groupState != PLVHiClassGroupStateInGroup ||
        (manager.groupState == PLVHiClassGroupStateInGroup && manager.teacherInGroup)) {
        if (linkMicUser.userType == PLVSocketUserTypeTeacher) { // 非分组时，或分组且讲师在当前分组中时，待删除用户不可为讲师
            linkMicUser.streamLeaveRoom = YES; // 讲师仅在流离开教室时，会有remove操作，此时标注streamLeaveRoom为YES用于UI显示讲师流不在教室时的占位图
            [self notifyLinkMicUserArrayChanged];
            return NO;
        }
    }
    
    dispatch_barrier_async(linkMicUserArrayQueue, ^{
        [self.linkMicUserArray removeObject:linkMicUser];
    });
    
    [self notifyLinkMicUserArrayChanged];
    return YES;
}

- (void)removeAllLinkMicUserExceptTeacherAndGroupLeader {
    dispatch_barrier_async(linkMicUserArrayQueue, ^{
        if (self.userType == PLVSocketUserTypeTeacher) { // 当前用户为讲师
            [self.linkMicUserArray removeAllObjects];
            [self.linkMicUserArray addObject:self.localUser];
        } else if ([PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 当前用户为组长
            PLVLinkMicOnlineUser *firstLinkMicUser = self.linkMicUserArray.firstObject;
            [self.linkMicUserArray removeAllObjects];
            if (firstLinkMicUser.userType == PLVSocketUserTypeTeacher) {
                [self.linkMicUserArray addObject:firstLinkMicUser];
            }
            [self.linkMicUserArray addObject:self.localUser];
        }
    });
    
    [self notifyLinkMicUserArrayChanged];
}

/// 清空连麦数组的用户
- (void)removeAllLinkMicUser {
    dispatch_barrier_async(linkMicUserArrayQueue, ^{
        [self.linkMicUserArray removeAllObjects];
    });
    
    [self notifyLinkMicUserArrayChanged];
}

/// 解析‘连麦用户列表数据’并刷新连麦用户数组 linkMicUserArray
- (void)updateLinkMicUserArrayWithJoinArray:(NSArray *)joinArray {
    if (!self.inRTCRoom) {
        return;
    }
    
    // 遍历 linkMicUserArray 检查是否每个成员都在 joinList 字段之中
    // 如不存在，将该数据模型的 linkMicId 登记到 needRemoveLinkMicIdArray 数组中
    __block NSMutableArray *needRemoveLinkMicIdArray = [[NSMutableArray alloc] init];
    dispatch_sync(linkMicUserArrayQueue, ^{
        for (PLVLinkMicOnlineUser *linkMicUser in self.linkMicUserArray) {
            BOOL existInJoinList = NO;
            for (NSDictionary *userDict in joinArray) {
                if (![PLVFdUtil checkDictionaryUseable:userDict]) {
                    continue;
                }
                NSString *joinListLinkMicId = PLV_SafeStringForDictKey(userDict, @"userId");
                if (joinListLinkMicId && [joinListLinkMicId isEqualToString:linkMicUser.linkMicUserId]) {
                    existInJoinList = YES;
                    break;
                }
            }

            if (!existInJoinList) {
                if (linkMicUser.userType == PLVBSocketUserTypeTeacher) {
                    PLVHiClassManager *manager = [PLVHiClassManager sharedManager];
                    if (manager.groupState != PLVHiClassGroupStateNotInGroup && !manager.teacherInGroup) {
                        [needRemoveLinkMicIdArray addObject:linkMicUser.linkMicUserId];
                    }
                } else {
                    [needRemoveLinkMicIdArray addObject:linkMicUser.linkMicUserId];
                }
            }
        }
    });
    
    // 遍历 needRemoveLinkMicIdArray 数组，移除 joinList 字段没有的连麦成员, 不包括 PLVBSocketUserTypeTeacher 类型的成员
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(linkMicUserArrayQueue, ^{
        for (NSString *removeLinkMicId in needRemoveLinkMicIdArray) {
            NSArray *tempArray = [weakSelf.linkMicUserArray copy];
            for (PLVLinkMicOnlineUser *aUser in tempArray) {
                if ([aUser.linkMicUserId isEqualToString:removeLinkMicId]) {
                    [weakSelf.linkMicUserArray removeObject:aUser];
                    [weakSelf unsubscribeStreamWithRTCUserId:aUser.linkMicUserId];
                    break;
                }
            }
        }
    });
    
    // 遍历 joinList 字段数组，确保每个成员都在数组 linkMicUserArray 中
    for (NSDictionary *userDict in joinArray) {
        if (![PLVFdUtil checkDictionaryUseable:userDict]) {
            continue;
        }
        PLVLinkMicOnlineUser *linkMicUser = [PLVLinkMicOnlineUser modelWithDictionary:userDict];
        BOOL add = [self addLinkMicUser:linkMicUser];
        if (add) {
            [self subscribeStreamWithLinkMicUser:linkMicUser streamSourceType:-1];
        } else {
            PLVLinkMicOnlineUser *existLinkMicUser = [self linkMicUserWithLinkMicId:linkMicUser.linkMicUserId];
            [existLinkMicUser updateWithDictionary:userDict];
        }
    }
    
    // 确保讲师在第一位，其次是组长；讲师不在数组中时，组长第一位。
    dispatch_barrier_async(linkMicUserArrayQueue, ^{
        NSInteger teacherIndex = -1;
        NSInteger groupLeaderIndex = -1;
        NSInteger index = 0;
        for (PLVLinkMicOnlineUser *linkMicUser in self.linkMicUserArray) {
            if (linkMicUser.userType == PLVSocketUserTypeTeacher) {
                self.teacherLinkMicUser = linkMicUser;
                teacherIndex = index;
            } else if (linkMicUser.groupLeader) {
                self.groupLeaderLinkMicUser = linkMicUser;
                groupLeaderIndex = index;
            }
            if (teacherIndex != -1 && groupLeaderIndex != -1) {
                break;
            }
            index++;
        }
        if (teacherIndex > 0) { // 讲师位置不对
            [self.linkMicUserArray removeObject:self.teacherLinkMicUser];
            [self.linkMicUserArray insertObject:self.teacherLinkMicUser atIndex:0];
            teacherIndex = 0;
        }
        if ((teacherIndex == 0 && groupLeaderIndex != -1 && [self.linkMicUserArray count] >= 2) ||
            (teacherIndex == -1 && groupLeaderIndex != -1 && [self.linkMicUserArray count] >= 1)) {
            NSInteger groupLeaderShouldIndex = teacherIndex == 0 ? 1 : 0; // 组长正确索引
            PLVLinkMicOnlineUser *shouldGroupLeaderUser = self.linkMicUserArray[groupLeaderShouldIndex];
            if (!shouldGroupLeaderUser.groupLeader) { // 正确索引取得的用户数据不是组长，证明组长位置不对
                [self.linkMicUserArray removeObject:self.groupLeaderLinkMicUser];
                [self.linkMicUserArray insertObject:self.groupLeaderLinkMicUser atIndex:groupLeaderShouldIndex];
            }
        }
    });
    
    [self notifyLinkMicUserArrayChanged];
}

/// 从连麦用户数组找出指定ID的连麦用户，标记摄像头状态为(mute-NO)开启或(mute-YES)关闭
/// 若找不到指定ID的连麦用户，记录在prerecordUserMediaStatusDict字典中
- (void)findUserWithLinkMicId:(NSString *)linkMicId muteCamera:(BOOL)mute streamSourceType:(PLVBRTCSubscribeStreamSourceType)streamSourceType {
    if ([self.linkMicUserId isEqualToString:linkMicId]) { // 目标用户是本地用户
        [self openLocalUserCamera:!mute];
    } else { // 目标用户是远端用户
        PLVLinkMicOnlineUser *linkMicUser = [self linkMicUserWithLinkMicId:linkMicId];
        if (linkMicUser) {
            if (linkMicUser.userType == PLVSocketUserTypeTeacher) {
                if (streamSourceType != PLVBRTCSubscribeStreamSourceType_Screen) { // 讲师的屏幕流无需进行处理
                    [linkMicUser updateUserCurrentCameraOpen:!mute];
                }
            } else {
                [linkMicUser updateUserCurrentCameraOpen:!mute];
            }
        } else {
            [self prerecordMuteStatus:mute linkMicId:linkMicId mediaType:@"video" streamSourceType:streamSourceType];
        }
    }
}

/// 从连麦用户数组找出指定ID的连麦用户，标记麦克风状态为(mute-NO)开启或(mute-YES)关闭
/// 若找不到指定ID的连麦用户，记录在prerecordUserMediaStatusDict字典中
- (void)findUserWithLinkMicId:(NSString *)linkMicId muteMicrophone:(BOOL)mute streamSourceType:(PLVBRTCSubscribeStreamSourceType)streamSourceType {
    if ([self.linkMicUserId isEqualToString:linkMicId]) { // 目标用户是本地用户
        [self openLocalUserMic:!mute];
    } else { // 目标用户是远端用户
        PLVLinkMicOnlineUser *linkMicUser = [self linkMicUserWithLinkMicId:linkMicId];
        if (linkMicUser) {
            if (linkMicUser.userType == PLVSocketUserTypeTeacher) {
                if (streamSourceType != PLVBRTCSubscribeStreamSourceType_Screen) { // 讲师的屏幕流无需进行处理
                    [linkMicUser updateUserCurrentMicOpen:!mute];
                }
            } else {
                [linkMicUser updateUserCurrentMicOpen:!mute];
            }
        } else {
            [self prerecordMuteStatus:mute linkMicId:linkMicId mediaType:@"audio" streamSourceType:streamSourceType];
        }
    }
}

/// 更新连麦用户数组中连麦用户的音量大小
- (void)updateLinkMicUserVolumeWithVolumeDictionary:(NSDictionary<NSString *,NSNumber *> *)volumeDict {
    for (PLVLinkMicOnlineUser *linkMicUser in self.currentLinkMicUserArray) {
        CGFloat volume = PLV_SafeFloatForDictKey(volumeDict, linkMicUser.linkMicUserId);
        [linkMicUser updateUserCurrentVolume:volume];
    }
}


#pragma mark 连麦用户操作管理（以下API仅讲师身份时有效）

/// 调用 SDK 接口对某个用户同意连麦
- (void)emitJoinResponseEventWithUserDict:(NSDictionary *)userDict
                               needAnswer:(BOOL)needAnswer
                                  success:(void (^ _Nullable)(PLVLinkMicOnlineUser *linkMicUser))successBlock {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅在当前用户为讲师或组长时该方法才有效
        return;
    }
    
    [self.linkMicManager joinResponseWithRemoteUserDict:userDict needAnswer:needAnswer completed:^(BOOL success) {
        if (success) {
            PLVLinkMicOnlineUser *linkMicUser = [PLVLinkMicOnlineUser modelWithDictionary:userDict];
            if (successBlock) {
                successBlock(linkMicUser);
            }
        }
    }];
}

/// 调用 SDK 接口对某个用户断开连麦
- (void)emitCloseLinkMicEventWithLinkMicId:(NSString *)linkMicId success:(void (^ _Nullable)(void))successBlock {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅在当前用户为讲师或组长时该方法才有效
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.linkMicManager closeLinkMicWithRemoteUserId:linkMicId completed:^(BOOL success) {
        if (success) {
            [weakSelf removeLinkMicUserWithLinkMicId:linkMicId];
            [weakSelf unsubscribeStreamWithRTCUserId:linkMicId];
            if (successBlock) {
                successBlock();
            }
        }
    }];
}

/// 通过回调【onlineUserArrayForMultiRoleLinkMicPresenter:】获取成员列表数据并逐一发送 joinResponse 消息
- (void)emitJoinResponseEventWithOnlineUserArray {
    if (self.userType != PLVSocketUserTypeTeacher) { // 仅在当前用户为讲师时该方法才有效
        return;
    }
    
    NSArray <PLVChatUser *> *onlineUserArray = [self notifyToGetOnlineUserArray];
    if (![PLVFdUtil checkArrayUseable:onlineUserArray]) {
        return;
    }
    
    if ([PLVHiClassManager sharedManager].status != PLVHiClassStatusInClass) { // 非上课时无需发送 joinResponse 消息
        return;
    }
    
    for (id userObject in onlineUserArray) {
        if (userObject && [userObject isKindOfClass:[PLVChatUser class]]) {
            PLVChatUser *chatUser = (PLVChatUser *)userObject;
            if (!chatUser.userId ||
                [chatUser.userId isEqualToString:self.userId]) { // user 为讲师自己时无需发送 joinResponse 消息
                continue;
            }
            
            NSDictionary *userDict = [self userDictionayWithChatUser:chatUser];
            if (userDict) {
                if (![self hasEmitJoinResponseWithUserId:chatUser.userId]) {
                    [self emitJoinResponseEventWithUserDict:userDict needAnswer:NO success:nil];
                }
            }
        }
    }
}

// 讲师身份开始上课后的自动上台逻辑
- (void)autoLinkMic {
    if (![PLVRoomDataManager sharedManager].roomData.autoLinkMic) { // 该课程没有开启自动连麦
        return;
    }
    
    if ([PLVHiClassManager sharedManager].status != PLVHiClassStatusInClass) { // 未上课时不自动连麦
        return;
    }
    
    if ([PLVHiClassManager sharedManager].duration > kAllJoinResponseInterval) { // 已上课时长超过30秒不自动连麦
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    // 标记startClassInHalfMin为YES
    self.startClassInHalfMin = YES;
    self.emitedJoinResponseUserIdArray = [[NSMutableArray alloc] init];
    NSInteger autoLinkMicTime = kAllJoinResponseInterval - [PLVHiClassManager sharedManager].duration;
    dispatch_time_t startClassDelayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(autoLinkMicTime * NSEC_PER_SEC));
    dispatch_after(startClassDelayTime, dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        // 上课超过30秒，标记startClassInHalfMin为NO
        strongSelf.startClassInHalfMin = NO;
        [strongSelf.emitedJoinResponseUserIdArray removeAllObjects];
    });
    
    // 1秒后对成员列表数据逐一发送 joinResponse 消息
    // 给成员列表模块1秒时间用来在上课之后获取成员列表
    dispatch_time_t getOnlineUserArrayDelayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
    dispatch_after(getOnlineUserArrayDelayTime, dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf emitJoinResponseEventWithOnlineUserArray];
    });
}

/// startClassInHalfMin为YES时，确保每个用户最多只发送一次joinResponse消息
/// 发送过返回YES，否则返回NO
- (BOOL)hasEmitJoinResponseWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return YES;
    }
    
    BOOL exist = NO;
    for (NSString *enumUserId in self.emitedJoinResponseUserIdArray) {
        if(![PLVFdUtil checkStringUseable:enumUserId]){
            continue;
        }
        if ([enumUserId isEqualToString:userId]) {
            exist = YES;
            break;
        }
    }
    if (exist) {
        return YES;
    } else {
        [self.emitedJoinResponseUserIdArray addObject:userId];
        return NO;
    }
}

/// 将 PLVChatUser 对象转换为发送 joinResponse 消息所需要的 NSDictionary 对象
- (NSDictionary *)userDictionayWithChatUser:(PLVChatUser *)chatUser {
    NSString *userType = [PLVRoomUser userTypeStringWithUserType:chatUser.userType];
    NSString *userId = chatUser.userId ?: @"";
    NSString *nick = chatUser.userName ?: @"";
    NSString *pic = chatUser.avatarUrl ?: @"";
    NSString *actor = chatUser.actor ?: @"";
    NSDictionary *userDict = @{
        @"userType" : userType,
        @"userId" : userId,
        @"nick" : nick,
        @"pic" : pic,
        @"actor" : actor
    };
    return userDict;
}

#pragma mark Socket消息接收处理

- (void)handleLoginEventWithDict:(NSDictionary *)dict {
    if ([PLVHiClassManager sharedManager].status != PLVHiClassStatusInClass) { // 非上课时无需发送 joinResponse 消息
        return;
    }
    
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅当前用户为讲师或组长时才需响应 LOGIN 消息
        return;
    }
    
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    NSString *userId = PLV_SafeStringForDictKey(userDict, @"userId");
    if (!userDict ||
        ![PLVFdUtil checkStringUseable:userId] ||
        [userId isEqualToString:self.userId]) { // user 为空或 user 为讲师自己时无需发送 joinResponse 消息
        return;
    }
    
    if (self.startClassInHalfMin) {
        if (![self hasEmitJoinResponseWithUserId:userId]) {
            [self emitJoinResponseEventWithUserDict:userDict needAnswer:NO success:nil];
        }
    } else {
        NSDictionary *classStatusDict = PLV_SafeDictionaryForDictKey(dict, @"classStatus");
        NSInteger voice = PLV_SafeIntegerForDictKey(classStatusDict, @"voice");
        if (classStatusDict && voice == 1) {
            [self emitJoinResponseEventWithUserDict:userDict needAnswer:NO success:nil];
        }
    }
}

- (void)handleLogoutEventWithDict:(NSDictionary *)dict {
    NSString *linkMicId = PLV_SafeStringForDictKey(dict, @"userId");
    // 把相应用户从连麦列表中移除
    BOOL exist = [self removeLinkMicUserWithLinkMicId:linkMicId];
    if (exist) {
        [self unsubscribeStreamWithRTCUserId:linkMicId];
    }
}

- (void)handleOnSliceIdEventWithDict:(NSDictionary *)dict {
    if (self.userType == PLVSocketUserTypeTeacher) { // 仅当前用户为学员时才需响应 onSliceId 消息
        return;
    }
    
    NSDictionary *dataDict = PLV_SafeDictionaryForDictKey(dict, @"data");
    NSString *userId = PLV_SafeStringForDictKey(dataDict, @"userId");
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![userId isEqualToString:self.userId]) { // userId 不为当前用户时无需处理
        return;
    }
    
    NSDictionary *classStatusDict = PLV_SafeDictionaryForDictKey(dict, @"classStatus");
    NSInteger voice = PLV_SafeIntegerForDictKey(classStatusDict, @"voice");
    if (classStatusDict && [classStatusDict count] > 0 && voice != 1) {
        [self localUserLeaveLinkMic];
    }
}

- (void)handleOnTeacherSetPermissionEventWithDict:(NSDictionary *)dict {
    if (self.userType == PLVSocketUserTypeTeacher) { // 仅当前用户为学员时才需响应 TEACHER_SET_PERMISSION 消息
        return;
    }
    
    NSString *userId = PLV_SafeStringForDictKey(dict, @"userId");
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![userId isEqualToString:self.userId]) { // userId 不为当前用户时无需处理
        return;
    }
    
    NSString *type = PLV_SafeStringForDictKey(dict, @"type");
    NSString *status = PLV_SafeStringForDictKey(dict, @"status");
    BOOL open = (status && [status isEqualToString:@"1"]) ? YES : NO;
    if ([type isEqualToString:@"video"]) {
        [self openLocalUserCamera:open];
    } else if ([type isEqualToString:@"audio"]) {
        [self openLocalUserMic:open];
    } else if ([type isEqualToString:@"voice"]) {
        if (open && [PLVHiClassManager sharedManager].groupState != PLVHiClassGroupStateNotInGroup) {
            if (self.inRTCRoom) {
                [self localUserJoinLinkMic];
            } else {
                self.delayResponse = YES;
            }
        }
    }
}

- (void)handleJoinAnswerEventWithDict:(NSDictionary *)dict {
    if (self.userType != PLVSocketUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 仅当前用户为讲师或组长时才需响应 joinAnswer 消息
        return;
    }
    
    // 学员对 joinResponse 进行答复
    NSString *userId = PLV_SafeStringForDictKey(dict, @"userId");
    NSInteger status = PLV_SafeIntegerForDictKey(dict, @"status");
    BOOL result = PLV_SafeBoolForDictKey(dict, @"result");
    BOOL success = (status == 1 && result);
    if (!success) { // 用户拒绝连麦或连麦失败
        [self removeLinkMicUserWithLinkMicId:userId];
    }
    [self notifyDidUserJoinAnswer:success linkMicId:userId];
}

- (void)handleJoinResponseEventWithDict:(NSDictionary *)dict {
    if (self.userType == PLVSocketUserTypeTeacher) {  // 仅当前用户为学员时才需响应 joinResponse 消息
        return;
    }
    
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    NSString *userId = PLV_SafeStringForDictKey(userDict, @"userId");
    if (![PLVFdUtil checkStringUseable:userId] ||
        ![userId isEqualToString:self.userId]) { // userId 不为当前用户时无需处理
        return;
    }
    
    NSInteger needAnswer = PLV_SafeIntegerForDictKey(dict, @"needAnswer");
    if (needAnswer == 1) { // 需要用户答复
        [self notifyJoinResponseNeedAnswer];
    } else {
        if (self.inRTCRoom) {
            [self localUserJoinLinkMic];
        } else {
            self.delayResponse = YES;
        }
    }
}

- (void)handleJoinLeaveEventWithDict:(NSDictionary *)dict {
    NSDictionary *userDict = PLV_SafeDictionaryForDictKey(dict, @"user");
    NSString *linkMicId = PLV_SafeStringForDictKey(userDict, @"userId");
    if ([linkMicId isEqualToString:self.userId]) { // joinLeave 对象为当前用户时
        [self localUserLeaveLinkMic];
    } else {
        BOOL exist = [self removeLinkMicUserWithLinkMicId:linkMicId];
        if (exist) {
            [self unsubscribeStreamWithRTCUserId:linkMicId];
        }
    }
}

#pragma mark Delegate方法触发

- (NSArray <PLVChatUser *> * _Nullable)notifyToGetOnlineUserArray {
    NSArray <PLVChatUser *> *onlineUserArray = nil;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(onlineUserArrayForMultiRoleLinkMicPresenter:)]) {
        onlineUserArray = [self.delegate onlineUserArrayForMultiRoleLinkMicPresenter:self];
    }
    return onlineUserArray;
}

- (PLVChatUser * _Nullable)notifyToGetOnlineUserWithUserId:(NSString *)userId {
    PLVChatUser *chatUser = nil;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(onlineUserForMultiRoleLinkMicPresenter:withUserId:)]) {
        chatUser = [self.delegate onlineUserForMultiRoleLinkMicPresenter:self withUserId:userId];
    }
    return chatUser;
}

- (void)notifyJoinRTCChannelSuccess {
    self.inRTCRoom = YES;
    [self setScreenAlwaysOn];
    
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenterJoinRTCChannelSuccess:)]) {
            [self.delegate multiRoleLinkMicPresenterJoinRTCChannelSuccess:self];
        }
    })
}

- (void)notifyJoinRTCChannelFailure {
    self.inRTCRoom = NO;
    
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenterJoinRTCChannelFailure:)]) {
            [self.delegate multiRoleLinkMicPresenterJoinRTCChannelFailure:self];
        }
    })
}

- (void)notifyLeaveRTCChannel {
    self.inRTCRoom = NO;
    [self resumeScreenStatus];
    
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenterLeaveRTCChannelResult:)]) {
            [self.delegate multiRoleLinkMicPresenterLeaveRTCChannelResult:self];
        }
    })
}

- (void)notifyNetworkQualityChanged:(PLVBLinkMicNetworkQuality)networkQuality {
    if (networkQuality == PLVBLinkMicNetworkQualityUnknown ||
        networkQuality == self.lastNotifyNetworkQuality) {
        return;
    }
    self.lastNotifyNetworkQuality = networkQuality;
    
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:networkQualityChanged:)]) {
            [self.delegate multiRoleLinkMicPresenter:self networkQualityChanged:self.lastNotifyNetworkQuality];
        }
    })
}

- (void)notifyUserRTT:(NSInteger)rtt {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:localUserRttMS:)]) {
            [self.delegate multiRoleLinkMicPresenter:self localUserRttMS:rtt];
        }
    })
}

- (void)notifyLocalUserMicOpenChanged {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:localUserMicOpenChanged:)]) {
            [self.delegate multiRoleLinkMicPresenter:self localUserMicOpenChanged:self.currentMicOpen];
        }
    })
}

- (void)notifyLocalUserCameraShouldShowChanged {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:localUserCameraShouldShowChanged:)]) {
            [self.delegate multiRoleLinkMicPresenter:self localUserCameraShouldShowChanged:self.currentCameraShouldShow];
        }
    })
}

- (void)notifyLocalUserCameraFrontChanged {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:localUserCameraFrontChanged:)]) {
            [self.delegate multiRoleLinkMicPresenter:self localUserCameraFrontChanged:self.currentCameraFront];
        }
    })
}

- (void)notifyLocalUserLinkMicStatusChanged {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:localUserLinkMicStatusChanged:)]) {
            [self.delegate multiRoleLinkMicPresenter:self localUserLinkMicStatusChanged:self.linkingMic];
        }
    })
}

- (void)notifyJoinResponseNeedAnswer {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenterNeedAnswerForJoinResponseEvent:)]) {
            [self.delegate multiRoleLinkMicPresenterNeedAnswerForJoinResponseEvent:self];
        }
    })
}

- (void)notifyLinkMicUserArrayChanged {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:linkMicUserArrayChanged:)]) {
            [self.delegate multiRoleLinkMicPresenter:self linkMicUserArrayChanged:self.currentLinkMicUserArray];
        }
    })
}

- (void)notifyDidJoinUserLinkMic:(PLVLinkMicOnlineUser *)linkMicUser {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:didJoinUserLinkMic:)]) {
            [self.delegate multiRoleLinkMicPresenter:self didJoinUserLinkMic:linkMicUser];
        }
    })
}

- (void)notifyDidUserJoinAnswer:(BOOL)success linkMicId:(NSString *)linkMicId {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:didUserJoinAnswer:linkMicId:)]) {
            [self.delegate multiRoleLinkMicPresenter:self didUserJoinAnswer:success linkMicId:linkMicId];
        }
    })
}

- (void)notifyDidCloseUserLinkMic:(PLVLinkMicOnlineUser *)linkMicUser {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:didCloseUserLinkMic:)]) {
            [self.delegate multiRoleLinkMicPresenter:self didCloseUserLinkMic:linkMicUser];
        }
    })
}

- (void)notifyDidLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser audioMuted:(BOOL)mute {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:linkMicUser:audioMuted:)]) {
            [self.delegate multiRoleLinkMicPresenter:self linkMicUser:linkMicUser audioMuted:mute];
        }
    })
}

- (void)notifyDidLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser videoMuted:(BOOL)mute {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:linkMicUser:videoMuted:)]) {
            [self.delegate multiRoleLinkMicPresenter:self linkMicUser:linkMicUser videoMuted:mute];
        }
    })
}


- (void)notifyDidAuthUserBrush:(PLVLinkMicOnlineUser *)authUser auth:(BOOL)auth {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:authBrushUser:authBrush:)]) {
            [self.delegate multiRoleLinkMicPresenter:self authBrushUser:authUser authBrush:auth];
        }
    })
}

- (void)notifyDidGrantUserCup:(PLVLinkMicOnlineUser *)grantUser {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:grantCupUser:)]) {
            [self.delegate multiRoleLinkMicPresenter:self grantCupUser:grantUser];
        }
    })
}

- (void)notifyDidTeacherScreenStreamRenderd {
    if (self.userType == PLVBSocketUserTypeTeacher) {
        return;
    }
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:didTeacherScreenStreamRenderdIn:)]) {
            [self.delegate multiRoleLinkMicPresenter:self didTeacherScreenStreamRenderdIn:self.rtcScreenStreamView];
        }
    })
}

- (void)notifyDidTeacherScreenStreamRemoved {
    if (self.userType == PLVBSocketUserTypeTeacher) {
        return;
    }
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(multiRoleLinkMicPresenter:didTeacherScreenStreamRemovedIn:)]) {
            [self.delegate multiRoleLinkMicPresenter:self didTeacherScreenStreamRemovedIn:self.rtcScreenStreamView];
        }
    })
}

#pragma mark 屏幕常亮设置

/// 上课时屏幕保持常亮
- (void)setScreenAlwaysOn {
    plv_dispatch_main_async_safe(^{
        if (![UIApplication sharedApplication].idleTimerDisabled) {
            self.originalIdleTimerDisabled = -1;
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        }
    });
}

/// 恢复屏幕原始常亮与否的设置
- (void)resumeScreenStatus {
    if (self.originalIdleTimerDisabled != 0) {
        plv_dispatch_main_async_safe(^{
            [UIApplication sharedApplication].idleTimerDisabled = self.originalIdleTimerDisabled < 0 ? NO : YES;
            self.originalIdleTimerDisabled = 0;
        });
    }
}

#pragma mark Timer

/// 创建 获取连麦在线用户列表 定时器
- (void)startLinkMicListTimer {
    self.linkMicTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(linkMicTimerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.linkMicTimer forMode:NSRunLoopCommonModes];
    [self.linkMicTimer fire];
}

- (void)stopLinkMicListTimer {
    [_linkMicTimer invalidate];
    _linkMicTimer = nil;
}

#pragma mark Prerecord MediaStatus

/*
 prerecordUserMediaStatusDict的完整数据结构：
 {
     @"universal":{@"video":@(videoMute), @"audio":@(audioMute))},  // 用于学生，学生只有一路流，所以记录最新一次回调的mute状态，不关心是哪种类型的流
     @"camera":   {@"video":@(videoMute), @"audio":@(audioMute))},  // 用于讲师，讲师可能同时订阅多路流，需要区分记录不同流的mute状态
     @"screen":   {@"video":@(videoMute), @"audio":@(audioMute))}   // 讲师的屏幕流目前不需要显示麦克风、摄像头开关状态，所以暂时用不到
 */
- (void)prerecordMuteStatus:(BOOL)mute linkMicId:(NSString *)linkMicId mediaType:(NSString *)mediaType streamSourceType:(PLVBRTCSubscribeStreamSourceType)streamSourceType {
    if (![PLVFdUtil checkStringUseable:linkMicId]) {
        return;
    }
    
    NSDictionary *lastMediaStatusDict = self.prerecordUserMediaStatusDict[linkMicId];
    NSMutableDictionary *updateMediaStatusDict;
    if ([PLVFdUtil checkDictionaryUseable:lastMediaStatusDict]) {
        updateMediaStatusDict = [[NSMutableDictionary alloc] initWithDictionary:lastMediaStatusDict];
    } else {
        updateMediaStatusDict = [[NSMutableDictionary alloc] init];
    }
    
    // 记录最新的一次流mute回调，用于学生单一流类型订阅的情况
    [self prerecordMutableDict:updateMediaStatusDict key:@"universal" mediaType:mediaType muteStatus:mute];
    
    // 区分流类型记录mute回调，用于讲师端存在多路流订阅的情况
    NSString *streamSource = (streamSourceType == PLVBRTCSubscribeStreamSourceType_Screen) ? @"screen" : @"camera";
    [self prerecordMutableDict:updateMediaStatusDict key:streamSource mediaType:mediaType muteStatus:mute];
    
    [self.prerecordUserMediaStatusDict setObject:[updateMediaStatusDict copy] forKey:linkMicId];
}

- (void)prerecordMutableDict:(NSMutableDictionary *)mutableDict key:(NSString *)keyValue mediaType:(NSString *)mediaType muteStatus:(BOOL)mute {
    NSDictionary *mediaStatusDict = mutableDict[keyValue];
    NSMutableDictionary *updateDict;
    if ([PLVFdUtil checkDictionaryUseable:mediaStatusDict]) {
        updateDict = [[NSMutableDictionary alloc] initWithDictionary:mediaStatusDict];
    } else {
        updateDict = [[NSMutableDictionary alloc] init];
    }
    updateDict[mediaType] = @(mute);
    mutableDict[keyValue] = [updateDict copy];
}

- (BOOL)readPrerecordMuteStatusWithLinkMicId:(NSString *)linkMicId isTeacher:(BOOL)isTeacher mediaType:(NSString *)mediaType defaultMuteStatus:(BOOL)defaultStatus {
    if (![PLVFdUtil checkStringUseable:linkMicId]) {
        return defaultStatus;
    }
    
    NSDictionary *lastMediaStatusDict = self.prerecordUserMediaStatusDict[linkMicId];
    if (![PLVFdUtil checkDictionaryUseable:lastMediaStatusDict]) {
        return defaultStatus;
    }
    
    NSDictionary *mediaStatusDict;
    if (isTeacher) {
        mediaStatusDict = lastMediaStatusDict[@"camera"];
    } else {
        mediaStatusDict = lastMediaStatusDict[@"universal"];
    }
    if (![PLVFdUtil checkDictionaryUseable:mediaStatusDict]) {
        return defaultStatus;
    }
    
    NSNumber *mediaStatusNumber = mediaStatusDict[mediaType];
    if (!mediaStatusNumber ||
        ![mediaStatusNumber isKindOfClass:[NSNumber class]]) {
        return defaultStatus;
    }
    return mediaStatusNumber.boolValue;;
}

- (void)removePrerecordWithLinkMicId:(NSString *)linkMicId {
    if (![PLVFdUtil checkStringUseable:linkMicId]) {
        return;
    }
    [self.prerecordUserMediaStatusDict removeObjectForKey:linkMicId];
}

- (void)updateUserMediaStatusWithLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser {
    BOOL isTeacher = linkMicUser.userType == PLVBSocketUserTypeTeacher;
    BOOL cameraMute = [self readPrerecordMuteStatusWithLinkMicId:linkMicUser.linkMicUserId isTeacher:isTeacher mediaType:@"video" defaultMuteStatus:NO];
    BOOL micMute = [self readPrerecordMuteStatusWithLinkMicId:linkMicUser.linkMicUserId isTeacher:isTeacher mediaType:@"audio" defaultMuteStatus:NO];
    
    /// 设置初始值
    [linkMicUser updateUserCurrentCameraOpen:!cameraMute];
    [linkMicUser updateUserCurrentMicOpen:!micMute];
    
    [self removePrerecordWithLinkMicId:linkMicUser.linkMicUserId];
}

#pragma mark - [ Event ]

#pragma mark Timer

- (void)linkMicTimerEvent:(NSTimer *)timer {
    if (!self.inRTCRoom ||
        ![PLVSocketManager sharedManager].login) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:self.roomId
                                              sessionId:self.sessionId
                                             completion:^(NSDictionary * _Nonnull responseDict) {
        NSArray *joinArray = PLV_SafeArraryForDictKey(responseDict, @"joinList");
        if ([PLVFdUtil checkArrayUseable:joinArray]) {
            [weakSelf updateLinkMicUserArrayWithJoinArray:joinArray];
        }
    } failure:^(NSError *error) {
        NSLog(@"PLVMultiRoleLinkMicPresenter - request linkmic online user list failed : %@", error);
    }];
}

#pragma mark - [ Delegate ]

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if (self.userType == PLVSocketUserTypeTeacher) { // 仅当前用户为讲师时才需响应的消息
        
    } else { // 当前用户为学员时需响应的消息
        if ([subEvent isEqualToString:@"onSliceID"]) {
            [self handleOnSliceIdEventWithDict:jsonDict];
        } else if ([subEvent isEqualToString:@"TEACHER_SET_PERMISSION"]) {
            [self handleOnTeacherSetPermissionEventWithDict:jsonDict];
        }
    }
    
    if ([subEvent isEqualToString:@"LOGIN"]) {
        [self handleLoginEventWithDict:jsonDict];
    } else if ([subEvent isEqualToString:@"LOGOUT"]) {
        [self handleLogoutEventWithDict:jsonDict];
    }
}

- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if (self.userType == PLVSocketUserTypeTeacher) { // 仅当前用户为讲师时才需响应的消息
        if ([event isEqualToString:@"joinAnswer"]) {
            [self handleJoinAnswerEventWithDict:jsonDict];
        }
    } else {  // 当前用户为学员时需响应的消息
        if ([event isEqualToString:@"joinResponse"]) {
            [self handleJoinResponseEventWithDict:jsonDict];
        }
    }
    
    if ([event isEqualToString:@"joinLeave"]) {
        [self handleJoinLeaveEventWithDict:jsonDict];
    }
}

#pragma mark PLVLinkMicManagerDelegate

#pragma mark 本地用户事件回调

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager joinRTCChannelComplete:(NSString *)channelID uid:(NSString *)uid {
    [self.linkMicManager setupLocalVideoPreviewMirrorMode:PLVBRTCVideoMirrorMode_Disabled];
    if (self.userType == PLVSocketUserTypeTeacher) {
        [self localUserJoinLinkMic];
    } else {
        if (self.delayResponse) {
            self.delayResponse = NO;
            [self localUserJoinLinkMic];
        }
    }
    
    [self notifyJoinRTCChannelSuccess];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager joinRTCChannelFailure:(NSString *)channelID uid:(NSString *)uid {
    [self notifyJoinRTCChannelFailure];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager leaveRTCChannelComplete:(NSString *)channelID {
    [self notifyLeaveRTCChannel];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didOccurError:(NSInteger)errorCode {
    [self notifyLeaveRTCChannel];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager userRttDict:(NSDictionary <NSString *, NSNumber *> *)rttDict {
    NSInteger rtt = 0;
    if (self.linkingMic) {
        NSNumber *rttNumber = rttDict[self.linkMicUserId];
        rtt = rttNumber ? rttNumber.integerValue : 0;
    } else {
        if ([self.currentLinkMicUserArray count] > 0) {
            PLVLinkMicOnlineUser *linkMicUsr = [self linkMicUserWithIndex:0];
            NSNumber *rttNumber = rttDict[linkMicUsr.linkMicUserId];
            rtt = rttNumber ? rttNumber.integerValue : 0;
        }
    }
    
    [self notifyUserRTT:MAX(0, rtt)];
}

#pragma mark 远端用户事件回调

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didAudioMuted:(BOOL)muted streamSourceType:(PLVBRTCSubscribeStreamSourceType)streamSourceType byUid:(NSString *)uid {
    [self findUserWithLinkMicId:uid muteMicrophone:muted streamSourceType:streamSourceType];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didVideoMuted:(BOOL)muted streamSourceType:(PLVBRTCSubscribeStreamSourceType)streamSourceType byUid:(NSString *)uid {
    [self findUserWithLinkMicId:uid muteCamera:muted streamSourceType:streamSourceType];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager streamJoinRoom:(PLVBRTCSubscribeStreamSourceType)streamSourceType userRTCId:(NSString *)userRTCId {
    PLVLinkMicOnlineUser *linkMicUser = [self linkMicUserWithLinkMicId:userRTCId];
    if (!linkMicUser) {
        PLVChatUser *chatUser = [self notifyToGetOnlineUserWithUserId:userRTCId];
        if (chatUser) {
            linkMicUser = [PLVLinkMicOnlineUser localUserModelWithChatUser:chatUser];
        } else if ([userRTCId isEqualToString:self.teacherLinkMicUser.linkMicUserId]) {
            linkMicUser = self.teacherLinkMicUser;
        }
    }
    if (linkMicUser) {
        linkMicUser.streamLeaveRoom = NO; // 若讲师的流加入教室，标注streamLeaveRoom为NO用于隐藏讲师流不在教室时的占位图
        BOOL add = [self addLinkMicUser:linkMicUser];
        if (add) {
            [self subscribeStreamWithLinkMicUser:linkMicUser streamSourceType:streamSourceType];
        }
    } else {
        if (streamSourceType == PLVBRTCSubscribeStreamSourceType_Screen) {
            [self recordUnsubscribeScreenStreamWithLinkMicId:userRTCId];
        }
    }
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager streamLeaveRoom:(PLVBRTCSubscribeStreamSourceType)streamSourceType userRTCId:(NSString *)userRTCId {
    if (streamSourceType == PLVBRTCSubscribeStreamSourceType_Screen) {
        [self removeRecordUnsubscribeScreenStreamWihtLinkMicId:userRTCId];
        PLVLinkMicOnlineUser *linkMicUser = [self linkMicUserWithLinkMicId:userRTCId];
        if (!linkMicUser) {
            return;
        }
        if (linkMicUser.userType == PLVBSocketUserTypeTeacher ||
            ([PLVHiClassManager sharedManager].groupState == PLVHiClassGroupStateInGroup && linkMicUser.groupLeader)) {
            plv_dispatch_main_async_safe(^{
                [self.linkMicManager unsubscribeStreamWithRTCUserId:userRTCId subscribeMode:PLVBRTCSubscribeStreamSubscribeMode_Screen];
                [self notifyDidTeacherScreenStreamRemoved];
            })
        }
    } else {
        if ([userRTCId isEqualToString:self.teacherLinkMicUser.linkMicUserId]) {
            [self removeLinkMicUserWithLinkMicId:userRTCId];
        }
    }
}

#pragma mark 通用(自己、别人)事件回调

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager reportAudioVolumeOfSpeakers:(NSDictionary<NSString *,NSNumber *> *)volumeDict{
    [self updateLinkMicUserVolumeWithVolumeDictionary:volumeDict];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager userNetworkQualityDidChanged:(NSString *)userRTCId txQuality:(PLVBLinkMicNetworkQuality)txQuality rxQuality:(PLVBLinkMicNetworkQuality)rxQuality {
    PLVBLinkMicNetworkQuality networkQuality = PLVBLinkMicNetworkQualityUnknown;
    if (self.linkingMic) {
        networkQuality = [userRTCId isEqualToString:self.linkMicUserId] ? txQuality : PLVBLinkMicNetworkQualityUnknown;
    } else {
        if ([self.currentLinkMicUserArray count] > 0) {
            PLVLinkMicOnlineUser *linkMicUsr = [self linkMicUserWithIndex:0];
            networkQuality = [userRTCId isEqualToString:linkMicUsr.linkMicUserId] ? rxQuality : PLVBLinkMicNetworkQualityUnknown;
        }
    }
    
    [self notifyNetworkQualityChanged:networkQuality];
}

@end
