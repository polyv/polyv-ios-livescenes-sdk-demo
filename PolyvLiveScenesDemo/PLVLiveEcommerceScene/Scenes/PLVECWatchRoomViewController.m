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
#import "PLVECGoodsDetailViewController.h"
#import "PLVBaseNavigationController.h"
#import "PLVECFloatingWindow.h"
#import "PLVInteractGenericView.h"
#import "PLVECLinkMicAreaView.h"

// UI
#import "PLVECHomePageView.h"
#import "PLVECLiveDetailPageView.h"
#import "PLVECWatchRoomScrollView.h"

// 工具
#import "PLVECUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NSString *PLVLEChatroomOpenBulletinNotification = @"PLVLCChatroomOpenBulletinNotification";

@interface PLVECWatchRoomViewController ()<
PLVSocketManagerProtocol,
PLVECHomePageViewDelegate,
PLVECFloatingWindowProtocol,
PLVECPlayerViewControllerProtocol,
PLVRoomDataManagerProtocol,
UIScrollViewDelegate,
PLVECLinkMicAreaViewDelegate
>

#pragma mark 数据
@property (nonatomic, assign) BOOL socketReconnecting; // socket是否重连中

#pragma mark 模块
@property (nonatomic, strong) PLVECPlayerViewController * playerVC; // 播放控制器
@property (nonatomic, strong) PLVECGoodsDetailViewController *goodsDetailVC; // 商品详情页控制器
@property (nonatomic, strong) PLVInteractGenericView *interactView; // 互动
@property (nonatomic, strong) PLVECLinkMicAreaView *linkMicAreaView; //连麦

#pragma mark UI
@property (nonatomic, strong) PLVECWatchRoomScrollView * scrollView;
@property (nonatomic, strong) PLVECHomePageView *homePageView;
@property (nonatomic, strong) PLVECLiveDetailPageView * liveDetailPageView;
@property (nonatomic, strong) UIButton * closeButton;

@end

@implementation PLVECWatchRoomViewController

#pragma mark - [ Life Period ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)dealloc{
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
    
    /// 布局视图 [多次]
    CGFloat closeBtn_y = 32.f;
    if (@available(iOS 11.0, *)) {
        closeBtn_y = self.view.safeAreaLayoutGuide.layoutFrame.origin.y + 12;
    }
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds)-47, closeBtn_y, 32, 32);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    if (![PLVECFloatingWindow sharedInstance].hidden) {
        [[PLVECFloatingWindow sharedInstance] close]; // 关闭悬浮窗
    }
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        self.playerVC.view.frame = self.scrollView.bounds;// 重新布局
        [self.scrollView insertSubview:self.playerVC.view atIndex:0];
        
        [self.playerVC cancelMute];
    } else {
        self.playerVC.view.frame = self.scrollView.bounds;// 重新布局
        [self.scrollView insertSubview:self.playerVC.view atIndex:0];
        
        [self.playerVC cancelMute];
    }
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
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - [ Private Methods ]
- (void)setupModule{
    // 通用的 配置
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(interfaceOrientationDidChange:)
//                                                 name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 监听事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationForOpenBulletin:) name:PLVLEChatroomOpenBulletinNotification object:nil];
        
    } else if (roomData.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
    
    }
}

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
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame) * 3, CGRectGetHeight(scrollViewFrame));
        
        self.homePageView.frame = CGRectMake(CGRectGetWidth(scrollViewFrame), 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        
        self.liveDetailPageView.frame = CGRectMake(0, 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(scrollViewFrame), 0);
        
        /// 互动
        [self.view addSubview:self.interactView];

        /// 配置
        self.interactView.frame = self.view.bounds;
        self.interactView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.interactView loadOnlineInteract];

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
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame) * 3, CGRectGetHeight(scrollViewFrame));
        
        self.homePageView.frame = CGRectMake(CGRectGetWidth(scrollViewFrame), 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        
        self.liveDetailPageView.frame = CGRectMake(0, 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(scrollViewFrame), 0);
        
        if (roomData.menuInfo) { [self roomDataManager_didMenuInfoChanged:roomData.menuInfo]; }
    }
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

- (PLVInteractGenericView *)interactView{
    PLVChannelVideoType videoType = [PLVRoomDataManager sharedManager].roomData.videoType;
    if (!_interactView && videoType == PLVChannelVideoType_Live) {
        _interactView = [[PLVInteractGenericView alloc] init];
        _interactView.frame = self.view.bounds;
        _interactView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_interactView loadOnlineInteract];
    }
    return _interactView;
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

#pragma mark - [ Event ]
#pragma mark Action
- (void)closeButtonAction:(UIButton *)button {
    [self exitCurrentController];
}

#pragma mark Notification
- (void)notificationForOpenBulletin:(NSNotification *)notif {
    [self.interactView openLastBulletin];
}

#pragma mark - [ Delegate ]
#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didChannelInfoChanged:(PLVChannelInfoModel *)channelInfo {
    [self.interactView updateUserInfo];
}

- (void)roomDataManager_didOnlineCountChanged:(NSUInteger)onlineCount {
    [self.homePageView updateRoomInfoCount:onlineCount];
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
        } else if ([menu.menuType isEqualToString:@"buy"] && roomData.videoType == PLVChannelVideoType_Live) {
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

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
//    [PLVECUtils showHUDWithTitle:@"登陆成功" detail:@"" view:self.view];
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    if (error.code == PLVSocketLoginErrorCodeKick) {
        plv_dispatch_main_async_safe(^{
            [PLVECUtils showHUDWithTitle:nil detail:@"您已被管理员踢出聊天室！" view:self.view afterDelay:3.0];
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
            [PLVECUtils showHUDWithTitle:@"聊天室重连中" detail:@"" view:self.view];
        })
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            self.socketReconnecting = NO;
            plv_dispatch_main_async_safe(^{
                [PLVECUtils showHUDWithTitle:@"聊天室重连成功" detail:@"" view:self.view];
            })
        }
    }
}

#pragma mark socket 数据解析

/// 有用户登陆
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
    NSString *string = closeRoom ? @"聊天室已经关闭" : @"聊天室已经打开";
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
    if (back) {
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self.goodsDetailVC dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        [self.playerVC mute];
    }
}

#pragma mark PLVECPlayerViewController Protocol

- (void)playerController:(PLVECPlayerViewController *)playerController codeRateItems:(NSArray<NSString *> *)codeRateItems codeRate:(NSString *)codeRate lines:(NSUInteger)lines line:(NSInteger)line noDelayWatchMode:(BOOL)noDelayWatchMode {
    [self.homePageView updateCodeRateItems:codeRateItems defaultCodeRate:codeRate];
    [self.homePageView updateLineCount:lines defaultLine:line];
    [self.homePageView updateNoDelayWatchMode:noDelayWatchMode];
}

- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime {
    [self.homePageView updateDowloadProgress:dowloadProgress playedProgress:playedProgress duration:duration currentPlaybackTime:currentPlaybackTime durationTime:durationTime];
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

#pragma mark PLVECLinkMicAreaViewDelegate

- (void)plvECLinkMicAreaView:(PLVECLinkMicAreaView *)linkMicAreaView showFirstSiteCanvasViewOnExternal:(UIView *)canvasView {
    [self.playerVC displayContentView:canvasView];
}

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
    if (inRTCRoom) {
        [self.playerVC cleanPlayer];
    }
}

#pragma mark PLVECHomePageView Delegate

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

- (void)homePageView:(PLVECHomePageView *)homePageView openGoodsDetail:(NSURL *)goodsURL {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为直播
        [[PLVECFloatingWindow sharedInstance] showContentView:self.playerVC.view]; // 打开悬浮窗
    }
    
    // 跳转商品详情页
    self.goodsDetailVC = [[PLVECGoodsDetailViewController alloc] initWithGoodsURL:goodsURL];
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController pushViewController:self.goodsDetailVC animated:YES];
    } else {
        PLVBaseNavigationController *nav = [[PLVBaseNavigationController alloc] initWithRootViewController:self.goodsDetailVC];
        nav.navigationBarHidden = NO;
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }
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
    }
    [self.playerVC switchToNoDelayWatchMode:noDelayWatchMode];
}

#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect linkMicWindowFrame = self.playerVC.view.frame;
    linkMicWindowFrame.origin.x = scrollView.contentOffset.x;
    self.playerVC.view.frame = linkMicWindowFrame;
}

@end
