//
//  PLVAdvView.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2020/12/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVAdvView.h"
#import <PLVLiveScenesSDK/PLVPlayer.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVFWeakProxy.h>

@interface PLVAdvView ()
<
PLVPlayerDelegate
>

@property (nonatomic, strong) PLVPlayer *advPlayer; // 播放器
@property (nonatomic, strong) UIImageView *advIv; //

@property (nonatomic, strong) UILabel *lbTime; // 倒计时
@property (nonatomic, assign) NSInteger countDownTime; // 倒计时时间

@property (nonatomic, strong) NSTimer *countDownTimer; // 倒计时任务

@end

@implementation PLVAdvView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (CGRectGetWidth(self.bounds) < PLVScreenWidth / 2.0f) { // 广告显示小窗不显示倒计时
        _lbTime.hidden = YES;
        return;
    }
    
    _lbTime.hidden = NO;
    
    // 改变倒计时显示Y位置
    CGRect lbFrame = _lbTime.frame;
    lbFrame.origin.x = PLVScreenWidth + (CGRectGetWidth(self.bounds) - PLVScreenWidth) / 2.0f - 15 - lbFrame.size.width;
    lbFrame.origin.y = 15;
    
    CGFloat selfHeight = CGRectGetHeight(self.bounds);
    
    if (selfHeight >= PLVScreenHeight || PLVScreenHeight - selfHeight < 116) {
        lbFrame.origin.y = [PLVFdUtil isiPhoneXSeries] ? (116 + P_SafeAreaTopEdgeInsets()) : 116;
    }
    _lbTime.frame = lbFrame;
}

#pragma mark - 设置播放器外部容器
- (void)setupDisplaySuperview:(UIView *)displayeSuperview {
    if (! displayeSuperview) {
        return;
    }
    
    if (self.superview) {
        [self removeFromSuperview];
    }
    
    [displayeSuperview addSubview:self];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.frame = displayeSuperview.bounds;
}

#pragma mark - 查找到当前屏幕显示最顶层图层
- (UIView *)getTouchSuperView:(UIView *)superView {
    UIView *resultView, *childView;
    
    for (NSInteger i = superView.subviews.count - 1; i >= 0; i--) {
        childView = superView.subviews[i];
        CGRect rect = [[PLVFdUtil getCurrentViewController].view convertRect:childView.frame fromView:superView];
        /** 此view是否为当前显示View*/
        if (CGRectGetWidth(childView.bounds) == CGRectGetWidth(superView.bounds) &&                    // 宽度和父view宽度一样
            CGRectGetHeight(childView.bounds) >= CGRectGetHeight(superView.bounds) / 2.0f &&           // 高度有父view高度一半以上
            rect.origin.x <= 0 &&                                                                      // 初始坐标在屏幕坐标
            rect.origin.x + rect.size.width >= CGRectGetWidth([UIScreen mainScreen].bounds) / 2.0f) {  // 结束坐标在屏幕中间或右边
            resultView = childView;
            break;
        }
    }
    
    if (resultView) {
        // 继续向子view查找符合要求的屏幕顶层View
        resultView = [self getTouchSuperView:resultView];
    } else {
        resultView = superView;
    }
    
    return resultView;
}

#pragma mark - 展示图片url
- (void)showImageWithUrl:(NSString *)url time:(NSInteger)time {
    if (! [PLVFdUtil checkStringUseable:url]) {
        return;
    }
    
    [self stopCountDown];
    _countDownTime = time;
    
    _advIv = [[UIImageView alloc] init];
    self.advIv.frame = self.bounds;
    self.advIv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.advIv];
    
    __weak typeof(self) weakSelf = self;
    [PLVFdUtil setImageWithURL:[NSURL URLWithString:url]
                   inImageView:self.advIv completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf startCountDown];
        });
    }];
    
    _status = PLVAdvViewStatusPlay;
}

#pragma mark - 播放url
- (void)showVideoWithUrl:(NSString *)url time:(NSInteger)time {
    if (! [PLVFdUtil checkStringUseable:url]) {
        return;
    }
    
    NSURL *videoUrl = [NSURL URLWithString:url];
    [self stopCountDown];
    _countDownTime = time;
    
    /// 设置 播放配置
    PLVOptions *options = [PLVOptions optionsByDefault];
    [options setPlayerOptionIntValue:1 forKey:@"loop"];
    [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:1 forKey:@"enable-accurate-seek"]; // seek到准确位置播放，但可能会引起其他问题
    [options setPlayerOptionIntValue:1 forKey:@"framedrop"];
    [options setFormatOptionIntValue:1 forKey:@"dns_cache_clear"];
    [options setPlayerOptionIntValue:20 * 1024 * 1024 forKey:@"max-buffer-size"];
    
    _advPlayer = [[PLVPlayer alloc] init];
    self.advPlayer.delegate = self;
    [self.advPlayer setupDisplaySuperview:self];
    [self.advPlayer loadMainContentToPlayWithContentURL:videoUrl withOptions:options];
    
    _status = PLVAdvViewStatusPlay;
}

#pragma mark - 是否正在播放中
- (BOOL)playing{
    return self.status == PLVAdvViewStatusPlay;
}

#pragma mark - 销毁 播放器
- (void)distroy {
    [_lbTime removeFromSuperview];
    _lbTime = nil;
    
    [self stopCountDown];
    
    if (self.advPlayer) {
        [self.advPlayer pause];
        
        [self.advPlayer clearMainPlayer];
        self.advPlayer.delegate = nil;
        self.advPlayer = nil;
    }
    
    self.delegate = nil;
    
    [self removeFromSuperview];
}

#pragma mark - 开始倒计时
- (void)startCountDown {
    [self lbTime];
    self.lbTime.text = [NSString stringWithFormat:@" 广告：%lds ", self.countDownTime];
    
    _countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                       target:[PLVFWeakProxy proxyWithTarget:self]
                                                     selector:@selector(changeCountDown:)
                                                     userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
}

- (void)stopCountDown {
    if (self.countDownTimer) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

#pragma mark - 倒计时任务
- (void)changeCountDown:(NSTimer *)timer {
    self.lbTime.text = [NSString stringWithFormat:@"广告：%lds", self.countDownTime];
    
    if (self.countDownTime == 0) {
        [self stopCountDown];
        
        _status = PLVAdvViewStatusFinish;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(advView:status:)]) {
            [self.delegate advView:self status:self.status];
        }
    }
    
    self.countDownTime--;
}

- (UILabel *)lbTime {
    if (! _lbTime) {
        _lbTime = [[UILabel alloc] init];
        _lbTime.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.4];
        _lbTime.layer.cornerRadius = 12;
        _lbTime.frame = CGRectMake(0, 15, 66, 24);
        _lbTime.clipsToBounds = YES;
        _lbTime.font = [UIFont systemFontOfSize:12];
        _lbTime.textColor = [UIColor whiteColor];
        _lbTime.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lbTime];
    }
    return _lbTime;
}

#pragma mark - PLVPlayerDelegate
/// 播放器 ’加载状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerLoadStateDidChange:(PLVPlayerMainSubType)mainSubType {
}

/// 播放器 已准备好播放
- (void)plvPlayer:(PLVPlayer *)player playerIsPreparedToPlay:(PLVPlayerMainSubType)mainSubType {
    // 开始倒计时
    [self startCountDown];
}

/// 播放器 ’播放状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackStateDidChange:(PLVPlayerMainSubType)mainSubType {
}

/// 播放器 播放结束
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackDidFinish:(PLVPlayerMainSubType)mainSubType finishReson:(IJKMPMovieFinishReason)finishReson {
}

@end
