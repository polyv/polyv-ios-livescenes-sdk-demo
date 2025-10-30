//
//  PLVStickerPlayer.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/8/14.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerPlayer.h"
#import <PLVIJKPlayer/PLVIJKPlayer.h>
#import "PLVMediaPlayerSampleBufferDisplayView.h"

@interface PLVStickerPlayer ()

@property (nonatomic, strong) PLVIJKFFMoviePlayerController *player;
@property (nonatomic, strong) PLVMediaPlayerSampleBufferDisplayView *sampleBufferDisplayView;
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, assign, readwrite) PLVStickerPlayerState state;
@property (nonatomic, strong, readwrite) UIView *playerView;
@property (nonatomic, assign, readwrite) NSTimeInterval currentTime;
@property (nonatomic, assign, readwrite) NSTimeInterval totalTime;
@property (nonatomic, strong) NSTimer *progressTimer;

@end

@implementation PLVStickerPlayer

#pragma mark - Lifecycle

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _videoURL = url;
        _state = PLVStickerPlayerStateIdle;
        [self setupPlayer];
    }
    return self;
}

- (void)dealloc {
    [self destroy];
}

#pragma mark - Setup

- (void)setupPlayer {
    if (!self.videoURL) {
        [self updateState:PLVStickerPlayerStateError];
        return;
    }
    
    // 创建播放器配置
    PLVIJKFFOptions *options = [PLVIJKFFOptions optionsByDefault];
    // 设置硬解码
    [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:1 forKey:@"enable-audio-data-callback"];

    self.sampleBufferDisplayView = [[PLVMediaPlayerSampleBufferDisplayView alloc] initWithFrame:CGRectZero];
    self.sampleBufferDisplayView.backgroundColor = [UIColor clearColor];
    self.sampleBufferDisplayView.contentMode = UIViewContentModeScaleAspectFit;
    self.sampleBufferDisplayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // 创建播放器
    self.player = [[PLVIJKFFMoviePlayerController alloc] initWithMoreContent:self.videoURL
                                                                 withOptions:options
                                                                  withGLView:self.sampleBufferDisplayView];

    if (self.player ) {
        self.playerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
        self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.player.view.frame = self.playerView.bounds;
        [self.playerView insertSubview:self.player.view atIndex:0];
    }
    
    // 配置音频会话以支持混音
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker |
                                                AVAudioSessionCategoryOptionMixWithOthers |
                                                    AVAudioSessionCategoryOptionAllowBluetoothHFP
                                           error:&error];
    
    // 设置播放器属性
    self.player.shouldAutoplay = NO;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    // 静音设置
    self.player.playbackVolume = 0.0;
    
    // 添加播放器通知监听
    [self addPlayerNotifications];
    
    // 准备播放
    [self.player prepareToPlay];
    [self updateState:PLVStickerPlayerStatePreparing];
    
    // 注册音频回调
    __weak typeof(self) weakSelf = self;
    self.player.audioPacketCallback = ^(NSData *data, NSUInteger size, NSUInteger chanels, NSUInteger bitsSample, NSUInteger sampleRate) {
        // 一个完整的音频数据包
        if (size){
            NSDictionary *audioPacket = @{
                @"data": data,
                @"size": @(size),
                @"chanels": @(chanels),
                @"bitsSample": @(bitsSample),
                @"sampleRate": @(sampleRate)
            };      
            if ([weakSelf.delegate respondsToSelector:@selector(stickerPlayer:didUpdateAudioPacket:)]) {
                [weakSelf.delegate stickerPlayer:weakSelf didUpdateAudioPacket:audioPacket];
            }
        }
    };
}

- (void)addPlayerNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // 播放器准备完成
    [notificationCenter addObserver:self
                           selector:@selector(moviePlayerIsPreparedToPlayDidChange:)
                               name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                             object:self.player];
    
    // 加载状态改变
    [notificationCenter addObserver:self
                           selector:@selector(moviePlayerLoadStateDidChange:)
                               name:IJKMPMoviePlayerLoadStateDidChangeNotification
                             object:self.player];
    
    // 播放完成
    [notificationCenter addObserver:self
                           selector:@selector(moviePlayerPlaybackDidFinish:)
                               name:IJKMPMoviePlayerPlaybackDidFinishNotification
                             object:self.player];
    
    // 播放状态改变
    [notificationCenter addObserver:self
                           selector:@selector(moviePlayerPlaybackStateDidChange:)
                               name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                             object:self.player];
}

- (void)removePlayerNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)play {
    if (!self.player) {
        return;
    }
    
    [self.player play];
    [self startProgressTimer];
}

- (void)pause {
    if (!self.player) {
        return;
    }
    
    [self.player pause];
    [self stopProgressTimer];
}

- (void)stop {
    if (!self.player) {
        return;
    }
    
    [self.player stop];
    [self stopProgressTimer];
    [self updateState:PLVStickerPlayerStateStopped];
}

- (void)seekToTime:(NSTimeInterval)time {
    if (!self.player) {
        return;
    }
    
    self.player.currentPlaybackTime = time;
    self.currentTime = time;
    
    // 通知代理进度更新
    if ([self.delegate respondsToSelector:@selector(stickerPlayer:didUpdateProgress:totalTime:)]) {
        [self.delegate stickerPlayer:self didUpdateProgress:self.currentTime totalTime:self.totalTime];
    }
}

- (void)setupVolume:(CGFloat)volume {
    if (!self.player) {
        return;
    }
    
    self.player.playbackVolume = volume;
}   

- (void)destroy {
    [self stopProgressTimer];
    [self removePlayerNotifications];
    
    if (self.player) {
        [self.player stop];
        [self.player shutdown];
        self.player = nil;
    }
    
    self.playerView = nil;
    [self updateState:PLVStickerPlayerStateIdle];
}

#pragma mark - Properties

- (BOOL)isPlaying {
    return self.state == PLVStickerPlayerStatePlaying;
}

- (NSTimeInterval)currentTime {
    if (self.player) {
        return self.player.currentPlaybackTime;
    }
    return 0;
}

- (NSTimeInterval)totalTime {
    if (self.player) {
        return self.player.duration;
    }
    return 0;
}

#pragma mark - Private Methods

- (void)updateState:(PLVStickerPlayerState)state {
    if (_state != state) {
        _state = state;
        
        // 通知代理状态改变
        if ([self.delegate respondsToSelector:@selector(stickerPlayer:didChangeState:)]) {
            [self.delegate stickerPlayer:self didChangeState:state];
        }
    }
}

- (void)startProgressTimer {
    [self stopProgressTimer];
    
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                          target:self
                                                        selector:@selector(updateProgress)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)stopProgressTimer {
    if (self.progressTimer) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
}

- (void)updateProgress {
    if (self.player && self.isPlaying) {
        NSTimeInterval current = self.currentTime;
        NSTimeInterval total = self.totalTime;
        
        // 通知代理进度更新
        if ([self.delegate respondsToSelector:@selector(stickerPlayer:didUpdateProgress:totalTime:)]) {
            [self.delegate stickerPlayer:self didUpdateProgress:current totalTime:total];
        }
    }
}

#pragma mark - Player Notifications

- (void)moviePlayerIsPreparedToPlayDidChange:(NSNotification *)notification {
    // 播放器准备完成
    dispatch_async(dispatch_get_main_queue(), ^{
        // 自动播放
        [self play];
        [self updateState:PLVStickerPlayerStatePlaying];
        
        // 回调视频尺寸
        CGSize videoSize = self.player.naturalSize;
        NSLog(@"PLVStickerPlayer: Video size prepared - %@", NSStringFromCGSize(videoSize));
        
        if ([self.delegate respondsToSelector:@selector(stickerPlayer:didPrepareWithVideoSize:)]) {
            [self.delegate stickerPlayer:self didPrepareWithVideoSize:videoSize];
        }
    });
}

- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification {
    IJKMPMovieLoadState loadState = self.player.loadState;
    
    if (loadState & IJKMPMovieLoadStatePlaythroughOK) {
        // 可以播放
        NSLog(@"PLVStickerPlayer: Load state playthrough OK");
    } else if (loadState & IJKMPMovieLoadStateStalled) {
        // 缓冲中
        NSLog(@"PLVStickerPlayer: Load state stalled");
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopProgressTimer];
        
        NSNumber *reason = notification.userInfo[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
        IJKMPMovieFinishReason finishReason = [reason integerValue];
        
        switch (finishReason) {
            case IJKMPMovieFinishReasonPlaybackEnded:
                [self updateState:PLVStickerPlayerStateCompleted];
                break;
            case IJKMPMovieFinishReasonPlaybackError:
                [self updateState:PLVStickerPlayerStateError];
                // 通知代理错误
                if ([self.delegate respondsToSelector:@selector(stickerPlayer:didFailWithError:)]) {
                    NSError *error = [NSError errorWithDomain:@"PLVStickerPlayerError"
                                                         code:-1
                                                     userInfo:@{NSLocalizedDescriptionKey: @"播放出现错误"}];
                    [self.delegate stickerPlayer:self didFailWithError:error];
                }
                break;
            case IJKMPMovieFinishReasonUserExited:
                [self updateState:PLVStickerPlayerStateStopped];
                break;
            default:
                break;
        }
    });
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        IJKMPMoviePlaybackState playbackState = self.player.playbackState;
        
        switch (playbackState) {
            case IJKMPMoviePlaybackStatePlaying:
                [self updateState:PLVStickerPlayerStatePlaying];
                [self startProgressTimer];
                break;
            case IJKMPMoviePlaybackStatePaused:
                [self updateState:PLVStickerPlayerStatePaused];
                [self stopProgressTimer];
                break;
            case IJKMPMoviePlaybackStateStopped:
                [self updateState:PLVStickerPlayerStateStopped];
                [self stopProgressTimer];
                break;
            case IJKMPMoviePlaybackStateInterrupted:
                [self updateState:PLVStickerPlayerStatePaused];
                [self stopProgressTimer];
                break;
            default:
                break;
        }
    });
}

- (UIImage *)snapshot {
    if (!self.sampleBufferDisplayView) {
        return nil;
    }
    
    // 直接调用PLVMediaPlayerSampleBufferDisplayView的snapshot方法
    if ([self.sampleBufferDisplayView respondsToSelector:@selector(snapshot)]) {
        return [self.sampleBufferDisplayView snapshot];
    }
    
    return nil;
}

- (CGSize)videoSize {
    if (self.player) {
        return self.player.naturalSize;
    }
    return CGSizeZero;
}

@end
