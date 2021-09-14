//
//  PLVECPlayerViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/3.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECPlayerViewController.h"
#import "PLVRoomDataManager.h"
#import "PLVECPlayerBackgroundView.h"
#import "PLVECAudioAnimalView.h"
#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVProgressHUD.h>

#import "PLVPlayerPresenter.h"
#import "PLVPlayerLogoView.h"

@interface PLVECPlayerViewController ()<
PLVPlayerPresenterDelegate
>

@property (nonatomic, strong) PLVPlayerPresenter * playerPresenter; // 播放器 功能模块

#pragma mark 视图
@property (nonatomic, strong) UIImageView *backgroundView; // 全尺寸背景图
@property (nonatomic, strong) PLVECPlayerBackgroundView *playerBackgroundView; // 显示播放器（未开播时的）背景图
@property (nonatomic, strong) PLVECAudioAnimalView *audioAnimalView; // 显示音频模式背景图
@property (nonatomic, strong) UIView *displayView; // 播放器区域
@property (nonatomic, strong) UIView * logoMainView; // LOGO父视图 （用于显示 '播放器LOGO'）
@property (nonatomic, strong) UIButton * playButton; // 播放器暂停、播放按钮

#pragma mark 基本数据
@property (nonatomic, assign) CGRect displayRect; // 播放器区域rect
@property (nonatomic, assign) CGSize videoSize; // 视频源尺寸

@end

@implementation PLVECPlayerViewController

#pragma mark - Life Cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        /// 播放器
        self.playerPresenter = [[PLVPlayerPresenter alloc] initWithVideoType:[PLVRoomDataManager sharedManager].roomData.videoType];
        self.playerPresenter.openAdv = YES;
        self.playerPresenter.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.backgroundView];
    [self.view addSubview:self.playerBackgroundView];
    [self.view addSubview:self.displayView];
    [self.view addSubview:self.audioAnimalView];
    [self.view addSubview:self.playButton];
    
    [self.playerPresenter setupPlayerWithDisplayView:self.displayView];
}

- (void)viewWillLayoutSubviews {
    // 设置全尺寸背景图位置、尺寸
    self.backgroundView.frame = self.view.bounds;
    
    // 设置播放器背景图位置、尺寸
    CGSize boundsSize = self.view.bounds.size;
    CGSize playerBgSize = CGSizeMake(boundsSize.width, boundsSize.width / 16 * 9);
    self.playerBackgroundView.frame = CGRectMake(0, (boundsSize.height - playerBgSize.height) / 2.0, playerBgSize.width, playerBgSize.height);
    
    // 设置音频模式背景图位置、尺寸
    self.audioAnimalView.frame = self.playerBackgroundView.frame;
    
    // 设置播放器区域位置、尺寸
    self.displayRect = [self getDisplayViewRect];
    if (CGRectEqualToRect(self.displayRect, CGRectZero)) {
        self.displayView.frame = self.playerBackgroundView.frame;
    } else {
        self.displayView.frame = self.displayRect;
    }
    
    CGFloat margin = 15;
    CGRect logoMainViewFrame = self.view.frame;
    logoMainViewFrame.origin.x = margin;
    logoMainViewFrame.origin.y = P_SafeAreaTopEdgeInsets() + margin;
    logoMainViewFrame.size.width -= margin * 2;
    logoMainViewFrame.size.height -= margin * 2 + P_SafeAreaTopEdgeInsets() + P_SafeAreaBottomEdgeInsets();
    self.logoMainView.frame = logoMainViewFrame;
    
    self.playButton.frame = CGRectMake(0, 0, 74, 72);
    self.playButton.center = self.view.center;
}

- (CGRect)getDisplayViewRect {
    CGSize containerSize = self.view.bounds.size;
    if (self.videoSize.width == 0 || self.videoSize.height == 0 ||
        containerSize.width == 0 || containerSize.height == 0) {
        return CGRectZero;
    }
    
    if (self.videoSize.width >= self.videoSize.height) { // 视频源宽大于高时，屏幕等宽，等比缩放居中显示
        
        CGFloat width = containerSize.width;
        CGFloat height = containerSize.width / self.videoSize.width * self.videoSize.height;
        return CGRectMake(0, (containerSize.height - height) / 2.0, width, height);
        
    } else {  // 视频源高大于宽时
        CGFloat w_h = self.videoSize.width / self.videoSize.height;
        CGFloat w_h_base = containerSize.width / containerSize.height;
        CGRect displayerRect = self.view.bounds;
        if (w_h > w_h_base) { // 视频源"宽高比"比屏幕"宽高比"大时，屏幕等高等比缩放居中
            displayerRect.origin.y = 0;
            displayerRect.size.height = containerSize.height;
            displayerRect.size.width = containerSize.height * self.videoSize.width / self.videoSize.height;
            displayerRect.origin.x = (containerSize.width - displayerRect.size.width) / 2.0;
        } else if (w_h < w_h_base) { // 视频源"宽高比"比屏幕"宽高比"小时，屏幕等宽等比缩放居中
            displayerRect.origin.x = 0;
            displayerRect.size.width = containerSize.width;
            displayerRect.size.height = containerSize.width / self.videoSize.width * self.videoSize.height;
            displayerRect.origin.y = (containerSize.height - displayerRect.size.height) / 2.0;
        }
        return displayerRect;
    }
}

#pragma mark - Getter

- (UIImageView *)backgroundView {
    if (!_backgroundView) {
        UIImage *image = [PLVECUtils imageForWatchResource:@"plv_background_img"];
        _backgroundView = [[UIImageView alloc] initWithImage:image];
    }
    return _backgroundView;
}

- (PLVECPlayerBackgroundView *)playerBackgroundView {
    if (!_playerBackgroundView) {
        _playerBackgroundView = [[PLVECPlayerBackgroundView alloc] init];
        _playerBackgroundView.hidden = !([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live);
    }
    return _playerBackgroundView;
}

- (PLVECAudioAnimalView *)audioAnimalView {
    if (!_audioAnimalView) {
        _audioAnimalView = [[PLVECAudioAnimalView alloc] init];
        _audioAnimalView.hidden = YES;
    }
    return _audioAnimalView;
}

- (UIView *)displayView {
    if (!_displayView) {
        _displayView = [[UIView alloc] init];
        _displayView.backgroundColor = [UIColor blackColor];
        _displayView.hidden = !([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback);;
    }
    return _displayView;
}

- (UIView *)logoMainView {
    if (!_logoMainView) {
        _logoMainView = [[UIView alloc]init];
    }
    return _logoMainView;
}

- (UIButton *)playButton {
    if (! _playButton) {
        UIImage *imgPlay = [PLVECUtils imageForWatchResource:@"plv_player_play_big_btn"];
        
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:imgPlay forState:UIControlStateNormal];
        _playButton.userInteractionEnabled = NO;
        _playButton.hidden = YES;
    }
    return _playButton;
}

- (BOOL)advPlaying {
    return _playerPresenter.advPlaying;
}

- (NSString *)advLinkUrl {
    return _playerPresenter.advLinkUrl;
}

#pragma mark - Public

- (void)play {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.videoType == PLVChannelVideoType_Live &&
        roomData.liveState != PLVChannelLiveStreamState_Live) { // 直播时未开播，不响应播放
        return;
    }
    
    if ([self.playerPresenter resumePlay]) {
        self.playButton.hidden = YES;
    }
}

- (void)pause {
    if ([self.playerPresenter pausePlay]) {
        self.playButton.hidden = NO;
    }
}

- (void)mute{
    [self.playerPresenter mute];
}

- (void)cancelMute{
    [self.playerPresenter cancelMute];
}

#pragma mark 直播方法

- (void)reload {
    [self.playerPresenter resumePlay];
}

- (void)switchPlayLine:(NSUInteger)Line showHud:(BOOL)showHud {
    /* TODO 由Presenter处理
    PLVProgressHUD *hud = nil;
    if (showHud) {
        hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
        [hud.label setText:@"加载直播..."];
    }
    */
    [self.playerPresenter switchLiveToLineIndex:Line];
}

- (void)switchPlayCodeRate:(NSString *)codeRate showHud:(BOOL)showHud {
    [self.playerPresenter switchLiveToCodeRate:codeRate];
}

- (void)switchAudioMode:(BOOL)audioMode {
    if ([PLVRoomDataManager sharedManager].roomData.videoType != PLVChannelVideoType_Live) {
        return;
    }
    
    if (audioMode) {
        [self.audioAnimalView startAnimating];
        self.displayView.hidden = YES;
    } else {
        [self.audioAnimalView stopAnimating];
        self.displayView.hidden = NO;
    }
    self.logoMainView.hidden = self.displayView.hidden;
    [self.playerPresenter switchLiveToAudioMode:audioMode];
}

#pragma mark 回放方法

- (void)seek:(NSTimeInterval)time {
    [self.playerPresenter seekLivePlaybackToTime:time];
}

- (void)speedRate:(NSTimeInterval)speed {
    [self.playerPresenter switchLivePlaybackSpeedRate:speed];
}

#pragma mark - PLVPlayerPresenterDelegate Delegate
/// 播放器 ‘正在播放状态’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter playerPlayingStateDidChanged:(BOOL)playing{
    _playing = playing;
}

- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter loadPlayerFailureWithMessage:(NSString *)errorMessage{
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.mode = PLVProgressHUDModeText;
    [hud.label setText:@"播放器加载失败"];
    hud.detailsLabel.text = errorMessage;
    [hud hideAnimated:YES afterDelay:2];
}

- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter videoSizeChange:(CGSize)videoSize{
    self.videoSize = videoSize;
    CGSize containerSize = self.view.bounds.size;
    if (self.videoSize.width == 0 || self.videoSize.height == 0 ||
        containerSize.width == 0 || containerSize.height == 0) {
        self.displayRect = CGRectZero;
        return;
    }
    
    self.displayRect = [self getDisplayViewRect];
    self.displayView.frame = self.displayRect;
}

- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter streamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged{
    PLVChannelInfoModel *channelInfo = [PLVRoomDataManager sharedManager].roomData.channelInfo;
    if (newestStreamState == PLVChannelLiveStreamState_Unknown ||
        (newestStreamState == PLVChannelLiveStreamState_End &&
         channelInfo.warmUpType == PLVChannelWarmUpType_None)) {
        self.displayView.hidden = YES;
        self.displayRect = self.backgroundView.frame;
        self.displayView.frame = self.displayRect;
    } else {
        self.displayView.hidden = NO;
    }
    
    if (newestStreamState == PLVChannelLiveStreamState_Live) {
        // 设置logo
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        [self setupPlayerLogoImage:roomData.channelInfo];
    } else {
        
        // 设置去掉logo
        [self.logoMainView removeFromSuperview];
    }
}

/// 直播播放器 ‘码率可选项、当前码率、线路可选数、当前线路‘ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter codeRateOptions:(NSArray <NSString *> *)codeRateOptions currentCodeRate:(NSString *)currentCodeRate lineNum:(NSInteger)lineNum currentLineIndex:(NSInteger)currentLineIndex{
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerController:codeRateItems:codeRate:lines:line:)]) {
        [self.delegate playerController:self
                          codeRateItems:codeRateOptions
                               codeRate:currentCodeRate
                                  lines:lineNum
                                   line:currentLineIndex];
    }
}

- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter downloadProgress:(CGFloat)downloadProgress playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString {
    if (! self.logoMainView.superview) {
        // 设置logo
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        [self setupPlayerLogoImage:roomData.channelInfo];
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(updateDowloadProgress:playedProgress:duration:currentPlaybackTime:durationTime:)]) {
        [self.delegate updateDowloadProgress:downloadProgress playedProgress:playedProgress duration:playerPresenter.duration currentPlaybackTime:playedTimeString durationTime:durationTimeString];
    }
}

- (void)playerPresenterPlaybackInterrupted:(PLVPlayerPresenter *)playerPresenter {
    self.playButton.hidden = NO;
}

#pragma mark - 播放器LOGO
- (void)setupPlayerLogoImage:(PLVChannelInfoModel *)channel {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if ((roomData.liveState == PLVChannelLiveStreamState_Live || // 已经开播了
         roomData.videoType == PLVChannelVideoType_Playback) &&  // 是回看
         [PLVFdUtil checkStringUseable:channel.logoImageUrl]) { // 存在logo url
        
        [self.view insertSubview:self.logoMainView aboveSubview:self.displayView];
        
        PLVPlayerLogoParam *logoParam = [[PLVPlayerLogoParam alloc] init];
        logoParam.logoUrl = channel.logoImageUrl;
        logoParam.position = channel.logoPosition;
        logoParam.logoAlpha = channel.logoOpacity;
        logoParam.logoWidthScale = 100.0f / CGRectGetWidth(self.logoMainView.bounds);
        logoParam.logoHeightScale = 100.0f / CGRectGetHeight(self.logoMainView.bounds);
        logoParam.xOffsetScale = 0;
        logoParam.yOffsetScale = 0;

        PLVPlayerLogoView *playerLogo = [[PLVPlayerLogoView alloc] init];
        [playerLogo insertLogoWithParam:logoParam];
        [self addPlayerLogo:playerLogo];
    }
}

- (void)addPlayerLogo:(PLVPlayerLogoView *)logo {
    if (self.logoMainView) {
        [logo addAtView:self.logoMainView];
    }
}

@end
