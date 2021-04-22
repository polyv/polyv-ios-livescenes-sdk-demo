//
//  PLVLCLinkMicAreaView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/7/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCLinkMicAreaView.h"

#import "PLVLCLinkMicWindowsView.h"
#import "PLVLCLinkMicSpeakingView.h"
#import "PLVLinkMicPresenter.h"
#import "PLVLCUtils.h"

#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

@interface PLVLCLinkMicAreaView () <
PLVLinkMicPresenterDelegate,
PLVLCLinkMicControlBarDelegate,
PLVLCLinkMicWindowsViewDelegate
>

#pragma mark 状态
@property (nonatomic, assign) BOOL areaViewShow;

#pragma mark 数据
@property (nonatomic, assign) BOOL currentLandscape; // 当前是否横屏 (YES:当前横屏 NO:当前竖屏)
@property (nonatomic, assign) NSInteger currentRTCRoomUserCount;

#pragma mark 对象
@property (nonatomic, strong) PLVLinkMicPresenter * presenter; // 连麦逻辑处理模块

#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  ├── (PLVLCLinkMicAreaView) self (lowest)
///  │    └── (PLVLCLinkMicWindowsView) windowsView
///  │
///  ├── (PLVLCLinkMicPortraitControlBar) portraitControlBar
///  └── (PLVLCLinkMicLandscapeControlBar) landscapeControlBar
@property (nonatomic, strong) PLVLCLinkMicWindowsView * windowsView;          // 连麦窗口列表视图 (负责展示 多个连麦成员RTC画面窗口，该视图支持左右滑动浏览)
@property (nonatomic, strong) PLVLCLinkMicPortraitControlBar * portraitControlBar;   // 连麦悬浮控制栏 (竖屏时出现)
@property (nonatomic, strong) PLVLCLinkMicLandscapeControlBar * landscapeControlBar; // 连麦悬浮控制栏 (横屏时出现)
@property (nonatomic, strong) id <PLVLCLinkMicControlBarProtocol> currentControlBar; // 当前连麦悬浮控制栏 (当前显示在屏幕上的 悬浮控制栏)
@property (nonatomic, strong) PLVLCLinkMicSpeakingView * landscapeSpeakingView; // 横屏‘某某正在发言’ 视图

@end

@implementation PLVLCLinkMicAreaView

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
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
    
    self.windowsView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    
    if (!fullScreen) {
        // 竖屏
        /// 添加 竖屏连麦悬浮控制栏
        /// (注:不可添加在window上，否则页面push时将一并带去)
        if (self.superview && !_portraitControlBar.superview) { [self.superview addSubview:self.portraitControlBar]; }
        self.currentControlBar = self.portraitControlBar; /// 设置当前的控制栏、同步另一控制栏的状态
    } else {
        // 横屏
        /// 添加 横屏连麦悬浮控制栏
        /// (注:不可添加在window上，否则页面push时将一并带去)
        if (self.superview && !_landscapeControlBar.superview) { [self.superview addSubview:self.landscapeControlBar]; }
        self.currentControlBar = self.landscapeControlBar; /// 设置当前的控制栏、同步另一控制栏的状态
        
        /// 添加 某某正在发言 视图
        if (self.superview && !_landscapeSpeakingView.superview) { [self.superview addSubview:self.landscapeSpeakingView]; }
    }
    
    if (fullScreenDifferent) {
        /// 布局 连麦控制栏
        [self.portraitControlBar refreshControlBarFrame];
        [self.landscapeControlBar refreshControlBarFrame];
    }
}


#pragma mark - [ Public Methods ]
- (void)showAreaView:(BOOL)showStatus{
    if (!self.inRTCRoom) {
        NSLog(@"PLVLCLinkMicAreaView - showAreaView failed, not in RTC Room");
        return;
    }
    self.areaViewShow = showStatus;
    __weak typeof(self) weakSelf = self;
    CGFloat toAlpha = showStatus ? 1.0 : 0.0;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.alpha = toAlpha;
    }];
}

- (void)showLinkMicControlBar:(BOOL)showStatus{
    [self.currentControlBar showSelfViewWithAnimation:showStatus];
}

- (void)startWatchNoDelay:(BOOL)startWatch{
    if (startWatch) {
        [self.presenter startWatchNoDelay];
    }else{
        [self.presenter stopWatchNoDelay];
    }
}

#pragma mark Getter
- (BOOL)inRTCRoom{
    return self.presenter.inRTCRoom;
}

- (PLVChannelLinkMicSceneType)linkMicSceneType{
    return self.presenter.linkMicSceneType;
}

- (BOOL)inLinkMic{
    return self.presenter.inLinkMic;
}


#pragma mark - [ Private Methods ]
- (void)setup{
    // 添加 连麦功能模块
    self.presenter = [[PLVLinkMicPresenter alloc] init];
    self.presenter.delegate = self;
    self.presenter.preRenderContainer = self;
    
    // 配置默认值
    /* 默认值以 连麦悬浮控制栏 中声明的为准 (详见 PLVLCLinkMicControlBarProtocol.h)
       若业务改变时，可直接修改 PLVLCLinkMicControlBarProtocol.h 的默认值，则 [Presenter]连麦管理器 中同时生效 */
    self.presenter.micDefaultOpen = PLVLCLinkMicControlBarMicDefaultOpen;
    self.presenter.cameraDefaultOpen = PLVLCLinkMicControlBarCameraDefaultOpen;
    self.presenter.cameraDefaultFront = PLVLCLinkMicControlBarSwitchCameraDefaultFront;
}

- (void)setupUI{
    self.alpha = 0;
    
    // 添加 连麦窗口列表视图
    [self addSubview:self.windowsView];
    
    [self portraitControlBar];
    self.currentControlBar = self.landscapeControlBar;
}

- (void)updateLandscapeSpeakingViewLayout{
    if (!self.landscapeSpeakingView.currentShow) { return; }
    
    CGFloat superViwWidth = CGRectGetWidth(self.superview.bounds);
    CGFloat topPadding = 60.0;
    CGFloat rightPadding = P_SafeAreaRightEdgeInsets();
    CGFloat landscapeSpeakingViewRightPadding = 150 + (rightPadding > 0 ? (rightPadding + 10) : 0);
    CGFloat landscapeSpeakingViewX = superViwWidth - landscapeSpeakingViewRightPadding - self.landscapeSpeakingView.currentWidthWithNicknamesText;
    
    self.landscapeSpeakingView.frame = CGRectMake(landscapeSpeakingViewX, topPadding, self.landscapeSpeakingView.currentWidthWithNicknamesText, 25);
}

#pragma mark Getter
- (PLVLCLinkMicPortraitControlBar *)portraitControlBar{
    if (!_portraitControlBar) {
        _portraitControlBar = [[PLVLCLinkMicPortraitControlBar alloc] init];
        _portraitControlBar.delegate = self;
    }
    return _portraitControlBar;
}

- (PLVLCLinkMicLandscapeControlBar *)landscapeControlBar{
    if (!_landscapeControlBar) {
        _landscapeControlBar = [[PLVLCLinkMicLandscapeControlBar alloc] init];
        _landscapeControlBar.delegate = self;
    }
    return _landscapeControlBar;
}

- (PLVLCLinkMicWindowsView *)windowsView{
    if (!_windowsView) {
        _windowsView = [[PLVLCLinkMicWindowsView alloc] init];
        _windowsView.delegate = self;
    }
    return _windowsView;
}

- (PLVLCLinkMicSpeakingView *)landscapeSpeakingView{
    if (!_landscapeSpeakingView) {
        _landscapeSpeakingView = [[PLVLCLinkMicSpeakingView alloc] init];
    }
    return _landscapeSpeakingView;
}

#pragma mark Setter
- (void)setCurrentControlBar:(id<PLVLCLinkMicControlBarProtocol>)currentControlBar{
    if (currentControlBar && currentControlBar != _currentControlBar) {
        [currentControlBar synchControlBarState:_currentControlBar];
        _currentControlBar = currentControlBar;
    }
}


#pragma mark - [ Delegate ]
#pragma mark PLVLCLinkMicControlBarDelegate
/// 连麦开关按钮 被点击
- (void)plvLCLinkMicControlBar:(id<PLVLCLinkMicControlBarProtocol>)bar onOffButtonClickedCurrentStatus:(PLVLCLinkMicControlBarStatus)status{
    __weak typeof(self) weakSelf = self;
    if (status == PLVLCLinkMicControlBarStatus_Open) {
        // Bar 处于显示 ‘申请连麦’，点击表示希望申请连麦
        [self.presenter requestJoinLinkMic];
    }else if (status == PLVLCLinkMicControlBarStatus_Waiting){
        // Bar 处于显示 ‘请求中...’，点击表示希望取消申请连麦
        [PLVFdUtil showAlertWithTitle:@"确认取消申请连麦吗？" message:nil viewController:[PLVFdUtil getCurrentViewController] cancelActionTitle:@"按错了" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:@"取消申请连麦" confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:^(UIAlertAction * _Nonnull action) {
            [weakSelf.presenter cancelRequestJoinLinkMic];
        }];
    }else if (status == PLVLCLinkMicControlBarStatus_Joined){
        // Bar 处于已连麦，点击表示希望取消申请连麦
        [PLVFdUtil showAlertWithTitle:@"确认挂断连麦吗？" message:nil viewController:[PLVFdUtil getCurrentViewController] cancelActionTitle:@"按错了" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:@"挂断" confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:^(UIAlertAction * _Nonnull action) {
            [weakSelf.presenter leaveLinkMic];
        }];
    }
}

/// 摄像头按钮 被点击
- (void)plvLCLinkMicControlBar:(id<PLVLCLinkMicControlBarProtocol>)bar cameraButtonClicked:(BOOL)wannaOpen openResult:(void (^)(BOOL))openResultBlock{
    [self.presenter cameraOpen:wannaOpen];
    if (openResultBlock) openResultBlock(YES);
}

/// 切换前后摄像头按钮 被点击
- (void)plvLCLinkMicControlBar:(id<PLVLCLinkMicControlBarProtocol>)bar switchCameraButtonClicked:(BOOL)front{
    [self.presenter cameraSwitch:front];
}

/// 麦克风按钮 被点击
- (void)plvLCLinkMicControlBar:(id<PLVLCLinkMicControlBarProtocol>)bar micCameraButtonClicked:(BOOL)open{
    [self.presenter micOpen:open];
}

#pragma mark PLVLCLinkMicWindowsViewDelegate
/// 连麦窗口列表视图 需获知 ‘当前频道连麦场景类型’
- (PLVChannelLinkMicSceneType)plvLCLinkMicWindowsViewGetCurrentLinkMicSceneType:(PLVLCLinkMicWindowsView *)windowsView{
    return self.presenter.linkMicSceneType;
}

/// 连麦窗口列表视图 需外部展示 ‘第一画面连麦窗口’
- (void)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView showFirstSiteCanvasViewOnExternal:(UIView *)canvasView{
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicAreaView:showFirstSiteCanvasViewOnExternal:)]) {
        [self.delegate plvLCLinkMicAreaView:self showFirstSiteCanvasViewOnExternal:canvasView];
    }
}

/// 连麦窗口被点击事件 (表示用户希望视图位置交换)
- (UIView *)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView wantExchangeWithExternalViewForLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser canvasView:(UIView *)canvasView{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLinkMicAreaView:rtcWindowDidClickedCanvasView:)]) {
        return [self.delegate plvLCLinkMicAreaView:self rtcWindowDidClickedCanvasView:canvasView];
    }else{
        NSLog(@"PLVLCLinkMicAreaView - delegate not implement method:%s",__FUNCTION__);
        return nil;
    }
}

/// 连麦窗口需要回退外部视图
- (void)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView rollbackExternalView:(UIView *)externalView{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLinkMicAreaView:rollbackExternalView:)]) {
        [self.delegate plvLCLinkMicAreaView:self rollbackExternalView:externalView];
    }
}

/// 连麦窗口被点击事件 (表示用户希望某个窗口成为‘第一画面’)
- (void)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView linkMicUserWantToBecomeFirstSite:(NSInteger)index{
    [self.presenter changeMainSpeakerInLocalWithLinkMicUserIndex:index];
}

/// 连麦窗口列表视图 需要获取当前用户数组
- (NSArray *)plvLCLinkMicWindowsViewGetCurrentUserModelArray:(PLVLCLinkMicWindowsView *)windowsView{
    return self.presenter.onlineUserArray;
}

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
- (NSInteger)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock{
    return [self.presenter findUserModelIndexWithFiltrateBlock:filtrateBlockBlock];
}

/// 连麦窗口列表视图 需要根据下标值获取对应用户
- (PLVLinkMicOnlineUser *)plvLCLinkMicWindowsView:(PLVLCLinkMicWindowsView *)windowsView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex{
    return [self.presenter getUserModelFromOnlineUserArrayWithIndex:targetIndex];
}

#pragma mark PLVLinkMicPresenterDelegate
/// 房间加入状态发生改变
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter currentRtcRoomJoinStatus:(PLVLinkMicPresenterRoomJoinStatus)currentRtcRoomJoinStatus inRTCRoomChanged:(BOOL)inRTCRoomChanged inRTCRoom:(BOOL)inRTCRoom{
    if (inRTCRoomChanged) {
        [self showAreaView:inRTCRoom]; /// 作为默认显示状态
        
        if ([self.delegate respondsToSelector:@selector(plvLCLinkMicAreaView:inRTCRoomChanged:)]) {
            [self.delegate plvLCLinkMicAreaView:self inRTCRoomChanged:inRTCRoom];
        }
    }
}

/// 连麦状态 发生改变
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter currentLinkMicStatus:(PLVLinkMicStatus)currentLinkMicStatus inLinkMicChanged:(BOOL)inLinkMicChanged inLinkMic:(BOOL)inLinkMic{
    if (inLinkMicChanged) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLinkMicAreaView:inLinkMicChanged:)]) {
            [self.delegate plvLCLinkMicAreaView:self inLinkMicChanged:inLinkMic];
        }
    }
    
    if (currentLinkMicStatus == PLVLinkMicStatus_NotOpen) {
        [self.currentControlBar controlBarStatusSwitchTo:PLVLCLinkMicControlBarStatus_Default];
    }else if (currentLinkMicStatus == PLVLinkMicStatus_Open) {
        PLVLCLinkMicControlBarType barType = presenter.linkMicMediaType == PLVLinkMicMediaType_Audio ? PLVLCLinkMicControlBarType_Audio : PLVLCLinkMicControlBarType_Video;
        self.currentControlBar.barType = barType;
        [self.currentControlBar controlBarStatusSwitchTo:PLVLCLinkMicControlBarStatus_Open];
    }else if (currentLinkMicStatus == PLVLinkMicStatus_Waiting) {
        [self.currentControlBar controlBarStatusSwitchTo:PLVLCLinkMicControlBarStatus_Waiting];
    }else if (currentLinkMicStatus == PLVLinkMicStatus_Joined) {
        [self.currentControlBar controlBarStatusSwitchTo:PLVLCLinkMicControlBarStatus_Joined];
    }
}

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter didMediaMuted:(BOOL)mute mediaType:(NSString *)mediaType linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser{
    if (linkMicUser.localUser) {
        /// 本地用户
        if ([mediaType isEqualToString:@"audio"]) {
            self.currentControlBar.micButton.selected = !linkMicUser.currentMicOpen;
        }else if ([mediaType isEqualToString:@"video"]){
            [self.currentControlBar changeCameraButtonOpenUIWithoutEvent:linkMicUser.currentCameraOpen];
        }
    }else{
        /// 远端用户
        /// 远端用户的UI改变，将由 PLVLinkMicOnlineUser 中的Block事件处理
    }
}

/// 连麦管理器的处理状态 发生改变
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter operationInProgress:(BOOL)inProgress{
    [self.currentControlBar controlBarUserInteractionEnabled:!inProgress];
}

/// 连麦在线用户数组 发生变化
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray *)onlineUserArray{
    NSInteger userCount = onlineUserArray.count;
    BOOL needCallback = (self.currentRTCRoomUserCount != userCount);
    self.currentRTCRoomUserCount = userCount;
    if (needCallback) {
        if ([self.delegate respondsToSelector:@selector(plvLCLinkMicAreaView:currentRTCRoomUserCountChanged:)]) {
            [self.delegate plvLCLinkMicAreaView:self currentRTCRoomUserCountChanged:self.currentRTCRoomUserCount];
        }
    }
    
    [self.windowsView reloadLinkMicUserWindows];
}

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter mainSpeakerLinkMicUserId:(NSString *)mainSpeakerLinkMicUserId mainSpeakerToMainScreen:(BOOL)mainSpeakerToMainScreen{
    if (presenter.inRTCRoom) {
        [self.windowsView linkMicWindowMainSpeaker:mainSpeakerLinkMicUserId toMainScreen:mainSpeakerToMainScreen];
    }else{
        NSLog(@"PLVLCLinkMicAreaView -  call [linkMicWindowLinkMicUserId:wannaBecomeFirstSite:] failed, not in linkmic");
    }
}

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter mainSpeakerChangedToLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser {
    // 讲师让某位连麦人成为’主讲‘，即第一画面；TODO 当前不会触发此方法
}

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter didOccurError:(PLVLinkMicErrorCode)errorCode extraCode:(NSInteger)extraCode{
    UIViewController * currentVC = [PLVFdUtil getCurrentViewController];
    if (errorCode >= PLVLinkMicErrorCode_RequestJoinFailedNoAuth &&
        errorCode <= PLVLinkMicErrorCode_RequestJoinFailedSocketTimeout) { /// 举手失败
        // 定义提示文案
        NSString * title = @"举手失败";
        NSString * msg = @"";
        BOOL showed = NO;
        
        // 可根据业务所需，自定义具体提示文案内容
        if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedNoAuth) {
            msg = [NSString stringWithFormat:@"连麦需要获取您的音视频权限，请前往设置 %ld",(long)errorCode];
            showed = YES;
            [PLVAuthorizationManager showAlertWithTitle:title message:msg viewController:currentVC];
        } else if (errorCode == PLVLinkMicErrorCode_RequestJoinFailedStatusIllegal){
            msg = [NSString stringWithFormat:@"当前连麦状态不匹配 %ld,%ld",(long)errorCode,(long)extraCode];
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
        
        // 弹窗提示
        if (!showed) { [PLVLCUtils showHUDWithTitle:title detail:msg view:currentVC.view]; }
    } else if (errorCode == PLVLinkMicErrorCode_CancelRequestJoinFailedStatusIllegal){ /// 取消举手失败
        NSString * msg = @"";
        if (errorCode == PLVLinkMicErrorCode_CancelRequestJoinFailedStatusIllegal) {
            msg = [NSString stringWithFormat:@"当前连麦状态不匹配 %ld 请稍后再试",(long)presenter.linkMicStatus];
        }
        
        [PLVLCUtils showHUDWithTitle:@"取消举手失败" detail:msg view:currentVC.view];
    } else if (errorCode >= PLVLinkMicErrorCode_JoinChannelFailed &&
               errorCode <= PLVLinkMicErrorCode_JoinChannelFailedSocketCannotSend){ /// 加入Rtc频道失败
        NSString * msg = @"";
        if (errorCode == PLVLinkMicErrorCode_JoinChannelFailed) {
            msg = [NSString stringWithFormat:@"连麦引擎创建错误 %ld,%ld",(long)errorCode,(long)extraCode];
        }else if (errorCode == PLVLinkMicErrorCode_JoinChannelFailedStatusIllegal){
            msg = [NSString stringWithFormat:@"当前连麦状态不匹配 %ld 请稍后再试",(long)presenter.linkMicStatus];
        } else if (errorCode == PLVLinkMicErrorCode_JoinChannelFailedSocketCannotSend){
            msg = [NSString stringWithFormat:@"消息暂时无法发送，请稍后再试 %ld",(long)errorCode];
        }
        
        [PLVLCUtils showHUDWithTitle:@"加入连麦失败" detail:msg view:currentVC.view];
    } else if (errorCode == PLVLinkMicErrorCode_JoinedOccurError){ /// 连麦中发生错误
        NSString * msg = @"";
        if (errorCode == PLVLinkMicErrorCode_JoinedOccurError) {
            msg = [NSString stringWithFormat:@"%ld,%ld",(long)errorCode,(long)extraCode];
        }
        
        [PLVLCUtils showHUDWithTitle:@"RTC遇到错误" detail:msg view:currentVC.view];
    } else if (errorCode >= PLVLinkMicErrorCode_LeaveChannelFailedStatusIllegal &&
               errorCode <= PLVLinkMicErrorCode_LeaveChannelFailedSocketCannotSend){ /// 退出连麦失败
        NSString * msg = @"";
        if (errorCode == PLVLinkMicErrorCode_LeaveChannelFailedStatusIllegal) {
            msg = [NSString stringWithFormat:@"当前连麦状态不匹配 %ld 请稍后再试",(long)presenter.linkMicStatus];
        } else if (errorCode == PLVLinkMicErrorCode_LeaveChannelFailedSocketCannotSend){
            msg = [NSString stringWithFormat:@"消息暂时无法发送，请稍后再试 %ld",(long)errorCode];
        }
        
        [PLVLCUtils showHUDWithTitle:@"退出连麦失败" detail:msg view:currentVC.view];
    }
}

/// 全部连麦成员的音频音量 回调
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter reportAudioVolumeOfSpeakers:(NSDictionary<NSString *,NSNumber *> *)volumeDict{

}

/// 当前正在讲话的连麦成员
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter reportCurrentSpeakingUsers:(NSArray<PLVLinkMicOnlineUser *> *)currentSpeakingUsers{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        [self.landscapeSpeakingView updateSpeakingInfoWithNicknames:[currentSpeakingUsers valueForKeyPath:@"nickname"]];
        [self updateLandscapeSpeakingViewLayout];
    }
}

@end
