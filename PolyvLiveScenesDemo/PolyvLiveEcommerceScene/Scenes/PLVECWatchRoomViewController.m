//
//  PLVECWatchRoomViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/12/1.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECWatchRoomViewController.h"

// 模块
#import "PLVLiveRoomManager.h"
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
PLVECLiveHomePageViewDelegate,
PLVPalybackHomePageViewDelegate,
PLVECFloatingWindowProtocol,
PLVECPlayerViewControllerProtocol
>

#pragma mark 数据
@property (nonatomic, strong) PLVLiveRoomData * watchRoomData; // 观看间数据

#pragma mark 模块
@property (nonatomic, strong) PLVLiveRoomManager * watchRoomManager; // 观看间数据管理器
@property (nonatomic, strong) PLVECPlayerViewController * playerVC; // 播放控制器
@property (nonatomic, strong) PLVECGoodsDetailViewController *goodsDetailVC; // 商品详情页控制器

#pragma mark UI
@property (nonatomic, strong) UIScrollView * scrollView;
@property (nonatomic, strong) PLVECLiveHomePageView * liveHomePageView;
@property (nonatomic, strong) PLVECLiveDetailPageView * liveDetailPageView;
@property (nonatomic, strong) PLVECPalybackHomePageView * livePlaybackHomePageView;
@property (nonatomic, strong) UIButton * closeButton;
@property (nonatomic, weak) PLVPlayerController *player;

@end

@implementation PLVECWatchRoomViewController

#pragma mark - [ Life Period ]
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
    
    if (![PLVECFloatingWindow sharedInstance].hidden) {
        [[PLVECFloatingWindow sharedInstance] close]; // 关闭悬浮窗
    }
    
    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为直播
        self.playerVC.view.frame = self.view.bounds;// 重新布局
        [self.view insertSubview:self.playerVC.view atIndex:0];
        
        PLVLivePlayerController *livePlayer = (PLVLivePlayerController *)self.player;
        [livePlayer cancelMute];
    } else {
        self.playerVC.view.frame = self.view.bounds;// 重新布局
        [self.view insertSubview:self.playerVC.view atIndex:0];
        
        PLVVodPlayerController *playbackPlayer = (PLVVodPlayerController *)self.player;
        [playbackPlayer cancelMute];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([PLVECFloatingWindow sharedInstance].hidden) {
        if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为直播
            PLVLivePlayerController *livePlayer = (PLVLivePlayerController *)self.player;
            [livePlayer mute];
        } else {
            PLVVodPlayerController *playbackPlayer = (PLVVodPlayerController *)self.player;
            [playbackPlayer mute];
        }
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


#pragma mark - [ Public Methods ]
- (instancetype)initWithLiveRoomData:(PLVLiveRoomData *)roomData {
    if (self = [super init]) {
        self.watchRoomData = roomData;
    }
    return self;
}


#pragma mark - [ Private Methods ]
- (void)setupUI{
    /// 注意：1. 此处不建议将共同拥有的图层，提炼在 if 判断外，来做“代码简化”
    ///         因为此处涉及到添加顺序，而影响图层顺序。放置在 if 内，能更加准确地配置图层顺序，也更清晰地预览图层顺序。
    ///      2. 懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil
    
    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
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
    }else if (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
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
    if (!self.watchRoomData) {
        NSLog(@"%@ 初始化失败！请调用 -initWithChannel:roomData: API 初始化",NSStringFromClass(self.class));
        return;
    }
    
    /// 观看间数据管理器
    self.watchRoomManager = [[PLVLiveRoomManager alloc] initWithRoomData:self.watchRoomData];
    [self.watchRoomManager requestLiveDetail]; // 获取直播详情数据
    [self.watchRoomManager requestPageview];   // 上报观看热度
    
    /// 监听房间数据
    [self observeRoomData];
    
    /// 注意：懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil
    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live ||
        self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback) {
        self.playerVC = [[PLVECPlayerViewController alloc] initWithRoomData:self.watchRoomData];
        self.playerVC.view.frame = self.view.bounds;
        self.playerVC.delegate = self;
        [self.view insertSubview:self.playerVC.view atIndex:0];
    }
    
    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
        self.player = self.playerVC.livePresenter.player; // PLVLivePlayerController
    }else if (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
        self.player = self.playerVC.playbackPresenter.player; // PLVVodPlayerController
    }
}

- (void)observeRoomData {
    PLVLiveRoomData *roomData = self.watchRoomData;
    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNEL options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_ONLINECOUNT options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_LIKECOUNT options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_LIVESTATE options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }else if (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_ONLINECOUNT options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNEL options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_VIEWCOUNT options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_DURATION options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_PLAYING options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveRoomData {
    PLVLiveRoomData *roomData = self.watchRoomData;
    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNEL];
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_ONLINECOUNT];
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_LIKECOUNT];
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_LIVESTATE];
    }else if (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_ONLINECOUNT];
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNEL];
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_VIEWCOUNT];
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_DURATION];
        [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_PLAYING];
    }
}

- (void)exitCurrentController {
    [self removeObserveRoomData];
    [self.liveHomePageView destroy];
    [self.playerVC destroy];

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
    if (!_liveHomePageView && self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) {
        _liveHomePageView = [[PLVECLiveHomePageView alloc] initWithDelegate:self roomData:self.watchRoomData];
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
    if (!_livePlaybackHomePageView && self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback) {
        _livePlaybackHomePageView = [[PLVECPalybackHomePageView alloc] initWithDelegate:self roomData:self.watchRoomData];
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

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (![object isKindOfClass:PLVLiveRoomData.class]) {
        return;
    }
    
    PLVLiveRoomData *roomData = object;
    if ([keyPath isEqualToString:KEYPATH_LIVEROOM_CHANNEL]) { // 频道信息
        if (!roomData.channelMenuInfo)
            return;
        
        for (PLVLiveVideoChannelMenu *menu in roomData.channelMenuInfo.channelMenus) {
            if ([menu.menuType isEqualToString:@"desc"]) {
                [self.liveDetailPageView addLiveInfoCardView:menu.content];
            } else if ([menu.menuType isEqualToString:@"buy"] && self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) {
                self.liveHomePageView.shoppingCardButton.hidden = NO;
            }
        }
        
        if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
            [self.liveHomePageView updateChannelInfo:roomData.channelMenuInfo.publisher coverImage:roomData.channelMenuInfo.coverImage];
        } else if (self.watchRoomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
            [self.livePlaybackHomePageView updateChannelInfo:roomData.channelMenuInfo.publisher coverImage:roomData.channelMenuInfo.coverImage];
        }
    } else if ([keyPath isEqualToString:KEYPATH_LIVEROOM_ONLINECOUNT]) { // 观看热度
        [self.liveHomePageView updateOnlineCount:roomData.onlineCount];
        [self.livePlaybackHomePageView updateWatchViewCount:roomData.onlineCount];
    } else if ([keyPath isEqualToString:KEYPATH_LIVEROOM_LIKECOUNT]) { // 点赞数
        [self.liveHomePageView updateLikeCount:roomData.likeCount];
    } else if ([keyPath isEqualToString:KEYPATH_LIVEROOM_LIVESTATE]) { // 直播状态
        [self.liveHomePageView updatePlayerState:roomData.liveState == PLVLiveStreamStateLive];
    } else if ([keyPath isEqualToString:KEYPATH_LIVEROOM_VIEWCOUNT]) {
//        [self.livePlaybackHomePageView updateWatchViewCount:roomData.watchViewCount];
    } else if ([keyPath isEqualToString:KEYPATH_LIVEROOM_DURATION]) {
        [self.livePlaybackHomePageView updateVideoDuration:roomData.duration];
    } else if ([keyPath isEqualToString:KEYPATH_LIVEROOM_PLAYING]) {
        [self.livePlaybackHomePageView updatePlayButtonState:roomData.playing];
    }
}


#pragma mark - [ Delegate ]
#pragma mark PLVECFloatingWindowProtocol

- (void)floatingWindow_closeWindowAndBack:(BOOL)back {
    if (back) {
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self.goodsDetailVC dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为直播
            PLVLivePlayerController *livePlayer = (PLVLivePlayerController *)self.player;
            [livePlayer mute];
        } else {
            PLVVodPlayerController *playbackPlayer = (PLVVodPlayerController *)self.player;
            [playbackPlayer mute];
        }
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

- (void)presenter:(PLVPlaybackPlayerPresenter *)presenter mainPlayerPlaybackDidFinish:(NSDictionary *)dataInfo {
    // 播放完成
    [self updateDowloadProgress:0 playedProgress:1
            currentPlaybackTime:[PLVFdUtil secondsToString:self.watchRoomData.duration]
                       duration:[PLVFdUtil secondsToString:self.watchRoomData.duration]];
}

#pragma mark PLVECLiveHomePageView Delegate

- (void)homePageView:(PLVECLiveHomePageView *)homePageView authorizationVerificationFailed:(PLVLiveRoomErrorReason)reason message:(NSString *)message {
    __weak typeof(self) weakSelf = self;
    [PLVFdUtil showAlertWithTitle:nil message:message viewController:self cancelActionTitle:@"确定" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:^(UIAlertAction * _Nonnull action) {
        [weakSelf exitCurrentController];
    } confirmActionTitle:nil confirmActionStyle:UIAlertActionStyleDefault confirmActionBlock:nil];
}

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
    return self.watchRoomData.liveState == PLVLiveStreamStateLive;
}

- (void)homePageView:(PLVECLiveHomePageView *)homePageView receiveBulletinMessage:(NSString *)content open:(BOOL)open {
    if (open) {
        [self.liveDetailPageView addBulletinCardView:content];
    } else {
        [self.liveDetailPageView removeBulletinCardView];
    }
}

- (void)homePageView:(PLVECLiveHomePageView *)homePageView openGoodsDetail:(NSURL *)goodsURL {
    NSLog(@"商品详情 %@", goodsURL);
    
    if (self.watchRoomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为直播
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
    if (open) {
        [self.liveDetailPageView addBulletinCardView:content];
    } else {
        [self.liveDetailPageView removeBulletinCardView];
    }
}

@end
