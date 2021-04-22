//
//  PLVECWatchRoomViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/12/1.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECWatchRoomViewController.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVECPlayerViewController.h"
#import "PLVECGoodsDetailViewController.h"
#import "PLVBaseNavigationController.h"
#import "PLVECFloatingWindow.h"
#import "PLVInteractView.h"

// UI
#import "PLVECHomePageView.h"
#import "PLVECLiveDetailPageView.h"

// 工具
#import "PLVECUtils.h"

// 依赖库
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NSString *PLVLEChatroomOpenBulletinNotification = @"PLVLCChatroomOpenBulletinNotification";

@interface PLVECWatchRoomViewController ()<
PLVSocketManagerProtocol,
PLVECHomePageViewDelegate,
PLVECFloatingWindowProtocol,
PLVECPlayerViewControllerProtocol,
PLVRoomDataManagerProtocol,
UIGestureRecognizerDelegate
>

#pragma mark 数据

#pragma mark 模块
@property (nonatomic, strong) PLVECPlayerViewController * playerVC; // 播放控制器
@property (nonatomic, strong) PLVECGoodsDetailViewController *goodsDetailVC; // 商品详情页控制器
@property (nonatomic, strong) PLVInteractView *interactView; // 互动

#pragma mark UI
@property (nonatomic, strong) UIScrollView * scrollView;
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
    
    // 单击、双击手势控制播放器和UI
    UITapGestureRecognizer *doubleGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    doubleGestureRecognizer.numberOfTapsRequired = 2;
    doubleGestureRecognizer.numberOfTouchesRequired = 1;
    doubleGestureRecognizer.delegate = self;
    [doubleGestureRecognizer addTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:doubleGestureRecognizer];
    
    UITapGestureRecognizer *singleGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    singleGestureRecognizer.numberOfTapsRequired = 1;
    singleGestureRecognizer.numberOfTouchesRequired = 1;
    singleGestureRecognizer.delegate = self;
    [singleGestureRecognizer addTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:singleGestureRecognizer];
    
    [singleGestureRecognizer requireGestureRecognizerToFail:doubleGestureRecognizer];
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
        self.playerVC.view.frame = self.view.bounds;// 重新布局
        [self.view insertSubview:self.playerVC.view atIndex:0];
        
        [self.playerVC cancelMute];
    } else {
        self.playerVC.view.frame = self.view.bounds;// 重新布局
        [self.view insertSubview:self.playerVC.view atIndex:0];
        
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
        self.playerVC.view.frame = self.view.bounds;
        self.playerVC.delegate = self;
        [self.view insertSubview:self.playerVC.view atIndex:0];
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
- (UIScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.pagingEnabled = YES;
        _scrollView.backgroundColor = UIColor.clearColor;
        _scrollView.bounces = NO;
        _scrollView.alwaysBounceVertical = NO;
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
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

- (PLVInteractView *)interactView{
    PLVChannelVideoType videoType = [PLVRoomDataManager sharedManager].roomData.videoType;
    if (!_interactView && videoType == PLVChannelVideoType_Live) {
        _interactView = [[PLVInteractView alloc] init];
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


#pragma mark - [ Event ]
#pragma mark Action
- (void)closeButtonAction:(UIButton *)button {
    [self exitCurrentController];
}

- (void)tapAction:(UITapGestureRecognizer *)gestureRecognizer {
    /** 播放广告中，点击屏幕跳转广告链接 */
    if (self.playerVC.advPlaying) {
        if ([PLVFdUtil checkStringUseable:self.playerVC.advLinkUrl]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.playerVC.advLinkUrl]];
        }
        return;
    }
    
    if (gestureRecognizer.numberOfTapsRequired == 1) {
        if (! self.playerVC.playing) {
            [self.playerVC play];
        }
    } else if (gestureRecognizer.numberOfTapsRequired == 2) {
        if (self.playerVC.playing) {
            [self.playerVC pause];
        } else {
            [self.playerVC play];
        }
    }
}

#pragma mark Notification
- (void)notificationForOpenBulletin:(NSNotification *)notif {
    [self.interactView openLastBulletin];
}

#pragma mark - [ Delegate ]
#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didOnlineCountChanged:(NSUInteger)onlineCount {
    [self.homePageView updateRoomInfoCount:onlineCount];
}

- (void)roomDataManager_didLikeCountChanged:(NSUInteger)likeCount {
    [self.homePageView updateLikeCount:likeCount];
}

- (void)roomDataManager_didPlayingStatusChanged:(BOOL)playing {
    [self.homePageView updatePlayerState:playing];
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
    if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin ||
        error.code == PLVSocketLoginErrorCodeKick) &&
        error.localizedDescription) {
        __weak typeof(self) weakSelf = self;
        [PLVFdUtil showAlertWithTitle:nil message:error.localizedDescription viewController:self cancelActionTitle:@"确定" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:^(UIAlertAction * _Nonnull action) {
            [weakSelf exitCurrentController];
        } confirmActionTitle:nil confirmActionStyle:UIAlertActionStyleDefault confirmActionBlock:nil];
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

- (void)playerController:(PLVECPlayerViewController *)playerController
           codeRateItems:(NSArray <NSString *>*)codeRateItems
                codeRate:(NSString *)codeRate
                   lines:(NSUInteger)lines
                    line:(NSInteger)line {
    [self.homePageView updateCodeRateItems:codeRateItems defaultCodeRate:codeRate];
    [self.homePageView updateLineCount:lines defaultLine:line];
}

- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime {
    [self.homePageView updateDowloadProgress:dowloadProgress playedProgress:playedProgress duration:duration currentPlaybackTime:currentPlaybackTime durationTime:durationTime];
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
    /** 播放广告中，点击屏幕跳转广告链接 */
    if (self.playerVC.advPlaying) {
        if ([PLVFdUtil checkStringUseable:self.playerVC.advLinkUrl]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.playerVC.advLinkUrl]];
        }
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

#pragma mark - UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if([touch.view isKindOfClass:UIButton.class] ||
       [touch.view isKindOfClass:UITableView.class] ||
       [touch.view isKindOfClass:UIVisualEffectView.class]) {
        return NO;
    }
    return YES;
}

@end
