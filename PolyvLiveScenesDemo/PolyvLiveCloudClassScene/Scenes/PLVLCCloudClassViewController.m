//
//  PLVLCCloudClassViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/11/10.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCCloudClassViewController.h"

// 模块
#import "PLVSocketLoginManager.h"
#import "PLVLiveRoomManager.h"
#import "PLVLCChatroomManager.h"

// UI
#import "PLVLCMediaAreaView.h"
#import "PLVLCLinkMicAreaView.h"
#import "PLVLCLivePageMenuAreaView.h"
#import "PLVLCLiveRoomPlayerSkinView.h"
#import "PLVLCChatLandscapeView.h"
#import "PLVInteractView.h"

// 工具
#import "PLVECUtils.h"

@interface PLVLCCloudClassViewController ()<
PLVSocketLoginManagerDelegate,
PLVLCMediaAreaViewDelegate,
PLVLCLinkMicAreaViewDelegate,
PLVLCLiveRoomPlayerSkinViewDelegate,
PLVLCChatroomManagerProtocol
>

#pragma mark 数据
@property (nonatomic, strong) PLVLiveRoomData *watchRoomData;

#pragma mark 状态
@property (nonatomic, assign) BOOL currentLandscape;    // 当前是否横屏 (YES:当前横屏 NO:当前竖屏)
@property (nonatomic, assign) BOOL fullScreenDifferent; // 在更新UI布局之前，横竖屏是否发现了变化 (YES:已变化 NO:没有变化)
@property (nonatomic, assign) BOOL inLinkMic;           // 当前是否连麦中

#pragma mark 模块
@property (nonatomic, strong) PLVSocketLoginManager *socketLoginManager;// Socket 登录管理
@property (nonatomic, strong) PLVLiveRoomManager *liveRoomManager;      // 直播间数据管理器
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
/// ├── (PLVLCLinkMicVerticalControlBar) controlBarV (由 linkMicAreaView 持有及管理)
/// └── (PLVInteractView) interactView
///
/// [直播] 横屏
/// (UIView) self.view
/// ├── (PLVLCMediaAreaView) mediaAreaView
/// ├── (PLVLCLinkMicAreaView) linkMicAreaView
/// ├── (PLVLCChatLandscapeView) chatLandscapeView
/// ├── (PLVLCMediaFloatView) floatView (由 mediaAreaView 持有及管理)
/// ├── (PLVLCLiveRoomPlayerSkinView) liveRoomSkinView
/// ├── (PLVLCLinkMicVerticalControlBar) controlBarV (由 linkMicAreaView 持有及管理)
/// ├── (UIView) marqueeView (由 mediaAreaView 持有及管理)
/// └── (PLVInteractView) interactView
@property (nonatomic, strong) PLVLCMediaAreaView *mediaAreaView;        // 媒体区
@property (nonatomic, strong) PLVLCLinkMicAreaView *linkMicAreaView;    // 连麦区
@property (nonatomic, strong) PLVLCLivePageMenuAreaView *menuAreaView;  // 菜单区
@property (nonatomic, strong) PLVInteractView *interactView;            // 互动

@property (nonatomic, strong) PLVLCChatLandscapeView *chatLandscapeView;     // 横屏聊天区
@property (nonatomic, strong) PLVLCLiveRoomPlayerSkinView * liveRoomSkinView;// 横屏频道皮肤

@end

@implementation PLVLCCloudClassViewController

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s",__FUNCTION__);
    [_countdownTimer invalidate];
    _countdownTimer = nil;
}

- (instancetype)initWithWatchRoomData:(PLVLiveRoomData *)watchRoomData{
    self = [super init];
    if (self) {
        self.watchRoomData = watchRoomData;
        [[PLVLCChatroomManager sharedManager] setupRoomData:watchRoomData];
        [[PLVLCChatroomManager sharedManager] addListener:self];
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight);
}


#pragma mark - [ Private Methods ]
- (void)setupModule{
    // 通用的 配置
    /// 观看间数据管理器
    self.liveRoomManager = [[PLVLiveRoomManager alloc] initWithRoomData:self.watchRoomData];
    [self.liveRoomManager requestLiveDetail]; // 获取直播详情数据
    [self.liveRoomManager requestPageview];   // 上报观看热度
    
    /// 监听房间数据
    [self observeWatchRoomData];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interfaceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    /// Socket 登录管理
    self.socketLoginManager = [[PLVSocketLoginManager alloc] initWithDelegate:self roomData:self.watchRoomData];
    [self.socketLoginManager loginSocketServer];

    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
        /// 监听事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationForOpenBulletin:) name:PLVLCChatroomOpenBulletinNotification object:nil];
        
    } else if (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
    
    }
}

- (void)observeWatchRoomData {
    PLVLiveRoomData *roomData = self.watchRoomData;
    [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNEL options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNELINFO options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserveWatchRoomData { // TODO：取消使用这种方式，规避忘记调用remove而崩溃的问题
    PLVLiveRoomData *roomData = self.watchRoomData;
    [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNEL];
    [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNELINFO];
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.blackColor;
    
    /// 注意：1. 此处不建议将共同拥有的图层，提炼在 if 判断外，来做“代码简化”
    ///         因为此处涉及到添加顺序，而影响图层顺序。放置在 if 内，能更加准确地配置图层顺序，也更清晰地预览图层顺序。
    ///      2. 懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil

    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
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
        
    }else if (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
        /// 创建添加视图
        [self.view addSubview:self.mediaAreaView];    // 媒体区
        [self.view addSubview:self.menuAreaView];     // 菜单区
        [self.view addSubview:self.chatLandscapeView];// 横屏聊天区
        [self.view addSubview:self.liveRoomSkinView]; // 横屏频道皮肤
        
        /// 配置
        self.liveRoomSkinView.frame = self.view.bounds;
        self.liveRoomSkinView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

- (void)updateUI {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (!fullScreen) {
        // 竖屏
        self.linkMicAreaView.hidden = !self.inLinkMic;
        self.menuAreaView.hidden = NO;
        self.chatLandscapeView.frame = CGRectZero;
        
        if (self.fullScreenDifferent) {
            [self.mediaAreaView.skinView synchOtherSkinViewState:self.liveRoomSkinView];
            [self.menuAreaView.chatVctrl resumeLikeButtonViewLayout];
        }

        CGRect mediaAreaViewFrame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds) * PPTPlayerViewScale + P_SafeAreaTopEdgeInsets());
        self.mediaAreaView.frame = mediaAreaViewFrame;
        
        CGFloat linkMicAreaViewHeight = self.inLinkMic ? (self.linkMicAreaView.areaViewShow ? 70 : 0) : 0;
        CGRect linkMicAreaViewFrame = CGRectMake(0, CGRectGetMaxY(self.mediaAreaView.frame), CGRectGetWidth(self.view.bounds), linkMicAreaViewHeight);
        self.linkMicAreaView.frame = linkMicAreaViewFrame;
        
        CGFloat menuAreaOriginY = self.inLinkMic ? CGRectGetMaxY(linkMicAreaViewFrame) : CGRectGetMaxY(mediaAreaViewFrame);
        self.menuAreaView.frame = CGRectMake(0, menuAreaOriginY, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-menuAreaOriginY);
        
        /// 图层管理
        [self.view insertSubview:self.mediaAreaView.marqueeView aboveSubview:self.mediaAreaView]; /// 保证高于 mediaAreaView 即可
        [self.view insertSubview:self.mediaAreaView.floatView belowSubview:self.interactView]; /// 保证低于 interactView
        [self.view insertSubview:((UIView *)self.linkMicAreaView.currentControlBar) belowSubview:self.interactView]; /// 保证低于 interactView 即可
        
    } else {
        // 横屏
        self.linkMicAreaView.hidden = !self.inLinkMic;
        self.menuAreaView.hidden = YES;
        
        CGFloat leftPadding = P_SafeAreaLeftEdgeInsets() + 16;
        CGFloat rightPadding = P_SafeAreaRightEdgeInsets();
        if ([PLVLiveUtil isiPhoneXSeries]) {
            rightPadding += 10;
        }
        
        self.chatLandscapeView.frame = CGRectMake(leftPadding, self.view.bounds.size.height / 2.0, 240,  self.view.bounds.size.height / 2.0 - 16);
        
        if (self.fullScreenDifferent) {
            [self.liveRoomSkinView synchOtherSkinViewState:self.mediaAreaView.skinView];
            [self.liveRoomSkinView displayLikeButtonView:self.menuAreaView.chatVctrl.likeButtonView];
        }
        [self.view insertSubview:self.chatLandscapeView belowSubview:self.liveRoomSkinView];
       
        CGFloat linkMicAreaViewWidth = 150.0 + rightPadding;
        linkMicAreaViewWidth = self.inLinkMic ? (self.linkMicAreaView.areaViewShow ? linkMicAreaViewWidth : 0) : 0;
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
        [self.view insertSubview:((UIView *)self.linkMicAreaView.currentControlBar) belowSubview:self.interactView]; /// 保证低于 interactView
    }
    
    self.fullScreenDifferent = NO;
}

- (void)refreshLiveRoomPlayerSkinViewUIInfo{
    [self.liveRoomSkinView setTitleLabelWithText:self.watchRoomData.channelMenuInfo.name];
    [self.liveRoomSkinView setPlayTimesLabelWithTimes:self.watchRoomData.channelMenuInfo.pageView.integerValue];
}

- (void)exitCurrentController {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserveWatchRoomData];

    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
        [self.socketLoginManager exitAndDisconnet];
        
    }else if (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
        
    }

    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self.menuAreaView clearResource];
    
    [[PLVLCChatroomManager sharedManager] destroy];
}

- (void)startCountdownTimer {
    if (self.countdownTimer || self.watchRoomData.videoType != PLVWatchRoomVideoType_Live) {
        return;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSDate *startTime = [formatter dateFromString:self.watchRoomData.channelMenuInfo.startTime];
    
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

#pragma mark Setter
- (void)setInLinkMic:(BOOL)inLinkMic {
    if (_inLinkMic == inLinkMic) { return; }
    _inLinkMic = inLinkMic;
    [self updateUI];
}

#pragma mark Getter
- (PLVLCMediaAreaView *)mediaAreaView{
    if (!_mediaAreaView) {
        _mediaAreaView = [[PLVLCMediaAreaView alloc] initWithRoomData:self.watchRoomData];
        _mediaAreaView.delegate = self;
        _mediaAreaView.limitContentViewInSafeArea = YES;
        _mediaAreaView.topPaddingBelowiOS11 = 20.0;
    }
    return _mediaAreaView;
}

- (PLVLCLinkMicAreaView *)linkMicAreaView{
    if (!_linkMicAreaView && self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) {
        _linkMicAreaView = [[PLVLCLinkMicAreaView alloc] initWithRoomData:self.watchRoomData];
        _linkMicAreaView.delegate = self;
        _linkMicAreaView.hidden = YES;
    }
    return _linkMicAreaView;
}

- (PLVLCLivePageMenuAreaView *)menuAreaView{
    if (!_menuAreaView) {
        _menuAreaView = [[PLVLCLivePageMenuAreaView alloc] initWithLiveRoom:self roomData:self.watchRoomData];
        _menuAreaView.inPlaybackScene = (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback);
    }
    return _menuAreaView;
}

- (PLVLCLiveRoomPlayerSkinView *)liveRoomSkinView{
    if (!_liveRoomSkinView) {
        _liveRoomSkinView = [[PLVLCLiveRoomPlayerSkinView alloc] initWithType:(self.watchRoomData.videoType == PLVWatchRoomVideoType_Live ? PLVLCBasePlayerSkinViewType_Live : PLVLCBasePlayerSkinViewType_Playback)];
        _liveRoomSkinView.baseDelegate = self.mediaAreaView; /// 由 mediaAreaView 一并处理基础事件
        _liveRoomSkinView.delegate = self; /// 由 self 处理 liveRoomSkinView 特有事件
    }
    return _liveRoomSkinView;
}

- (PLVLCChatLandscapeView *)chatLandscapeView{
    if (!_chatLandscapeView) {
        _chatLandscapeView = [[PLVLCChatLandscapeView alloc] initWithRoomData:self.watchRoomData];
    }
    return _chatLandscapeView;
}

- (PLVInteractView *)interactView{
    if (!_interactView && self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) {
        _interactView = [[PLVInteractView alloc] init];
        _interactView.frame = self.view.bounds;
        _interactView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_interactView loadOnlineInteract];
    }
    return _interactView;
}


#pragma mark - [ Event ]
#pragma mark Notification
- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    self.fullScreenDifferent = (self.currentLandscape != fullScreen);
    self.currentLandscape = fullScreen;
    
    // 全屏播放器皮肤 liveRoomSkinView 的弹幕按钮 danmuButton 为显示状态，且为非选中状态，且当前为横屏时，才显示弹幕
    BOOL danmuEnable = !self.liveRoomSkinView.danmuButton.selected && !self.liveRoomSkinView.danmuButton.hidden;
    [self.mediaAreaView showDanmu:fullScreen && danmuEnable];
    
    // 调用setStatusBarHidden后状态栏旋转横屏不自动隐藏
    [[UIApplication sharedApplication] setStatusBarHidden:fullScreen];
}

- (void)notificationForOpenBulletin:(NSNotification *)notif {
    [self.interactView openLastBulletin];
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (![object isKindOfClass:PLVLiveRoomData.class]) {
        return;
    }
    
    PLVLiveRoomData *roomData = object;
    if ([keyPath isEqualToString:KEYPATH_LIVEROOM_CHANNEL]) { // 频道信息（后台信息）
        if (!roomData.channelMenuInfo) {
            return;
        }
        
        [self.mediaAreaView refreshUIInfo];
        [self refreshLiveRoomPlayerSkinViewUIInfo];
        [self startCountdownTimer];
    } else if ([keyPath isEqualToString:KEYPATH_LIVEROOM_CHANNELINFO]) { // 频道信息
        self.liveRoomSkinView.danmuButtonShow = !roomData.channelInfo.closeDanmuEnable;
    }
}


#pragma mark - [ Delegate ]
#pragma mark PLVSocketLoginManagerDelegate
- (void)socketLoginManager_loginSuccess:(PLVSocketLoginManager *)socketLoginManager {
    // [PLVLiveUtil showHUDWithTitle:@"登陆成功" detail:@"" view:self.view];
}

- (void)socketLoginManager:(PLVSocketLoginManager *)socketLoginManager authorizationVerificationFailed:(PLVLiveRoomErrorReason)reason message:(NSString *)message {
    __weak typeof(self) weakSelf = self;
    [PLVFdUtil showAlertWithTitle:nil message:message viewController:self cancelActionTitle:@"确定" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:^(UIAlertAction * _Nonnull action) {
        [weakSelf exitCurrentController];
    } confirmActionTitle:nil confirmActionStyle:UIAlertActionStyleDefault confirmActionBlock:nil];
}

#pragma mark PLVLCChatroomManagerProtocol

- (void)chatroomManager_danmu:(NSString * )content {
    [self.mediaAreaView insertDanmu:content];
}

#pragma mark PLVLCMediaAreaViewDelegate
/// 用户希望退出当前页面
- (void)plvLCMediaAreaViewWannaBack:(PLVLCMediaAreaView *)mediaAreaView{
    [self exitCurrentController];
}

/// 媒体区域视图需要得知当前的连麦状态
- (BOOL)plvLCMediaAreaViewGetInLinkMic:(PLVLCMediaAreaView *)mediaAreaView{
    return self.linkMicAreaView.inLinkMic;
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView livePlayerStateDidChange:(LivePlayerState)livePlayerState{
    if (livePlayerState == LivePlayerStateLiving) {
        [self stopCountdownTimer];
        if (self.inLinkMic == NO) {
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living];
        }
    }else if (livePlayerState == LivePlayerStatePause){
        [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
    }else{
        if (livePlayerState == LivePlayerStateEnd) {
            [self startCountdownTimer];
        }
        [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
    }
    [self.menuAreaView liveStatueChange:(livePlayerState == LivePlayerStateLiving)];
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView livePlayerPlayingDidChange:(BOOL)playing{
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

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView playbackPlayerPlayingDidChange:(BOOL)playing{
    [self.liveRoomSkinView setPlayButtonWithPlaying:playing];
}

#pragma mark PLVLCLiveRoomPlayerSkinViewDelegate
- (void)plvLCLiveRoomPlayerSkinViewBulletinButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView{
    [self.interactView openLastBulletin];
}

- (void)plvLCLiveRoomPlayerSkinViewDanmuButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaShowDanmu:(BOOL)showDanmu{
    [self.mediaAreaView showDanmu:showDanmu];
}

- (void)plvLCLiveRoomPlayerSkinView:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaSendChatContent:(NSString *)chatContent {
    [[PLVLCChatroomManager sharedManager] sendSpeakMessage:chatContent];
}

#pragma mark PLVLCLinkMicAreaViewDelegate
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

/// ‘是否正在连麦’状态值改变
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView inLinkMicChanged:(BOOL)inLinkMic{
    self.inLinkMic = inLinkMic;
    
    /// 告知 连麦区域视图 是否允许出现
    [self.linkMicAreaView showAreaView:inLinkMic];
    
    /// 告知 媒体区域视图
    [self.mediaAreaView switchPlayerTypeTo:inLinkMic ? PLVLCMediaAreaViewPlayerType_RTCPlayer : PLVLCMediaAreaViewPlayerType_CDNPlayer];
    
    if (inLinkMic) {
        [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic]; /// 告知 横屏皮肤视图
    }else{
        if (self.watchRoomData.liveState == PLVLiveStreamStateLive) {
            // 直播中
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living]; /// 告知 横屏皮肤视图
        }else{
            // 非直播中
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None]; /// 告知 横屏皮肤视图
        }
    }
    
    /// 更新布局
    [self updateUI];
}
@end
