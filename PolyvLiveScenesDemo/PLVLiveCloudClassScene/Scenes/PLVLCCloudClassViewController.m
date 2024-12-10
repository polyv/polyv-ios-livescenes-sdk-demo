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
#import "PLVCommodityCardDetailView.h"
#import "PLVLCDownloadListViewController.h"
#import "PLVLCMessagePopupView.h"
#import "PLVLCLandscapeMessagePopupView.h"
#import "PLVLiveToast.h"
#import "PLVSecureView.h"
#import "PLVLCOnlineListSheet.h"

// 工具
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"

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
PLVInteractGenericViewDelegate,
PLVLCChatroomPlaybackDelegate,
PLVLCChatLandscapeViewDelegate,
PLVLCMessagePopupViewDelegate,
PLVLCLandscapeMessagePopupViewDelegate,
PLVLCOnlineListSheetDelegate
>

#pragma mark 数据
@property (nonatomic, assign, readonly) PLVChannelType channelType; // 只读，当前 频道类型
@property (nonatomic, assign, readonly) PLVChannelVideoType videoType; // 只读，当前 视频类型
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中
@property (nonatomic, strong) NSURL *commodityURL;
@property (nonatomic, assign) BOOL logoutWhenStopPictureInPicutre;   // 关闭画中画的时候是否登出
@property (nonatomic, assign) BOOL welfareLotteryWidgetShowed;

#pragma mark 状态
@property (nonatomic, assign) BOOL currentLandscape;    // 当前是否横屏 (YES:当前横屏 NO:当前竖屏)
@property (nonatomic, assign) BOOL fullScreenDifferent; // 在更新UI布局之前，横竖屏是否发现了变化 (YES:已变化 NO:没有变化)
@property (nonatomic, assign) BOOL hideLinkMicAreaViewInSmallScreen;// 连麦列表是否在iPad小分屏时隐藏
@property (nonatomic, assign) PLVLinkMicStatus linkMicStatus;   // 当前的连麦状态

#pragma mark 模块
@property (nonatomic, strong) NSTimer * countdownTimer;
@property (nonatomic, assign) NSTimeInterval countdownTime;
@property (nonatomic, strong) PLVLCChatroomPlaybackViewModel *playbackViewModel; // 聊天重放viewModel

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
/// ├── (PLVLCDocumentPaintModeView) paintModeView (由 mediaAreaView 持有及管理)
/// └── (PLVPopoverView) popoverView
@property (nonatomic, strong) PLVLCMediaAreaView *mediaAreaView;        // 媒体区
@property (nonatomic, strong) PLVLCLinkMicAreaView *linkMicAreaView;    // 连麦区
@property (nonatomic, strong) PLVLCLivePageMenuAreaView *menuAreaView;  // 菜单区
@property (nonatomic, strong) PLVPopoverView *popoverView;              // 浮动区域
@property (nonatomic, strong) PLVRewardDisplayManager *rewardDisplayManager; // 礼物打赏动画管理器
@property (nonatomic, strong) UIView *rewardSvgaView;                   // 礼物打赏动画父视图 （仅在横屏下有效）
@property (nonatomic, strong) PLVCommodityPushView *pushView;           // 商品推送视图
@property (nonatomic, strong) PLVCommodityCardDetailView *cardDetailView;           // 卡片推送加载视图

@property (nonatomic, strong) PLVLCChatLandscapeView *chatLandscapeView;     // 横屏聊天区
@property (nonatomic, strong) PLVLCLiveRoomPlayerSkinView * liveRoomSkinView;// 横屏频道皮肤
@property (nonatomic, strong) PLVLCOnlineListSheet *onlineListSheet;

@property (nonatomic, assign) BOOL inBackground;
@property (nonatomic, assign) BOOL enableSysScreenShot;

@end

@implementation PLVLCCloudClassViewController {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Period ]
- (void)dealloc {
    PLV_LOG_INFO(PLVConsoleLogModuleTypePlayer,@"%s",__FUNCTION__);
    [_countdownTimer invalidate];
    _countdownTimer = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        // 设置多语言场景
        [[PLVMultiLanguageManager sharedManager] setupLocalizedLiveScene:PLVMultiLanguageLiveSceneLC channelId:roomData.channelId language:roomData.menuInfo.watchLangType];
        
        // 设置画中画
        if (@available(iOS 15.0, *)) {
            [PLVLivePictureInPictureManager sharedInstance].pictureInPictureMode = PLVLivePictureInPictureMode_IJKPlayer;
        } else {
            [PLVLivePictureInPictureManager sharedInstance].pictureInPictureMode = PLVLivePictureInPictureMode_AVPlayer;
        }

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

- (void)loadView{
    if ([PLVRoomDataManager sharedManager].roomData.systemScreenShotProtect){
        PLVSecureView *secureView = [[PLVSecureView alloc] init];
        self.view = secureView.secureView;
    }else{
        self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [self setupModule];
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self getEdgeInset];
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

- (void)getEdgeInset {
    [PLVLCUtils sharedUtils].landscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (@available(iOS 11, *)) {
        [[PLVLCUtils sharedUtils] setupAreaInsets:self.view.safeAreaInsets];
    }
}

#pragma mark - [ Public Method ]

- (void)exitCleanCurrentLiveController {
    if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
        [PLVLivePictureInPictureManager sharedInstance].restoreDelegate = nil;
        [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
    }
    [self.linkMicAreaView leaveLinkMicOnlyEmit];
    [self exitCurrentController];
}

#pragma mark - [ Private Methods ]
- (void)setupModule{
    // 通用的 配置
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationForOpenInteractApp:) name:PLVLCChatroomOpenInteractAppNotification object:nil];

    if (self.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 监听事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationForOpenBulletin:) name:PLVLCChatroomOpenBulletinNotification object:nil];
        
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
    }
}

/// 是否支持开启聊天重放：当前处于回放场景、后端接口返回chatInputDisable为YES、已获取到当场回放的场次id
- (BOOL)enableChatroomPlaybackViewModel {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.videoType == PLVChannelVideoType_Playback && roomData.menuInfo.chatInputDisable && roomData.playbackSessionId;
}

/// 创建聊天室回放viewModel并更新到相关子视图
- (void)setupChatroomPlaybackViewModel {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    self.playbackViewModel = [[PLVLCChatroomPlaybackViewModel alloc] initWithChannelId:roomData.channelId sessionId:roomData.playbackSessionId videoId:roomData.playbackVideoInfo.fileId];
    self.playbackViewModel.delegate = self;
    
    [self.menuAreaView updatePlaybackViewModel:self.playbackViewModel];
    [self.chatLandscapeView updatePlaybackViewModel:self.playbackViewModel];
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
    self.fullScreenDifferent = YES; //初始化默认值为YES。用于[updateUI]方法中，需要判断该字段的UI更新默认都执行一次
    self.currentLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    
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
        [self.view addSubview:self.popoverView];      // 浮动区域

        /// 配置
        self.popoverView.frame = self.view.bounds;
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
            [self.menuAreaView.chatVctrl resumeFloatingButtonViewLayout];
            [self.menuAreaView rollbackProductPageContentView];
            [self.pushView showOnView:self.menuAreaView initialFrame:CGRectMake(-CGRectGetWidth(self.view.frame), 60, isPad ? 308 : CGRectGetWidth(self.view.frame) - 60, 128)];
            [self.cardDetailView hiddenCardDetailView];
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
        [self.view insertSubview:((UIView *)self.linkMicAreaView.linkMicPreView) belowSubview:self.popoverView.interactView]; /// 保证低于 interactView 即可
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
            [self.liveRoomSkinView displayRedpackButtonView:self.menuAreaView.chatVctrl.redpackButtonView];
            [self.liveRoomSkinView displayCardPushButtonView:self.menuAreaView.chatVctrl.cardPushButtonView];
            [self.liveRoomSkinView displayLotteryWidgetView:self.menuAreaView.chatVctrl.lotteryWidgetView];
            [self.liveRoomSkinView displayWelfareLotteryWidgetView:self.menuAreaView.chatVctrl.welfareLotteryWidgetView];
            [self.pushView showOnView:self.liveRoomSkinView initialFrame:CGRectMake(- CGRectGetWidth(self.view.frame), CGRectGetMinY(self.chatLandscapeView.frame) + (CGRectGetHeight(self.chatLandscapeView.frame) - 128), 308, 128)];
            [self.cardDetailView hiddenCardDetailView];
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
        [self.view insertSubview:((UIView *)self.linkMicAreaView.linkMicPreView) belowSubview:self.popoverView.interactView]; /// 保证低于 interactView 即可
        [self.view insertSubview:self.mediaAreaView.paintModeView belowSubview:self.popoverView.interactView]; /// 保证低于 interactView
        
        [self.liveRoomSkinView setNeedsLayout];
        [self.popoverView setNeedsLayout];
    }
    
    self.fullScreenDifferent = NO;
}

- (void)refreshLiveRoomPlayerSkinViewUIInfo{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    [self.liveRoomSkinView setTitleLabelWithText:roomData.menuInfo.name];
    [self.liveRoomSkinView setPlayTimesLabelWithTimes:roomData.menuInfo.pageView.integerValue];
    self.liveRoomSkinView.guideChatLabel.hidden = !self.menuAreaView.chatVctrl;
    self.liveRoomSkinView.rewardButton.hidden = !self.menuAreaView.chatVctrl;
    [self.liveRoomSkinView showCommodityButton:self.menuAreaView.showCommodityMenu];
}

- (void)exitCurrentController {
    [self.menuAreaView leaveLiveRoom];
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
        PLVLiveVideoChannelMenuInfo *menuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
        _mediaAreaView.allowChangePPT = (self.videoType == PLVChannelVideoType_Live && menuInfo.transmitMode && !menuInfo.mainRoom);
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
        _chatLandscapeView.delegate = self;
    }
    return _chatLandscapeView;
}

- (PLVPopoverView *)popoverView {
    if (!_popoverView) {
        _popoverView = [[PLVPopoverView alloc] initWithLiveType:PLVPopoverViewLiveTypeLC liveRoom:self.videoType == PLVChannelVideoType_Live];
        _popoverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (self.videoType == PLVChannelVideoType_Live) {
            _popoverView.delegate = self;
        }
        _popoverView.interactView.delegate = self;
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
        _rewardDisplayManager = [[PLVRewardDisplayManager alloc] initWithLiveType:PLVRewardDisplayManagerTypeLC];
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

- (PLVCommodityCardDetailView *)cardDetailView {
    if (!_cardDetailView) {
        _cardDetailView = [[PLVCommodityCardDetailView alloc] init];
        __weak typeof(self) weakSelf = self;
        _cardDetailView.tapActionBlock = ^{
            if (weakSelf.currentLandscape) {
                [weakSelf.liveRoomSkinView hiddenLiveRoomPlayerSkinView:!weakSelf.liveRoomSkinView.needShowSkin];
            }
        };
    }
    return _cardDetailView;
}

- (PLVLCOnlineListSheet *)onlineListSheet {
    if (!_onlineListSheet) {
        _onlineListSheet = [[PLVLCOnlineListSheet alloc] init];
        _onlineListSheet.delegate = self;
        [_onlineListSheet setSheetCornerRadius:16.0f];
    }
    return _onlineListSheet;
}

- (PLVChannelType)channelType{
    return [PLVRoomDataManager sharedManager].roomData.channelType;
}

- (PLVChannelVideoType)videoType{
    return [PLVRoomDataManager sharedManager].roomData.videoType;
}

#pragma mark Setter

- (void)setFullScreenButtonShowOnIpad:(BOOL)fullScreenButtonShowOnIpad {
    _fullScreenButtonShowOnIpad = fullScreenButtonShowOnIpad;
    self.mediaAreaView.fullScreenButtonShowOnIpad = fullScreenButtonShowOnIpad;
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
    // 可在此处控制 “横屏聊天区”，当竖屏聊天Tab存在时是否跟随 “弹幕” 一并显示/隐藏；注释或移除下方，则不跟随；
    // 其他相关代码，可在此文件中，搜索 “self.chatLandscapeView.hidden = ”
    if (self.menuAreaView.chatVctrl) {
        self.chatLandscapeView.hidden = !(fullScreen && danmuEnable);
    } else {
        self.chatLandscapeView.hidden = YES;
    }
    
    if (self.fullScreenDifferent) {
        [self.popoverView hidRewardView];
    }
    
    // 旋转竖屏需要退出画笔模式
    if (self.mediaAreaView.isInPaintMode && self.fullScreenDifferent && !fullScreen) {
        [self.mediaAreaView exitPaintMode];
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
    if ((self.videoType != PLVChannelVideoType_Live && !self.playTimesLabelUseNewStrategy_playback) || (self.videoType == PLVChannelVideoType_Live && !self.playTimesLabelUseNewStrategy_live)) {
        [self.mediaAreaView.skinView setPlayTimesLabelWithTimes:watchCount];
        [self.liveRoomSkinView setPlayTimesLabelWithTimes:watchCount];
    }
}

// 在线人数 onlineCount 更新
- (void)roomDataManager_didOnlineCountChanged:(NSUInteger)onlineCount {
    if ((self.videoType != PLVChannelVideoType_Live && self.playTimesLabelUseNewStrategy_playback) || (self.videoType == PLVChannelVideoType_Live && self.playTimesLabelUseNewStrategy_live)) {
        [self.mediaAreaView.skinView setPlayTimesLabelWithOnlineUsers:onlineCount];
        [self.liveRoomSkinView setPlayTimesLabelWithOnlineUsers:onlineCount];
    }
    [self.liveRoomSkinView updateOnlineListButton:onlineCount];
}

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"登录成功") detail:@"" view:self.view];
//    });
    [self.menuAreaView updateQAUserInfo];
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    if (error.code == PLVSocketLoginErrorCodeKick) {
        [self.linkMicAreaView leaveLinkMicOnlyEmit];
        plv_dispatch_main_async_safe(^{
            [PLVLCUtils showHUDWithTitle:nil detail:PLVLocalizedString(@"您已被管理员踢出聊天室！") view:self.view afterDelay:3.0];
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
            [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"聊天室重连中") detail:@"" view:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"聊天室重连成功") detail:@"" view:self.view];
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
    
    if ([subEvent isEqualToString:@"PRODUCT_MESSAGE"]) {
        plv_dispatch_main_async_safe(^{
            [self productMessageEvent:jsonDict];
        })
    } else if ([subEvent isEqualToString:@"onSliceID"]) {
        NSDictionary *data = PLV_SafeDictionaryForDictKey(jsonDict, @"data");
        if ([PLVFdUtil checkDictionaryUseable:data]) {
            NSDictionary *speakTop = PLV_SafeDictionaryForDictKey(data, @"speakTop");
            PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
            if ([PLVFdUtil checkDictionaryUseable:speakTop] &&
                roomData.videoType == PLVChannelVideoType_Live) {
                PLVSpeakTopMessage *message = [[PLVSpeakTopMessage alloc] initWithDictionary:speakTop];
                plv_dispatch_main_async_safe(^{
                    [self.mediaAreaView showPinMessagePopupView:YES message:message];
                })
            } else if (roomData.videoType == PLVChannelVideoType_Live) {
                plv_dispatch_main_async_safe(^{
                    [self.mediaAreaView showPinMessagePopupView:NO message:nil];
                })
            }
        }
    }
}

- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if ([event isEqualToString:@"product"]) {
        if ([subEvent isEqualToString:@"PRODUCT_CLICK_TIMES"]) {
            NSDictionary *jsonDict = (NSDictionary *)object;
            if ([PLVFdUtil checkDictionaryUseable:jsonDict]) {
                [self.pushView updateProductClickTimes:jsonDict];
            }
        }
    } else if ([event isEqualToString:@"speak"]) {
        if ([subEvent isEqualToString:@"TO_TOP"] || [subEvent isEqualToString:@"CANCEL_TOP"]) {
            NSDictionary *jsonDict = (NSDictionary *)object;
            if ([PLVFdUtil checkDictionaryUseable:jsonDict] && roomData.videoType == PLVChannelVideoType_Live) {
                BOOL show = [subEvent isEqualToString:@"TO_TOP"];
                PLVSpeakTopMessage *message = [[PLVSpeakTopMessage alloc] initWithDictionary:jsonDict];
                plv_dispatch_main_async_safe(^{
                    [self.mediaAreaView showPinMessagePopupView:show message:message];
                })
            }
        }
    }
    
    if (self.videoType != PLVChannelVideoType_Live ||
        !roomData.menuInfo.transmitMode ||
        roomData.menuInfo.mainRoom) { // 【直播+支持双师模式+小房间】三个条件满足才需要监听以下消息
        return;
    }
    
    BOOL listenMain = roomData.listenMain;
    if ([event isEqualToString:@"transmit"]) { // 【双师模式】所需监听event
        if ([subEvent isEqualToString:@"transmitDoubleMode"]) { // 双师模式小房间登录聊天室时收到ack
            if (jsonString &&
                [jsonString isKindOfClass:[NSString class]]) {
                if ([jsonString isEqualToString:@"listenMain"]) {
                    roomData.listenMain = YES;
                } else if ([jsonString isEqualToString:@"listenChild"]) {
                    roomData.listenMain = NO;
                }
            }
        } else if ([subEvent isEqualToString:@"changeDoubleMode"]) { // 双师模式切换房间时收到
            NSDictionary *jsonDict = (NSDictionary *)object;
            if (jsonDict &&
                [jsonDict isKindOfClass:[NSDictionary class]]) {
                NSString *mode = jsonDict[@"mode"];
                if ([mode isEqualToString:@"listenMain"]) {
                    roomData.listenMain = YES;
                } else if ([mode isEqualToString:@"listenChild"]) {
                    roomData.listenMain = NO;
                }
                NSInteger autoId = [jsonDict[@"autoId"] integerValue];
                NSInteger pageId = [jsonDict[@"pageId"] integerValue];
                [self.mediaAreaView changePPTWithAutoId:autoId pageNumber:pageId];
            }
        }
    }
    
    if (roomData.listenMain != listenMain) { // listenMain发生变化时，切换播放器频道
        dispatch_async(dispatch_get_main_queue(), ^{
            if (roomData.listenMain) {
                [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"已切换至大房间进行上课") inView:self.view afterDelay:3.0];
                [self.mediaAreaView changePlayertoChannelId:roomData.menuInfo.mainRoomChannelId vodId:nil vodList:NO recordFile:nil recordEnable:NO];
            } else {
                [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"已切回小房间上课") inView:self.view afterDelay:3.0];
                [self.mediaAreaView changePlayertoChannelId:roomData.channelId vodId:nil vodList:NO recordFile:nil recordEnable:NO];
            }
        });
    }
}

#pragma mark socket 数据解析

/// 推送商品
- (void)productMessageEvent:(NSDictionary *)jsonDict {
    NSInteger status = PLV_SafeIntegerForDictKey(jsonDict, @"status");
    if (status == 9) {
        NSDictionary *content = PLV_SafeDictionaryForDictKey(jsonDict, @"content");
        PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:content];
        if (![PLVFdUtil checkStringUseable:model.productPushRule]) {
            return;
        }
        
        if ([model.productPushRule isEqualToString:@"smallCard"]) {
            [self.pushView setModel:model];
            [self.pushView reportTrackEvent];
            if (self.currentLandscape) {
                [self.pushView showOnView:self.liveRoomSkinView initialFrame:CGRectMake(-CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 128 - 16, 308, 128)];
            } else {
                [self.pushView showOnView:self.menuAreaView initialFrame:CGRectMake(-CGRectGetWidth(self.view.frame), 60, CGRectGetWidth(self.view.frame) - 60, 128)];
            }
        } else {
            [_pushView hide];
        }
    } else if (status == 3 || status == 2 || status == 11) { // 收到 删除/下架/取消推送商品 消息时进行处理
        [ _pushView hide];
    } else if (status == 10) { // 收到 关闭商品列表 消息时进行处理
        NSDictionary *contentDict = PLV_SafeDictionaryForDictKey(jsonDict, @"content");
        NSString *enabledString = PLV_SafeStringForDictKey(contentDict, @"enabled");
        BOOL enabled = [enabledString isEqualToString:@"N"]?NO:YES;
        if (!enabled && _pushView) {
            [ _pushView hide];
        }
        
        [self.menuAreaView updateProductMenuTab:contentDict];
        [self.liveRoomSkinView showCommodityButton:enabled];
    }
}

#pragma mark PLVLCChatroomViewModelProtocol

- (void)chatroomManager_danmu:(NSString * )content {
    [self.mediaAreaView insertDanmu:content];
}

- (void)chatroomManager_loadRewardEnable:(BOOL)enable payWay:payWay rewardModelArray:(NSArray *)modelArray pointUnit:(NSString *)pointUnit {
    self.liveRoomSkinView.rewardButton.hidden = !enable || !self.menuAreaView.chatVctrl;
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

- (void)chatroomManager_didLoginRestrict{
    __weak typeof(self)weakSelf = self;
    plv_dispatch_main_async_safe(^{
        [PLVLCUtils showHUDWithTitle:nil detail:PLVLocalizedString(@"直播间太过火爆了，请稍后再来(2050407)")  view:self.view afterDelay:3.0];
    })
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf exitCurrentController]; // 使用weakSelf，不影响self释放内存
    });
}

- (void)chatroomManager_startCardPush:(BOOL)start pushInfo:(NSDictionary *)pushDict {
    __weak typeof(self) weakSelf = self;
    [self.menuAreaView startCardPush:start cardPushInfo:pushDict callback:^(BOOL show) {
        [weakSelf.liveRoomSkinView showCardPushButtonView:show];
    }];
}

- (void)chatroomManager_showDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    if (type != PLVRedpackMessageTypeAliPassword) {
        return;
    }
    [self.liveRoomSkinView showRedpackButtonView:YES];
}

- (void)chatroomManager_hideDelayRedpack {
    [self.liveRoomSkinView showRedpackButtonView:NO];
}

- (void)chatroomManager_closeRoom:(BOOL)closeRoom {
    NSString *string = closeRoom ? PLVLocalizedString(@"聊天室已经关闭") : PLVLocalizedString(@"聊天室已经打开");
    plv_dispatch_main_async_safe(^{
        [PLVLCUtils showHUDWithTitle:string detail:@"" view:self.view];
        [self.liveRoomSkinView changeCloseRoomStatus:closeRoom];
    })
}

- (void)chatroomManager_focusMode:(BOOL)focusMode {
    NSString *string = focusMode ? PLVLocalizedString(@"聊天室专注模式已开启") : PLVLocalizedString(@"聊天室专注模式已关闭");
    plv_dispatch_main_async_safe(^{
        [PLVLCUtils showHUDWithTitle:string detail:@"" view:self.view];
        [self.liveRoomSkinView changeFocusModeStatus:focusMode];
        [self.chatLandscapeView updateChatTableView];
    })

}

- (void)chatroomManager_checkRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model {
    // 若红包已过期或领完，打开后h5的UI会给予提示
    [self.popoverView.interactView openRedpackWithChatModel:model];
}

- (void)chatroomManager_didUpdateOnlineList:(NSArray<PLVChatUser *> *)list total:(NSInteger)total {
    [self.menuAreaView updateOnlineList:list total:total];
    [self.onlineListSheet updateOnlineList:list];
}

- (void)chatroomManager_didSendMessage:(PLVChatModel *)model {
    if (!self.welfareLotteryWidgetShowed ||!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    
    id message = model.message;
    if (message &&
        [message isKindOfClass:[PLVSpeakMessage class]] && model.contentLength == PLVChatMsgContentLength_0To500) {
        PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
        NSString *comment = speakMessage.content;
        if (![PLVFdUtil checkStringUseable:comment]) {
            return;
        }
        [self.popoverView.interactView checkWelfareLotteryComment:comment];
    }
}

#pragma mark PLVLCChatroomPlaybackDelegate

- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    return self.mediaAreaView.currentPlayTime;
}

- (void)didReceiveDanmu:(NSString * )content chatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.mediaAreaView insertDanmu:content];
}

- (void)didReceiveSpeakTopMessageChatModel:(PLVChatModel *)model
                            showPinMsgView:(BOOL)show
                 chatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.mediaAreaView showPinMessagePopupView:show message:model.message];
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
    if (![PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
        [self.liveRoomSkinView setPlayButtonWithPlaying:playing];
    }
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

- (void)plvLCMediaAreaViewWannaLiveRoomSkinViewShowMoreView:(PLVLCMediaAreaView *)mediaAreaView {
    if (self.liveRoomSkinView) {
        [self.mediaAreaView plvLCBasePlayerSkinViewMoreButtonClicked:self.liveRoomSkinView];
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

// 画笔权限改变
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView didChangePaintPermission:(BOOL)permission {
    NSString *title = permission ? PLVLocalizedString(@"讲师已授予你画笔权限") : PLVLocalizedString(@"讲师已收回你的画笔权限");
    [PLVLCUtils showHUDWithTitle:title detail:@"" view:self.view];
    if (permission && !self.liveRoomSkinView.skinShow) {
        [self.liveRoomSkinView controlsSwitchShowStatusWithAnimation:YES];
    }
    [self.liveRoomSkinView refreshPaintButtonShow:permission];
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView didChangeInPaintMode:(BOOL)paintMode {
    [self.linkMicAreaView restoreExternalView];
    [self.liveRoomSkinView controlsSwitchShowStatusWithAnimation:NO];
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

/// 广告‘正在播放状态’ 发生改变
- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView advertViewPlayingDidChange:(BOOL)playing {
    [self.liveRoomSkinView refreshPictureInPictureButtonShow:!playing];
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

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView preventScreenCapturing:(BOOL)start {
    [self.linkMicAreaView preventScreenCapturing:start];
    
    if (start) {
        [PLVFdUtil showAlertWithTitle:PLVLocalizedString(@"暂时无法观看") message:PLVLocalizedString(@"停止录屏才能继续正常观看") viewController:[PLVFdUtil getCurrentViewController] cancelActionTitle:PLVLocalizedString(@"确认") cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:nil confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:nil];
    }
    
    if ([PLVRoomDataManager sharedManager].roomData.fullScreenProtectWhenCaptureScreen) {
        self.view.hidden = start;
    }
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView playbackVideoSizeChange:(CGSize)videoSize {
    if (self.videoType == PLVChannelVideoType_Playback) {
        [self.liveRoomSkinView refreshPictureInPictureButtonShow:YES];
    }
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView playbackVideoInfoDidUpdated:(PLVPlaybackVideoInfoModel *)videoInfo {
    if ([videoInfo isKindOfClass:[PLVPlaybackLocalVideoInfoModel class]]) {
        [self.menuAreaView updateLiveStatus:PLVLCLiveStatusCached];
    }else {
        [self.menuAreaView updateLiveStatus:PLVLCLiveStatusPlayback];
    }
    [self.playbackViewModel clear];
    if ([self enableChatroomPlaybackViewModel]) {
        [self setupChatroomPlaybackViewModel];
    }
    [self.menuAreaView updateSectionMenuTab];
}

- (void)plvLCMediaAreaViewWannaStartPictureInPicture:(PLVLCMediaAreaView *)mediaAreaView {
    self.linkMicAreaView.currentControlBar.pictureInPictureStarted = YES;
}

#pragma mark PLVLCLiveRoomPlayerSkinViewDelegate
- (void)plvLCLiveRoomPlayerSkinViewBulletinButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView{
    [self.popoverView.interactView openLastBulletin];
}

- (void)plvLCLiveRoomPlayerSkinViewDanmuButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaShowDanmu:(BOOL)showDanmu{
    [self.mediaAreaView showDanmu:showDanmu];
    // 可在此处控制 “横屏聊天区”，当竖屏聊天Tab存在时是否跟随 “弹幕” 一并显示/隐藏；注释或移除下方代码，则不跟随；
    // 其他相关代码，可在此文件中，搜索 “self.chatLandscapeView.hidden = ”
    if (self.menuAreaView.chatVctrl) {
        self.chatLandscapeView.hidden = !showDanmu;
    } else {
        self.chatLandscapeView.hidden = YES;
    }
}

- (void)plvLCLiveRoomPlayerSkinViewDanmuSettingButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView {
    [self.mediaAreaView danmuSettingViewOnSuperview:liveRoomPlayerSkinView.superview];
}

- (void)plvLCLiveRoomPlayerSkinView:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView
           userWannaSendChatContent:(NSString *)chatContent
                         replyModel:(PLVChatModel *)replyModel {
    BOOL success = [[PLVLCChatroomViewModel sharedViewModel] sendSpeakMessage:chatContent replyChatModel:replyModel];
    if (!success) {
        [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"消息发送失败") detail:@"" view:self.view];
    }
}

- (void)plvLCLiveRoomPlayerSkinViewRewardButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView {
    [self.popoverView showRewardView];
}

- (void)plvLCLiveRoomPlayerSkinViewCommodityButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView {
    [self.liveRoomSkinView hiddenLiveRoomPlayerSkinView:YES];
    // 加载商品库视图
    [self.menuAreaView displayProductPageToExternalView:self.view];
}

- (void)plvLCLiveRoomPlayerSkinViewOnlineListButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView {
    [self.onlineListSheet showInView:self.view];
}

#pragma mark PLVLCLinkMicAreaViewDelegate
/// 连麦Rtc画面窗口 需外部展示 ‘第一画面连麦窗口’
- (void)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView showFirstSiteCanvasViewOnExternal:(UIView *)canvasView{
    [self.mediaAreaView displayContentView:canvasView];
}

/// 连麦Rtc画面窗口被点击 (表示用户希望视图位置交换)
- (UIView *)plvLCLinkMicAreaView:(PLVLCLinkMicAreaView *)linkMicAreaView rtcWindowDidClickedCanvasView:(UIView *)canvasView{
    if (self.mediaAreaView.isInPaintMode) {
        [self.mediaAreaView exitPaintMode];
    }
    
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
        if (self.mediaAreaView.isInPaintMode) { // 退出画笔模式
            [self.mediaAreaView exitPaintMode];
        }
        [self.liveRoomSkinView refreshPaintButtonShow:NO];
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
    return self.mediaAreaView.channelInLive && !self.mediaAreaView.advertPlaying;
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

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView clickProductCommodityModel:(PLVCommodityModel *)commodity {
    [self plvCommodityPushViewDidClickCommodityDetail:commodity];
}

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView didShowJobDetail:(NSDictionary *)data {
    [self.popoverView.interactView openJobDetailWithData:data];
}

- (void)plvLCLivePageMenuAreaViewCloseProductView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView {
    if (self.currentLandscape) {
        [self.liveRoomSkinView hiddenLiveRoomPlayerSkinView:!self.liveRoomSkinView.needShowSkin];
    }
}

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView needOpenInteract:(NSDictionary *)dict {
    [self.popoverView.interactView openNewPushCardWithDict:dict];
}

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView alertLongContentMessage:(PLVChatModel *)model {
    NSString *content = [model isOverLenMsg] ? model.overLenContent : model.content;
    if (content) {
        PLVLCMessagePopupView *popupView = [[PLVLCMessagePopupView alloc] initWithChatModel:model];
        CGFloat containerHeight = [UIScreen mainScreen].bounds.size.height - CGRectGetMaxY(self.mediaAreaView.frame);
        [popupView setContainerHeight:containerHeight];
        popupView.delegate = self;
        [popupView showOnView:self.popoverView];
    }
}

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView emitInteractEvent:(NSString *)event {
    [self.popoverView.interactView openInteractAppWithEventName:event];
}

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView lotteryWidgetShowStatusChanged:(BOOL)show {
    [self.liveRoomSkinView showLotteryWidgetView:show];
}

- (void)plvLCLivePageMenuAreaViewWannaShowOnlineListRule:(PLVLCLivePageMenuAreaView *)pageMenuAreaView {
    [self.mediaAreaView showOnlineListRuleListView];
}

- (void)plvLCLivePageMenuAreaViewNeedUpdateOnlineList:(PLVLCLivePageMenuAreaView *)pageMenuAreaView {
    [[PLVLCChatroomViewModel sharedViewModel] updateOnlineList];
}

- (void)plvLCLivePageMenuAreaViewWannaShowWelfareLottery:(PLVLCLivePageMenuAreaView *)pageMenuAreaView {
    [self.popoverView.interactView openWelfareLottery];
}

- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView welfareLotteryWidgetShowStatusChanged:(BOOL)show {
    self.welfareLotteryWidgetShowed = show;
    [self.liveRoomSkinView showWelfareLotteryWidgetView:show];
}

#pragma mark  PLVCommodityPushViewDelegate

- (void)plvCommodityPushViewDidClickCommodityDetail:(PLVCommodityModel *)commodity {
    [self.pushView sendProductClickedEvent:commodity];
    if ([commodity.buyType isEqualToString:@"inner"]) { /// 直接购买
    } else if ([commodity.buyType isEqualToString:@"link"]) { /// 外链购买
        if (![PLVFdUtil checkStringUseable:commodity.formattedLink]) {
            return;
        }
        
        self.commodityURL = [NSURL URLWithString:commodity.formattedLink];
        if (self.videoType == PLVChannelVideoType_Live) { /// 直播场景需要开启画中画播放
            if (self.mediaAreaView.channelInLive &&
                !self.linkMicAreaView.inLinkMic &&
                [[PLVLivePictureInPictureManager sharedInstance] checkPictureInPictureSupported] &&
                ![PLVRoomDataManager sharedManager].roomData.captureScreenProtect &&
                ![PLVRoomDataManager sharedManager].roomData.systemScreenShotProtect) {
                [self.mediaAreaView startPictureInPicture];
            } else {
                [self jumpToCommodityDetailViewController];
            }
        } else if (self.videoType == PLVChannelVideoType_Playback) { /// 回放场景不支持画中画
            [self jumpToCommodityDetailViewController];
        }
    }
}

- (void)plvCommodityPushViewDidShowJobDetail:(NSDictionary *)data {
    [self.popoverView.interactView openJobDetailWithData:data];
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
    [self.liveRoomSkinView enablePlayControlButtons:NO];
        
    if (self.videoType == PLVChannelVideoType_Live){ // 视频类型为 直播回放
        // 画中画占位视图显示控制、播放控制
        if (self.mediaAreaView.currentLiveSceneType != PLVLCMediaAreaViewLiveSceneType_WatchCDN) {
            [self.linkMicAreaView setPictureInPicturePlaceholderShow:YES];
        }
    } else if (self.videoType == PLVChannelVideoType_Playback) { // 视频类型为 直播回放
        [self.liveRoomSkinView refreshProgressControlsShow:NO];
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
    self.linkMicAreaView.currentControlBar.pictureInPictureStarted = NO;
    [self.liveRoomSkinView enablePlayControlButtons:YES];
    
    if (self.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        // 画中画展位视图显示控制、播放控制
        if (self.mediaAreaView.currentLiveSceneType != PLVLCMediaAreaViewLiveSceneType_WatchCDN) {
            [self.linkMicAreaView setPictureInPicturePlaceholderShow:NO];
        }
    } else if (self.videoType == PLVChannelVideoType_Playback) { // 视频类型为 直播回放
        [self.liveRoomSkinView refreshProgressControlsShow:YES];
    }
    
    // 清理恢复逻辑的处理者
    [[PLVLivePictureInPictureRestoreManager sharedInstance] cleanRestoreManager];
}

- (void)plvLCMediaAreaView:(PLVLCMediaAreaView *)mediaAreaView pictureInPicturePlayerPlayingStateDidChange:(BOOL)playing {
    [self.liveRoomSkinView setPlayButtonWithPlaying:playing];
}

#pragma mark PLVPopoverViewDelegate

- (void)popoverViewDidDonatePointWithError:(NSString *)error {
    plv_dispatch_main_async_safe(^{
        [PLVLCUtils showHUDWithTitle:error detail:@"" view:self.view];
    })
}

#pragma mark PLVInteractGenericViewDelegate

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView loadWebViewURL:(NSURL *)url insideLoad:(BOOL)insideLoad {
    if (insideLoad) {
        [self.cardDetailView loadWebviewWithCardURL:url];
        if (self.currentLandscape) {
            [self.liveRoomSkinView hiddenLiveRoomPlayerSkinView:YES];
            [self.cardDetailView showOnView:self.view frame:CGRectMake(self.view.bounds.size.width * 0.6, 0, self.view.bounds.size.width * 0.4, self.view.bounds.size.height)];
        } else {
            [self.cardDetailView showOnView:self.view frame:CGRectMake(0, CGRectGetMinY(self.menuAreaView.frame) +  48, self.menuAreaView.bounds.size.width, self.menuAreaView.bounds.size.height - 48)];
        }
    } else {
        self.commodityURL = url;
        [self jumpToCommodityDetailViewController];
    }
}

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView
                didOpenRedpack:(NSString *)redpackId
                        status:(NSString *)status {
    [[PLVLCChatroomViewModel sharedViewModel] changeRedpackStateWithRedpackId:redpackId state:status];
}

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView updateLotteryWidget:(NSDictionary *)dict {
    NSArray *dataArray = PLV_SafeArraryForDictKey(dict, @"dataArray");
    [self.menuAreaView.chatVctrl updateLotteryWidgetViewInfo:dataArray];
}

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView clickBigCardCommodityDetail:(PLVCommodityModel *)commodity {
    [self plvCommodityPushViewDidClickCommodityDetail:commodity];
}

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView updateWelfareLotteryWidget:(NSDictionary *)dict {
    [self.menuAreaView.chatVctrl updateWelfareLotteryWidgetInfo:dict];
}

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView welfareLotteryCommentSuccess:(NSDictionary *)dict {
    NSString *comment = PLV_SafeStringForDictKey(dict, @"comment");
    if ([PLVFdUtil checkStringUseable:comment]) {
        [[PLVLCChatroomViewModel sharedViewModel] welfareLotteryCommentSuccess:comment];
    }
}
#pragma mark PLVLCChatLandscapeViewDelegate

- (void)chatLandscapeView:(PLVLCChatLandscapeView *)chatView alertLongContentMessage:(PLVChatModel *)model {
    NSString *content = [model isOverLenMsg] ? model.overLenContent : model.content;
    if (content) {
        PLVLCLandscapeMessagePopupView *popupView = [[PLVLCLandscapeMessagePopupView alloc] initWithChatModel:model];
        popupView.delegate = self;
        [popupView showOnView:self.popoverView];
    }
}

- (void)chatLandscapeView:(PLVLCChatLandscapeView *)chatView didTapReplyMessage:(PLVChatModel *)model {
    [self.liveRoomSkinView didTapReplyChatModel:model];
}

#pragma mark PLVLCMessagePopupViewDelegate

- (void)messagePopupViewWillCopy:(PLVLCMessagePopupView *)popupView {
    [UIPasteboard generalPasteboard].string = popupView.content;
    [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.view afterDelay:3.0];
}

#pragma mark PLVLCLandscapeMessagePopupViewDelegate

- (void)landscapeMessagePopupViewWillCopy:(PLVLCLandscapeMessagePopupView *)popupView {
    [UIPasteboard generalPasteboard].string = popupView.content;
    [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.view afterDelay:3.0];
}

#pragma mark PLVLCOnlineListSheetDelegate

- (void)plvLCOnlineListSheetWannaShowRule:(PLVLCOnlineListSheet *)sheet {
    [self.mediaAreaView showOnlineListRuleListView];
}

- (void)plvLCOnlineListSheetNeedUpdateOnlineList:(PLVLCOnlineListSheet *)sheet {
    [[PLVLCChatroomViewModel sharedViewModel] updateOnlineList];
}

@end
