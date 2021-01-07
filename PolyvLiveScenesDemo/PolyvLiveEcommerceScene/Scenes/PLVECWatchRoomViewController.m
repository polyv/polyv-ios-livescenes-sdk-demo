//
//  PLVECWatchRoomViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/12/1.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECWatchRoomViewController.h"

// 模块
#import "PLVRoomDataManager.h"
#import "PLVECPlayerViewController.h"
#import "PLVECGoodsDetailViewController.h"
#import "PLVECBaseNavigationController.h"
#import "PLVECFloatingWindow.h"

// UI
#import "PLVECLiveHomePageView.h"
#import "PLVECLiveDetailPageView.h"
#import "PLVECPalybackHomePageView.h"

// 工具
#import "PLVECUtils.h"

// 依赖库
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVECWatchRoomViewController ()<
PLVSocketManagerProtocol,
PLVECLiveHomePageViewDelegate,
PLVPalybackHomePageViewDelegate,
PLVECFloatingWindowProtocol,
PLVECPlayerViewControllerProtocol,
PLVRoomDataManagerProtocol,
UIGestureRecognizerDelegate
>

#pragma mark 数据

#pragma mark 模块
@property (nonatomic, strong) PLVECPlayerViewController * playerVC; // 播放控制器
@property (nonatomic, strong) PLVECGoodsDetailViewController *goodsDetailVC; // 商品详情页控制器

#pragma mark UI
@property (nonatomic, strong) UIScrollView * scrollView;
@property (nonatomic, strong) PLVECLiveHomePageView * liveHomePageView;
@property (nonatomic, strong) PLVECLiveDetailPageView * liveDetailPageView;
@property (nonatomic, strong) PLVECPalybackHomePageView * livePlaybackHomePageView;
@property (nonatomic, strong) UIButton * closeButton;

@end

@implementation PLVECWatchRoomViewController

#pragma mark - [ Life Period ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        PLVRoomUser *roomUser = roomData.roomUser;
        
        /// Socket 登录管理
        PLVSocketUserType userType = roomUser.viewerType == PLVRoomUserTypeStudent ? PLVSocketUserTypeStudent : PLVSocketUserTypeSlice;
        [PLVSocketManager sharedManager].allowChildRoom = YES;
        [[PLVSocketManager sharedManager] loginWithChannelId:roomData.channelId viewerId:roomUser.viewerId viewerName:roomUser.viewerName avatarUrl:roomUser.viewerAvatar actor:nil userType:userType];
        
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
- (void)setupUI{
    /// 注意：1. 此处不建议将共同拥有的图层，提炼在 if 判断外，来做“代码简化”
    ///         因为此处涉及到添加顺序，而影响图层顺序。放置在 if 内，能更加准确地配置图层顺序，也更清晰地预览图层顺序。
    ///      2. 懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 创建添加视图
        [self.view addSubview:self.scrollView];
        [self.scrollView addSubview:self.liveHomePageView];
        [self.scrollView addSubview:self.liveDetailPageView];
        [self.view addSubview:self.closeButton];
        
        /// 布局视图 [单次]
        CGRect scrollViewFrame = CGRectMake(0, P_SafeAreaTopEdgeInsets(), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - P_SafeAreaTopEdgeInsets());
        self.scrollView.frame = scrollViewFrame;
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame) * 3, CGRectGetHeight(scrollViewFrame));
        
        self.liveHomePageView.frame = CGRectMake(CGRectGetWidth(scrollViewFrame), 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        
        self.liveDetailPageView.frame = CGRectMake(0, 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(scrollViewFrame), 0);
    } else if (roomData.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
        /// 创建添加视图
        [self.view addSubview:self.scrollView];
        [self.scrollView addSubview:self.livePlaybackHomePageView];
        [self.scrollView addSubview:self.liveDetailPageView];
        [self.view addSubview:self.closeButton];
        
        /// 布局视图 [单次]
        CGRect scrollViewFrame = CGRectMake(0, P_SafeAreaTopEdgeInsets(), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - P_SafeAreaTopEdgeInsets());
        self.scrollView.frame = scrollViewFrame;
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame) * 3, CGRectGetHeight(scrollViewFrame));
        
        self.livePlaybackHomePageView.frame = CGRectMake(CGRectGetWidth(scrollViewFrame), 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        
        self.liveDetailPageView.frame = CGRectMake(0, 0, CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame));
        self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(scrollViewFrame), 0);
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
    [[PLVSocketManager sharedManager] logout];
    [self.liveHomePageView destroy];
    [self.livePlaybackHomePageView destroy];

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

- (PLVECLiveHomePageView *)liveHomePageView{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (!_liveHomePageView && roomData.videoType == PLVChannelVideoType_Live) {
        _liveHomePageView = [[PLVECLiveHomePageView alloc] initWithDelegate:self];
    }
    return _liveHomePageView;
}

- (PLVECLiveDetailPageView *)liveDetailPageView{
    if (!_liveDetailPageView) {
        _liveDetailPageView = [[PLVECLiveDetailPageView alloc] init];
    }
    return _liveDetailPageView;
}

- (PLVECPalybackHomePageView *)livePlaybackHomePageView{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (!_livePlaybackHomePageView && roomData.videoType == PLVChannelVideoType_Playback) {
        _livePlaybackHomePageView = [[PLVECPalybackHomePageView alloc] initWithDelegate:self];
    }
    return _livePlaybackHomePageView;
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

#pragma mark - [ Delegate ]
#pragma mark PLVRoomDataManagerProtocol

- (void)roomDataManager_didOnlineCountChanged:(NSUInteger)onlineCount {
    [self.liveHomePageView updateOnlineCount:onlineCount];
    [self.livePlaybackHomePageView updateWatchViewCount:onlineCount];
}

- (void)roomDataManager_didLikeCountChanged:(NSUInteger)likeCount {
    [self.liveHomePageView updateLikeCount:likeCount];
}

- (void)roomDataManager_didPlayingStatusChanged:(BOOL)playing {
    [self.livePlaybackHomePageView updatePlayButtonState:playing];
}

- (void)roomDataManager_didMenuInfoChanged:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    for (PLVLiveVideoChannelMenu *menu in menuInfo.channelMenus) {
        if ([menu.menuType isEqualToString:@"desc"]) {
            [self.liveDetailPageView addLiveInfoCardView:menu.content];
        } else if ([menu.menuType isEqualToString:@"buy"] && roomData.videoType == PLVChannelVideoType_Live) {
            self.liveHomePageView.shoppingCardButton.hidden = NO;
        }
    }
    
    if (roomData.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        [self.liveHomePageView updateChannelInfo:roomData.menuInfo.publisher coverImage:roomData.menuInfo.coverImage];
    } else if (roomData.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
        [self.livePlaybackHomePageView updateChannelInfo:roomData.menuInfo.publisher coverImage:roomData.menuInfo.coverImage];
    }
}

- (void)roomDataManager_didLiveStateChanged:(PLVChannelLiveStreamState)liveState {
    [self.liveHomePageView updatePlayerState:liveState == PLVChannelLiveStreamState_Live];
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
    [self.liveHomePageView updateCodeRateItems:codeRateItems defaultCodeRate:codeRate];
    [self.liveHomePageView updateLineCount:lines defaultLine:line];
}

- (void)updateDowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration {
    [self.livePlaybackHomePageView updateDowloadProgress:dowloadProgress playedProgress:playedProgress currentPlaybackTime:currentPlaybackTime duration:duration];
}

#pragma mark PLVECLiveHomePageView Delegate

- (void)homePageView:(PLVECLiveHomePageView *)homePageView switchPlayLine:(NSUInteger)line {
    [self.playerVC switchPlayLine:line showHud:NO];
}

- (void)homePageView:(PLVECLiveHomePageView *)homePageView switchCodeRate:(NSString *)codeRate {
    [self.playerVC switchPlayCodeRate:codeRate showHud:NO];
}

- (void)homePageView:(PLVECLiveHomePageView *)homePageView switchAudioMode:(BOOL)audioMode {
    [self.playerVC switchAudioMode:audioMode];
}

- (BOOL)playerIsPlaying {
    return self.playerVC.playing;
}

- (void)homePageView:(PLVECLiveHomePageView *)homePageView receiveBulletinMessage:(NSString *)content open:(BOOL)open {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (open) {
            [self.liveDetailPageView addBulletinCardView:content];
        } else {
            [self.liveDetailPageView removeBulletinCardView];
        }
    });
}

- (void)homePageView:(PLVECLiveHomePageView *)homePageView openGoodsDetail:(NSURL *)goodsURL {
    NSLog(@"商品详情 %@", goodsURL);
    
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
        PLVECBaseNavigationController *nav = [[PLVECBaseNavigationController alloc] initWithRootViewController:self.goodsDetailVC];
        nav.navigationBarHidden = NO;
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark PLVPalybackHomePageViewDelegate
- (void)homePageView:(PLVECPalybackHomePageView *)homePageView switchPause:(BOOL)pause {
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

- (void)homePageView:(PLVECPalybackHomePageView *)homePageView seekToTime:(NSTimeInterval)time {
    [self.playerVC seek:time];
}

- (void)homePageView:(PLVECPalybackHomePageView *)homePageView switchSpeed:(CGFloat)speed {
    [self.playerVC speedRate:speed];
}

- (void)palyback_homePageView:(PLVECPalybackHomePageView *)homePageView receiveBulletinMessage:(NSString *)content open:(BOOL)open {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (open) {
            [self.liveDetailPageView addBulletinCardView:content];
        } else {
            [self.liveDetailPageView removeBulletinCardView];
        }
    });
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
