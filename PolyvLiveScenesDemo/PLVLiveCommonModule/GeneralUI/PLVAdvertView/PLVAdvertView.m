//
//  PLVAdvertView.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2020/12/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVAdvertView.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@implementation PLVAdvertParam


@end


@interface PLVAdvertView () <PLVPlayerDelegate>

@property (nonatomic, strong) PLVAdvertParam *param;    // 广告数据模型
#pragma mark 片头广告
@property (nonatomic, assign) NSInteger advertDuration;  // 倒计时时间
@property (nonatomic, strong) PLVPlayer *advertPlayer;  // 广告播放器
@property (nonatomic, strong) NSTimer *countDownTimer;  // 倒计时定时器
@property (nonatomic, strong) UIImageView *advertImageView;  // 广告图片
@property (nonatomic, strong) UILabel *advertDurationLabel;  // 倒计时文本
@property (nonatomic, strong) UITapGestureRecognizer *advertTap;  // 广告点击事件
@property (nonatomic, assign) PLVAdvertViewPlayState playState;  // 片头广告显示状态
#pragma mark 暂停广告
@property (nonatomic, strong) UIImageView *stopAdvertImageView;  // 暂停广告图片

@end

@implementation PLVAdvertView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithParam:(PLVAdvertParam *)param {
    self = [super init];
    if (self) {
        self.param = param;
        self.playState = PLVAdvertViewPlayStateUnKnow;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat selfHeight = CGRectGetHeight(self.bounds);
    CGFloat selfWidth = CGRectGetWidth(self.bounds);
    
    if (selfWidth < PLVScreenWidth / 2.0f) { // 广告显示小窗不显示倒计时
        self.advertDurationLabel.hidden = YES;
        return;
    }
    self.advertDurationLabel.hidden = NO;
    
    CGFloat labelWidth = [self.advertDurationLabel sizeThatFits:CGSizeMake(MAXFLOAT, 24)].width + 15;
    self.advertDurationLabel.frame = CGRectMake(selfWidth - labelWidth - 20, 15, labelWidth, 24);
    
    if (selfHeight > PLVScreenHeight / 2) {
        self.stopAdvertImageView.frame = CGRectMake((selfWidth - PLVScreenWidth) / 2, (selfHeight - selfHeight / 3) / 2, PLVScreenWidth, selfHeight / 3);
    } else {
        self.stopAdvertImageView.frame = self.bounds;
    }
    self.advertImageView.frame = self.bounds;
}

- (void)dealloc {
    NSLog(@"%s",__FUNCTION__);
}

#pragma mark - [ Private ]

- (void)setupUI {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.userInteractionEnabled = NO;
    
    self.backgroundColor = [UIColor blackColor];
    [self addSubview:self.advertImageView];
    [self addSubview:self.advertDurationLabel];
    [self addSubview:self.stopAdvertImageView];
    [self startAdvertAddTapGestureRecognizer];
    [self stopAdvertAddTapGestureRecognizer];
}


- (void)startAdvertAddTapGestureRecognizer {
    if ([PLVFdUtil checkStringUseable:self.param.advertHref]) {
        self.advertTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startAdvertTapAction:)];
        [self addGestureRecognizer:self.advertTap];
        self.userInteractionEnabled = YES;
    }
}

- (void)stopAdvertAddTapGestureRecognizer {
    if ([PLVFdUtil checkStringUseable:self.param.stopAdvertHref]) {
        UITapGestureRecognizer *stopAdvertTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stopAdvertTapAction:)];
        [self.stopAdvertImageView addGestureRecognizer:stopAdvertTap];
        self.userInteractionEnabled = YES;
        self.stopAdvertImageView.userInteractionEnabled = YES;
    }
}

- (void)startCountDownTimer {
    self.countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                           target:[PLVFWeakProxy proxyWithTarget:self]
                                                         selector:@selector(countDownTimerEvent:)
                                                         userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
}

- (void)stopCountDownTimer {
    if (self.countDownTimer) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

- (void)setupAdvertPlayer {
    /// 设置 播放配置
    PLVOptions *options = [PLVOptions optionsByDefault];
    [options setPlayerOptionIntValue:0 forKey:@"loop"];
    [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:1 forKey:@"enable-accurate-seek"]; // seek到准确位置播放，但可能会引起其他问题
    [options setPlayerOptionIntValue:1 forKey:@"framedrop"];
    [options setFormatOptionIntValue:1 forKey:@"dns_cache_clear"];
    [options setPlayerOptionIntValue:20 * 1024 * 1024 forKey:@"max-buffer-size"];
    
    self.advertPlayer = [[PLVPlayer alloc] init];
    self.advertPlayer.delegate = self;
    [self.advertPlayer setupDisplaySuperview:self];
    NSURL *contentURL = [NSURL URLWithString:self.param.advertFlvUrl];
    [self.advertPlayer loadMainContentToPlayWithContentURL:contentURL withOptions:options];
}

- (void)stopAdvert {
    [self stopCountDownTimer];
    
    self.playState = PLVAdvertViewPlayStateFinish;
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvAdvertView:playStateDidChange:)]) {
        [self.delegate plvAdvertView:self playStateDidChange:self.playState];
    }
}

#pragma mark Getter & Setter

- (UILabel *)advertDurationLabel {
    if (!_advertDurationLabel) {
        _advertDurationLabel = [[UILabel alloc] init];
        _advertDurationLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.4];
        _advertDurationLabel.layer.cornerRadius = 12;
        _advertDurationLabel.clipsToBounds = YES;
        _advertDurationLabel.font = [UIFont systemFontOfSize:12];
        _advertDurationLabel.textColor = [UIColor whiteColor];
        _advertDurationLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _advertDurationLabel;
}

- (UIImageView *)advertImageView {
    if (!_advertImageView) {
        _advertImageView = [[UIImageView alloc] init];
        _advertImageView.hidden = YES;
        _advertImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _advertImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _advertImageView;
}

- (UIImageView *)stopAdvertImageView {
    if (!_stopAdvertImageView) {
        _stopAdvertImageView = [[UIImageView alloc] init];
        _stopAdvertImageView.hidden = YES;
        _stopAdvertImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _stopAdvertImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _stopAdvertImageView;
}

#pragma mark - [ Public ]

- (void)setupDisplaySuperview:(UIView *)displaySuperview {
    if (!displaySuperview) {
        return;
    }
    
    if (self.superview) {
        [self removeFromSuperview];
    }
    
    [displaySuperview addSubview:self];
    self.frame = displaySuperview.bounds;
}

- (void)showTitleAdvert {
    if (self.param.advertType == PLVChannelAdvertType_None) {
        return;
    }
    
    if (self.param.advertType == PLVChannelAdvertType_Video) {
        [self setupAdvertPlayer];
    } else if (self.param.advertType == PLVChannelAdvertType_Image) {
        self.advertImageView.hidden = NO;
        __weak typeof(self) weakSelf = self;
        [PLVFdUtil setImageWithURL:[NSURL URLWithString:self.param.advertImageUrl]
                       inImageView:self.advertImageView
                         completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf startCountDownTimer];
            });
        }];
    }
    
    self.advertDuration = self.param.advertDuration;
    self.advertDurationLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"广告：%lds"), self.advertDuration];
    
    self.playState = PLVAdvertViewPlayStatePlay;
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvAdvertView:playStateDidChange:)]) {
        [self.delegate plvAdvertView:self playStateDidChange:self.playState];
    }
}

- (void)showStopAdvertImage {
    if (self.startAdvertIsPlaying || ![PLVFdUtil checkStringUseable:self.param.stopAdvertImageUrl]) {
        return;
    }
    
    self.hidden = NO;
    self.stopAdvertImageView.hidden = NO;
    if (!self.stopAdvertImageView.image) {
        [PLVFdUtil setImageWithURL:[NSURL URLWithString:self.param.stopAdvertImageUrl]
                       inImageView:self.stopAdvertImageView
                         completed:^(UIImage *image, NSError *error, NSURL *imageURL) {}];
    }
}

- (void)destroyTitleAdvert {
    if (self.advertPlayer) {
        [self.advertPlayer clearMainPlayer];
        self.advertPlayer = nil;
    }
    [self stopCountDownTimer];
    [self.advertImageView removeFromSuperview];
    [self.advertDurationLabel removeFromSuperview];
    [self removeGestureRecognizer:self.advertTap];
}

- (void)hideStopAdvertView {
    self.hidden = YES;
    self.stopAdvertImageView.hidden = YES;
}

#pragma mark Getter & Setter
/// 是否正在播放广告中
- (BOOL)startAdvertIsPlaying {
    return self.playState == PLVAdvertViewPlayStatePlay;
}

#pragma mark - [ Delegate ]
#pragma mark PLVPlayerDelegate
/// 播放器 ’加载状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerLoadStateDidChange:(PLVPlayerMainSubType)mainSubType {
}

/// 播放器 已准备好播放
- (void)plvPlayer:(PLVPlayer *)player playerIsPreparedToPlay:(PLVPlayerMainSubType)mainSubType {
    [self startCountDownTimer];
}

/// 播放器 ’播放状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackStateDidChange:(PLVPlayerMainSubType)mainSubType {
}

/// 播放器 播放结束
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackDidFinish:(PLVPlayerMainSubType)mainSubType finishReson:(IJKMPMovieFinishReason)finishReson {
    if (finishReson == IJKMPMovieFinishReasonPlaybackEnded && self.advertDuration > 1) {
        [self.advertPlayer seekToTime:0];
        [self.advertPlayer play];
    } else if (finishReson == IJKMPMovieFinishReasonPlaybackError) {
        /// 暖场视频无法播放 结束暖场
        [self stopAdvert];
    }
}

#pragma mark - [ Event ]
#pragma mark Timer

- (void)countDownTimerEvent:(NSTimer *)timer {
    self.advertDuration--;
    self.advertDurationLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"广告：%lds"), self.advertDuration];
    
    if (self.advertDuration == 0) {
        [self stopAdvert];
    }
}

#pragma mark Action

- (void)startAdvertTapAction:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.startAdvertIsPlaying) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvAdvertView:clickStartAdvertWithHref:)]) {
            [self.delegate plvAdvertView:self clickStartAdvertWithHref:[NSURL URLWithString:self.param.advertHref]];
        }
    }
}

- (void)stopAdvertTapAction:(UITapGestureRecognizer *)gestureRecognizer {
    if (!self.startAdvertIsPlaying) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvAdvertView:clickStopAdvertWithHref:)]) {
            [self.delegate plvAdvertView:self clickStopAdvertWithHref:[NSURL URLWithString:self.param.stopAdvertHref]];
        }
    }
}

@end
