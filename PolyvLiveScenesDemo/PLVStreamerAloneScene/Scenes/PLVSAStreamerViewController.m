//
//  PLVSAStreamerViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStreamerViewController.h"

// 工具类
#import "PLVSAUtils.h"

// UI
#import "PLVSALinkMicAreaView.h"
#import "PLVSAShadowMaskView.h"
#import "PLVSAStreamerSettingView.h"
#import "PLVSACountDownView.h"
#import "PLVSAStreamerHomeView.h"
#import "PLVSAStreamerFinishView.h"
#import "PLVSAFinishStreamerSheet.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVSAChatroomViewModel.h"
#import "PLVMemberPresenter.h"
#import "PLVStreamerPresenter.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

/// PLVSAStreamerViewController 所处的四种状态，不同状态下，展示不同的页面
typedef NS_ENUM(NSInteger, PLVSAStreamerViewState) {
    PLVSAStreamerViewStateBeforeSteam = 0, // 开播前的设置页
    PLVSAStreamerViewStateBeginSteam  = 1, // 准备开播的倒计时页
    PLVSAStreamerViewStateSteaming    = 2, // 开播中的推流页
    PLVSAStreamerViewStateFinishSteam = 3  // 结束开播的结束页
};

@interface PLVSAStreamerViewController ()<
PLVSAStreamerSettingViewDelegate,
PLVSALinkMicAreaViewDelegate,
PLVSocketManagerProtocol,
PLVStreamerPresenterDelegate,
PLVMemberPresenterDelegate,
PLVSAStreamerHomeViewDelegate
>

#pragma mark 模块
@property (nonatomic, strong) PLVStreamerPresenter *streamerPresenter;
@property (nonatomic, strong) PLVMemberPresenter *memberPresenter;

#pragma mark UI
/// view hierarchy
///
/// 开播前（viewState为PLVSAStreamerViewStateBeforeSteam时）
/// (UIView) self.view
///    ├─ (PLVSALinkMicAreaView) linkMicAreaView
///    │     └── (PLVSALinkMicWindowsView) linkMicWindowsView
///    ├─ (PLVSAShadowMaskView) shadowMaskView
///    └─ (PLVSAStreamerSettingView) settingView
///
/// 准备开播（viewState为PLVSAStreamerViewStateBeginSteam时）
/// (UIView) self.view
///    ├─ (PLVSALinkMicAreaView) linkMicAreaView
///    │     └── (PLVSALinkMicWindowsView) linkMicWindowsView
///    ├─ (PLVSAShadowMaskView) shadowMaskView
///    └─ (PLVSAStreamerHomeView) homeView
///
/// 开播时（viewState为PLVSAStreamerViewStateSteaming时）
/// (UIView) self.view
///    ├─ (PLVSALinkMicAreaView) linkMicAreaView
///    ├─ (PLVSAShadowMaskView) shadowMaskView
///    └─ (PLVSAStreamerHomeView) homeView
///          └── (PLVSALinkMicWindowsView) linkMicWindowsView
///
/// 开播结束（viewState为PLVSAStreamerViewStateFinishSteam时）
/// (UIView) self.view
///    ├─ (PLVSALinkMicAreaView) linkMicAreaView
///    ├─ (PLVSAShadowMaskView) shadowMaskView
///    └─ (PLVSAStreamerFinishView) finishView
@property (nonatomic, assign) PLVSAStreamerViewState viewState; // 控制器所处的页面状态
@property (nonatomic, strong) PLVSALinkMicAreaView *linkMicAreaView; // 连麦视图
@property (nonatomic, strong) PLVSAShadowMaskView *shadowMaskView; // 渐变遮罩视图
@property (nonatomic, strong) PLVSAStreamerSettingView *settingView; // 开播前的设置页
@property (nonatomic, strong) PLVSACountDownView *countDownView; // 准备开播的倒计时页
@property (nonatomic, strong) PLVSAStreamerHomeView *homeView; // 开播中的推流页
@property (nonatomic, strong) PLVSAStreamerFinishView *finishView; // 结束开播的结束页

#pragma mark 数据
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中

@end

@implementation PLVSAStreamerViewController

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        // 启动聊天室管理器
        [[PLVSAChatroomViewModel sharedViewModel] setup];
        
        // 监听socket消息
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [PLVSAUtils sharedUtils].homeVC = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupModule];
    [self preapareStartClass];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self getEdgeInset];
    
    self.linkMicAreaView.frame = self.view.bounds;
    self.shadowMaskView.frame = self.view.bounds;
    
    // 此处不可使用 self. 会触发初始化
    _settingView.frame = self.view.bounds;
    _countDownView.frame = self.view.bounds;
    _homeView.frame = self.view.bounds;
    _finishView.frame = self.view.bounds;
}

#pragma mark - [ Override ]

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - [ Private Method ]

/// 登出操作
- (void)logout {
    [self chatroomLogout];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerViewControllerLogout:)]) {
        [self.delegate streamerViewControllerLogout:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// 启动、挂断视频连麦
- (void)startLinkMic:(BOOL)start {
    NSString * suceessTitle = start ? @"已开启视频连麦，观众可以申请连麦" : @"已挂断所有连麦";
    NSString * failTitle = start ? @"开启视频连麦失败，请稍后再试" : @"关闭视频连麦失败，请稍后再试";
    __weak typeof(self) weakSelf = self;
    [self.streamerPresenter openVideoLinkMic:start
                           emitCompleteBlock:^(BOOL emitSuccess) {
        if (emitSuccess) { // 成功
            [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType = weakSelf.streamerPresenter.channelLinkMicMediaType;
            [self.homeView setLinkMicButtonSelected:start];
            [PLVSAUtils showToastInHomeVCWithMessage:suceessTitle];
        } else {
            [self.homeView setLinkMicButtonSelected:self.streamerPresenter.channelLinkMicOpen];
            [PLVSAUtils showToastInHomeVCWithMessage:failTitle];
            
        }
    }];
}

#pragma mark Getter & Setter

- (PLVSALinkMicAreaView *)linkMicAreaView {
    if (!_linkMicAreaView) {
        _linkMicAreaView = [[PLVSALinkMicAreaView alloc] init];
        _linkMicAreaView.delegate = self;
    }
    return _linkMicAreaView;
}

- (PLVSAShadowMaskView *)shadowMaskView {
    if (!_shadowMaskView) {
        _shadowMaskView = [[PLVSAShadowMaskView alloc] init];
    }
    return _shadowMaskView;
}

- (PLVSAStreamerSettingView *)settingView {
    if (!_settingView) {
        _settingView = [[PLVSAStreamerSettingView alloc] init];
        _settingView.delegate = self;
    }
    return _settingView;
}

- (PLVSACountDownView *)countDownView {
    if (!_countDownView) {
        _countDownView = [[PLVSACountDownView alloc] init];
        __weak typeof(self) weakSelf = self;
        _countDownView.countDownCompletedHandler = ^{ // 结束倒计时
            // 开始上课
            int resultCode = [weakSelf.streamerPresenter startClass];
            if (resultCode < 0) {
                [PLVSAUtils showToastWithMessage:[NSString stringWithFormat:@"上课错误 %d",resultCode] inView:weakSelf.view];
            }
            // 更新界面UI
            [weakSelf updateViewState:PLVSAStreamerViewStateSteaming];
        };
    }
    return _countDownView;
}

- (PLVSAStreamerFinishView *)finishView {
    if (!_finishView) {
        _finishView = [[PLVSAStreamerFinishView alloc] init];
        __weak typeof(self) weakSelf = self;
        _finishView.finishButtonHandler = ^{
            [weakSelf logout];
        };
    }
    return _finishView;
}

#pragma mark Initialize

- (void)setupUI {
    [self.view addSubview:self.linkMicAreaView];
    [self.view addSubview:self.shadowMaskView];
    [self.view addSubview:self.settingView];
}

- (void)setupModule {
    // 初始化成员模块
    self.memberPresenter = [[PLVMemberPresenter alloc] init];
    self.memberPresenter.delegate = self;
    [self.memberPresenter start];// 开始获取成员列表数据并开启自动更新
    
    // 初始化推流模块
    self.streamerPresenter = [[PLVStreamerPresenter alloc] init];
    self.streamerPresenter.delegate = self;
    
    // 设置麦克风、摄像头默认配置
    self.streamerPresenter.micDefaultOpen = YES;
    self.streamerPresenter.cameraDefaultOpen = YES;
    self.streamerPresenter.cameraDefaultFront = YES;
    
    self.streamerPresenter.previewType = PLVStreamerPresenterPreviewType_UserArray;
    [self.streamerPresenter setupStreamQuality:[PLVRoomData streamQualityWithResolutionType:[PLVRoomDataManager sharedManager].roomData.maxResolution]];
    [self.streamerPresenter setupStreamScale:PLVBLinkMicStreamScale9_16];
    [self.streamerPresenter setupLocalVideoPreviewSameAsRemoteWatch:YES];
    [self.streamerPresenter setupMixLayoutType:PLVRTCStreamerMixLayoutType_Tile];
}

- (void)getEdgeInset {
    if ([PLVSAUtils sharedUtils].hadSetAreaInsets) {
        return;
    }
    
    [PLVSAUtils sharedUtils].hadSetAreaInsets = YES;
    [PLVSAUtils sharedUtils].landscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (@available(iOS 11, *)) {
        [[PLVSAUtils sharedUtils] setupAreaInsets:self.view.safeAreaInsets];
    }
}

#pragma mark UI

- (void)updateViewState:(PLVSAStreamerViewState)viewState {
    if (viewState <= self.viewState) { // viewState 只能递增，不能递减
        return;
    }
    self.viewState = viewState;
    
    if (_settingView && _settingView.superview) {
        [_settingView removeFromSuperview];
        _settingView = nil;
    }
    if (_countDownView && _countDownView.superview) {
        [_countDownView removeFromSuperview];
        _countDownView = nil;
    }
    if (_homeView && _homeView.superview) {
        [_homeView removeFromSuperview];
        _homeView = nil;
    }
    if (_finishView && _finishView.superview) {
        [_finishView removeFromSuperview];
        _finishView = nil;
    }
    
    if (self.viewState == PLVSAStreamerViewStateBeginSteam) {
        [self.view addSubview:self.countDownView];
        [self.countDownView startCountDown];
    } else if (self.viewState == PLVSAStreamerViewStateSteaming) {
        [self setupHomeView];
        [self.view addSubview:self.homeView];
    } else if (self.viewState == PLVSAStreamerViewStateFinishSteam) {
        [self.linkMicAreaView clear];
        [self.view addSubview:self.finishView];
    }
}

- (void)setupHomeView { // home不使用懒加载，是为了避免在回调中提前初始化
    self.homeView = [[PLVSAStreamerHomeView alloc] initWithLocalOnlineUser:self.streamerPresenter.localOnlineUser
                                                        linkMicWindowsView:self.linkMicAreaView.windowsView];
    self.homeView.delegate = self;
    [self.homeView updateUserList:[self.memberPresenter userList]
                        userCount:self.memberPresenter.userCount
                      onlineCount:[self.streamerPresenter.onlineUserArray count]];
}

#pragma mark Start Class

- (void)preapareStartClass {
    __weak typeof(self) weakSelf = self;
    [self.streamerPresenter prepareLocalMicCameraPreviewCompletion:^(BOOL granted, BOOL prepareSuccess) {
        if (prepareSuccess) {
            [weakSelf.streamerPresenter setupLocalPreviewWithCanvaView:nil setupCompletion:^(BOOL setupResult) {
                if (setupResult) {
                    [weakSelf.streamerPresenter startLocalMicCameraPreviewByDefault];
                }
            }];
        }
        if (!granted) {
            [PLVSAUtils showAlertWithTitle:@"音视频权限申请"
                                   Message:@"请前往“设置-隐私”开启权限"
                         cancelActionTitle:@"取消"
                         cancelActionBlock:nil
                        confirmActionTitle:@"设置" confirmActionBlock:^{
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }
        [weakSelf.settingView cameraAuthorizationGranted:granted];
    }];
}

- (void)tryStartClass:(BOOL)autoTry {
    if (self.streamerPresenter.micCameraGranted) {
        if (self.streamerPresenter.networkQuality == PLVBLinkMicNetworkQualityUnknown) {
            NSString * tips = autoTry ? @"网络信号弱，持续检测中，请稍候再试" : @"网络检测中，请稍候";
            [PLVSAUtils showToastInHomeVCWithMessage:tips];
            if (!autoTry) {
                __weak typeof(self) weakSelf = self;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf tryStartClass:YES];
                });
            }
        }else if(self.streamerPresenter.networkQuality == PLVBLinkMicNetworkQualityDown){
            [PLVSAUtils showToastInHomeVCWithMessage:@"网络已断开，请检查网络"];
        }else{ // 开始上课倒数
            [self updateViewState:PLVSAStreamerViewStateBeginSteam];
        }
    }else{
        [self preapareStartClass];
    }
}

- (void)startClass { // 在此处理推流正式开始的UI更新
    [self.homeView startClass:YES];
}

#pragma mark finishClass（直播推流结束时调用）

- (void)finishClass {
    plv_dispatch_main_async_safe(^{
        // 结束上课
        self.finishView.duration = self.streamerPresenter.pushStreamValidDuration;
        self.finishView.startTime = self.streamerPresenter.startPushStreamTimestamp;
        [self.streamerPresenter finishClass];
        // 直播间关闭
        [self chatroomLogout];
        // 成员列表数据停止自动更新
        [self.memberPresenter stop];
        // 更新界面UI
        [self updateViewState:PLVSAStreamerViewStateFinishSteam];
    })
}

#pragma mark chatroomLogout（退出登录页时调用）

- (void)chatroomLogout {
    // 直播间关闭
    [PLVRoomLoginClient logout];
    [[PLVSAChatroomViewModel sharedViewModel] clear];
    [[PLVSocketManager sharedManager] logout];
    
}

#pragma mark - [ Delegate ]

#pragma mark PLVMemberPresenterDelegate

- (void)userListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    if (self.viewState != PLVSAStreamerViewStateSteaming) { // 尚未进入开播页，则尚未初始化成员列表弹层，无需更新数据
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.homeView updateUserList:[weakSelf.memberPresenter userList]
                                userCount:weakSelf.memberPresenter.userCount
                              onlineCount:[weakSelf.streamerPresenter.onlineUserArray count]];
    });
}

- (NSArray *)currentOnlineUserListInMemberPresenter:(PLVMemberPresenter *)memberPresenter{
    return self.streamerPresenter.onlineUserArray;
}

#pragma mark PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString { // 登陆成功
    [self.streamerPresenter joinRTCChannel];
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin ||
        error.code == PLVSocketLoginErrorCodeKick) &&
        error.localizedDescription) {
        [PLVSAUtils showAlertWithMessage:error.localizedDescription cancelActionTitle:@"确定" cancelActionBlock:^{
            [self logout];
        } confirmActionTitle:nil confirmActionBlock:nil];
    }
}

- (void)socketMananger_didConnectStatusChange:(PLVSocketConnectStatus)connectStatus {
    if(self.viewState != PLVSAStreamerViewStateSteaming){
        return;
    }
    if (connectStatus == PLVSocketConnectStatusReconnect) {
        self.socketReconnecting = YES;
        plv_dispatch_main_async_safe(^{
            [PLVSAUtils showToastWithMessage:@"聊天室重连中" inView:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVSAUtils showToastWithMessage:@"聊天室重连成功" inView:self.view];
            })
        }
    }
}

#pragma mark PLVStreamerPresenterDelegate

/// ‘房间加入状态’ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRtcRoomJoinStatus:(PLVStreamerPresenterRoomJoinStatus)currentRtcRoomJoinStatus
            inRTCRoomChanged:(BOOL)inRTCRoomChanged
                   inRTCRoom:(BOOL)inRTCRoom {
}

/// ‘网络状态’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
    networkQualityDidChanged:(PLVBLinkMicNetworkQuality)networkQuality {
    [self.homeView setNetworkQuality:networkQuality];
}

/// ’等待连麦用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
  linkMicWaitUserListRefresh:(NSArray <PLVLinkMicWaitUser *>*)waitUserArray
            newWaitUserAdded:(BOOL)newWaitUserAdded {
    if (newWaitUserAdded) {
        [self.homeView ShowNewWaitUserAdded];
    }
    
    if (waitUserArray &&
        [waitUserArray count] > 0) {
        [self.homeView showMemberBadge:YES];
    } else {
        [self.homeView showMemberBadge:NO];
    }
    
    [self.memberPresenter refreshUserListWithLinkMicWaitUserArray:waitUserArray];
}

/// ’RTC房间在线用户数组‘ 发生改变
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
linkMicOnlineUserListRefresh:(NSArray <PLVLinkMicOnlineUser *>*)onlineUserArray {
    [self.linkMicAreaView reloadLinkMicUserWindows];
    [self.memberPresenter refreshUserListWithLinkMicOnlineUserArray:onlineUserArray];
    [self.homeView showOrHiddenLinMicGuied:onlineUserArray.count];
}

/// ‘是否上课已开始’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
      classStartedDidChanged:(BOOL)classStarted
          startClassInfoDict:(NSDictionary *)startClassInfoDict{
    [PLVRoomDataManager sharedManager].roomData.startTimestamp = presenter.startPushStreamTimestamp;
    [PLVRoomDataManager sharedManager].roomData.liveDuration = presenter.pushStreamValidDuration;
    if (classStarted) {
        [self startClass];
    }
}

/// 当前 ’已有效推流时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
currentPushStreamValidDuration:(NSTimeInterval)pushStreamValidDuration {
    [self.homeView setPushStreamDuration:pushStreamValidDuration];
}

/// 当前 ’单次重连时长‘ 定时回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
currentReconnectingThisTimeDuration:(NSInteger)reconnectingThisTimeDuration{
    if (reconnectingThisTimeDuration == 20) {
        [PLVSAUtils showAlertWithMessage:@"网络断开，已停止直播，请更换网络后重试" cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:nil confirmActionBlock:nil];
    }
}

/// sessionId 场次Id发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
         sessionIdDidChanged:(NSString *)sessionId{
    [PLVRoomDataManager sharedManager].roomData.sessionId = sessionId;
}

/// 已挂断 某位远端用户的连麦 事件回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
   didCloseRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser {
    
}

/// 本地用户的 ’麦克风开关状态‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
     localUserMicOpenChanged:(BOOL)currentMicOpen {
    if (self.viewState == PLVSAStreamerViewStateSteaming) {
        [PLVSAUtils showToastWithMessage:(currentMicOpen ? @"已开启麦克风" : @"已关闭麦克风") inView:self.view];
    }
    [self.homeView setCurrentMicOpen:currentMicOpen];
}

/// 本地用户的 ’摄像头是否应该显示值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
localUserCameraShouldShowChanged:(BOOL)currentCameraShouldShow {
    if (self.viewState == PLVSAStreamerViewStateSteaming) {
        [PLVSAUtils showToastWithMessage:(currentCameraShouldShow ? @"已开启摄像头" : @"已关闭摄像头") inView:self.view];
    }
}

/// 本地用户的 ’摄像头前后置状态值‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
 localUserCameraFrontChanged:(BOOL)currentCameraFront {
}

/// 推流管理器 ‘发生错误’ 回调
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter
               didOccurError:(NSError *)error
               fullErrorCode:(NSString *)fullErrorCodeString {
    NSString * message = @"";
    if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedEmitFailed) {
        message = @"上课错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_StartClassFailedNetError){
        message = @"推流请求错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_UpdateRTCTokenFailedNetError){
        message = @"更新Token错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_UnknownError){
        message = @"未知错误";
    }else if (error.code == PLVStreamerPresenterErrorCode_NoError){
        message = @"错误";
    }
    message = [message stringByAppendingFormat:@" code:%@",fullErrorCodeString];
    
    [PLVSAUtils showToastWithMessage:message inView:self.view];
}

#pragma mark PLVSALinkMicAreaViewDelegate

- (PLVLinkMicOnlineUser *)localUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView {
    return self.streamerPresenter.localOnlineUser;
}

- (NSArray *)currentOnlineUserListInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView {
    return self.streamerPresenter.onlineUserArray;
}

- (NSInteger)onlineUserIndexInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView
                                  filterBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filterBlock {
    return [self.streamerPresenter findOnlineUserModelIndexWithFiltrateBlock:filterBlock];
}

- (PLVLinkMicOnlineUser *)onlineUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView
                                      withTargetIndex:(NSInteger)targetIndex {
    return [self.streamerPresenter getOnlineUserModelFromOnlineUserArrayWithIndex:targetIndex];
}

- (void)didSelectLinkMicUserInLinkMicAreaView:(PLVSALinkMicAreaView *)areaView {
    [self.homeView showOrHiddenLinMicGuied:0];
}

#pragma mark PLVSAStreamerSettingViewDelegate

- (void)streamerSettingViewBackButtonClick {
    [self logout];
}

- (void)streamerSettingViewStartButtonClickWithResolutionType:(PLVResolutionType)type {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:type];
    [self.streamerPresenter setupStreamQuality:streamQuality];
    [self tryStartClass:NO];
}

- (void)streamerSettingViewCameraReverseButtonClick {
    [self.streamerPresenter switchLocalUserFrontCamera];
    [self.settingView enableMirrorButton:self.streamerPresenter.currentCameraFront];
}

- (void)streamerSettingViewMirrorButtonClickWithMirror:(BOOL)mirror {
    [self.streamerPresenter setupLocalVideoPreviewMirrorMode:(mirror ? PLVBRTCVideoMirrorMode_Auto : PLVBRTCVideoMirrorMode_Disabled)];
}

- (void)streamerSettingViewBitRateButtonClickWithResolutionType:(PLVResolutionType)type {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:type];
    [self.streamerPresenter setupStreamQuality:streamQuality];
}

#pragma mark PLVSAStreamerHomeViewProtocol

- (void)bandUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId banned:(BOOL)banned {
    [self.memberPresenter banUserWithUserId:userId banned:banned];
}

- (void)kickUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId {
    [self.memberPresenter removeUserWithUserId:userId];
}

- (void)streamerHomeViewDidTapCloseButton:(PLVSAStreamerHomeView *)homeView {
    __weak typeof(self) weakSelf = self;
    PLVSAFinishStreamerSheet *actionSheet = [[PLVSAFinishStreamerSheet alloc] init];
    [actionSheet showInView:self.view finishAction:^{
        [weakSelf finishClass];
    }];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeCameraOpen:(BOOL)cameraOpen{
    [self.streamerPresenter openLocalUserCamera:cameraOpen];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)moreInfoSheet didChangeFlashOpen:(BOOL)flashOpen{
    [self.streamerPresenter openLocalUserCameraTorch:flashOpen];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeMicOpen:(BOOL)micOpen{
    [self.streamerPresenter openLocalUserMic:micOpen];
}

- (void)streamerHomeViewDidChangeCameraFront:(PLVSAStreamerHomeView *)homeView {
    [self.streamerPresenter switchLocalUserFrontCamera];
    if (self.streamerPresenter.currentCameraFront) {
        [self.homeView changeFlashButtonSelectedState:NO];
    }
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)moreInfoSheet didChangeMirrorOpen:(BOOL)mirrorOpen{
    [self.streamerPresenter setupLocalVideoPreviewMirrorMode:(mirrorOpen ? PLVBRTCVideoMirrorMode_Auto : PLVBRTCVideoMirrorMode_Disabled)];
}

- (PLVResolutionType)streamerHomeViewCurrentQuality:(PLVSAStreamerHomeView *)homeView {
    PLVResolutionType resolutionType = [PLVRoomData resolutionTypeWithStreamQuality:self.streamerPresenter.streamQuality];
    return resolutionType;
}

- (BOOL)streamerHomeViewChannelLinkMicOpen:(PLVSAStreamerHomeView *)homeView {
    return self.streamerPresenter.channelLinkMicOpen;
}

/// 点击连麦按钮回调
- (void)streamerHomeViewDidTapLinkMicButton:(PLVSAStreamerHomeView *)homeView linkMicButtonSelected:(BOOL)selected {
    if (!self.streamerPresenter.pushStreamStarted) {
        // 未开启连麦，更新连麦UI为未选中
        [self.homeView setLinkMicButtonSelected:NO];
        return;
    }
    
    if ([PLVRoomDataManager sharedManager].roomData.interactNumLimit == 0) {
        [PLVSAUtils showToastWithMessage:@"尚未开通，请联系管理员" inView:self.view];
        [self.homeView setLinkMicButtonSelected:NO];
        return;
    }
    
    if (!self.streamerPresenter.channelLinkMicOpen) {
        [self startLinkMic:YES];
    } else {
        __weak typeof(self) weakSelf = self;
        [PLVSAUtils showAlertWithTitle:@"确定关闭视频连麦吗？" Message:@"关闭后将挂断进行中的所有连麦" cancelActionTitle:@"取消" cancelActionBlock:^{
            [weakSelf.homeView setLinkMicButtonSelected:YES];
        } confirmActionTitle:@"确定" confirmActionBlock:^{
            [weakSelf startLinkMic:NO];
        }];
    }
}

- (void)streamerHomeViewDidMemberSheetDismiss:(PLVSAStreamerHomeView *)homeView {
    [self.homeView showMemberBadge:NO];
}

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeResolutionType:(PLVResolutionType)type {
    PLVBLinkMicStreamQuality streamQuality = [PLVRoomData streamQualityWithResolutionType:type];
    [self.streamerPresenter setupStreamQuality:streamQuality];
}

@end
