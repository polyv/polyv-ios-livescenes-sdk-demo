//
//  PLVPlaybackPlayerPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/9.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVPlaybackPlayerPresenter.h"
#import <PLVLiveScenesSDK/PLVVodPlayerController.h>

@interface PLVPlaybackPlayerPresenter () <PLVPlayerControllerDelegate, PLVVodPlayerControllerDelegate>

@property (nonatomic, strong) PLVPlaybackPlayerViewModel *viewModel;

@property (nonatomic, strong) PLVVodPlayerController *player;

@end

@implementation PLVPlaybackPlayerPresenter{
    BOOL _playbackProgressFlag;
}

#pragma mark - Setter

- (void)setView:(id<PLVPlayerPresenterDelegate,PLVPlaybackPlayerPresenterDelegate>)view {
    _view = view;
    _playbackProgressFlag = [view respondsToSelector:@selector(updateDowloadProgress:playedProgress:currentPlaybackTime:duration:)];
}

#pragma mark - Override

- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData {
    self = [super initWithRoomData:roomData];
    if (self) {
        self.viewModel = [[PLVPlaybackPlayerViewModel alloc] init];
    }
    return self;
}

- (void)setupPlayerWithDisplayView:(UIView *)displayView {
    self.player = [[PLVVodPlayerController alloc] initWithVodId:self.roomData.vid
                                                    displayView:displayView
                                                       delegate:self];
    self.viewModel.player = self;
    
    // 配置统计参数
    PLVLiveChannelConfig *channel = self.roomData.channel;
    self.player.liveParam1 = channel.liveParam1;
    self.player.liveParam2 = channel.liveParam2;
    self.player.liveParam4 = channel.liveParam4;
    self.player.liveParam5 = channel.liveParam5;
    self.player.vodSid = channel.vodSid;
    self.player.vodParam1 = channel.vodParam1;
    self.player.vodParam2 = channel.vodParam2;
    self.player.vodParam3 = channel.vodParam3;
    self.player.vodParam4 = channel.vodParam4;
    self.player.vodParam5 = channel.vodParam5;
    self.player.vodKey1 = channel.vodKey1;
    self.player.vodKey2 = channel.vodKey2;
    self.player.vodKey3 = channel.vodKey3;
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    if (liveConfig.channelId && liveConfig.userId) {
        __weak typeof(self)weakSelf = self;
        [PLVLivePlayerController loadLiveVideoChannelWithUserId:liveConfig.userId channelId:liveConfig.channelId.integerValue completion:^(PLVLiveVideoChannel *channel) {
            weakSelf.roomData.channelInfo = channel;
            if ([weakSelf.view respondsToSelector:@selector(presenterChannelInfoChanged:)]) {
                [weakSelf.view presenterChannelInfoChanged:weakSelf];
            }
        } failure:^(NSError *error) {
            NSLog(@"PLVPlaybackPlayerPresenter - 直播频道信息加载失败：%@",error);
        }];
    }
}

- (void)setPlayerFrame:(CGRect)rect {
    [self.player setFrame:rect];
}

- (void)destroy {
    [self.player clearPlayersAndTimers];
}

#pragma mark - Public

- (void)play {
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)seek:(NSTimeInterval)time {
    [self.player seek:time];
}

- (void)speedRate:(NSTimeInterval)speed {
    [self.player speedRate:speed];
}

#pragma mark - <PLVPlayerControllerDelegate>

/// 刷新皮肤的多码率和多线路的按钮
- (void)playerController:(PLVPlayerController *)playerController codeRateItems:(NSMutableArray *)codeRateItems codeRate:(NSString *)codeRate lines:(NSUInteger)lines line:(NSInteger)line {
    //NSLog(@"player: codeRateItems %@ codeRate %@ lines %ld line %ld",codeRateItems,codeRate,lines,line);
    self.roomData.curLine = line;
    self.roomData.lines = lines;
    self.roomData.curCodeRate = codeRate;
    self.roomData.codeRateItems = codeRateItems;
}

/// 加载主播放器失败（原因：1.网络请求失败；2.如果是直播，且该频道设置了限制条件）
- (void)playerController:(PLVPlayerController *)playerController loadMainPlayerFailure:(NSString *)message {
    if ([self.view respondsToSelector:@selector(presenter:loadMainPlayerFailure:)]) {
        [self.view presenter:self loadMainPlayerFailure:message];
    }
}

/// 播放器状态改变的Message消息回调
- (void)playerController:(PLVPlayerController *)playerController showMessage:(NSString *)message {
    if ([self.view respondsToSelector:@selector(presenter:showMessage:)]) {
        [self.view presenter:self showMessage:message];
   }
}

/// 改变视频所在窗口（主屏或副屏）的底色
- (void)changePlayerScreenBackgroundColor:(PLVPlayerController *)playerController {
    if ([self.view respondsToSelector:@selector(changePlayerScreenBackgroundColor:)]) {
        [self.view changePlayerScreenBackgroundColor:self];
    }
}

#pragma mark SubPlayer

/// 子播放器已准备好开始播放暖场视频
- (void)playerController:(PLVPlayerController *)playerController subPlaybackIsPreparedToPlay:(NSNotification *)notification {
    
}

/// 子播放器已结束播放暖场视频
- (void)playerController:(PLVPlayerController *)playerController subPlayerDidFinish:(NSNotification *)notification {
    
}

#pragma mark MainPlayer

/// 主播放器已准备好开始播放正片
- (void)playerController:(PLVPlayerController *)playerController mainPlaybackIsPreparedToPlay:(NSNotification *)notification {
    CGSize naturalSize = ((PLVIJKFFMoviePlayerController *)notification.object).naturalSize;
    if ([self.view respondsToSelector:@selector(presenter:videoSizeChange:)]) {
        [self.view presenter:self videoSizeChange:naturalSize];
    }
    
    if ([self.view respondsToSelector:@selector(presenter:mainPlaybackIsPreparedToPlay:)]) {
        [self.view presenter:self mainPlaybackIsPreparedToPlay:notification.userInfo];
    }
}

/// 主播放器加载状态有改变
- (void)playerController:(PLVPlayerController *)playerController mainPlayerLoadStateDidChange:(NSNotification *)notification {
    if ([self.view respondsToSelector:@selector(presenter:mainPlayerLoadStateDidChange:)]) {
        [self.view presenter:self mainPlayerLoadStateDidChange:self.viewModel.loadState];
    }
}

/// 主播放器播放播放状态有改变
- (void)playerController:(PLVPlayerController *)playerController mainPlayerPlaybackStateDidChange:(NSNotification *)notification {
    if ([self.view respondsToSelector:@selector(presenter:mainPlayerPlaybackStateDidChange:)]) {
        [self.view presenter:self mainPlayerPlaybackStateDidChange:self.viewModel.playbackState];
    }
}

/// 主播放器已结束播放
- (void)playerController:(PLVPlayerController *)playerController mainPlayerPlaybackDidFinish:(NSNotification *)notification {
    if ([self.view respondsToSelector:@selector(presenter:mainPlayerPlaybackDidFinish:)]) {
        [self.view presenter:self mainPlayerPlaybackDidFinish:notification.userInfo];
    }
}

/// 主播放器Seek完成
- (void)playerController:(PLVPlayerController *)playerController mainPlayerDidSeekComplete:(NSNotification *)notification {
    if ([self.view respondsToSelector:@selector(presenter:mainPlayerDidSeekComplete:)]) {
        [self.view presenter:self mainPlayerDidSeekComplete:notification.userInfo];
    }
}

/// 主播放器精准Seek完成
- (void)playerController:(PLVPlayerController *)playerController mainPlayerAccurateSeekComplete:(NSNotification *)notification {
    if ([self.view respondsToSelector:@selector(presenter:mainPlayerAccurateSeekComplete:)]) {
        [self.view presenter:self mainPlayerAccurateSeekComplete:notification.userInfo];
    }
}

#pragma mark - <PLVVodPlayerControllerDelegate>

/// 点播播放器的播放状态改变，刷新皮肤的总播放时间
- (void)vodPlayerController:(PLVVodPlayerController *)vodPlayer duration:(NSTimeInterval)duration playing:(BOOL)playing {
    self.roomData.duration = duration;
    self.roomData.playing = playing;
    if ([self.view respondsToSelector:@selector(presenter:playing:)]) {
        [self.view presenter:self playing:playing];
    }
}

/// 点播播放器的播放状态改变，刷新皮肤的总播放时间，已加载进度，和已播放进度
- (void)vodPlayerController:(PLVVodPlayerController *)vodPlayer dowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration {
    if (_playbackProgressFlag) {
        self.roomData.playedProgress = playedProgress;
        [self.view updateDowloadProgress:dowloadProgress playedProgress:playedProgress currentPlaybackTime:currentPlaybackTime duration:duration];
    }
}

@end
