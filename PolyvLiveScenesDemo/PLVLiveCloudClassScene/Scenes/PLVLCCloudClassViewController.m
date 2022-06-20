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
#import "PLVLCChatroomPlaybackViewModel.h"
#import "PLVPopoverView.h"
#import <PLVLiveScenesSDK/PLVSocketManager.h>
#import "PLVLivePictureInPictureRestoreManager.h"
#import "PLVLCDownloadViewModel.h"

// UI
#import "PLVLCMediaAreaView.h"
#import "PLVLCLinkMicAreaView.h"
#import "PLVLCLivePageMenuAreaView.h"
#import "PLVLCLiveRoomPlayerSkinView.h"
#import "PLVLCChatLandscapeView.h"
#import "PLVRewardDisplayManager.h"
#import "PLVCommodityPushView.h"
#import "PLVBaseNavigationController.h"
#import "PLVCommodityDetailViewController.h"
#import "PLVLCDownloadListViewController.h"

// 工具
#import "PLVLCUtils.h"

@interface PLVLCCloudClassViewController ()<
PLVSocketManagerProtocol,
PLVLCMediaAreaViewDelegate,
PLVLCLinkMicAreaViewDelegate,
PLVLCLiveRoomPlayerSkinViewDelegate,
PLVLCLivePageMenuAreaViewDelegate,
PLVLCChatroomViewModelProtocol,
PLVRoomDataManagerProtocol,
PLVCommodityPushViewDelegate,
PLVCommodityDetailViewControllerDelegate,
PLVPopoverViewDelegate,
PLVLCChatroomPlaybackDelegate
>

#pragma mark 数据
@property (nonatomic, assign, readonly) PLVChannelType channelType; // 只读，当前 频道类型
@property (nonatomic, assign, readonly) PLVChannelVideoType videoType; // 只读，当前 视频类型
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中
@property (nonatomic, strong) NSURL *commodityURL;
@property (nonatomic, assign) BOOL logoutWhenStopPictureInPicutre;   // 关闭画中画的时候是否登出

#pragma mark 状态
@property (nonatomic, assign) BOOL currentLandscape;    // 当前是否横屏 (YES:当前横屏 NO:当前竖屏)
@property (nonatomic, assign) BOOL fullScreenDifferent; // 在更新UI布局之前，横竖屏是否发现了变化 (YES:已变化 NO:没有变化)
@property (nonatomic, assign) BOOL hideLinkMicAreaViewInSmallScreen;// 连麦列表是否在iPad小分屏时隐藏
@property (nonatomic, assign) PLVLinkMicStatus linkMicStatus;   // 当前的连麦状态

#pragma mark 模块
@property (nonatomic, strong) NSTimer * countdownTimer;
@property (nonatomic, assign) NSTimeInterval countdownTime;
@property (nonatomic, strong) PLVLCChatroomPlaybackViewModel *playbackViewModel;

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
/// └── (PLVPopoverView) popoverView
///
/// [直播] 横屏
/// (UIView) self.view
/// ├── (PLVLCMediaAreaView) mediaAreaView
/// ├── (UIView) rewardSvgaView
/// ├── (PLVLCLinkMicAreaView) linkMicAreaView
/// ├── (PLVLCChatLandscapeView) chatLandscapeView
/// ├── (PLVLCMediaFloatView) floatView (由 mediaAreaView 持有及管理)
/// ├── (PLVLCLiveRoomPlayerSkinView) liveRoomSkinView
/// ├── (PLVLCLinkMicLandscapeControlBar) landscapeControlBar (由 linkMicAreaView 持有及管理)
/// ├── (UIView) marqueeView (由 mediaAreaView 持有及管理)
/// └── (PLVPopoverView) popoverView
@property (nonatomic, strong) PLVLCMediaAreaView *mediaAreaView;        // 媒体区
@property (nonatomic, strong) PLVLCLinkMicAreaView *linkMicAreaView;    // 连麦区
@property (nonatomic, strong) PLVLCLivePageMenuAreaView *menuAreaView;  // 菜单区
@property (nonatomic, strong) PLVPopoverView *popoverView;              // 浮动区域
@property (nonatomic, strong) PLVRewardDisplayManager *rewardDisplayManager; // 礼物打赏动画管理器
@property (nonatomic, strong) UIView *rewardSvgaView;                   // 礼物打赏动画父视图 （仅在横屏下有效）
@property (nonatomic, strong) PLVCommodityPushView *pushView;           // 商品推送视图 （仅在竖屏下有效）

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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.logoutWhenStopPictureInPicutre = NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate{
    if (self.inBackground) { return NO; }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if ([PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate) {
        return UIInterfaceOrientationMaskPortrait;
    }

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationForOpenInteractApp:) name:PLVLCChatroomOpenInteractAppNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationForOpenRewardView:) name:PLVLCChatroomOpenRewardViewNotification object:nil];

        
    } else if (self.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
        __weak typeof(self) weakSelf = self;
        [[PLVLCDownloadViewModel sharedViewModel] setup];
        NSString *viewerId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
        [[PLVLCDownloadViewModel sharedViewModel] setupDownloadViewerId:viewerId];
        [[PLVLCDownloadViewModel sharedViewModel] setExitViewControllerFromDownlaodListBlock:^{
            [weakSelf releaseCurrenrController];
        }];
        
        [[PLVLCDownloadViewModel sharedViewModel] setRefreshWatchPlayerAfterDeleteTaskInfoBlock:^(NSString * _Nonnull deleteFileId) {
            PLVPlaybackVideoInfoModel *model = [PLVRoomDataManager sharedManager].roomData.playbackVideoInfo;
            if ([model isKindOfClass:[PLVPlaybackLocalVideoInfoModel class]] &&
                [model.fileId isEqualToString:deleteFileId]) {
                // 当删除的视频 是当前正在播放的视频的时候，刷新播放器
                [weakSelf.mediaAreaView changeFileId:deleteFileId];
            }
        }];
        
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        if (roomData.menuInfo.chatInputDisable && roomData.playbackSessionId && roomData.videoType == PLVChannelVideoType_Playback) {
            self.playbackViewModel = [[PLVLCChatroomPlaybackViewModel alloc] initWithChannelId:roomData.channelId sessionId:roomData.playbackSessionId];
            self.playbackViewModel.delegate = self;
            [self.menuAreaView updatePlaybackViewModel:self.playbackViewModel];
            [self.chatLandscapeView updatePlaybackViewModel:self.playbackViewModel];
        }
    }
}

- (void)releaseCurrenrController {
    [PLVRoomLoginClient logout];
    [[PLVSocketManager sharedManager] logout];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[PLVLCChatroomViewModel sharedViewModel] clear];
    [[PLVLCDownloadViewModel sharedViewModel] clear];
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
        [self.view addSubview:self.rewardSvgaView];
        [self.view addSubview:self.menuAreaView];     // 菜单区
        [self.view addSubview:self.linkMicAreaView];  // 连麦区
        [self.view addSubview:self.chatLandscapeView];// 横屏聊天区
        [self.view addSubview:self.liveRoomSkinView]; // 横屏频道皮肤
        [self.view addSubview:self.popoverView];      // 浮动区域

        /// 配置
        self.popoverView.frame = self.view.bounds;
        
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
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        
    if (isPad) {
        // iPad小分屏1:2时，隐藏连麦列表；非小分屏时，显示连麦列表
        Boolean isSmallScreen = CGRectGetWidth(self.view.bounds) <= PLVScreenWidth / 3;
        if (isSmallScreen) {
            // 小屏 皆隐藏
            if (showLinkMicAreaView) {
                showLinkMicAreaView = NO;
                self.hideLinkMicAreaViewInSmallScreen = YES;
            }
        } else {
            // 非小屏 但曾在小屏被强制隐藏，需显示
            if (self.hideLinkMicAreaViewInSmallScreen){
                showLinkMicAreaView = YES;
                self.hideLinkMicAreaViewInSmallScreen = NO;
            }
        }
    }
    
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
        [self enableRewardSvgaPlayer:NO];
        
        CGFloat linkMicAreaViewHeight = 0;
        if (showLinkMicAreaView) {
            linkMicAreaViewHeight = isPad ? 101 : 70;
        }

        CGRect linkMicAreaViewFrame = CGRectMake(0, CGRectGetMaxY(self.mediaAreaView.frame), CGRectGetWidth(self.view.bounds), linkMicAreaViewHeight);
        self.linkMicAreaView.frame = linkMicAreaViewFrame;
        
        CGFloat menuAreaOriginY = self.linkMicAreaView.inRTCRoom ? CGRectGetMaxY(linkMicAreaViewFrame) : CGRectGetMaxY(mediaAreaViewFrame);
        self.menuAreaView.frame = CGRectMake(0, menuAreaOriginY, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-menuAreaOriginY);
        
        /// 图层管理
        [self.view insertSubview:self.mediaAreaView.marqueeView aboveSubview:self.mediaAreaView]; /// 保证高于 mediaAreaView 即可
        [self.view insertSubview:self.mediaAreaView.floatView belowSubview:self.popoverView.interactView]; /// 保证低于 interactView
        [self.view insertSubview:((UIView *)self.linkMicAreaView.currentControlBar) belowSubview:self.popoverView.interactView]; /// 保证低于 interactView 即可
        
    } else {
        // 横屏
        self.linkMicAreaView.hidden = !self.linkMicAreaView.inRTCRoom;
        self.menuAreaView.hidden = YES;
        
        CGFloat commonPadding = isPad ? 30 : 16;
        
        CGFloat leftPadding = P_SafeAreaLeftEdgeInsets() + commonPadding;
        CGFloat rightPadding = P_SafeAreaRightEdgeInsets();
        if ([PLVFdUtil isiPhoneXSeries]) {
            rightPadding += 10;
        }
        
        self.chatLandscapeView.frame = CGRectMake(leftPadding, self.view.bounds.size.height / 2.0, 240,  self.view.bounds.size.height / 2.0 - commonPadding);
        
        if (self.fullScreenDifferent) {
            [self.liveRoomSkinView synchOtherSkinViewState:self.mediaAreaView.skinView];
            [self.liveRoomSkinView displayLikeButtonView:self.menuAreaView.chatVctrl.likeButtonView];
        }
        [self.view insertSubview:self.chatLandscapeView belowSubview:self.liveRoomSkinView];
       
        CGFloat linkMicAreaViewWidth = isPad ? 180.0 + rightPadding + commonPadding : 150.0 + rightPadding + commonPadding;
        linkMicAreaViewWidth = showLinkMicAreaView ? linkMicAreaViewWidth : 0;
        CGRect linkMicAreaViewFrame = CGRectMake(CGRectGetWidth(self.view.bounds) - linkMicAreaViewWidth,
                                                 0,
                                                 linkMicAreaViewWidth,
                                                 CGRectGetHeight(self.view.bounds));
        self.linkMicAreaView.frame = linkMicAreaViewFrame;
        [self enableRewardSvgaPlayer:YES];
        
        if (isPad) {
            // iPad横屏的分屏变换时，刷新连麦工具栏布局
            [self.linkMicAreaView setNeedsLayout];
            [self.linkMicAreaView layoutIfNeeded];
        }
        
        CGRect mediaAreaViewFrame = CGRectMake(0,
                                               0,
                                               CGRectGetWidth(self.view.bounds) - linkMicAreaViewWidth,
                                               CGRectGetHeight(self.view.bounds));
        self.mediaAreaView.frame = mediaAreaViewFrame;
        
        /// 图层管理
        [self.view insertSubview:self.mediaAreaView.floatView belowSubview:self.liveRoomSkinView]; /// 保证低于 liveRoomSkinView
        [self.view insertSubview:self.mediaAreaView.marqueeView aboveSubview:self.liveRoomSkinView]; /// 保证高于 liveRoomSkinView 即可
        [self.view insertSubview:self.mediaAreaView.retryPlayView aboveSubview:self.liveRoomSkinView]; /// 保证高于 liveRoomSkinView 即可
        [self.view insertSubview:((UIView *)self.linkMicAreaView.currentControlBar) belowSubview:self.popoverView.interactView]; /// 保证低于 interactView
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
    [[PLVLCDownloadViewModel sharedViewModel] clear];
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

- (void)noDelayLiveWannaPlay:(BOOL)play {
    [self.liveRoomSkinView setPlayButtonWithPlaying:play];
    [self.mediaAreaView.skinView setPlayButtonWithPlaying:play];
}

/// 是否在播放器区域展示打赏动画
- (void)enableRewardSvgaPlayer:(BOOL)enable {
    UIView *superView = enable ? self.rewardSvgaView : nil;
    self.rewardDisplayManager.superView = superView;
    CGRect frame = enable ? self.mediaAreaView.frame : CGRectZero;
    self.rewardSvgaView.frame = frame;
    self.rewardSvgaView.hidden = !enable;
}

/// 跳转至商品详情页
- (void)jumpToCommodityDetailViewController {
    PLVCommodityDetailViewController *commodityDetailVC = [[PLVCommodityDetailViewController alloc] initWithCommodityURL:self.commodityURL];
    commodityDetailVC.delegate = self;
    self.commodityURL = nil;
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController pushViewController:commodityDetailVC animated:YES];
    } else {
        [PLVLivePictureInPictureRestoreManager sharedInstance].restoreWithPresent = NO;
        PLVBaseNavigationController *nav = [[PLVBaseNavigationController alloc] initWithRootViewController:commodityDetailVC];
        nav.navigationBarHidden = NO;
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }
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
        _menuAreaView.delegate = self;
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

- (PLVPopoverView *)popoverView {
    if (!_popoverView && self.videoType == PLVChannelVideoType_Live) {
        _popoverView = [[PLVPopoverView alloc] initWithLiveType:PLVPopoverViewLiveTypeLC];
        _popoverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _popoverView.delegate = self;
    }
    return _popoverView;
}

- (UIView *)rewardSvgaView {
    if (!_rewardSvgaView) {
        _rewardSvgaView = [[UIView alloc] init];
        _rewardSvgaView.backgroundColor = [UIColor clearColor];
        _rewardSvgaView.userInteractionEnabled = NO;
        _rewardSvgaView.hidden = YES;
    }
    return _rewardSvgaView;
}

- (PLVRewardDisplayManager *)rewardDisplayManager{
    if (!_rewardDisplayManager) {
        _rewardDisplayManager = [[PLVRewardDisplayManager alloc] init];
    }
    return _rewardDisplayManager;
}

- (PLVCommodityPushView *)pushView {
    if (!_pushView) {
        _pushView = [[PLVCommodityPushView alloc] initWithType:PLVCommodityPushViewTypeLC];
        _pushView.layer.masksToBounds = YES;
        _pushView.layer.cornerRadius = 4;
        _pushView.backgroundColor = [UIColor whiteColor];
        _pushView.delegate = self;
    }
    return _pushView;
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
    if (!self.fullScreenDifferent) {
        self.fullScreenDifferent = (self.currentLandscape != fullScreen);
    }
    self.currentLandscape = fullScreen;
    
    // 全屏播放器皮肤 liveRoomSkinView 的弹幕按钮 danmuButton 为显示状态，且为非选中状态，且当前为横屏时，才显示弹幕
    BOOL danmuEnable = !self.liveRoomSkinView.danmuButton.selected && !self.liveRoomSkinView.danmuButton.hidden;
    [self.mediaAreaView showDanmu:fullScreen && danmuEnable];
    // 可在此处控制 “横屏聊天区”，是否跟随 “弹幕” 一并显示/隐藏；注释或移除此句，则不跟随；
    // 其他相关代码，可在此文件中，搜索 “self.chatLandscapeView.hidden = ”
    self.chatLandscapeView.hidden = !(fullScreen && danmuEnable);
    
    if (self.fullScreenDifferent) {
        [self.popoverView hidRewardView];
    }
    
    // 调用setStatusBarHidden后状态栏旋转横屏不自动隐藏
    [[UIApplication sharedApplication] setStatusBarHidden:fullScreen];
}

- (void)notificationForOpenBulletin:(NSNotification *)notif {
    [self.popoverView.interactView openLastBulletin];
}

- (void)notificationForOpenRewardView:(NSNotification *)notif {
    [self.popoverView showRewardView];
}

- (void)notificationForOpenInteractApp:(NSNotification *)notif {
    if ([PLVFdUtil checkStringUseable:notif.object]) {
        [self.popoverView.interactView openInteractAppWithEventName:notif.object];
    }
}

#pragma mark - [ Delegate ]
#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didChannelInfoChanged:(PLVChannelInfoModel *)channelInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    
    BOOL playbackEnable = roomData.menuInfo.chatInputDisable && roomData.videoType == PLVChannelVideoType_Playback;
    if (playbackEnable && !self.playbackViewModel) {
        [self.playbackViewModel clear];
        
        self.playbackViewModel = [[PLVLCChatroomPlaybackViewModel alloc] initWithChannelId:roomData.channelId sessionId:roomData.playbackSessionId];
        self.playbackViewModel.delegate = self;
        [self.menuAreaView updatePlaybackViewModel:self.playbackViewModel];
        [self.chatLandscapeView updatePlaybackViewModel:self.playbackViewModel];
    }
    
    self.liveRoomSkinView.danmuButtonShow = !roomData.channelInfo.closeDanmuEnable;
    [self.menuAreaView updateLiveUserInfo];
    [self.popoverView.interactView updateUserInfo];
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

- (void)roomDataManager_didVidChanged:(NSString *)vid {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.menuInfo.chatInputDisable && roomData.playbackSessionId) {
        [self.playbackViewModel clear];
        
        self.playbackViewModel = [[PLVLCChatroomPlaybackViewModel alloc] initWithChannelId:roomData.channelId sessionId:roomData.playbackSessionId];
        self.playbackViewModel.delegate = self;
        [self.menuAreaView updatePlaybackViewModel:self.playbackViewModel];
        [self.chatLandscapeView updatePlaybackViewModel:self.playbackViewModel];
    }
}

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [PLVLCUtils showHUDWithTitle:@"登陆成功" detail:@"" view:self.view];
//    });
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    if (error.code == PLVSocketLoginErrorCodeKick) {
        [self.linkMicAreaView leaveLinkMicOnlyEmit];
        plv_dispatch_main_async_safe(^{
            [PLVLCUtils showHUDWithTitle:nil detail:@"您已被管理员踢出聊天室！" view:self.view afterDelay:3.0];
        })
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf exitCurrentController]; // 使用weakSelf，不影响self释放内存
        });
    } else if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
                error.code == PLVSocketLoginErrorCodeRelogin) &&
               error.localizedDescription) {
        [self.linkMicAreaView leaveLinkMicOnlyEmit];
        plv_dispatch_main_async_safe(^{
            [PLVLCUtils showHUDWithTitle:nil detail:error.localizedDescription view:self.view afterDelay:3.0];
        })
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf exitCurrentController];
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

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([subEvent isEqualToString:@"CLOSEROOM"]) { // admin closes or opens the chatroom
        [self closeRoomEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"PRODUCT_MESSAGE"]) {
        [self productMessageEvent:jsonDict];
    }
}

#pragma mark socket 数据解析

/// 讲师关闭、打开聊天室
- (void)closeRoomEvent:(NSDictionary *)jsonDict {
    NSDictionary *value = PLV_SafeDictionaryForDictKey(jsonDict, @"value");
    BOOL closeRoom = PLV_SafeBoolForDictKey(value, @"closed");
    NSString *string = closeRoom ? @"聊天室已经关闭" : @"聊天室已经打开";
    plv_dispatch_main_async_safe(^{
        [PLVLCUtils showHUDWithTitle:string detail:@"" view:self.view];
    })
}

/// 推送商品
- (void)productMessageEvent:(NSDictionary *)jsonDict {
    NSInteger status = PLV_SafeIntegerForDictKey(jsonDict, @"status");
    if (status == 9) {
        NSDictionary *content = PLV_SafeDictionaryForDictKey(jsonDict, @"content");
        PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:content];
        __weak typeof(self)weakSelf = self;
        plv_dispatch_main_async_safe(^{
            [weakSelf.pushView setModel:model];
            [weakSelf.pushView showOnView:weakSelf.menuAreaView initialFrame:CGRectMake(-CGRectGetWidth(weakSelf.view.frame), 60, CGRectGetWidth(weakSelf.view.frame) - 40, 114)];
        })
    }
}

#pragma mark PLVLCChatroomViewModelProtocol

- (void)chatroomManager_danmu:(NSString * )content {
    [self.mediaAreaView insertDanmu:content];
}

- (void)chatroomManager_loadRewardEnable:(BOOL)enable payWay:payWay rewardModelArray:(NSArray *)modelArray pointUnit:(NSString *)pointUnit {
    self.liveRoomSkinView.rewardButton.hidden = !enable;
    if (enable) {
        [self.popoverView setRewardViewData:payWay rewardModelArray:modelArray pointUnit:pointUnit];
    }
}

- (void)chatroomManager_rewardSuccess:(NSDictionary *)modelDict {
    if (![PLVLCChatroomViewModel sharedViewModel].hideRewardDisplay) {
        NSInteger num = [modelDict[@"goodNum"] integerValue];
        NSString *unick = modelDict[@"unick"];
        PLVRewardGoodsModel *model = [PLVRewardGoodsModel modelWithSocketObject:modelDict];
        [self.rewardDisplayManager addGoodsShowWithModel:model goodsNum:num personName:unick];
    }
}

#pragma mark PLVLCChatroomPlaybackDelegate

- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    return self.mediaAreaView.currentPlayTime;
}

- (void)didReceiveDanmu:(NSString * )content chatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.mediaAreaView insertDanmu:content];
}

#pragma mark PLVLCMediaAreaViewDelegate
/// 用户希望退出当前页面
- (void)plvLCMediaAreaViewWannaBack:(PLVLCMediaAreaView *)mediaAreaView{
    // 在打开画中画的时候退出直播间，则直接退出，当前控制器会被PLVLivePictureInPictureRestoreManager持有不被释放，恢复的时候再次显示
    if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
        self.logoutWhenStopPictureInPicutre = YES;
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [PLVLivePictureInPictureRestoreManager sharedInstance].restoreWithPresent = YES;
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }else {
        [self.linkMicAreaView leaveLinkMicOnlyEmit];
        [self exitCurrentController];
    }
}

/// 媒体区域视图需要得知当前‘是否正在连麦’
- (BOOL)plvLCMediaAreaViewGetInLinkMic:(PLVLCMediaAreaView *)mediaAreaView{
    return self.linkMicAreaView.inLinkMic;
}

/// 媒体区域视图需要得知当前‘是否正在连麦的过程中’
- (BOOL)plvLCMediaAreaViewGetInLinkMicProcess:(PLVLCMediaAreaView *)mediaAreaView {
    if (self.linkMicStatus == PLVLinkMicStatus_Open ||
        self.linkMicStatus == PLVLinkMicStatus_NotOpen ||
        self.linkMicStatus == PLVLinkMicStatus_Unknown) {
        return NO;
    }
    return YES;
}

- (BOOL)plvLCMediaAreaViewGetPausedWatchNoDelay:(PLVLCMediaAreaView *)mediaAreaView {
    return self.linkMicAreaView.pausedWatchNoDelay;
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
        
        [self.menuAreaView updateLiveStatus:PLVLCLiveStatusLiving];
    }else if (livePlayerState == PLVChannelLiveStreamState_Stop){
        [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        
        [self.menuAreaView updateLiveStatus:PLVLCLiveStatusStop];
    }else{
        if (livePlayerState == PLVChannelLiveStreamState_End) {
            [self startCountdownTimer];
        }
        [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        
        [self.menuAreaView updateLiveStatus:PLVLCLiveStatusEnd];
    }
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
    [self.liveRoomSkinView setPlayButtonWithPlaying:noDelayLiveStart];
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
    if ([PLVLCBasePlayerSkinView checkView:self.linkMicAreaView.logoImageView canBeHandlerForTouchPoint:point onSkinView:skinView]){
        return YES;
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
    [self.playbackViewModel updateDuration:durationTime];
    [self.liveRoomSkinView setProgressWithCachedProgress:cachedProgress playedProgress:playedProgress durationTime:(NSTimeInterval)durationTime currentTimeString:currentTimeString durationString:durationString];
}

- (void)plvLCMediaAreaViewDidSeekSuccess:(PLVLCMediaAreaView *)mediaAreaView {
    [self.playbackViewModel playbakTimeChanged];
}

// 文档、白板页码变化的回调
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView pageStatusChangeWithAutoId:(NSUInteger)autoId pageNumber:(NSUInteger)pageNumber totalPage:(NSUInteger)totalPage pptStep:(NSUInteger)step maxNextNumber:(NSUInteger)maxNextNumber {
    [self.liveRoomSkinView.documentToolView setupPageNumber:pageNumber totalPage:totalPage maxNextNumber:maxNextNumber];
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView didChangeMainSpeakerPPTOnMain:(BOOL)mainSpeakerPPTOnMain {
    [self.liveRoomSkinView setupMainSpeakerPPTOnMain:mainSpeakerPPTOnMain];
}

/// [无延迟直播] 无延迟观看模式 发生改变
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView noDelayWatchModeSwitched:(BOOL)noDelayWatchMode {
    [self noDelayLiveWannaPlay:YES];
    [self.linkMicAreaView startWatchNoDelay:noDelayWatchMode];
    if (noDelayWatchMode) {
        [self.linkMicAreaView pauseWatchNoDelay:NO];
    }
}

/// [无延迟直播] 无延迟直播 ‘播放或暂停’
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView noDelayLiveWannaPlay:(BOOL)wannaPlay {
    [self noDelayLiveWannaPlay:wannaPlay];
    [self.linkMicAreaView pauseWatchNoDelay:!wannaPlay];
}

-(void)plvLCMediaAreaViewClickDownloadListButton:(PLVLCMediaAreaView *)mediaAreaView {
    PLVLCDownloadListViewController *downlistVC = [[PLVLCDownloadListViewController alloc]init];
    
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController pushViewController:downlistVC animated:YES];
    } else {
        PLVBaseNavigationController *nav = [[PLVBaseNavigationController alloc] initWithRootViewController:downlistVC];
        nav.navigationBarHidden = NO;
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView playbackVideoInfoDidUpdated:(PLVPlaybackVideoInfoModel *)videoInfo {
    if ([videoInfo isKindOfClass:[PLVPlaybackLocalVideoInfoModel class]]) {
        [self.menuAreaView updateLiveStatus:PLVLCLiveStatusCached];
    }else {
        [self.menuAreaView updateLiveStatus:PLVLCLiveStatusPlayback];
    }
}

#pragma mark PLVLCLiveRoomPlayerSkinViewDelegate
- (void)plvLCLiveRoomPlayerSkinViewBulletinButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView{
    [self.popoverView.interactView openLastBulletin];
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

- (void)plvLCLiveRoomPlayerSkinViewRewardButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView {
    [self.popoverView showRewardView];
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
    
    // 连麦Rtc画面会显示在主屏，需要隐藏PPT翻页
    [self.liveRoomSkinView setupMainSpeakerPPTOnMain:NO];
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
            skinViewLiveStatus = PLVLCBasePlayerSkinViewLiveStatus_Living_CDN;
        }else{
            // 非直播中
            skinViewLiveStatus = PLVLCBasePlayerSkinViewLiveStatus_None;
        }
    }
    [self.liveRoomSkinView switchSkinViewLiveStatusTo:skinViewLiveStatus];
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
        sceneType = self.mediaAreaView.noDelayLiveWatching ? PLVLCMediaAreaViewLiveSceneType_WatchNoDelay : PLVLCMediaAreaViewLiveSceneType_WatchCDN;
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
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:self.mediaAreaView.noDelayLiveWatching ? PLVLCBasePlayerSkinViewLiveStatus_Living_NODelay : PLVLCBasePlayerSkinViewLiveStatus_Living_CDN];
        }else{
            // 非直播中
            [self.liveRoomSkinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        }
    }
    
    /// 恢复所有远端流
    if (inLinkMic) {
        [self noDelayLiveWannaPlay:YES];
        if (self.mediaAreaView.noDelayLiveWatching) {
            [self.linkMicAreaView pauseWatchNoDelay:NO];
        }
    }
}

/// ‘连麦状态’状态值改变
-(void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView currentLinkMicStatus:(PLVLinkMicStatus)currentLinkMicStatus {
    self.linkMicStatus = currentLinkMicStatus;
    // 连麦的时候不允许开启画中画小窗
    if (self.linkMicStatus == PLVLinkMicStatus_Open ||
        self.linkMicStatus == PLVLinkMicStatus_NotOpen) {
        [self.liveRoomSkinView refreshPictureInPictureButtonShow:YES];
        [self.mediaAreaView refreshPictureInPictureButtonShow:YES];
    }else {
        [self.liveRoomSkinView refreshPictureInPictureButtonShow:NO];
        [self.mediaAreaView refreshPictureInPictureButtonShow:NO];
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

/// 无延迟直播观看 网络质量检测
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView localUserNetworkRxQuality:(PLVBLinkMicNetworkQuality)rxQuality {
    if (rxQuality == PLVBLinkMicNetworkQualityFine) {
        [self.mediaAreaView showNetworkQualityMiddleView];
    } else if (rxQuality == PLVBLinkMicNetworkQualityBad) {
        [self.mediaAreaView showNetworkQualityPoorView];
    }
}

#pragma mark PLVLCLivePageMenuAreaViewDelegate

- (NSTimeInterval)plvLCLivePageMenuAreaViewGetPlayerCurrentTime:(PLVLCLivePageMenuAreaView *)pageMenuAreaView{
    return self.mediaAreaView.currentPlayTime;
}

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView seekTime:(NSTimeInterval)time{
    [self.mediaAreaView seekLivePlaybackToTime:time];
}

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView clickProductLinkURL:(NSURL *)linkURL {
    [self plvCommodityPushViewJumpToCommodityDetail:linkURL];
}

#pragma mark  PLVCommodityPushViewDelegate

- (void)plvCommodityPushViewJumpToCommodityDetail:(NSURL *)commodityURL {
    self.commodityURL = commodityURL;
    if (self.videoType == PLVChannelVideoType_Live) { /// 直播场景需要开启画中画播放
        if (self.mediaAreaView.channelInLive &&
            !self.linkMicAreaView.inLinkMic &&
            [[PLVLivePictureInPictureManager sharedInstance] checkPictureInPictureSupported]) {
            [self.mediaAreaView startPictureInPicture];
        } else {
            [self jumpToCommodityDetailViewController];
        }
    } else if (self.videoType == PLVChannelVideoType_Playback) { /// 回放场景不支持画中画
        [self jumpToCommodityDetailViewController];
    }
}

#pragma mark  PLVCommodityDetailViewControllerDelegate

- (void)plvCommodityDetailViewControllerAfterTheBack {
    [self.mediaAreaView stopPictureInPicture];
}

- (void)plvLCMediaAreaViewPictureInPictureWillStart:(PLVLCMediaAreaView *)mediaAreaView {
}

- (void)plvLCMediaAreaViewPictureInPictureDidStart:(PLVLCMediaAreaView *)mediaAreaView {
    // 更多按钮显示控制
    [self.liveRoomSkinView refreshMoreButtonHiddenOrRestore:YES];
    
    // 画中画占位视图显示控制、播放控制
    if (self.mediaAreaView.currentLiveSceneType != PLVLCMediaAreaViewLiveSceneType_WatchCDN) {
        [self.linkMicAreaView setPictureInPicturePlaceholderShow:YES];
    }
    
    // 设定画中画恢复逻辑的处理者为PLVLivePictureInPictureRestoreManager
    [PLVLivePictureInPictureManager sharedInstance].restoreDelegate = [PLVLivePictureInPictureRestoreManager sharedInstance];
    // 开启画中画之后，让PLVLivePictureInPictureRestoreManager持有本控制器，使得退出本页面后还能通过画中画恢复
    [PLVLivePictureInPictureRestoreManager sharedInstance].holdingViewController = self;
    
    if (!self.commodityURL) {
        return;
    }
    [self jumpToCommodityDetailViewController];
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView pictureInPictureFailedToStartWithError:(NSError *)error {
    // 清理恢复逻辑的处理者
    [[PLVLivePictureInPictureRestoreManager sharedInstance] cleanRestoreManager];
}

- (void)plvLCMediaAreaViewPictureInPictureWillStop:(PLVLCMediaAreaView *)mediaAreaView {
    if (self.logoutWhenStopPictureInPicutre &&
        ![PLVLivePictureInPictureManager sharedInstance].restoreDelegate) {
        [self.linkMicAreaView leaveLinkMicOnlyEmit];
        [PLVRoomLoginClient logout];
        [[PLVSocketManager sharedManager] logout];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[PLVLCChatroomViewModel sharedViewModel] clear];
    }
}

- (void)plvLCMediaAreaViewPictureInPictureDidStop:(PLVLCMediaAreaView *)mediaAreaView {
    // 更多按钮显示控制
    [self.liveRoomSkinView refreshMoreButtonHiddenOrRestore:NO];
    
    // 画中画展位视图显示控制、播放控制
    if (self.mediaAreaView.currentLiveSceneType != PLVLCMediaAreaViewLiveSceneType_WatchCDN) {
        [self.linkMicAreaView setPictureInPicturePlaceholderShow:NO];
    }
    
    // 清理恢复逻辑的处理者
    [[PLVLivePictureInPictureRestoreManager sharedInstance] cleanRestoreManager];
}

#pragma mark  PLVPopoverViewDelegate

- (void)popoverViewDidDonatePointWithError:(NSString *)error {
    plv_dispatch_main_async_safe(^{
        [PLVLCUtils showHUDWithTitle:error detail:@"" view:self.view];
    })
}

@end
