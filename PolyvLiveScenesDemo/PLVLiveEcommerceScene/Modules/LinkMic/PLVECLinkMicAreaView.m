//
//  PLVECLinkMicAreaView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/10/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECLinkMicAreaView.h"
#import "PLVECLinkMicWindowsView.h"
#import "PLVLinkMicPresenter.h"
#import "PLVLinkMicOnlineUser+EC.h"
#import "PLVECLinkMicControlBar.h"
#import "PLVECUtils.h"

@interface PLVECLinkMicAreaView ()<
PLVLinkMicPresenterDelegate,
PLVECLinkMicControlBarDelegate,
PLVECLinkMicPreviewViewDelegate,
PLVECLinkMicWindowsViewDelegate
>
#pragma mark 状态
@property (nonatomic, assign) BOOL externalNoDelayPaused; // 外部的 ‘无延迟播放’ 是否已暂停
@property (nonatomic, assign) BOOL currentLandscape; // 当前是否横屏 (YES:当前横屏 NO:当前竖屏)
#pragma mark 对象
@property (nonatomic, strong) PLVLinkMicPresenter * presenter; // 连麦逻辑处理模块
@property (nonatomic, strong) id <PLVECLinkMicControlBarProtocol> currentControlBar; // 当前连麦悬浮控制栏 (当前显示在屏幕上的 悬浮控制栏)
#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  ├── (PLVECLinkMicAreaView) self (lowest)
///  │    └── (PLVECLinkMicWindowsView) windowsView
///  │
///  └── (PLVECLinkMicControlBar) controlBar
@property (nonatomic, strong) PLVECLinkMicWindowsView *windowsView; // 连麦窗口列表视图 (负责展示多个连麦成员RTC画面窗口)
@property (nonatomic, strong) PLVECLinkMicPreviewView *linkMicPreView; // 连麦预览图
@property (nonatomic, strong) PLVECLinkMicControlBar *controlBar;   // 连麦悬浮控制栏

@end

@implementation PLVECLinkMicAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL fullScreenDifferent = (self.currentLandscape != fullScreen);
    self.currentLandscape = fullScreen;
    self.windowsView.frame = self.bounds;
    
    // iPad分屏尺寸变动，刷新连麦布局
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    if (isPad || fullScreenDifferent) {
        [self.controlBar refreshControlBarFrame];
    }
}

#pragma mark - [ Public Methods ]

- (void)reloadLinkMicUserWindows {
    [self.windowsView reloadLinkMicUserWindows];
}

- (void)startWatchNoDelay:(BOOL)startWatch {
    if (startWatch) {
        [self.presenter startWatchNoDelay];
    }else{
        [self.presenter stopWatchNoDelay];
    }
}

- (void)pauseWatchNoDelay:(BOOL)pause {
    [self.presenter pauseWatchNoDelay:pause];
    [self.windowsView refreshAllLinkMicCanvasPauseImageView:self.presenter.pausedWatchNoDelay];
}

#pragma mark Getter

- (BOOL)pausedWatchNoDelay {
    return self.presenter.pausedWatchNoDelay;
}

- (BOOL)inRTCRoom {
    return self.presenter.inRTCRoom;
}

- (BOOL)inLinkMic {
    return self.presenter.inLinkMic;
}

- (UIView *)firstSiteCanvasView {
    return self.windowsView.firstSiteCanvasView;
}

#pragma mark - [ Private Methods ]

- (void)setup {
    // 添加 连麦功能模块
    self.presenter = [[PLVLinkMicPresenter alloc] init];
    self.presenter.linkMicListSort = YES;
    self.presenter.delegate = self;
    self.presenter.preRenderContainer = self;
    self.presenter.streamScale = PLVBLinkMicStreamScale9_16;
    
    // 配置默认值
    /* 默认值以 连麦悬浮控制栏 中声明的为准 (详见 PLVECLinkMicControlBarProtocol.h)
       若业务改变时，可直接修改 PLVECLinkMicControlBarProtocol.h 的默认值，则 [Presenter]连麦管理器 中同时生效 */
    self.presenter.micDefaultOpen = PLVECLinkMicControlBarMicDefaultOpen;
    self.presenter.cameraDefaultOpen = PLVECLinkMicControlBarCameraDefaultOpen;
    self.presenter.cameraDefaultFront = PLVECLinkMicControlBarSwitchCameraDefaultFront;
}

- (void)setupUI {
    self.alpha = 0;
    [self addSubview:self.windowsView];
    
    self.currentControlBar = self.controlBar;
}

- (void)showAreaView:(BOOL)showStatus {
    if (!self.inRTCRoom) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    CGFloat toAlpha = showStatus ? 1.0 : 0.0;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.alpha = toAlpha;
    }];
}

#pragma mark Getter & Setter

- (PLVECLinkMicControlBar *)controlBar{
    if (!_controlBar) {
        _controlBar = [[PLVECLinkMicControlBar alloc] init];
        _controlBar.delegate = self;
    }
    return _controlBar;
}

- (void)setCurrentControlBar:(id<PLVECLinkMicControlBarProtocol>)currentControlBar {
    if (currentControlBar && currentControlBar != _currentControlBar) {
        [currentControlBar synchControlBarState:_currentControlBar];
        [currentControlBar updateLinkMicRequestIndex:self.presenter.linkMicRequestIndex];
        _currentControlBar = currentControlBar;
    }
}

- (PLVECLinkMicWindowsView *)windowsView {
    if (!_windowsView) {
        _windowsView = [[PLVECLinkMicWindowsView alloc] init];
        _windowsView.delegate = self;
    }
    return _windowsView;
}

- (PLVECLinkMicPreviewView *)linkMicPreView {
    if (!_linkMicPreView) {
        _linkMicPreView = [[PLVECLinkMicPreviewView alloc] init];
        _linkMicPreView.delegate = self;
    }
    return _linkMicPreView;
}

#pragma mark - [Delegate]

#pragma mark PLVLCLinkMicControlBarDelegate

/// 连麦开关按钮 被点击
- (void)PLVECLinkMicControlBar:(id<PLVECLinkMicControlBarProtocol>)bar onOffButtonClickedCurrentStatus:(PLVECLinkMicControlBarStatus)status {
    __weak typeof(self) weakSelf = self;
    if (status == PLVECLinkMicControlBarStatus_Open) { // Bar 处于显示 ‘申请连麦’，点击表示希望申请连麦
        [self.presenter requestJoinLinkMic];
    } else if (status == PLVECLinkMicControlBarStatus_Waiting) { // Bar 处于显示 ‘请求中...’，点击表示希望取消申请连麦
        [PLVFdUtil showAlertWithTitle:@"确认取消申请连麦吗？"
                              message:nil
                       viewController:[PLVFdUtil getCurrentViewController]
                    cancelActionTitle:@"按错了"
                    cancelActionStyle:UIAlertActionStyleDefault
                    cancelActionBlock:nil
                   confirmActionTitle:@"取消申请连麦"
                   confirmActionStyle:UIAlertActionStyleDestructive
                   confirmActionBlock:^(UIAlertAction * _Nonnull action) {
            [weakSelf.presenter cancelRequestJoinLinkMic];
            [[PLVWLogReporterManager sharedManager] reportWithEvent:@"waitingUserDidCancelLinkMic" modul:@"link" information:nil patch:YES];
        }];
    } else if (status == PLVECLinkMicControlBarStatus_Joined) { // Bar 处于已连麦，点击表示希望取消申请连麦
        [PLVFdUtil showAlertWithTitle:@"确认挂断连麦吗？"
                              message:nil
                       viewController:[PLVFdUtil getCurrentViewController]
                    cancelActionTitle:@"按错了"
                    cancelActionStyle:UIAlertActionStyleDefault
                    cancelActionBlock:nil
                   confirmActionTitle:@"挂断"
                   confirmActionStyle:UIAlertActionStyleDestructive
                   confirmActionBlock:^(UIAlertAction * _Nonnull action) {
            [weakSelf.presenter leaveLinkMic];
            [[PLVWLogReporterManager sharedManager] reportWithEvent:@"joinedUserDidCloseLinkMic" modul:@"link" information:nil patch:YES];
        }];
    }
}

/// 摄像头按钮 被点击
- (void)PLVECLinkMicControlBar:(id<PLVECLinkMicControlBarProtocol>)bar
           cameraButtonClicked:(BOOL)wannaOpen
                    openResult:(void(^)(BOOL openResult))openResultBlock {
    [self.presenter cameraOpen:wannaOpen];
    if (openResultBlock) {
        openResultBlock(YES);
    }
}

/// 切换前后摄像头按钮 被点击
- (void)PLVECLinkMicControlBar:(id<PLVECLinkMicControlBarProtocol>)bar switchCameraButtonClicked:(BOOL)front {
    [self.presenter cameraSwitch:front];
}

/// 麦克风按钮 被点击
- (void)PLVECLinkMicControlBar:(id<PLVECLinkMicControlBarProtocol>)bar micCameraButtonClicked:(BOOL)open {
    [self.presenter micOpen:open];
}

#pragma mark PLVLCLinkMicPreviewViewDelegate

/// 连麦邀请 剩余等待时间
- (void)plvECLinkMicPreviewView:(PLVECLinkMicPreviewView *)linkMicPreView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback {
    [self.presenter requestInviteLinkMicTTLCallback:callback];
}

/// 同意 连麦邀请
- (void)plvECLinkMicPreviewViewAcceptLinkMicInvitation:(PLVECLinkMicPreviewView *)linkMicPreView {
    self.presenter.cameraDefaultOpen = self.linkMicPreView.cameraOpen;
    self.presenter.micDefaultOpen = self.linkMicPreView.micOpen;
    self.currentControlBar.micButton.selected = !self.linkMicPreView.micOpen;
    [self.currentControlBar changeCameraButtonOpenUIWithoutEvent:self.linkMicPreView.cameraOpen];
    [self.presenter acceptLinkMicInvitation:YES timeoutCancel:NO];
}

/// 拒绝 连麦邀请
- (void)plvECLinkMicPreviewView:(PLVECLinkMicPreviewView *)linkMicPreView cancelLinkMicInvitationReason:(PLVECCancelLinkMicInvitationReason)reason {
    [self.presenter acceptLinkMicInvitation:NO timeoutCancel:reason == PLVECCancelLinkMicInvitationReason_Timeout];
}

#pragma mark PLVECLinkMicWindowsViewDelegate

/// 连麦窗口列表视图 需要获取当前用户数组
- (NSArray *)currentOnlineUserListInLinkMicWindowsView:(PLVECLinkMicWindowsView *)windowsView {
    return self.presenter.onlineUserArray;
}

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
- (NSInteger)onlineUserIndexInLinkMicWindowsView:(PLVECLinkMicWindowsView *)windowsView
                                     filterBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filterBlock {
    NSInteger index = [self.presenter findUserModelIndexWithFiltrateBlock:filterBlock];
    return index;
}

/// 连麦窗口列表视图 需要根据下标值获取对应用户
- (PLVLinkMicOnlineUser *)onlineUserInLinkMicWindowsView:(PLVECLinkMicWindowsView *)windowsView
                                         withTargetIndex:(NSInteger)targetIndex {
    PLVLinkMicOnlineUser *onlineUser = [self.presenter getUserModelFromOnlineUserArrayWithIndex:targetIndex];
    return onlineUser;
}

- (void)currentFirstSiteCanvasViewChangedInLinkMicWindowsView:(PLVECLinkMicWindowsView *)windowsView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvECLinkMicAreaViewCurrentFirstSiteCanvasViewChanged:)]) {
        [self.delegate plvECLinkMicAreaViewCurrentFirstSiteCanvasViewChanged:self];
    }
}

#pragma mark PLVLinkMicPresenterDelegate

/// ‘房间加入状态’ 发生改变
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
   currentRtcRoomJoinStatus:(PLVLinkMicPresenterRoomJoinStatus)currentRtcRoomJoinStatus
           inRTCRoomChanged:(BOOL)inRTCRoomChanged
                  inRTCRoom:(BOOL)inRTCRoom {
    if (inRTCRoomChanged) {
        [self showAreaView:inRTCRoom];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvECLinkMicAreaView:inRTCRoomChanged:)]) {
            [self.delegate plvECLinkMicAreaView:self inRTCRoomChanged:inRTCRoom];
        }
    }
}

/// ‘连麦状态’ 发生改变
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
       currentLinkMicStatus:(PLVLinkMicStatus)currentLinkMicStatus
           inLinkMicChanged:(BOOL)inLinkMicChanged
                  inLinkMic:(BOOL)inLinkMic {
    if (inLinkMicChanged) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvECLinkMicAreaView:inLinkMicChanged:)]) {
            [self.delegate plvECLinkMicAreaView:self inLinkMicChanged:inLinkMic];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvECLinkMicAreaView:currentLinkMicStatus:)]) {
        [self.delegate plvECLinkMicAreaView:self currentLinkMicStatus:currentLinkMicStatus];
    }
    
    if (currentLinkMicStatus == PLVLinkMicStatus_NotOpen) { // 讲师未开启连麦
        [self.currentControlBar controlBarStatusSwitchTo:PLVECLinkMicControlBarStatus_Default];
        
        // 关闭连麦邀请预览弹窗
        [self.linkMicPreView showLinkMicPreviewView:NO];
    } else if (currentLinkMicStatus == PLVLinkMicStatus_Open) { // 讲师已开启连麦，但未加入连麦
        PLVECLinkMicControlBarType barType = (presenter.linkMicMediaType == PLVChannelLinkMicMediaType_Audio ? PLVECLinkMicControlBarType_Audio : PLVECLinkMicControlBarType_Video);
        [self.currentControlBar changeBarType:barType];
        [self.currentControlBar controlBarStatusSwitchTo:PLVECLinkMicControlBarStatus_Open];
    } else if (currentLinkMicStatus == PLVLinkMicStatus_Waiting) { // 等待讲师允许中（举手中）
        [self.currentControlBar controlBarStatusSwitchTo:PLVECLinkMicControlBarStatus_Waiting];
        [self.currentControlBar updateLinkMicRequestIndex:presenter.linkMicRequestIndex];
    } else if (currentLinkMicStatus == PLVLinkMicStatus_Inviting) { // 讲师等待连麦邀请的应答中
        [self.currentControlBar controlBarStatusSwitchTo:PLVECLinkMicControlBarStatus_Default];
        
        // 显示连麦邀请预览弹窗
        self.linkMicPreView.isOnlyAudio = (presenter.linkMicMediaType == PLVChannelLinkMicMediaType_Audio);
        [self.linkMicPreView showLinkMicPreviewView:YES];
        
    } else if (currentLinkMicStatus == PLVLinkMicStatus_Joined) { // 已加入连麦（连麦中）
        [self.currentControlBar controlBarStatusSwitchTo:PLVECLinkMicControlBarStatus_Joined];
        // 同步控件状态
        self.currentControlBar.micButton.selected = !self.presenter.micDefaultOpen;
        [self.currentControlBar changeCameraButtonOpenUIWithoutEvent:self.presenter.cameraDefaultOpen];
    }
}

/// 连麦管理器 ‘是否正在处理’ 发生改变
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter operationInProgress:(BOOL)inProgress {
    [self.controlBar controlBarUserInteractionEnabled:!inProgress];
}

/// 连麦管理器发生错误
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
              didOccurError:(PLVLinkMicErrorCode)errorCode
                  extraCode:(NSInteger)extraCode {
    UIViewController *currentVC = [PLVFdUtil getCurrentViewController];
    if (errorCode >= PLVLinkMicErrorCode_RequestJoinFailedNoAuth &&
        errorCode <= PLVLinkMicErrorCode_RequestJoinFailedSocketTimeout) { // 举手失败
        // 定义提示文案
        NSString * title = @"举手失败";
        NSString * msg = @"";
        
        // 可根据业务所需，自定义具体提示文案内容
        if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedNoAuth) {
            msg = [NSString stringWithFormat:@"连麦需要获取您的音视频权限，请前往设置 %ld",(long)errorCode];
            [PLVAuthorizationManager showAlertWithTitle:title message:msg viewController:currentVC];
        } else if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedStatusIllegal){
            msg = [NSString stringWithFormat:@"当前连麦状态不匹配 %ld,%ld 请稍后再试或重进直播间",(long)errorCode,(long)extraCode];
        } else if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedRtcEnabledGetFail){
            msg = [NSString stringWithFormat:@"接口请求失败，请稍后再试 %ld",(long)errorCode];
        } else if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedNoRtcType){
            msg = [NSString stringWithFormat:@"rtcType 非法，请尝试重进直播间 %ld",(long)errorCode];
        } else if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedNoToken){
            msg = [NSString stringWithFormat:@"连麦 Token 更新失败，请稍后再试 %ld",(long)errorCode];
        }else if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedSocketCannotSend){
            msg = [NSString stringWithFormat:@"消息暂时无法发送，请稍后再试 %ld",(long)errorCode];
        } else if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedSocketTimeout){
            msg = [NSString stringWithFormat:@"消息发送超时，请稍后再试 %ld",(long)errorCode];
        }
        
        if (errorCode != PLVLinkMicErrorCode_RequestJoinFailedNoAuth) { // 弹窗提示
            [PLVECUtils showHUDWithTitle:@"举手失败" detail:msg view:currentVC.view];
        }
    } else if (errorCode == PLVLinkMicErrorCode_CancelRequestJoinFailedStatusIllegal) { // 取消举手失败
        NSString * msg = @"";
        if (errorCode == PLVLinkMicErrorCode_CancelRequestJoinFailedStatusIllegal) {
            msg = [NSString stringWithFormat:@"当前连麦状态不匹配 %ld 请稍后再试或重进直播间",(long)presenter.linkMicStatus];
        }
        
        [PLVECUtils showHUDWithTitle:@"取消举手失败" detail:msg view:currentVC.view];
    } else if (errorCode >= PLVLinkMicErrorCode_AnswerInvitationFailedStatusIllegal &&
               errorCode <= PLVLinkMicErrorCode_AnswerInvitationFailedLinkMicLimited) { // 接受连麦邀请失败
        NSString * msg = @"上麦失败";
        if (errorCode == PLVLinkMicErrorCode_AnswerInvitationFailedLinkMicLimited) {
            msg = @"上麦失败，当前上麦人数已达最大人数";
        }
        [PLVECUtils showHUDWithTitle:nil detail:msg view:currentVC.view afterDelay:3.0f];
    } else if (errorCode >= PLVLinkMicErrorCode_JoinChannelFailed &&
               errorCode <= PLVLinkMicErrorCode_JoinChannelFailedSocketCannotSend) { // 加入Rtc频道失败
        NSString * msg = @"";
        if (errorCode == PLVLinkMicErrorCode_JoinChannelFailed) {
            msg = [NSString stringWithFormat:@"连麦引擎创建错误 %ld,%ld",(long)errorCode,(long)extraCode];
        } else if (errorCode == PLVLinkMicErrorCode_JoinChannelFailedStatusIllegal) {
            msg = [NSString stringWithFormat:@"当前连麦状态不匹配 %ld 请稍后再试或重进直播间",(long)presenter.linkMicStatus];
        } else if (errorCode == PLVLinkMicErrorCode_JoinChannelFailedSocketCannotSend) {
            msg = [NSString stringWithFormat:@"消息暂时无法发送，请稍后再试 %ld",(long)errorCode];
        }
        
        [PLVECUtils showHUDWithTitle:@"加入连麦失败" detail:msg view:currentVC.view];
    } else if (errorCode >= PLVLinkMicErrorCode_JoinedOccurError &&
               errorCode <= PLVLinkMicErrorCode_JoinedOccurErrorStartAudioFailed) { // RTC遇到错误
        NSString * msg = @"";
        if (errorCode == PLVLinkMicErrorCode_JoinedOccurError) {
            msg = [NSString stringWithFormat:@"%ld,%ld",(long)errorCode,(long)extraCode];
        } else if (errorCode == PLVLinkMicErrorCode_JoinedOccurErrorStartAudioFailed) {
            msg = [NSString stringWithFormat:@"启动音频模块失败，请确认音频模块未被占用后再试 %ld,%ld",(long)errorCode,(long)extraCode];
        }
        
        [PLVECUtils showHUDWithTitle:@"RTC遇到错误" detail:msg view:currentVC.view];
    } else if (errorCode >= PLVLinkMicErrorCode_LeaveChannelFailedStatusIllegal &&
               errorCode <= PLVLinkMicErrorCode_LeaveChannelFailedSocketCannotSend) { // 退出连麦失败
        NSString * msg = @"";
        if (errorCode == PLVLinkMicErrorCode_LeaveChannelFailedStatusIllegal) {
            msg = [NSString stringWithFormat:@"当前连麦状态不匹配 %ld 请稍后再试或重进直播间",(long)presenter.linkMicStatus];
        } else if (errorCode == PLVLinkMicErrorCode_LeaveChannelFailedSocketCannotSend) {
            msg = [NSString stringWithFormat:@"消息暂时无法发送，请稍后再试 %ld",(long)errorCode];
        }
        
        [PLVECUtils showHUDWithTitle:@"退出连麦失败" detail:msg view:currentVC.view];
    }
}

/// 申请连麦时，用于更新连麦序号
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter didLinkMicRequestIndexUpdate:(NSInteger)linkMicIndex {
    [self.currentControlBar updateLinkMicRequestIndex:linkMicIndex];
}

/// ’RTC房间在线用户数组‘ 发生改变
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray *)onlineUserArray {
    [self.windowsView reloadLinkMicUserWindows];
}

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter mainSpeakerChangedToLinkMicUserId:(NSString *)linkMicUserId  {
    [self.windowsView updateFirstSiteCanvasViewWithUserId:linkMicUserId];
}

/// 当前’主讲‘ 的rtc画面，需要切至 主屏/副屏 显示
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
   mainSpeakerLinkMicUserId:(NSString *)mainSpeakerLinkMicUserId
    mainSpeakerToMainScreen:(BOOL)mainSpeakerToMainScreen {
    
}

/// 静音某个用户 媒体类型 关闭打开 返回是否能找到
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
              didMediaMuted:(BOOL)mute
                  mediaType:(NSString *)mediaType
                linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser {
    if (linkMicUser.localUser) { // 本地用户
        if ([mediaType isEqualToString:@"audio"]) {
            self.currentControlBar.micButton.selected = !linkMicUser.currentMicOpen;
        } else if ([mediaType isEqualToString:@"video"]) {
            [self.currentControlBar changeCameraButtonOpenUIWithoutEvent:linkMicUser.currentCameraOpen];
        }
    }
}

/// 需获知 ‘当前频道是否直播中’
- (BOOL)plvLinkMicPresenterGetChannelInLive:(PLVLinkMicPresenter *)presenter {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvECLinkMicAreaViewGetChannelInLive:)]) {
        return [self.delegate plvECLinkMicAreaViewGetChannelInLive:self];
    } else {
        NSLog(@"PLVECLinkMicAreaView - delegate not implement method:[plvECLinkMicAreaViewGetChannelInLive:]");
        return NO;
    }
}

/// 当前下行网络质量
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter localUserNetworkRxQuality:(PLVBLinkMicNetworkQuality)rxQuality {
    if (self.inLinkMic) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvECLinkMicAreaView:localUserNetworkRxQuality:)]) {
        [self.delegate plvECLinkMicAreaView:self localUserNetworkRxQuality:rxQuality];
    }
}

/// 当前用户被老师下麦
- (void)plvLinkMicPresenterLocalUserLinkMicWasHanduped:(PLVLinkMicPresenter *)presenter {
    UIViewController *currentVC = [PLVFdUtil getCurrentViewController];
    [PLVECUtils showHUDWithTitle:@"主播已结束您的连麦" detail:@"" view:currentVC.view];
}

@end
