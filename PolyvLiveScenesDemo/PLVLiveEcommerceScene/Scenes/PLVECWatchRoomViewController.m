//
//  PLVECWatchRoomViewController.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECWatchRoomViewController.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVECPlayerViewController.h"
#import "PLVCommodityDetailViewController.h"
#import "PLVBaseNavigationController.h"
#import "PLVECFloatingWindow.h"
#import "PLVECLinkMicAreaView.h"
#import "PLVPopoverView.h"
#import "PLVLivePictureInPictureRestoreManager.h"
#import "PLVChatModel.h"
#import "PLVECChatroomViewModel.h"

// UI
#import "PLVECHomePageView.h"
#import "PLVECLiveDetailPageView.h"
#import "PLVECWatchRoomScrollView.h"
#import "PLVCommodityCardDetailView.h"
#import "PLVECMessagePopupView.h"
#import "PLVToast.h"

// 工具
#import "PLVECUtils.h"
#import "PLVMultiLanguageManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NSString *PLVECInteractUpdateIarEntranceCallbackNotification = @"PLVInteractUpdateIarEntranceCallbackNotification";
NSString *PLVECInteractUpdateMoreButtonCallbackNotification = @"PLVInteractUpdateChatButtonCallbackNotification";

@interface PLVECWatchRoomViewController ()<
PLVSocketManagerProtocol,
PLVECHomePageViewDelegate,
PLVECFloatingWindowProtocol,
PLVECPlayerViewControllerProtocol,
PLVRoomDataManagerProtocol,
UIScrollViewDelegate,
PLVECLinkMicAreaViewDelegate,
PLVLivePictureInPictureRestoreDelegate,
PLVCommodityDetailViewControllerDelegate,
PLVPopoverViewDelegate,
PLVInteractGenericViewDelegate,
PLVECMessagePopupViewDelegate
>

#pragma mark 数据
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中
@property (nonatomic, assign) BOOL logoutWhenStopPictureInPicutre;   // 关闭画中画的时候是否登出

#pragma mark 模块
@property (nonatomic, strong) PLVECPlayerViewController * playerVC; // 播放控制器
@property (nonatomic, strong) PLVCommodityDetailViewController *commodityDetailVC; // 商品详情页控制器
@property (nonatomic, strong) PLVECLinkMicAreaView *linkMicAreaView; //连麦
@property (nonatomic, strong) PLVPopoverView *popoverView; // 浮动区域

#pragma mark UI
@property (nonatomic, strong) PLVECWatchRoomScrollView * scrollView;
@property (nonatomic, strong) PLVECHomePageView *homePageView;
@property (nonatomic, strong) PLVECLiveDetailPageView * liveDetailPageView;
@property (nonatomic, strong) UIButton * closeButton;
@property (nonatomic, strong) PLVCommodityCardDetailView *cardDetailView;           // 卡片推送加载视图

@end

@implementation PLVECWatchRoomViewController

#pragma mark - [ Life Period ]

- (instancetype)init {
    self = [super init];
    if (self) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        // 设置多语言场景
        [[PLVMultiLanguageManager sharedManager] setupLocalizedLiveScene:PLVMultiLanguageLiveSceneEC channelId:roomData.channelId language:roomData.menuInfo.watchLangType];
        
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[PLVRoomDataManager sharedManager].roomData requestChannelFunctionSwitch];
        
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self addObserver];
    }
    return self;
}

- (void)dealloc{
    [self removeObserver];
    NSLog(@"%s",__FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupData];
    
    [PLVECFloatingWindow sharedInstance].delegate = self;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self getEdgeInset];
    
    /// 布局视图 [多次]
    CGFloat closeBtn_y = 32.f;
    if (@available(iOS 11.0, *)) {
        closeBtn_y = self.view.safeAreaLayoutGuide.layoutFrame.origin.y + 12;
    }
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds)-47, closeBtn_y, 32, 32);
    self.closeButton.hidden = [PLVECUtils sharedUtils].isLandscape;
    CGRect scrollViewFrame = [PLVECUtils sharedUtils].isLandscape ? CGRectMake(P_SafeAreaLeftEdgeInsets(), 0, CGRectGetWidth(self.view.bounds) - P_SafeAreaLeftEdgeInsets(), CGRectGetHeight(self.view.bounds) ):CGRectMake(0, P_SafeAreaTopEdgeInsets(), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - P_SafeAreaTopEdgeInsets());
    self.scrollView.frame = scrollViewFrame;
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame) * 3, CGRectGetHeight(scrollViewFrame));
    
    self.homePageView.frame = CGRectMake(CGRectGetWidth(scrollViewFrame), 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
    
    self.liveDetailPageView.frame = CGRectMake(0, 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
    self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(scrollViewFrame), 0);
    self.popoverView.frame = self.view.bounds;
    
    CGFloat playerVCWidth = [PLVECUtils sharedUtils].isLandscape ? self.scrollView.bounds.size.width - P_SafeAreaRightEdgeInsets() : self.scrollView.bounds.size.width;

    self.playerVC.view.frame = CGRectMake(self.scrollView.bounds.origin.x, self.scrollView.bounds.origin.y, playerVCWidth, self.scrollView.bounds.size.height);// 重新布局
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    CGPoint boundsPoint = self.scrollView.bounds.origin;
    CGSize boundsSize = self.scrollView.bounds.size;
    CGFloat playerVCWidth = [PLVECUtils sharedUtils].isLandscape ? boundsSize.width - P_SafeAreaRightEdgeInsets() : boundsSize.width;

    self.playerVC.view.frame = CGRectMake(boundsPoint.x, boundsPoint.y, playerVCWidth, boundsSize.height);// 重新布局
    self.linkMicAreaView.frame = self.scrollView.bounds;
    
    CGSize marqueeViewSize = CGSizeMake(boundsSize.width, boundsSize.width / 16 * 9);
    self.playerVC.marqueeView.frame = CGRectMake(self.scrollView.contentOffset.x, (boundsSize.height - marqueeViewSize.height) / 2.0, marqueeViewSize.width, marqueeViewSize.height);
    
    [self.scrollView insertSubview:self.playerVC.view atIndex:0];
    [self.scrollView insertSubview:self.linkMicAreaView atIndex:1];
    [self.scrollView insertSubview:self.playerVC.marqueeView aboveSubview:self.linkMicAreaView];
    
    [self.playerVC cancelMute];
    if (self.linkMicAreaView.inLinkMic) {
        [self.linkMicAreaView reloadLinkMicUserWindows];
    }
    
    self.logoutWhenStopPictureInPicutre = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    if ([PLVECFloatingWindow sharedInstance].hidden) {
        [self.playerVC mute];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate {
    return (_playerVC.fullScreenEnable && !_linkMicAreaView.inLinkMic) || [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if ((_playerVC.fullScreenEnable && !_linkMicAreaView.inLinkMic) || [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height) {
        return [PLVECUtils sharedUtils].interfaceOrientation;
    }
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ((_playerVC.fullScreenEnable && !_linkMicAreaView.inLinkMic) || [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height) {
        return (UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait);
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
    
}

- (void)getEdgeInset {
    [PLVECUtils sharedUtils].landscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (@available(iOS 11, *)) {
        [[PLVECUtils sharedUtils] setupAreaInsets:self.view.safeAreaInsets];
    }
}

#pragma mark - [ Public Method ]

- (void)exitCleanCurrentLiveController {
    if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
        [PLVLivePictureInPictureManager sharedInstance].restoreDelegate = nil;
        [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
    }

    [PLVRoomLoginClient logout];
    [[PLVSocketManager sharedManager] logout];
    [self.homePageView destroy];

    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [PLVECFloatingWindow sharedInstance].delegate = nil;
}

#pragma mark - [ Private Methods ]

- (void)setupUI{
    /// 注意：1. 此处不建议将共同拥有的图层，提炼在 if 判断外，来做“代码简化”
    ///         因为此处涉及到添加顺序，而影响图层顺序。放置在 if 内，能更加准确地配置图层顺序，也更清晰地预览图层顺序。
    ///      2. 懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 创建添加视图
        [self.view addSubview:self.scrollView];
        [self.scrollView addSubview:self.homePageView];
        [self.scrollView addSubview:self.liveDetailPageView];
        [self.view addSubview:self.closeButton];
        
        /// 布局视图 [单次]
        CGRect scrollViewFrame = CGRectMake(0, P_SafeAreaTopEdgeInsets(), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - P_SafeAreaTopEdgeInsets());
        self.scrollView.frame = scrollViewFrame;
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame) * 3, CGRectGetHeight(scrollViewFrame) - P_SafeAreaBottomEdgeInsets());
        
        self.homePageView.frame = CGRectMake(CGRectGetWidth(scrollViewFrame), 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        
        self.liveDetailPageView.frame = CGRectMake(0, 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(scrollViewFrame), 0);
        
        /// 互动
        [self.view addSubview:self.popoverView];
        self.popoverView.frame = self.view.bounds;
        
        [self.view insertSubview:((UIView *)self.linkMicAreaView.linkMicPreView) belowSubview:self.popoverView]; /// 保证低于 互动视图
        [self.view insertSubview:((UIView *)self.linkMicAreaView.currentControlBar) belowSubview:self.popoverView]; /// 保证低于 互动视图
        
        if (roomData.menuInfo) { [self roomDataManager_didMenuInfoChanged:roomData.menuInfo]; }
        
    } else if (roomData.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
        /// 创建添加视图
        [self.view addSubview:self.scrollView];
        [self.scrollView addSubview:self.homePageView];
        [self.scrollView addSubview:self.liveDetailPageView];
        [self.view addSubview:self.closeButton];
        
        /// 布局视图 [单次]
        CGRect scrollViewFrame = CGRectMake(0, P_SafeAreaTopEdgeInsets(), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - P_SafeAreaTopEdgeInsets());
        self.scrollView.frame = scrollViewFrame;
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame) * 3, CGRectGetHeight(scrollViewFrame) - P_SafeAreaBottomEdgeInsets());
        
        self.homePageView.frame = CGRectMake(CGRectGetWidth(scrollViewFrame), 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        
        self.liveDetailPageView.frame = CGRectMake(0, 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(scrollViewFrame), 0);
       
        /// 互动
        [self.view addSubview:self.popoverView];
        self.popoverView.frame = self.view.bounds;
        
        if (roomData.menuInfo) { [self roomDataManager_didMenuInfoChanged:roomData.menuInfo]; }
    }
    
    /// 适配背景铺满全屏
    UIImage *image = [PLVECUtils imageForWatchResource:@"plv_background_img"];
    self.view.layer.contents = (id)image.CGImage;
}

- (void)setupData{
    /// 注意：懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.videoType == PLVChannelVideoType_Live ||
        roomData.videoType == PLVChannelVideoType_Playback) {
        self.playerVC = [[PLVECPlayerViewController alloc] init];
        self.playerVC.view.frame = self.scrollView.bounds;
        self.playerVC.delegate = self;
        self.scrollView.playerDisplayView = self.playerVC.displayView;
        [self.scrollView insertSubview:self.playerVC.view atIndex:0];
    }
}

- (void)exitCurrentController {
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
        [PLVRoomLoginClient logout];
        [[PLVSocketManager sharedManager] logout];
        [self.homePageView destroy];

        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        [PLVECFloatingWindow sharedInstance].delegate = nil;
    }
}

- (void)openCommodityDetailViewControllerWithURL:(NSURL *)commodityURL {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (![PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
        // 打开应用内悬浮窗
        if (self.linkMicAreaView.inLinkMic) {
            [[PLVECFloatingWindow sharedInstance] showContentView:self.linkMicAreaView.firstSiteCanvasView];
        } else {
            [[PLVECFloatingWindow sharedInstance] showContentView:self.playerVC.view size:self.playerVC.displayView.frame.size];
        }
        [PLVECFloatingWindow sharedInstance].holdingViewController = self;
    }
    
    // 跳转商品详情页
    self.commodityDetailVC = [[PLVCommodityDetailViewController alloc] initWithCommodityURL:commodityURL];
    self.commodityDetailVC.delegate = self;
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController pushViewController:self.commodityDetailVC animated:YES];
    } else {
        [PLVLivePictureInPictureRestoreManager sharedInstance].restoreWithPresent = NO;
        [PLVECFloatingWindow sharedInstance].restoreWithPresent = NO;
        PLVBaseNavigationController *nav = [[PLVBaseNavigationController alloc] initWithRootViewController:self.commodityDetailVC];
        nav.navigationBarHidden = NO;
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark Getter
- (PLVECWatchRoomScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[PLVECWatchRoomScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.pagingEnabled = YES;
        _scrollView.backgroundColor = UIColor.clearColor;
        _scrollView.bounces = NO;
        _scrollView.alwaysBounceVertical = NO;
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (PLVECHomePageView *)homePageView{
    if (!_homePageView) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        PLVECHomePageType homePageType = -1;
        if (roomData.videoType == PLVChannelVideoType_Live) {
            homePageType = PLVECHomePageType_Live;
        } else if (roomData.videoType == PLVChannelVideoType_Playback) {
            homePageType = PLVECHomePageType_Playback;
        }
        _homePageView = [[PLVECHomePageView alloc] initWithType:homePageType delegate:self];
    }
    return _homePageView;
}

- (PLVECLiveDetailPageView *)liveDetailPageView{
    if (!_liveDetailPageView) {
        _liveDetailPageView = [[PLVECLiveDetailPageView alloc] init];
    }
    return _liveDetailPageView;
}

- (PLVPopoverView *)popoverView {
    PLVChannelVideoType videoType = [PLVRoomDataManager sharedManager].roomData.videoType;
    if (!_popoverView) {
        _popoverView = [[PLVPopoverView alloc] initWithLiveType:PLVPopoverViewLiveTypeEC liveRoom:videoType == PLVChannelVideoType_Live];
        _popoverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _popoverView.interactView.delegate = self;
        if (videoType == PLVChannelVideoType_Live) {
            _popoverView.delegate = self;
        }
    }
    return _popoverView;
}

- (UIButton *)closeButton{
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[PLVECUtils imageForWatchResource:@"plv_close_btn"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (PLVECLinkMicAreaView *)linkMicAreaView {
    if (!_linkMicAreaView) {
        _linkMicAreaView = [[PLVECLinkMicAreaView alloc] init];
        _linkMicAreaView.delegate = self;
    }
    return _linkMicAreaView;
}

- (PLVCommodityCardDetailView *)cardDetailView {
    if (!_cardDetailView) {
        _cardDetailView = [[PLVCommodityCardDetailView alloc] init];
    }
    return _cardDetailView;
}

#pragma mark Getter
- (void)setFullScreenButtonShowOnIpad:(BOOL)fullScreenButtonShowOnIpad {
    _fullScreenButtonShowOnIpad = fullScreenButtonShowOnIpad;
    self.playerVC.fullScreenButtonShowOnIpad = fullScreenButtonShowOnIpad;
    self.homePageView.backButtonShowOnIpad = fullScreenButtonShowOnIpad;
}

#pragma mark - [ Event ]
#pragma mark Action
- (void)closeButtonAction:(UIButton *)button {
    [self exitCurrentController];
}

#pragma mark Notification

- (void)addObserver {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interactUpdateMoreButtonCallback:) name:PLVECInteractUpdateMoreButtonCallbackNotification object:nil];
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 监听事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationForUpdateIarEntrance:) name:PLVECInteractUpdateIarEntranceCallbackNotification object:nil];
    } else if (roomData.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
    }
}

- (void)removeObserver {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PLVECInteractUpdateMoreButtonCallbackNotification object:nil];
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 监听事件
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PLVECInteractUpdateIarEntranceCallbackNotification object:nil];
    } else if (roomData.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
    }
}
- (void)notificationForOpenBulletin:(NSNotification *)notif {
    [self.popoverView.interactView openLastBulletin];
}

- (void)notificationForUpdateIarEntrance:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;;
    NSArray *buttonDataArray = PLV_SafeArraryForDictKey(dict, @"dataArray");
    [self.homePageView updateIarEntranceButtonDataArray:buttonDataArray];
}

- (void)interactUpdateMoreButtonCallback:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSArray *buttonDataArray = PLV_SafeArraryForDictKey(dict, @"dataArray");
    [self.homePageView updateMoreButtonDataArray:buttonDataArray];
}

#pragma mark - [ Delegate ]
#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didChannelInfoChanged:(PLVChannelInfoModel *)channelInfo {
    [self.popoverView.interactView updateUserInfo];
}

- (void)roomDataManager_didOnlineCountChanged:(NSUInteger)onlineCount {
    // 在回放时 显示观看次数 不需要更新在线人数
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live) {
        [self.homePageView updateRoomInfoCount:onlineCount];
    }
}

- (void)roomDataManager_didLikeCountChanged:(NSUInteger)likeCount {
    [self.homePageView updateLikeCount:likeCount];
}

- (void)roomDataManager_didPlayingStatusChanged:(BOOL)playing {
    [self.homePageView updatePlayerState:playing];
}

- (void)roomDataManager_didVidChanged:(NSString *)vid {
    [self.playerVC changeVid:vid];
}

- (void)roomDataManager_didMenuInfoChanged:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    for (PLVLiveVideoChannelMenu *menu in menuInfo.channelMenus) {
        if ([menu.menuType isEqualToString:@"desc"]) {
            [self.liveDetailPageView addLiveInfoCardView:menu.content];
        } else if ([menu.menuType isEqualToString:@"buy"]) {
            [self.homePageView showShoppingCart:YES];
        }
    }
    
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        [self.homePageView updateChannelInfo:roomData.menuInfo.publisher coverImage:roomData.menuInfo.coverImage];
        [self.homePageView updateLikeCount:roomData.likeCount];
    } else if (roomData.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
        [self.homePageView updateChannelInfo:roomData.menuInfo.publisher coverImage:roomData.menuInfo.coverImage];
        [self.homePageView updateRoomInfoCount:roomData.menuInfo.pageView.integerValue];
    }
}

- (void)roomDataManager_didLiveStateChanged:(PLVChannelLiveStreamState)liveState {
    [self.homePageView updatePlayerState:liveState == PLVChannelLiveStreamState_Live];
}

- (void)roomDataManager_didWatchCountChanged:(NSUInteger)watchCount {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    // 在回放时 更新观看次数
    if (roomData.videoType == PLVChannelVideoType_Playback){
        [self.homePageView updateRoomInfoCount:roomData.watchCount];
    }
}

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
//    [PLVECUtils showHUDWithTitle:PLVLocalizedString(@"登录成功") detail:@"" view:self.view];
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    if (error.code == PLVSocketLoginErrorCodeKick) {
        plv_dispatch_main_async_safe(^{
            [PLVECUtils showHUDWithTitle:nil detail:PLVLocalizedString(@"您已被管理员踢出聊天室！") view:self.view afterDelay:3.0];
        })
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf exitCurrentController]; // 使用weakSelf，不影响self释放内存
        });
    } else if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
                error.code == PLVSocketLoginErrorCodeRelogin) &&
               error.localizedDescription) {
        plv_dispatch_main_async_safe(^{
            [PLVECUtils showHUDWithTitle:nil detail:error.localizedDescription view:self.view afterDelay:3.0];
        })
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf exitCurrentController];
        });
    }
}

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([subEvent isEqualToString:@"LOGIN"]) {   // someone logged in chatroom
        [self loginEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"LOGOUT"]) { // someone logged in chatroom
        [self logoutEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"CLOSEROOM"]) { // admin closes or opens the chatroom
        [self closeRoomEvent:jsonDict];
    }
}

- (void)socketMananger_didConnectStatusChange:(PLVSocketConnectStatus)connectStatus {
    if (connectStatus == PLVSocketConnectStatusReconnect) {
        self.socketReconnecting = YES;
        plv_dispatch_main_async_safe(^{
            [PLVECUtils showHUDWithTitle:PLVLocalizedString(@"聊天室重连中") detail:@"" view:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVECUtils showHUDWithTitle:PLVLocalizedString(@"聊天室重连成功") detail:@"" view:self.view];
            })
        }
    }
}

#pragma mark socket 数据解析

/// 有用户登录
- (void)loginEvent:(NSDictionary *)data {
    NSInteger onlineCount = PLV_SafeIntegerForDictKey(data, @"onlineUserNumber");
    [self updateOnlineCount:onlineCount];
}

/// 有用户登出
- (void)logoutEvent:(NSDictionary *)data {
    NSInteger onlineCount = PLV_SafeIntegerForDictKey(data, @"onlineUserNumber");
    [self updateOnlineCount:onlineCount];
}

/// 讲师关闭、打开聊天室
- (void)closeRoomEvent:(NSDictionary *)jsonDict {
    NSDictionary *value = PLV_SafeDictionaryForDictKey(jsonDict, @"value");
    BOOL closeRoom = PLV_SafeBoolForDictKey(value, @"closed");
    NSString *string = closeRoom ? PLVLocalizedString(@"聊天室已经关闭") : PLVLocalizedString(@"聊天室已经打开");
    plv_dispatch_main_async_safe(^{
        [PLVECUtils showHUDWithTitle:string detail:@"" view:self.view];
    })
}

#pragma mark 更新 RoomData 属性

- (void)updateOnlineCount:(NSInteger)onlineCount {
    [PLVRoomDataManager sharedManager].roomData.onlineCount = onlineCount;
}

#pragma mark PLVECFloatingWindowProtocol

- (void)floatingWindow_closeWindowAndBack:(BOOL)back {
    if (!back) {
        [self.playerVC mute];
    }
}

#pragma mark PLVECPlayerViewController Protocol

- (void)playerController:(PLVECPlayerViewController *)playerController codeRateItems:(NSArray<NSString *> *)codeRateItems codeRate:(NSString *)codeRate lines:(NSUInteger)lines line:(NSInteger)line noDelayWatchMode:(BOOL)noDelayWatchMode {
    [self.homePageView updateCodeRateItems:codeRateItems defaultCodeRate:codeRate];
    [self.homePageView updateLineCount:lines defaultLine:line];
    [self.homePageView updateNoDelayWatchMode:noDelayWatchMode];
}

- (void)playerControllerWannaSwitchLine:(PLVECPlayerViewController *)playerController {
    [UIView animateWithDuration:0.5 animations:^{
            self.scrollView.contentOffset = CGPointMake(CGRectGetMinX(self.homePageView.frame), 0);
        } completion:^(BOOL finished) {
            [self.homePageView showMoreView];
        }];
}

- (void)playerControllerWannaFullScreen:(PLVECPlayerViewController *)playerController {
    [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
    [[PLVECUtils sharedUtils] setupDeviceOrientation:UIDeviceOrientationLandscapeLeft];
}

- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
  currentPlaybackTimeInterval:(NSTimeInterval)currentPlaybackTimeInterval
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime {
    [self.homePageView updateDowloadProgress:dowloadProgress playedProgress:playedProgress duration:duration currentPlaybackTimeInterval:currentPlaybackTimeInterval currentPlaybackTime:currentPlaybackTime durationTime:durationTime];
}

- (void)playerController:(PLVECPlayerViewController *)playerController playbackVideoInfoDidUpdated:(PLVPlaybackVideoInfoModel *)videoInfo {
    [self.homePageView updatePlaybackVideoInfo];
}

- (void)playerController:(PLVECPlayerViewController *)playerController noDelayLiveStartUpdate:(BOOL)noDelayLiveStart {
    [self.linkMicAreaView startWatchNoDelay:noDelayLiveStart];
}

- (void)playerController:(PLVECPlayerViewController *)playerController quickLiveNetworkQuality:(PLVECLivePlayerQuickLiveNetworkQuality)netWorkQuality {
    if (netWorkQuality == PLVECLivePlayerQuickLiveNetworkQuality_Poor) {
        [self.homePageView showNetworkQualityPoorView];
    } else if (netWorkQuality == PLVECLivePlayerQuickLiveNetworkQuality_Middle) {
        [self.homePageView showNetworkQualityMiddleView];
    }
}

- (void)customMarqueeDefaultWithError:(NSError *)error {
    [self exitCurrentController];
}

- (void)playerController:(PLVECPlayerViewController *)playerController noDelayLiveWannaPlay:(BOOL)wannaPlay {
    [self.linkMicAreaView pauseWatchNoDelay:!wannaPlay];
}

- (BOOL)playerControllerGetPausedWatchNoDelay:(PLVECPlayerViewController *)playerController {
    return self.linkMicAreaView.pausedWatchNoDelay;
}

- (void)playerController:(PLVECPlayerViewController *)playerController noDelayWatchModeSwitched:(BOOL)noDelayWatchMode {
    [self.linkMicAreaView startWatchNoDelay:noDelayWatchMode];
    if (noDelayWatchMode) {
        [self.linkMicAreaView pauseWatchNoDelay:NO]; 
    }
}

/// 画中画即将开启
-(void)playerControllerPictureInPictureWillStart:(PLVECPlayerViewController *)playerController {
    [PLVProgressHUD hideHUDForView:self.view animated:YES];
}

/// 画中画已经开启
-(void)playerControllerPictureInPictureDidStart:(PLVECPlayerViewController *)playerController {
    [self.homePageView updateMoreButtonShow:NO];
    [PLVECUtils showHUDWithTitle:PLVLocalizedString(@"小窗播放中，可能存在画面延后的情况") detail:@"" view:self.view];
    
    if (self.playerVC.noDelayLiveWatching) {
        [self.linkMicAreaView pauseWatchNoDelay:YES];
    }else {
        [self.playerVC pause];
    }
    
    // 设定画中画恢复逻辑的处理者为PLVLivePictureInPictureRestoreManager
    [PLVLivePictureInPictureManager sharedInstance].restoreDelegate = [PLVLivePictureInPictureRestoreManager sharedInstance];
    // 开启画中画之后，让PLVLivePictureInPictureRestoreManager持有本控制器，使得退出本页面后还能通过画中画恢复
    [PLVLivePictureInPictureRestoreManager sharedInstance].holdingViewController = self;
}

/// 画中画开启错误
-(void)playerController:(PLVECPlayerViewController *)playerController pictureInPictureFailedToStartWithError:(NSError *)error {
    [PLVProgressHUD hideHUDForView:self.view animated:YES];
    // 清理恢复逻辑的处理者
    [[PLVLivePictureInPictureRestoreManager sharedInstance] cleanRestoreManager];
}

/// 画中画即将关闭
-(void)playerControllerPictureInPictureWillStop:(PLVECPlayerViewController *)playerController {
    if (self.logoutWhenStopPictureInPicutre &&
        ![PLVLivePictureInPictureManager sharedInstance].restoreDelegate) {
        [PLVRoomLoginClient logout];
        [[PLVSocketManager sharedManager] logout];
        [self.homePageView destroy];
        [PLVECFloatingWindow sharedInstance].delegate = nil;
    }
}

/// 画中画已经关闭
-(void)playerControllerPictureInPictureDidStop:(PLVECPlayerViewController *)playerController {
    [self.homePageView updateMoreButtonShow:YES];
    
    if (self.playerVC.noDelayLiveWatching) {
        [self.linkMicAreaView pauseWatchNoDelay:NO];
    }else {
        [self.playerVC play];
    }
    [self.homePageView updatePlayerState:YES];
    
    // 清理恢复逻辑的处理者
    [[PLVLivePictureInPictureRestoreManager sharedInstance] cleanRestoreManager];
}

#pragma mark PLVECLinkMicAreaViewDelegate

/// 无延迟直播观看 网络质量检测
- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView localUserNetworkRxQuality:(PLVBLinkMicNetworkQuality)rxQuality {
    if (rxQuality == PLVBLinkMicNetworkQualityFine) {
        [self.homePageView showNetworkQualityMiddleView];
    } else if (rxQuality == PLVBLinkMicNetworkQualityBad) {
        [self.homePageView showNetworkQualityPoorView];
    }
}

/// ‘是否在RTC房间中’ 状态值发生改变
- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView inRTCRoomChanged:(BOOL)inRTCRoom {
    //TODO: 随着RTC房间的状态变化，切换视图是否合适，如果网络变差，临时从连麦中断开，也会导致变成播放器画面
    if (inRTCRoom) {
        [self.playerVC cleanPlayer];
    } else {
        [self.playerVC reload];
    }
    self.playerVC.view.alpha = inRTCRoom ? 0 : 1;
    self.playerVC.displayView.alpha = inRTCRoom ? 0 : 1;
    self.linkMicAreaView.alpha = inRTCRoom ? 1 : 0;
    
    if (![PLVECFloatingWindow sharedInstance].hidden && !inRTCRoom) {
        [[PLVECFloatingWindow sharedInstance] showContentView:self.playerVC.view size:self.playerVC.displayView.frame.size];
    }
}

- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView inLinkMicChanged:(BOOL)inLinkMic {
    [self.homePageView updateLinkMicState:inLinkMic];
    if (inLinkMic && [PLVECUtils sharedUtils].isLandscape) {
        [PLVFdUtil changeDeviceOrientationToPortrait];
        [[PLVECUtils sharedUtils] setupDeviceOrientation:UIDeviceOrientationPortrait];
        [PLVECUtils showHUDWithTitle:nil detail:PLVLocalizedString(@"连麦成功，已为你切换到竖屏模式") view:self.view afterDelay:3.0];
    }
}

- (BOOL)plvECLinkMicAreaViewGetChannelInLive:(PLVECLinkMicAreaView *)linkMicAreaView {
    return self.playerVC.channelInLive && !self.playerVC.advertPlaying;
}

- (void)plvECLinkMicAreaViewCurrentFirstSiteCanvasViewChanged:(PLVECLinkMicAreaView *)linkMicAreaView {
    if (self.linkMicAreaView.inLinkMic && ![PLVECFloatingWindow sharedInstance].hidden) {
        [[PLVECFloatingWindow sharedInstance] showContentView:self.linkMicAreaView.firstSiteCanvasView];
    }
}

#pragma mark PLVECHomePageView Delegate

- (BOOL)homePageView_inLinkMic:(PLVECHomePageView *)homePageView {
    return self.linkMicAreaView.inLinkMic;
}

- (NSTimeInterval)homePageView_playbackMaxPosition:(PLVECHomePageView *)homePageView {
    return self.playerVC.playbackMaxPosition;
}

- (void)homePageView:(PLVECHomePageView *)homePageView switchPlayLine:(NSUInteger)line {
    [self.playerVC switchPlayLine:line showHud:NO];
}

- (void)homePageView:(PLVECHomePageView *)homePageView switchCodeRate:(NSString *)codeRate {
    [self.playerVC switchPlayCodeRate:codeRate showHud:NO];
}

- (void)homePageView:(PLVECHomePageView *)homePageView switchAudioMode:(BOOL)audioMode {
    [self.playerVC switchAudioMode:audioMode];
}

- (void)homePageView:(PLVECHomePageView *)homePageView receiveBulletinMessage:(NSString * _Nullable)content open:(BOOL)open {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (open) {
            [self.liveDetailPageView addBulletinCardView:content];
        } else {
            [self.liveDetailPageView removeBulletinCardView];
        }
    });
}

- (void)homePageView:(PLVECHomePageView *)homePageView openCommodityDetail:(NSURL *)commodityURL {
    [self openCommodityDetailViewControllerWithURL:commodityURL];
}

- (void)homePageView:(PLVECHomePageView *)homePageView switchPause:(BOOL)pause {
    /// 播放广告中点击暂停按钮跳转页面
    NSString *advertHref = [PLVRoomDataManager sharedManager].roomData.channelInfo.advertHref;
    if (self.playerVC.advertPlaying && [PLVFdUtil checkStringUseable:advertHref]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:advertHref]];
        [self.homePageView updatePlayerState:NO];
        return;
    }
    
    if (pause) {
        [self.playerVC pause];
    } else {
        [self.playerVC play];
    }
}

- (void)homePageView:(PLVECHomePageView *)homePageView seekToTime:(NSTimeInterval)time {
    [self.playerVC seek:time];
}

- (void)homePageView:(PLVECHomePageView *)homePageView switchSpeed:(CGFloat)speed {
    [self.playerVC speedRate:speed];
}

- (void)homePageView:(PLVECHomePageView *)homePageView switchToNoDelayWatchMode:(BOOL)noDelayWatchMode {
    if ([PLVRoomDataManager sharedManager].roomData.menuInfo.watchNoDelay) {
        [self.linkMicAreaView startWatchNoDelay:noDelayWatchMode];
        if (noDelayWatchMode) {
            [self.linkMicAreaView pauseWatchNoDelay:NO];
        }
    }
    [self.playerVC switchToNoDelayWatchMode:noDelayWatchMode];
}

- (void)homePageView_didLoginRestrict {
    __weak typeof(self) weakSelf = self;
    plv_dispatch_main_async_safe(^{
        [PLVECUtils showHUDWithTitle:nil detail:PLVLocalizedString(@"直播间太过火爆了，请稍后再来(2050407)") view:self.view afterDelay:3.0];
    })
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf exitCurrentController]; // 使用weakSelf，不影响self释放内存
    });
}

- (void)homePageViewOpenRewardView:(PLVECHomePageView *)homePageView {
    [self.popoverView showRewardView];
}

- (void)homePageView:(PLVECHomePageView *)homePageView openCardPush:(NSDictionary *)cardInfo {
    [self.popoverView.interactView openNewPushCardWithDict:cardInfo];
}

- (void)homePageViewClickPictureInPicture:(PLVECHomePageView *)homePageView {
    if (self.linkMicAreaView.inLinkMic) {
        return;
    }
    if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
        [self.playerVC stopPictureInPicture];
    }else {
        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud.label setText:PLVLocalizedString(@"正在开启小窗...")];
        [hud hideAnimated:YES afterDelay:3.0];
        [self.playerVC startPictureInPicture];
    }
}

- (void)homePageView:(PLVECHomePageView *)homePageView switchLanguageMode:(NSInteger)languageMode {
    [PLVFdUtil showAlertWithTitle:nil message:PLVLocalizedString(@"PLVAlertSwitchLanguageTips") viewController:[PLVFdUtil getCurrentViewController] cancelActionTitle:PLVLocalizedString(@"取消") cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"PLVAlertConfirmTitle") confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:^(UIAlertAction * _Nonnull action) {
        [[PLVMultiLanguageManager sharedManager] updateLanguage:MAX(MIN(languageMode, PLVMultiLanguageModeEN), PLVMultiLanguageModeSyetem)];
    }];
}

- (void)homePageViewWannaBackToVerticalScreen:(PLVECHomePageView *)homePageView {
    if (self.view.bounds.size.width > self.view.bounds.size.height) {
        [PLVFdUtil changeDeviceOrientationToPortrait];
        [[PLVECUtils sharedUtils] setupDeviceOrientation:UIDeviceOrientationPortrait];
    }
}

- (void)plvCommodityDetailViewControllerAfterTheBack {
    if (![PLVECFloatingWindow sharedInstance].hidden) {
        [[PLVECFloatingWindow sharedInstance] close]; // 关闭悬浮窗
    }
}

- (void)homePageView_loadRewardEnable:(BOOL)rewardEnable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray *_Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit {
    [self.popoverView setRewardViewData:payWay rewardModelArray:modelArray pointUnit:pointUnit];
}

- (void)homePageView_alertLongContentMessage:(PLVChatModel *)model {
    NSString *content = [model isOverLenMsg] ? model.overLenContent : model.content;
    if (content) {
        PLVECMessagePopupView *popupView = [[PLVECMessagePopupView alloc] initWithChatModel:model];
        popupView.delegate = self;
        [popupView showOnView:self.popoverView];
    }
}

- (void)homePageView_openInteractApp:(PLVECHomePageView *)homePageView eventName:(NSString *)eventName {
    if ([PLVFdUtil checkStringUseable:eventName]) {
        [self.popoverView.interactView openInteractAppWithEventName:eventName];
    }
}

- (void)homePageView_checkRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model {
    // 若红包已过期或领完，打开后h5的UI会给予提示
    [self.popoverView.interactView openRedpackWithChatModel:model];
}

- (void)homePageView:(PLVECHomePageView *)homePageView emitInteractEvent:(NSString *)event {
    [self.popoverView.interactView openInteractAppWithEventName:event];
}

#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect linkMicWindowFrame = self.linkMicAreaView.frame;
    linkMicWindowFrame.origin.x = scrollView.contentOffset.x;
    self.linkMicAreaView.frame = linkMicWindowFrame;
    
    CGRect playerVCFrame = self.playerVC.view.frame;
    playerVCFrame.origin.x = scrollView.contentOffset.x;
    self.playerVC.view.frame = playerVCFrame;
    
    CGRect marqueeViewFrame = self.playerVC.marqueeView.frame;
    marqueeViewFrame.origin.x = scrollView.contentOffset.x;
    self.playerVC.marqueeView.frame = marqueeViewFrame;
    
    if (scrollView.contentOffset.x == scrollView.frame.size.width) {
        [self.homePageView showInScreen:YES];
        [self.playerVC fullScreenButtonShowInView:YES];
    } else {
        [self.homePageView showInScreen:NO];
        [self.playerVC fullScreenButtonShowInView:NO];
    }
}

#pragma mark  PLVPopoverViewDelegate

- (void)popoverViewDidDonatePointWithError:(NSString *)error {
    plv_dispatch_main_async_safe(^{
        [PLVECUtils showHUDWithTitle:error detail:@"" view:self.view];
    })
}

#pragma mark PLVInteractGenericViewDelegate

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView loadWebViewURL:(NSURL *)url insideLoad:(BOOL)insideLoad {
    if (insideLoad) {
        [self.cardDetailView loadWebviewWithCardURL:url];
        [self.cardDetailView showOnView:self.view frame:CGRectMake(0, CGRectGetHeight(self.view.bounds) * 0.3, self.view.bounds.size.width, self.view.bounds.size.height * 0.7)];
    } else {
        [self openCommodityDetailViewControllerWithURL:url];
    }
}

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView
                didOpenRedpack:(NSString *)redpackId
                        status:(NSString *)status {
    [[PLVECChatroomViewModel sharedViewModel] changeRedpackStateWithRedpackId:redpackId state:status];
}

- (void)plvInteractGenericView:(PLVInteractGenericView *)interactView updateLotteryWidget:(NSDictionary *)dict {
    NSArray *dataArray = PLV_SafeArraryForDictKey(dict, @"dataArray");
    [self.homePageView updateLotteryWidgetViewInfo:dataArray];
}

#pragma mark PLVLCMessagePopupViewDelegate

- (void)messagePopupViewWillCopy:(PLVECMessagePopupView *)popupView {
    [UIPasteboard generalPasteboard].string = popupView.content;
    [PLVToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.view afterDelay:3.0];
}

@end
