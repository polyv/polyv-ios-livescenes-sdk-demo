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
#import "PLVLivePictureInPicturePlaceholderView.h"
#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVProgressHUD.h>
#import "PLVPlayerPresenter.h"
#import "PLVWatermarkView.h"

@interface PLVECPlayerViewController ()<
PLVPlayerPresenterDelegate
>

@property (nonatomic, strong) PLVPlayerPresenter * playerPresenter; // 播放器 功能模块

#pragma mark 视图
/// 直播带货视图层级:
/// (UIView) superview
/// ├── (UIView) self
/// │   ├── (UIImageView) backgroundView  背景图
/// │   ├── (PLVECPlayerBackgroundView) playerBackgroundView 显示播放器（未开播时的）背景图
/// │   ├── (UIView) contentBackgroudView 内容背景视图 (负责承载 播放器画面)
/// │   │   └── (UIView) displayView  播放器区域
/// │   ├── (PLVWatermarkView) watermarkView  防录屏水印
/// │   ├── (PLVECAudioAnimalView) audioAnimalView  // 显示音频模式背景图
/// │   ├── (UIButton) playButton  //播放器暂停、播放按钮
/// │   └── (PLVLivePictureInPicturePlaceholderView) pictureInPicturePlaceholderView
/// └── (PLVMarqueeView) marqueeView // 跑马灯 (用于显示 ‘用户昵称’，规避非法录屏)

@property (nonatomic, strong) UIImageView *backgroundView; // 全尺寸背景图
@property (nonatomic, strong) PLVECPlayerBackgroundView *playerBackgroundView; // 显示播放器（未开播时的）背景图
@property (nonatomic, strong) UIView *contentBackgroudView; // 内容背景视图 (负责承载 播放器画面)
@property (nonatomic, strong) PLVECAudioAnimalView *audioAnimalView; // 显示音频模式背景图
@property (nonatomic, strong) UIView *displayView; // 播放器区域
@property (nonatomic, strong) PLVWatermarkView * watermarkView; // 防录屏水印
@property (nonatomic, strong) UIButton * playButton; // 播放器暂停、播放按钮
@property (nonatomic, strong) PLVLivePictureInPicturePlaceholderView *pictureInPicturePlaceholderView;    // 画中画占位图
@property (nonatomic, strong) PLVMarqueeView * marqueeView; // 跑马灯 (用于显示 ‘用户昵称’，规避非法录屏)

#pragma mark 基本数据
@property (nonatomic, assign) CGRect displayRect; // 播放器区域rect
@property (nonatomic, assign) CGSize videoSize; // 视频源尺寸
@property (nonatomic, readonly) PLVRoomData *roomData; // 只读，当前直播间数据
@property (nonatomic, assign) BOOL playing; // 播放器播放状态

@end

@implementation PLVECPlayerViewController

#pragma mark - Life Cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        /// 播放器
        self.playerPresenter = [[PLVPlayerPresenter alloc] initWithVideoType:self.roomData.videoType];
        self.playerPresenter.delegate = self;
        
        [self addTapGestureRecognizer];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s",__FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.backgroundView];
    [self.view addSubview:self.playerBackgroundView];
    [self.view addSubview:self.contentBackgroudView];
    [self contentBackgroundViewDisplaySubview:self.displayView];
    [self.view addSubview:self.audioAnimalView];
    [self.view addSubview:self.playButton];
    [self.view addSubview:self.pictureInPicturePlaceholderView];
    
    [self.playerPresenter setupPlayerWithDisplayView:self.displayView];
    if (!self.marqueeView.superview) {
        [self.view insertSubview:self.marqueeView aboveSubview:self.view];
    }
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
        self.contentBackgroudView.frame = self.playerBackgroundView.frame;
    } else {
        self.contentBackgroudView.frame = self.displayRect;
    }
    
    // 设置跑马灯区域位置、尺寸
    self.marqueeView.frame = self.playerBackgroundView.frame;
    
    // 设置防录屏水印位置、尺寸
    self.watermarkView.frame = self.contentBackgroudView.frame;
    
    self.playButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - 74) / 2, (CGRectGetHeight(self.view.frame) - 72) / 2, 74, 72);
    
    // 设置画中画占位图
    self.pictureInPicturePlaceholderView.frame = self.contentBackgroudView.frame;
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

#pragma mark - [ Private Methods ]

- (void)contentBackgroundViewDisplaySubview:(UIView *)subview{
    [self removeSubview:self.contentBackgroudView];
    [self.contentBackgroudView addSubview:subview];
    subview.frame = self.contentBackgroudView.bounds;
    subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)removeSubview:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

#pragma mark Marquee
- (void)setupMarquee:(PLVChannelInfoModel *)channel customNick:(NSString *)customNick  {
    __weak typeof(self) weakSelf = self;
    [self handleMarquee:channel customNick:customNick completion:^(PLVMarqueeStyleModel *model, NSError *error) {
        if (model) {
            [weakSelf loadVideoMarqueeView:model];
        } else if (error) {
            if (error.code == -10000) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(customMarqueeDefaultWithError:)]) {
                    [weakSelf.delegate customMarqueeDefaultWithError:error];
                }
            } else {
                NSLog(@"自定义跑马灯加载失败：%@",error);
            }
        } else {
            NSLog(@"无跑马灯或跑马灯不显示");
        }
    }];
}

- (void)handleMarquee:(PLVChannelInfoModel *)channel customNick:(NSString *)customNick completion:(void (^)(PLVMarqueeStyleModel * model, NSError *error))completion {
    switch (channel.marqueeType) {
        case PLVChannelMarqueeType_Nick:
            if (customNick) {
                channel.marquee = customNick;
            } else {
                channel.marquee = @"自定义昵称";
            }
        case PLVChannelMarqueeType_Fixed: {
            float alpha = channel.marqueeOpacity.floatValue/100.0;
            PLVMarqueeStyleModel *model = [PLVMarqueeStyleModel createMarqueeModelWithContent:channel.marquee fontSize:channel.marqueeFontSize.unsignedIntegerValue fontColor:channel.marqueeFontColor alpha:alpha style:channel.marqueeSetting];
            completion(model, nil);
        } break;
        case PLVChannelMarqueeType_URL: {
            if (channel.marquee) {
                [PLVLiveVideoAPI loadCustomMarquee:[NSURL URLWithString:channel.marquee] withChannelId:channel.channelId.integerValue userId:channel.accountUserId code:@"" completion:^(BOOL valid, NSDictionary *marqueeDict) {
                    if (valid) {
                        completion([PLVMarqueeStyleModel createMarqueeModelWithMarqueeDict:marqueeDict], nil);
                    } else {
                        NSError *error = [NSError errorWithDomain:@"net.plv.ecommerceBaseMediaError" code:-10000 userInfo:@{NSLocalizedDescriptionKey:marqueeDict[@"msg"]}];
                        completion(nil, error);
                    }
                } failure:^(NSError *error) {
                    completion(nil, error);
                }];
            }
        } break;
        default:
            completion(nil, nil);
            break;
    }
}

- (void)loadVideoMarqueeView:(PLVMarqueeStyleModel *)model {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // 设置跑马灯
        [weakSelf.marqueeView setPLVMarqueeModel:model];
        [weakSelf.marqueeView start];
    });
}

- (PLVECLivePlayerQuickLiveNetworkQuality)transformQuickLiveNetworkQuality:(PLVLivePlayerQuickLiveNetworkQuality)networkQuality {
    if (networkQuality == PLVLivePlayerQuickLiveNetworkQuality_Poor) {
        return PLVECLivePlayerQuickLiveNetworkQuality_Poor;
    } else if (networkQuality == PLVLivePlayerQuickLiveNetworkQuality_Middle) {
        return PLVECLivePlayerQuickLiveNetworkQuality_Middle;
    } else if (networkQuality == PLVLivePlayerQuickLiveNetworkQuality_Good) {
        return PLVECLivePlayerQuickLiveNetworkQuality_Good;
    } else {
        return PLVECLivePlayerQuickLiveNetworkQuality_NoConnection;
    }
}

#pragma mark  防录屏水印
- (void)setupWatermark {
    if (self.contentBackgroudView) {
        [self.view addSubview:self.watermarkView];
    }
}

#pragma mark Getter

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
        _playerBackgroundView.hidden = !(self.roomData.videoType == PLVChannelVideoType_Live);
    }
    return _playerBackgroundView;
}

- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.backgroundColor = [UIColor blackColor];
        _contentBackgroudView.hidden = !(self.roomData.videoType == PLVChannelVideoType_Playback);
    }
    return _contentBackgroudView;
}

- (PLVECAudioAnimalView *)audioAnimalView {
    if (!_audioAnimalView) {
        _audioAnimalView = [[PLVECAudioAnimalView alloc] init];
        _audioAnimalView.hidden = YES;
    }
    return _audioAnimalView;
}

- (PLVLivePictureInPicturePlaceholderView *)pictureInPicturePlaceholderView {
    if (!_pictureInPicturePlaceholderView) {
        _pictureInPicturePlaceholderView = [[PLVLivePictureInPicturePlaceholderView alloc] init];
        _pictureInPicturePlaceholderView.hidden = YES;
    }
    return _pictureInPicturePlaceholderView;
}

- (UIView *)displayView {
    if (!_displayView) {
        _displayView = [[UIView alloc] init];
    }
    return _displayView;
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

- (BOOL)noDelayWatchMode {
    return _playerPresenter.noDelayWatchMode;
}

- (BOOL)advertPlaying {
    return _playerPresenter.advertPlaying;
}

- (BOOL)noDelayLiveWatching{
    return self.playerPresenter.noDelayLiveWatching;
}

- (PLVMarqueeView *)marqueeView{
    if (!_marqueeView) {
        _marqueeView = [[PLVMarqueeView alloc] init];
        _marqueeView.backgroundColor = [UIColor clearColor];
        _marqueeView.userInteractionEnabled = NO;
    }
    return _marqueeView;
}

- (PLVWatermarkView *)watermarkView {
    if (!_watermarkView) {
        PLVChannelInfoModel *channel = self.roomData.channelInfo;
        if (channel.watermarkRestrict) {
            NSString *content = channel.watermarkContent;
            if (channel.watermarkType == PLVChannelWatermarkType_Nick) {
                content = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerName;
            }
            PLVWatermarkModel *model = [PLVWatermarkModel watermarkModelWithContent:content fontSize:channel.watermarkFontSize opacity:channel.watermarkOpacity];
            _watermarkView = [[PLVWatermarkView alloc] initWithWatermarkModel:model];
        }
    }
    return _watermarkView;
}

- (PLVRoomData *)roomData {
    return [PLVRoomDataManager sharedManager].roomData;
}

- (BOOL)pausedWatchNoDelay {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControllerGetPausedWatchNoDelay:)]) {
        return [self.delegate playerControllerGetPausedWatchNoDelay:self];
    }else{
        NSLog(@"PLVECPlayerViewController - delegate not implement method:[playerControllerGetPausedWatchNoDelay:]");
        return NO;
    }
}

- (void)addTapGestureRecognizer {
    // 单击、双击手势控制播放器和UI
    UITapGestureRecognizer *doubleGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    doubleGestureRecognizer.numberOfTapsRequired = 2;
    doubleGestureRecognizer.numberOfTouchesRequired = 1;
    [doubleGestureRecognizer addTarget:self action:@selector(displayViewTapAction:)];
    [self.view addGestureRecognizer:doubleGestureRecognizer];
    
    UITapGestureRecognizer *singleGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    singleGestureRecognizer.numberOfTapsRequired = 1;
    singleGestureRecognizer.numberOfTouchesRequired = 1;
    [singleGestureRecognizer addTarget:self action:@selector(displayViewTapAction:)];
    [self.view addGestureRecognizer:singleGestureRecognizer];

    [singleGestureRecognizer requireGestureRecognizerToFail:doubleGestureRecognizer];
}

#pragma mark - [ Action ]
- (void)displayViewTapAction:(UITapGestureRecognizer *)gestureRecognizer {
    PLVRoomData *roomData = self.roomData;
    if (roomData.videoType == PLVChannelVideoType_Live &&
        roomData.liveState != PLVChannelLiveStreamState_Live) { // 直播时未开播，不响应播放
        return;
    }
    
    if (gestureRecognizer.numberOfTapsRequired == 1) {
        if (!self.playing) {
            [self play];
        }
    } else if (gestureRecognizer.numberOfTapsRequired == 2) {
        if (self.playing) {
            [self pause];
        } else {
            [self play];
        }
    }
}

#pragma mark - Public

- (void)play {
    if (self.playerPresenter.noDelayWatchMode) {
        self.playing = YES;
        self.playButton.hidden = YES;
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(playerController:noDelayLiveWannaPlay:)]) {
            [self.delegate playerController:self noDelayLiveWannaPlay:self.playing];
        }
    } else if ([self.playerPresenter resumePlay]) {
        self.playButton.hidden = YES;
    }
}

- (void)pause {
    if (self.playerPresenter.noDelayWatchMode) {
        self.playing = NO;
        self.playButton.hidden = NO;
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(playerController:noDelayLiveWannaPlay:)]) {
            [self.delegate playerController:self noDelayLiveWannaPlay:self.playing];
        }
    } else if ([self.playerPresenter pausePlay]) {
        self.playButton.hidden = NO;
    }
}

- (void)mute{
    [self.playerPresenter mute];
}

- (void)cancelMute{
    [self.playerPresenter cancelMute];
}

- (void)displayContentView:(UIView *)contentView {
    if (contentView && [contentView isKindOfClass:UIView.class]) {
        [self contentBackgroundViewDisplaySubview:contentView];
    }else{
        NSLog(@"PLVECPlayerViewController - displayExternalView failed, view is illegal : %@",contentView);
    }
}

- (void)cleanPlayer {
    [self.playerPresenter cleanPlayer];
}

- (BOOL)channelInLive {
    return self.playerPresenter.channelInLive;
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
    if (self.roomData.videoType != PLVChannelVideoType_Live) {
        return;
    }
    
    if (audioMode) {
        [self.audioAnimalView startAnimating];
        self.contentBackgroudView.hidden = YES;
    } else {
        [self.audioAnimalView stopAnimating];
        self.contentBackgroudView.hidden = NO;
    }
    [self.playerPresenter switchLiveToAudioMode:audioMode];
}

- (void)switchToNoDelayWatchMode:(BOOL)noDelayWatchMode {
    if (self.roomData.videoType != PLVChannelVideoType_Live) {
        return;
    }
    self.playButton.hidden = YES;
    if (self.playerPresenter.channelWatchNoDelay) {
        self.playing = ![self pausedWatchNoDelay]; // 无延迟切换后无[playerPresenter:noDelayLiveStartUpdate:noDelayLiveStartDidChanged:]回调，但是会自动播放
        [self contentBackgroundViewDisplaySubview:self.displayView];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(playerController:noDelayWatchModeSwitched:)]) {
            [self.delegate playerController:self noDelayWatchModeSwitched:noDelayWatchMode];
        }
    }
    [self.playerPresenter switchToNoDelayWatchMode:noDelayWatchMode];
}

- (void)startPictureInPicture {
    if ([PLVRoomDataManager sharedManager].roomData.videoType != PLVChannelVideoType_Live) {
        return;
    }
    [self.playerPresenter startPictureInPictureFromOriginView:self.contentBackgroudView];
}

- (void)stopPictureInPicture {
    if ([PLVRoomDataManager sharedManager].roomData.videoType != PLVChannelVideoType_Live) {
        return;
    }
    [self.playerPresenter stopPictureInPicture];
}

#pragma mark 回放方法

- (void)seek:(NSTimeInterval)time {
    [self.playerPresenter seekLivePlaybackToTime:time];
}

- (void)speedRate:(NSTimeInterval)speed {
    [self.playerPresenter switchLivePlaybackSpeedRate:speed];
}

- (void)changeVid:(NSString *)vid{
    [self.playerPresenter changeVid:vid];
    self.playButton.hidden = YES;
}

#pragma mark - PLVPlayerPresenterDelegate Delegate
/// 播放器 ‘正在播放状态’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter playerPlayingStateDidChanged:(BOOL)playing{
    self.playing = playing;
    if (playing) {
        [self.marqueeView start];
    }else {
        [self.marqueeView pause];
    }
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
    self.contentBackgroudView.frame = self.displayRect;
    self.watermarkView.frame = self.contentBackgroudView.frame;
    self.pictureInPicturePlaceholderView.frame = self.displayRect;
}

- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter streamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged{
    PLVChannelInfoModel *channelInfo = self.roomData.channelInfo;
    if (newestStreamState == PLVChannelLiveStreamState_Unknown ||
        (newestStreamState == PLVChannelLiveStreamState_End &&
         channelInfo.warmUpType == PLVChannelWarmUpType_None)) {
        self.contentBackgroudView.hidden = YES;
        self.displayRect = self.backgroundView.frame;
        self.contentBackgroudView.frame = self.displayRect;
        self.pictureInPicturePlaceholderView.frame = self.displayRect;
        [self.marqueeView stop];
    } else {
        self.contentBackgroudView.hidden = NO;
    }
    
    if (newestStreamState == PLVChannelLiveStreamState_Live) {
        [self.marqueeView start];
        // 设置水印
        [self setupWatermark];
    } else {
        // 移除水印
        [self.watermarkView removeFromSuperview];
    }
}

/// 直播播放器 ‘码率可选项、当前码率、线路可选数、当前线路‘ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter codeRateOptions:(NSArray <NSString *> *)codeRateOptions currentCodeRate:(NSString *)currentCodeRate lineNum:(NSInteger)lineNum currentLineIndex:(NSInteger)currentLineIndex{
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerController:codeRateItems:codeRate:lines:line:noDelayWatchMode:)]) {
        [self.delegate playerController:self codeRateItems:codeRateOptions codeRate:currentCodeRate lines:lineNum line:currentLineIndex noDelayWatchMode:playerPresenter.noDelayWatchMode];
    }
}

- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter downloadProgress:(CGFloat)downloadProgress playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(updateDowloadProgress:playedProgress:duration:currentPlaybackTimeInterval:currentPlaybackTime:durationTime:)]) {
        [self.delegate updateDowloadProgress:downloadProgress
                              playedProgress:playedProgress
                                    duration:playerPresenter.duration
                 currentPlaybackTimeInterval:self.playerPresenter.currentPlaybackTime
                         currentPlaybackTime:playedTimeString
                                durationTime:durationTimeString];
    }
}

- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter quickLiveNetworkQuality:(PLVLivePlayerQuickLiveNetworkQuality)netWorkQuality {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerController:quickLiveNetworkQuality:)]) {
        [self.delegate playerController:self quickLiveNetworkQuality:[self transformQuickLiveNetworkQuality:netWorkQuality]];
    }
}

- (void)playerPresenterPlaybackInterrupted:(PLVPlayerPresenter *)playerPresenter {
    self.playButton.hidden = NO;
}

/// 直播播放器 需获知外部 ‘当前是否已暂停无延迟观看’
- (BOOL)playerPresenterGetPausedWatchNoDelay:(PLVPlayerPresenter *)playerPresenter{
    BOOL pausedWatchNoDelay = self.pausedWatchNoDelay;
    NSLog(@"pausedWatchNoDelay#:%d", pausedWatchNoDelay);
    return pausedWatchNoDelay;
}

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter noDelayLiveStartUpdate:(BOOL)noDelayLiveStart noDelayLiveStartDidChanged:(BOOL)noDelayLiveStartDidChanged {
    self.playing = noDelayLiveStart;
    if (noDelayLiveStart) {
        [self.playerPresenter cleanPlayer];
    } else {
        [self contentBackgroundViewDisplaySubview:self.displayView];
    }
    if (noDelayLiveStartDidChanged) {
        if ([self.delegate respondsToSelector:@selector(playerController:noDelayLiveStartUpdate:)]) {
            [self.delegate playerController:self noDelayLiveStartUpdate:noDelayLiveStart];
        }
    }
}

/// 播放器 ‘频道信息’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo{
    /// 设置 跑马灯
    [self setupMarquee:self.roomData.channelInfo customNick:self.roomData.roomUser.viewerName];
    if (self.roomData.videoType == PLVChannelVideoType_Playback) {
        /// 设置防录屏水印
        [self setupWatermark];
    }
}

- (void)playerPresenterPictureInPictureWillStart:(PLVPlayerPresenter *)playerPresenter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControllerPictureInPictureWillStart:)]) {
        [self.delegate playerControllerPictureInPictureWillStart:self];
    }
}

- (void)playerPresenterPictureInPictureDidStart:(PLVPlayerPresenter *)playerPresenter {
    self.pictureInPicturePlaceholderView.hidden = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControllerPictureInPictureDidStart:)]) {
        [self.delegate playerControllerPictureInPictureDidStart:self];
    }
}

- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter pictureInPictureFailedToStartWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerController:pictureInPictureFailedToStartWithError:)]) {
        [self.delegate playerController:self pictureInPictureFailedToStartWithError:error];
    }
}

- (void)playerPresenterPictureInPictureWillStop:(PLVPlayerPresenter *)playerPresenter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControllerPictureInPictureWillStop:)]) {
        [self.delegate playerControllerPictureInPictureWillStop:self];
    }
}

- (void)playerPresenterPictureInPictureDidStop:(PLVPlayerPresenter *)playerPresenter {
    self.pictureInPicturePlaceholderView.hidden = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControllerPictureInPictureDidStop:)]) {
        [self.delegate playerControllerPictureInPictureDidStop:self];
    }
}

@end
