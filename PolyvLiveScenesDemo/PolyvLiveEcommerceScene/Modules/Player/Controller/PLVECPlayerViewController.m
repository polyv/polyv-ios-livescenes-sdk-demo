//
//  PLVECPlayerViewController.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/3.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECPlayerViewController.h"
#import "PLVECPlayerBackgroundView.h"
#import "PLVECAudioAnimalView.h"
#import "PLVECUtils.h"
#import <PolyvFoundationSDK/PLVProgressHUD.h>

@interface PLVECPlayerViewController ()<
PLVLivePlayerPresenterDelegate,
PLVPlaybackPlayerPresenterDelegate
>

@property (nonatomic, strong) PLVLivePlayerPresenter *livePresenter;
@property (nonatomic, strong) PLVPlaybackPlayerPresenter *playbackPresenter;

#pragma mark 视图
@property (nonatomic, strong) UIImageView *backgroundView; // 全尺寸背景图
@property (nonatomic, strong) PLVECPlayerBackgroundView *playerBackgroundView; // 显示播放器（未开播时的）背景图
@property (nonatomic, strong) PLVECAudioAnimalView *audioAnimalView; // 显示音频模式背景图
@property (nonatomic, strong) UIView *displayView; // 播放器区域

#pragma mark 基本数据
@property (nonatomic, assign) PLVWatchRoomVideoType type;
@property (nonatomic, assign) CGRect displayRect; // 播放器区域rect
@property (nonatomic, assign) CGSize videoSize; // 视频源尺寸

@end

@implementation PLVECPlayerViewController

#pragma mark - Life Cycle

- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData {
    self = [super init];
    if (self) {
        self.type = roomData.videoType;
        
        if (self.type == PLVWatchRoomVideoType_Live) {
            self.livePresenter = [[PLVLivePlayerPresenter alloc] initWithRoomData:roomData];
            self.livePresenter.view = self;
        } else if (self.type == PLVWatchRoomVideoType_LivePlayback) {
            self.playbackPresenter = [[PLVPlaybackPlayerPresenter alloc] initWithRoomData:roomData];
            self.playbackPresenter.view = self;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.backgroundView];
    [self.view addSubview:self.playerBackgroundView];
    [self.view addSubview:self.displayView];
    [self.view addSubview:self.audioAnimalView];
    
    if (self.type == PLVWatchRoomVideoType_Live) {
        [self.livePresenter setupPlayerWithDisplayView:self.displayView];
    } else if (self.type == PLVWatchRoomVideoType_LivePlayback) {
        [self.playbackPresenter setupPlayerWithDisplayView:self.displayView];
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
        self.displayView.frame = self.playerBackgroundView.frame;
    } else {
        self.displayView.frame = self.displayRect;
    }
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
        _playerBackgroundView.hidden = !(self.type == PLVWatchRoomVideoType_Live);
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
        _displayView.hidden = !(self.type == PLVWatchRoomVideoType_LivePlayback);;
    }
    return _displayView;
}

#pragma mark - Public

- (void)play {
    if (self.type == PLVWatchRoomVideoType_Live) {
        [self.livePresenter reloadLive:nil];
    } else if (self.type == PLVWatchRoomVideoType_LivePlayback) {
        [self.playbackPresenter play];
    }
}

- (void)pause {
    if (self.type == PLVWatchRoomVideoType_Live) {
        [self.livePresenter pauseLive];
    } else if (self.type == PLVWatchRoomVideoType_LivePlayback) {
        [self.playbackPresenter pause];
    }
}

- (void)destroy {
    if (self.type == PLVWatchRoomVideoType_Live) {
        [self.livePresenter destroy];
    } else if (self.type == PLVWatchRoomVideoType_LivePlayback) {
        [self.playbackPresenter destroy];
    }
}

#pragma mark 直播方法

- (void)reload {
    if (self.type != PLVWatchRoomVideoType_Live) {
        return;
    }
    
    [self.livePresenter reloadLive:nil];
}

- (void)switchPlayLine:(NSUInteger)Line showHud:(BOOL)showHud {
    if (self.type != PLVWatchRoomVideoType_Live) {
        return;
    }
    
    PLVProgressHUD *hud = nil;
    if (showHud) {
        hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
        [hud.label setText:@"加载直播..."];
    }
    [self.livePresenter switchPlayLine:Line completion:^(NSError * _Nonnull error) {
        if (error && hud) {
            hud.label.text = [NSString stringWithFormat:@"加载直播失败:%@", error.localizedDescription];
        }
        [hud hideAnimated:YES];
    }];
}

- (void)switchPlayCodeRate:(NSString *)codeRate showHud:(BOOL)showHud {
    if (self.type != PLVWatchRoomVideoType_Live) {
        return;
    }
    
    PLVProgressHUD *hud = nil;
    if (showHud) {
        hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
        [hud.label setText:@"加载直播..."];
    }
    [self.livePresenter switchPlayCodeRate:codeRate completion:^(NSError * _Nonnull error) {
        if (error && hud) {
            hud.label.text = [NSString stringWithFormat:@"加载直播失败:%@", error.localizedDescription];
        }
        [hud hideAnimated:YES];
    }];
}

- (void)switchAudioMode:(BOOL)audioMode {
    if (self.type != PLVWatchRoomVideoType_Live) {
        return;
    }
    
    if (audioMode) {
        [self.audioAnimalView startAnimating];
        self.displayView.hidden = YES;
    } else {
        [self.audioAnimalView stopAnimating];
        self.displayView.hidden = NO;
    }
    [self.livePresenter switchAudioMode:audioMode];
}

#pragma mark 回放方法

- (void)seek:(NSTimeInterval)time {
    if (self.type != PLVWatchRoomVideoType_LivePlayback) {
        return;
    }
    
    [self.playbackPresenter seek:time];
}

- (void)speedRate:(NSTimeInterval)speed {
    if (self.type != PLVWatchRoomVideoType_LivePlayback) {
        return;
    }
    
    [self.playbackPresenter speedRate:speed];
}

#pragma mark - PLVPlayerPresenter Delegate

- (void)presenter:(PLVLivePlayerPresenter *)presenter loadMainPlayerFailure:(NSString *)message {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    hud.mode = PLVProgressHUDModeText;
    [hud.label setText:@"播放器加载失败"];
    hud.detailsLabel.text = message;
    [hud hideAnimated:YES afterDelay:2];
}

- (void)presenter:(PLVBasePlayerPresenter *)presenter mainPlayerPlaybackDidFinish:(NSDictionary *)dataInfo {
    if (self.type != PLVWatchRoomVideoType_LivePlayback) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(presenter:mainPlayerPlaybackDidFinish:)]) {
        [self.delegate presenter:(PLVPlaybackPlayerPresenter *)presenter mainPlayerPlaybackDidFinish:dataInfo];
    }
}

- (void)presenter:(PLVBasePlayerPresenter *)presenter videoSizeChange:(CGSize)videoSize {
    self.videoSize = videoSize;
    CGSize containerSize = self.view.bounds.size;
    if (self.videoSize.width == 0 || self.videoSize.height == 0 ||
        containerSize.width == 0 || containerSize.height == 0) {
        self.displayRect = CGRectZero;
        return;
    }
    
    self.displayRect = [self getDisplayViewRect];
    self.displayView.frame = self.displayRect;
    
    if (self.type == PLVWatchRoomVideoType_Live) {
        [self.livePresenter setPlayerFrame:self.displayView.bounds];
    } else if (self.type == PLVWatchRoomVideoType_LivePlayback) {
        [self.playbackPresenter setPlayerFrame:self.displayView.bounds];
    }
    
}

#pragma mark - PLVLivePlayerPresenter Delegate

- (void)presenter:(PLVLivePlayerPresenter *)presenter livePlayerStateDidChange:(LivePlayerState)livePlayerState {
    if (livePlayerState == LivePlayerStateUnknown || livePlayerState == LivePlayerStateEnd) {
        self.displayView.hidden = YES;
        self.displayRect = self.backgroundView.frame;
        self.displayView.frame = self.displayRect;
    } else {
        self.displayView.hidden = NO;
    }
}

- (void)presenterChannelPlayOptionInfoDidUpdate:(PLVLivePlayerPresenter *)presenter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerController:codeRateItems:codeRate:lines:line:)]) {
        PLVLiveRoomData *roomData = presenter.roomData;
        [self.delegate playerController:self
                          codeRateItems:roomData.codeRateItems
                               codeRate:roomData.curCodeRate
                                  lines:roomData.lines
                                   line:roomData.curLine];
    }
}

#pragma mark - PLVPlaybackPlayerPresenter Delegate

- (void)updateDowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(updateDowloadProgress:playedProgress:currentPlaybackTime:duration:)]) {
        [self.delegate updateDowloadProgress:dowloadProgress playedProgress:playedProgress currentPlaybackTime:currentPlaybackTime duration:duration];
    }
}

@end
