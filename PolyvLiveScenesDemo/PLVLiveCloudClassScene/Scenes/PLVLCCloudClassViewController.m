//
//  PLVLCCloudClassViewController.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/11/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCCloudClassViewController.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVLCChatroomViewModel.h"
#import <PLVLiveScenesSDK/PLVSocketManager.h>

// UI
#import "PLVLCMediaAreaView.h"
#import "PLVLCLinkMicAreaView.h"
#import "PLVLCLivePageMenuAreaView.h"
#import "PLVLCLiveRoomPlayerSkinView.h"
#import "PLVLCChatLandscapeView.h"
#import "PLVInteractView.h"

// 工具
#import "PLVLCUtils.h"

@interface PLVLCCloudClassViewController ()<
PLVSocketManagerProtocol,
PLVLCMediaAreaViewDelegate,
PLVLCLinkMicAreaViewDelegate,
PLVLCLiveRoomPlayerSkinViewDelegate,
PLVLCChatroomViewModelProtocol,
PLVRoomDataManagerProtocol
>

#pragma mark 数据
@property (nonatomic, assign, readonly) PLVChannelType channelType; // 只读，当前 频道类型
@property (nonatomic, assign, readonly) PLVChannelVideoType videoType; // 只读，当前 视频类型
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中

#pragma mark 状态
@property (nonatomic, assign) BOOL currentLandscape;    // 当前是否横屏 (YES:当前横屏 NO:当前竖屏)
@property (nonatomic, assign) BOOL fullScreenDifferent; // 在更新UI布局之前，横竖屏是否发现了变化 (YES:已变化 NO:没有变化)

#pragma mark 模块
@property (nonatomic, strong) NSTimer * countdownTimer;
@property (nonatomic, assign) NSTimeInterval countdownTime;

#pragma mark UI
/// view hierarchy
///
/// @note 没有显示在视图层级中的视图，则可能是隐藏或不存在
///
/// [直播] 竖屏
/// (UIView) self.view
/// ├── (PLVLCMediaAreaView) mediaAreaView
/// ├── (UIView) marqueeView (由 mediaAreaView 持有及管理)
/// ├── (PLVLCLivePageMenuAreaView) menuAreaView
/// ├── (PLVLCLinkMicAreaView) linkMicAreaView
/// ├── (PLVLCMediaFloatView) floatView (由 mediaAreaView 持有及管理)
/// ├── (PLVLCLinkMicPortraitControlBar) portraitControlBar (由 linkMicAreaView 持有及管理)
/// └── (PLVInteractView) interactView
///
/// [直播] 横屏
/// (UIView) self.view
/// ├── (PLVLCMediaAreaView) mediaAreaView
/// ├── (PLVLCLinkMicAreaView) linkMicAreaView
/// ├── (PLVLCChatLandscapeView) chatLandscapeView
/// ├── (PLVLCMediaFloatView) floatView (由 mediaAreaView 持有及管理)
/// ├── (PLVLCLiveRoomPlayerSkinView) liveRoomSkinView
/// ├── (PLVLCLinkMicLandscapeControlBar) landscapeControlBar (由 linkMicAreaView 持有及管理)
/// ├── (UIView) marqueeView (由 mediaAreaView 持有及管理)
/// └── (PLVInteractView) interactView
@property (nonatomic, strong) PLVLCMediaAreaView *mediaAreaView;        // 媒体区
@property (nonatomic, strong) PLVLCLinkMicAreaView *linkMicAreaView;    // 连麦区
@property (nonatomic, strong) PLVLCLivePageMenuAreaView *menuAreaView;  // 菜单区
@property (nonatomic, strong) PLVInteractView *interactView;            // 互动

@property (nonatomic, strong) PLVLCChatLandscapeView *chatLandscapeView;     // 横屏聊天区
@property (nonatomic, strong) PLVLCLiveRoomPlayerSkinView * liveRoomSkinView;// 横屏频道皮肤

@property (nonatomic, assign) BOOL inBackground;

@end

@implementation PLVLCCloudClassViewController {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s",__FUNCTION__);
    [_countdownTimer invalidate];
    _countdownTimer = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // 启动聊天室管理器
        [[PLVLCChatroomViewModel sharedViewModel] setup];
        [[PLVLCChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // 监听socket消息
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [self setupModule];
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self updateUI];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate{
    if (self.inBackground) { return NO; }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight);
}


#pragma mark - [ Private Methods ]
- (void)setupModule{
    // 通用的 配置
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    if (self.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 监听事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationForOpenBulletin:) name:PLVLCChatroomOpenBulletinNotification object:nil];
        
        
    } else if (self.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
    
    }
}

- (void)setupUI {
    self.view.backgroundColor = PLV_UIColorFromRGB(@"#0E141E");
    
    /// 注意：1. 此处不建议将共同拥有的图层，提炼在 if 判断外，来做“代码简化”
    ///         因为此处涉及到添加顺序，而影响图层顺序。放置在 if 内，能更加准确地配置图层顺序，也更清晰地预览图层顺序。
    ///      2. 懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (self.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 创建添加视图
        [self.view addSubview:self.mediaAreaView];    // 媒体区
        [self.view addSubview:self.menuAreaView];     // 菜单区
        [self.view addSubview:self.linkMicAreaView];  // 连麦区
        [self.view addSubview:self.chatLandscapeView];// 横屏聊天区
        [self.view addSubview:self.liveRoomSkinView]; // 横屏频道皮肤
        [self.view addSubview:self.interactView];     // 互动

        /// 配置
        self.interactView.frame = self.view.bounds;
        self.interactView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.interactView loadOnlineInteract];
        
        self.liveRoomSkinView.frame = self.view.bounds;
        self.liveRoomSkinView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        if (roomData.menuInfo) { [self roomDataManager_didMenuInfoChanged:roomData.menuInfo]; }

        
    }else if (self.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
        /// 创建添加视图
        [self.view addSubview:self.mediaAreaView];    // 媒体区
        [self.view addSubview:self.menuAreaView];     // 菜单区
        [self.view addSubview:self.chatLandscapeView];// 横屏聊天区
        [self.view addSubview:self.liveRoomSkinView]; // 横屏频道皮肤
        
        /// 配置
        self.liveRoomSkinView.frame = self.view.bounds;
        self.liveRoomSkinView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        if (roomData.menuInfo) { [self roomDataManager_didMenuInfoChanged:roomData.menuInfo]; }
    }
}

- (void)updateUI {
    /// 连麦区域是否应该出现
    BOOL showLinkMicAreaView = self.linkMicAreaView.inRTCRoom;
    if (self.linkMicAreaView.inRTCRoom && self.channelType == PLVChannelTypeAlone) {
        showLinkMicAreaView = self.linkMicAreaView.currentRTCRoomUserCount > 1 ? YES : NO;
    }
    showLinkMicAreaView = self.linkMicAreaView.areaViewShow ? showLinkMicAreaView : NO;
    
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (!fullScreen) {
        // 竖屏
        self.linkMicAreaView.hidden = !self.linkMicAreaView.inRTCRoom;
        self.menuAreaView.hidden = NO;
        self.chatLandscapeView.frame = CGRectZero;
        
        if (self.fullScreenDifferent) {
            [self.mediaAreaView.skinView synchOtherSkinViewState:self.liveRoomSkinView];
            [self.menuAreaView.chatVctrl resumeLikeButtonViewLayout];
        }

        CGRect mediaAreaViewFrame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds) * PPTPlayerViewScale + P_SafeAreaTopEdgeInsets());
        self.mediaAreaView.frame = mediaAreaViewFrame;
        
        CGFloat linkMicAreaViewHeight = showLinkMicAreaView ? 70 : 0;
        CGRect linkMicAreaViewFrame = CGRectMake(0, CGRectGetMaxY(self.mediaAreaView.frame), CGRectGetWidth(self.view.bounds), linkMicAreaViewHeight);
        self.linkMicAreaView.frame = linkMicAreaViewFrame;
        
        CGFloat menuAreaOriginY = self.linkMicAreaView.inRTCRoom ? CGRectGetMaxY(linkMicAreaViewFrame) : CGRectGetMaxY(mediaAreaViewFrame);
        self.menuAreaView.frame = CGRectMake(0, menuAreaOriginY, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-menuAreaOriginY);
        
        /// 图层管理
        [self.view insertSubview:self.mediaAreaView.marqueeView aboveSubview:self.mediaAreaView]; /// 保证高于 mediaAreaView 即可
        [self.view insertSubview:self.mediaAreaView.floatView belowSubview:self.interactView]; /// 保证低于 interactView
        [self.view insertSubview:((UIView *)self.linkMicAreaView.currentControlBar) belowSubview:self.interactView]; /// 保证低于 interactView 即可
        
    } else {
        // 横屏
        self.linkMicAreaView.hidden = !self.linkMicAreaView.inRTCRoom;
        self.menuAreaView.hidden = YES;
        
        CGFloat leftPadding = P_SafeAreaLeftEdgeInsets() + 16;
        CGFloat rightPadding = P_SafeAreaRightEdgeInsets();
        if ([PLVFdUtil isiPhoneXSeries]) {
            rightPadding += 10;
        }
        
        self.chatLandscapeView.frame = CGRectMake(leftPadding, self.view.bounds.size.height / 2.0, 240,  self.view.bounds.size.height / 2.0 - 16);
        
        if (self.fullScreenDifferent) {
            [self.liveRoomSkinView synchOtherSkinViewState:self.mediaAreaView.skinView];
            [self.liveRoomSkinView displayLikeButtonView:self.menuAreaView.chatVctrl.likeButtonView];
        }
        [self.view insertSubview:self.chatLandscapeView belowSubview:self.liveRoomSkinView];
       
        CGFloat linkMicAreaViewWidth = 150.0 + rightPadding;
        linkMicAreaViewWidth = showLinkMicAreaView ? linkMicAreaViewWidth : 0;
        CGRect linkMicAreaViewFrame = CGRectMake(CGRectGetWidth(self.view.bounds) - linkMicAreaViewWidth,
                                                 0,
                                                 linkMicAreaViewWidth,
                                                 CGRectGetHeight(self.view.bounds));
        self.linkMicAreaView.frame = linkMicAreaViewFrame;
        
        CGRect mediaAreaViewFrame = CGRectMake(0,
                                               0,
                                               CGRectGetWidth(self.view.bounds) - linkMicAreaViewWidth,
                                               CGRectGetHeight(self.view.bounds));
        self.mediaAreaView.frame = mediaAreaViewFrame;
        
        /// 图层管理
        [self.view insertSubview:self.mediaAreaView.floatView belowSubview:self.liveRoomSkinView]; /// 保证低于 liveRoomSkinView
        [self.view insertSubview:self.mediaAreaView.marqueeView aboveSubview:self.liveRoomSkinView]; /// 保证高于 liveRoomSkinView 即可
        [self.view insertSubview:self.mediaAreaView.retryPlayView aboveSubview:self.liveRoomSkinView]; /// 保证高于 liveRoomSkinView 即可
        [self.view insertSubview:((UIView *)self.linkMicAreaView.currentControlBar) belowSubview:self.interactView]; /// 保证低于 interactView
    }
    
    self.fullScreenDifferent = NO;
}

- (void)refreshLiveRoomPlayerSkinViewUIInfo{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    [self.liveRoomSkinView setTitleLabelWithText:roomData.menuInfo.name];
    [self.liveRoomSkinView setPlayTimesLabelWithTimes:roomData.menuInfo.pageView.integerValue];
}

- (void)exitCurrentController {
    [PLVRoomLoginClient logout];
    [[PLVSocketManager sharedManager] logout];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [[PLVLCChatroomViewModel sharedViewModel] clear];
}

- (void)startCountdownTimer {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (self.countdownTimer || self.videoType != PLVChannelVideoType_Live) {
        return;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSDate *startTime = [formatter dateFromString:roomData.menuInfo.startTime];
    
    self.countdownTime = [startTime timeIntervalSinceNow];
    if (self.countdownTime <= 0.0) {
        return;
    }
    
    _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:[PLVFWeakProxy proxyWithTarget:self]
                                            selector:@selector(countdown:)
                                            userInfo:nil repeats:YES];
    [self.countdownTimer fire];
}

- (void)stopCountdownTimer {
    if (self.countdownTimer) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        
        self.countdownTime = 0;
        [self countdown:nil];
    }
}

- (void)countdown:(NSTimer *)timer {
    if (self.countdownTime >= 0.0) {
        [self.liveRoomSkinView setCountdownTime:self.countdownTime];
        [self.mediaAreaView.skinView setCountdownTime:self.countdownTime];
    } else {
        [self stopCountdownTimer];
    }
    self.countdownTime--;
}

#pragma mark Getter
- (PLVLCMediaAreaView *)mediaAreaView{
    if (!_mediaAreaView) {
        _mediaAreaView = [[PLVLCMediaAreaView alloc] init];
        _mediaAreaView.delegate = self;
        _mediaAreaView.limitContentViewInSafeArea = YES;
        _mediaAreaView.topPaddingBelowiOS11 = 20.0;
    }
    return _mediaAreaView;
}

- (PLVLCLinkMicAreaView *)linkMicAreaView{
    if (!_linkMicAreaView && self.videoType == PLVChannelVideoType_Live) {
        _linkMicAreaView = [[PLVLCLinkMicAreaView alloc] init];
        _linkMicAreaView.delegate = self;
        _linkMicAreaView.hidden = YES;
    }
    return _linkMicAreaView;
}

- (PLVLCLivePageMenuAreaView *)menuAreaView{
    if (!_menuAreaView) {
        _menuAreaView = [[PLVLCLivePageMenuAreaView alloc] initWithLiveRoom:self];
    }
    return _menuAreaView;
}

- (PLVLCLiveRoomPlayerSkinView *)liveRoomSkinView{
    if (!_liveRoomSkinView) {
        _liveRoomSkinView = [[PLVLCLiveRoomPlayerSkinView alloc] init];
        _liveRoomSkinView.baseDelegate = self.mediaAreaView; /// 由 mediaAreaView 一并处理基础事件
        _liveRoomSkinView.delegate = self; /// 由 self 处理 liveRoomSkinView 特有事件
    }
    return _liveRoomSkinView;
}

- (PLVLCChatLandscapeView *)chatLandscapeView{
    if (!_chatLandscapeView) {
        _chatLandscapeView = [[PLVLCChatLandscapeView alloc] init];
    }
    return _chatLandscapeView;
}

- (PLVInteractView *)interactView{
    if (!_interactView && self.videoType == PLVChannelVideoType_Live) {
        _interactView = [[PLVInteractView alloc] init];
        _interactView.frame = self.view.bounds;
        _interactView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_interactView loadOnlineInteract];
    }
    return _interactView;
}

- (PLVChannelType)channelType{
    return [PLVRoomDataManager sharedManager].roomData.channelType;
}

- (PLVChannelVideoType)videoType{
    return [PLVRoomDataManager sharedManager].roomData.videoType;
}


#pragma mark - [ Event ]
#pragma mark Notification
- (void)didBecomeActive:(NSNotification *)notification {
    self.inBackground = NO;
}

- (void)willResignActive:(NSNotification *)notification {
    self.inBackground = YES;
}

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    self.fullScreenDifferent = (self.currentLandscape != fullScreen);
    self.currentLandscape = fullScreen;
    
    // 全屏播放器皮肤 liveRoomSkinView 的弹幕按钮 danmuButton 为显示状态，且为非选中状态，且当前为横屏时，才显示弹幕
    BOOL danmuEnable = !self.liveRoomSkinView.danmuButton.selected && !self.liveRoomSkinView.danmuButton.hidden;
    [self.mediaAreaView showDanmu:fullScreen && danmuEnable];
    // 可在此处控制 “横屏聊天区”，是否跟随 “弹幕” 一并显示/隐藏；注释或移除此句，则不跟随；
    // 其他相关代码，可在此文件中，搜索 “self.chatLandscapeView.hidden = ”
    self.chatLandscapeView.hidden = !(fullScreen && danmuEnable);
    
    // 调用setStatusBarHidden后状态栏旋转横屏不自动隐藏
    [[UIApplication sharedApplication] setStatusBarHidden:fullScreen];
}

- (void)notificationForOpenBulletin:(NSNotification *)notif {
    [self.interactView openLastBulletin];
}

#pragma mark - [ Delegate ]
#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didChannelInfoChanged:(PLVChannelInfoModel *)channelInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    self.liveRoomSkinView.danmuButtonShow = !roomData.channelInfo.closeDanmuEnable;
}

- (void)roomDataManager_didMenuInfoChanged:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    [self.mediaAreaView refreshUIInfo];
    [self refreshLiveRoomPlayerSkinViewUIInfo];
    [self startCountdownTimer];
}

/// 观看数 watchCount 更新
- (void)roomDataManager_didWatchCountChanged:(NSUInteger)watchCount{
    [self.mediaAreaView.skinView setPlayTimesLabelWithTimes:watchCount];
    [self.liveRoomSkinView setPlayTimesLabelWithTimes:watchCount];
}

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [PLVLCUtils showHUDWithTitle:@"登陆成功" detail:@"" view:self.view];
//    });
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin ||
        error.code == PLVSocketLoginErrorCodeKick) &&
        error.localizedDescription) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [PLVFdUtil showAlertWithTitle:nil message:error.localizedDescription viewController:self cancelActionTitle:@"确定" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:^(UIAlertAction * _Nonnull action) {
                [weakSelf exitCurrentController];
            } confirmActionTitle:nil confirmActionStyle:UIAlertActionStyleDefault confirmActionBlock:nil];
        });
    }
}

- (void)socketMananger_didConnectStatusChange:(PLVSocketConnectStatus)connectStatus {
    if (connectStatus == PLVSocketConnectStatusReconnect) {
        self.socketReconnecting = YES;
        plv_dispatch_main_async_safe(^{
            [PLVLCUtils showHUDWithTitle:@"聊天室重连中" detail:@"" view:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVLCUtils showHUDWithTitle:@"聊天室重连成功" detail:@"" view:self.view];
            })
        }
    }
}

#pragma mark PLVLCChatroomViewModelProtocol

- (void)chatroomManager_danmu:(NSString * )content {
    [self.mediaAreaView insertDanmu:content];
}

#pragma mark PLVLCMediaAreaViewDelegate
/// 用户希望退出当前页面
- (void)plvLCMediaAreaViewWannaBack:(PLVLCMediaAreaView *)mediaAreaView{
    [self exitCurrentController];
}

/// 媒体区域视图需要得知当前‘是否正在连麦’
- (BOOL)plvLCMediaAreaViewGetInLinkMic:(PLVLCMediaAreaView *)mediaAreaView{
    return self.linkMicAreaView.inLinkMic;
}

/// 媒体区域视图需要得知当前‘是否在RTC房间中’
- (BOOL)plvLCMediaAreaViewGetInRTCRoom:(PLVLCMediaAreaView *)mediaAreaView{
    return self.linkMicAreaView.inRTCRoom;
}

/// 直播 ‘流状态’ 更新
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView livePlayerStateDidChange:(PLVChannelLiveStreamState)livePlayerState{
    if (livePlayerState == PLVChannelLiveStreamState_Live) {
        [self stopCountdownTimer];
        if (self.linkMicAreaView.inLinkMic == NO) {
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_CDN];
        }
    }else if (livePlayerState == PLVChannelLiveStreamState_Stop){
        [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
    }else{
        if (livePlayerState == PLVChannelLiveStreamState_End) {
            [self startCountdownTimer];
        }
        [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
    }
    [self.menuAreaView updateliveStatue:(livePlayerState == PLVChannelLiveStreamState_Live)];
}

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView noDelayLiveStartUpdate:(BOOL)noDelayLiveStart{
    [self.linkMicAreaView startWatchNoDelay:noDelayLiveStart];
    if (noDelayLiveStart) {
        /// 仅无延迟直播开始，需由此触发更新，让UI及时更新
        /// 告知 媒体区域视图
        [self.mediaAreaView switchAreaViewLiveSceneTypeTo:PLVLCMediaAreaViewLiveSceneType_WatchNoDelay];
        
        /// 告知 横屏 皮肤视图
        [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_NODelay];
    }
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView playerPlayingDidChange:(BOOL)playing{
    [self.liveRoomSkinView setPlayButtonWithPlaying:playing];
}

/// 媒体区域的 悬浮视图 出现/隐藏回调
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView floatViewSwitchToShow:(BOOL)show{
    [self.liveRoomSkinView setFloatViewButtonWithShowStatus:show];
}

/// 媒体区域的 皮肤视图 出现/隐藏回调
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView didChangedSkinShowStatus:(BOOL)skinShow forSkinView:(PLVLCBasePlayerSkinView *)skinView{
    if (skinView == self.liveRoomSkinView) {
        /// 横屏时，悬浮连麦控制栏跟随一同显示/隐藏
        [self.linkMicAreaView showLinkMicControlBar:skinShow];
    }
}

/// 媒体区域视图询问是否有 外部视图 处理此次触摸事件
- (BOOL)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView askHandlerForTouchPoint:(CGPoint)point onSkinView:(nonnull PLVLCBasePlayerSkinView *)skinView{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        // 横屏时
        if ([PLVLCBasePlayerSkinView checkView:self.mediaAreaView.floatView canBeHandlerForTouchPoint:point onSkinView:skinView]){
            /// 横屏时，判断触摸事件是否应由 ‘媒体悬浮视图’ 处理
            return YES;
        }else if ([PLVLCBasePlayerSkinView checkView:self.chatLandscapeView canBeHandlerForTouchPoint:point onSkinView:skinView]) {
            /// 横屏聊天室 显示时，判断触摸事件是否应由 ‘聊天室’ 处理
            return YES;
        }else if ([PLVLCBasePlayerSkinView checkView:self.linkMicAreaView canBeHandlerForTouchPoint:point onSkinView:skinView]){
            /// 横屏连麦区域视图 显示时，判断触摸事件是否应由 ‘连麦区域视图’ 处理
            return YES;
        }
    }
    return NO;
}

/// 用户希望连麦区域视图 隐藏/显示
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView userWannaLinkMicAreaViewShow:(BOOL)wannaShow onSkinView:(nonnull PLVLCBasePlayerSkinView *)skinView{
    /// 告知 连麦区域视图
    [self.linkMicAreaView showAreaView:wannaShow];
    
    /// 更新按钮状态
    [skinView setFloatViewButtonWithShowStatus:wannaShow];
    
    /// 更新布局
    [self updateUI];
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView progressUpdateWithCachedProgress:(CGFloat)cachedProgress playedProgress:(CGFloat)playedProgress durationTime:(NSTimeInterval)durationTime currentTimeString:(NSString *)currentTimeString durationString:(NSString *)durationString{
    [self.liveRoomSkinView setProgressWithCachedProgress:cachedProgress playedProgress:playedProgress durationTime:(NSTimeInterval)durationTime currentTimeString:currentTimeString durationString:durationString];
}

#pragma mark PLVLCLiveRoomPlayerSkinViewDelegate
- (void)plvLCLiveRoomPlayerSkinViewBulletinButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView{
    [self.interactView openLastBulletin];
}

- (void)plvLCLiveRoomPlayerSkinViewDanmuButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaShowDanmu:(BOOL)showDanmu{
    [self.mediaAreaView showDanmu:showDanmu];
    // 可在此处控制 “横屏聊天区”，是否跟随 “弹幕” 一并显示/隐藏；注释或移除此句，则不跟随；
    // 其他相关代码，可在此文件中，搜索 “self.chatLandscapeView.hidden = ”
    self.chatLandscapeView.hidden = !showDanmu;
}

- (void)plvLCLiveRoomPlayerSkinView:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaSendChatContent:(NSString *)chatContent {
    [[PLVLCChatroomViewModel sharedViewModel] sendSpeakMessage:chatContent];
}

#pragma mark PLVLCLinkMicAreaViewDelegate
/// 连麦Rtc画面窗口 需外部展示 ‘第一画面连麦窗口’
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView showFirstSiteCanvasViewOnExternal:(UIView *)canvasView{
    [self.mediaAreaView displayContentView:canvasView];
}

/// 连麦Rtc画面窗口被点击 (表示用户希望视图位置交换)
- (UIView *)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView rtcWindowDidClickedCanvasView:(UIView *)canvasView{
    UIView * contentViewOnMediaAreaView = [self.mediaAreaView getContentViewForExchange];
    [self.mediaAreaView displayContentView:canvasView];
    return contentViewOnMediaAreaView;
}

/// 恢复外部视图位置
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView rollbackExternalView:(UIView *)externalView{
    [self.mediaAreaView displayContentView:externalView];
}

/// ‘是否在RTC房间中’ 状态值发生改变
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView inRTCRoomChanged:(BOOL)inRTCRoom{
    /// 告知 媒体区域视图
    PLVLCMediaAreaViewLiveSceneType sceneType;
    if (inRTCRoom) {
        sceneType = self.mediaAreaView.channelWatchNoDelay ? PLVLCMediaAreaViewLiveSceneType_WatchNoDelay : PLVLCMediaAreaViewLiveSceneType_InLinkMic;
    }else{
        sceneType = PLVLCMediaAreaViewLiveSceneType_WatchCDN;
    }
    [self.mediaAreaView switchAreaViewLiveSceneTypeTo:sceneType];

    /// 告知 横屏 皮肤视图
    PLVLCBasePlayerSkinViewLiveStatus skinViewLiveStatus;
    if (inRTCRoom) {
        skinViewLiveStatus = PLVLCBasePlayerSkinViewLiveStatus_Living_NODelay;
    }else{
        PLVChannelLiveStreamState liveState = [PLVRoomDataManager sharedManager].roomData.liveState;
        if (liveState == PLVChannelLiveStreamState_Live) {
            // 直播中
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_CDN];
        }else{
            // 非直播中
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        }
    }
}

/// ‘RTC房间在线用户数’ 发生改变
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView currentRTCRoomUserCountChanged:(NSInteger)currentRTCRoomUserCount{
    /// 更新 观看间 UI布局
    [self updateUI];
}

/// ‘是否正在连麦’状态值改变
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView inLinkMicChanged:(BOOL)inLinkMic{
    /// 告知 媒体区域视图
    PLVLCMediaAreaViewLiveSceneType sceneType;
    if (inLinkMic) {
        sceneType = PLVLCMediaAreaViewLiveSceneType_InLinkMic;
    }else{
        sceneType = self.mediaAreaView.channelWatchNoDelay ? PLVLCMediaAreaViewLiveSceneType_WatchNoDelay : PLVLCMediaAreaViewLiveSceneType_WatchCDN;
    }
    [self.mediaAreaView switchAreaViewLiveSceneTypeTo:sceneType];
    
    /// 告知 横屏 皮肤视图
    if (inLinkMic) {
        if (linkMicAreaView.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PartRtc) {
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PartRTC];
        } else if (linkMicAreaView.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PureRtc){
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC];
        }else if (linkMicAreaView.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc){
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC];
        }
    }else{
        PLVChannelLiveStreamState liveState = [PLVRoomDataManager sharedManager].roomData.liveState;
        if (liveState == PLVChannelLiveStreamState_Live) {
            // 直播中
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:self.mediaAreaView.channelWatchNoDelay ? PLVLCBasePlayerSkinViewLiveStatus_Living_NODelay : PLVLCBasePlayerSkinViewLiveStatus_Living_CDN];
        }else{
            // 非直播中
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        }
    }
}

/// 需获知 ‘当前频道是否直播中’
- (BOOL)plvLCLinkMicAreaViewGetChannelInLive:(PLVLCLinkMicAreaView *)linkMicAreaView{
    return self.mediaAreaView.channelInLive;
}

/// 需获知 ‘主讲的PPT 当前是否在主屏’
- (BOOL)plvLCLinkMicAreaViewGetMainSpeakerPPTOnMain:(PLVLCLinkMicAreaView *)linkMicAreaView{
    return self.mediaAreaView.mainSpeakerPPTOnMain;
}

@end
