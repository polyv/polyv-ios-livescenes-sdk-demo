//
//  PLVSAMasterPlaybackSettingSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/2/27.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVSAMasterPlaybackSettingSheet.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

// 工具类
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVProgressSlider.h"

@interface PLVSAMasterPlaybackSettingSheetTipsView : UIView

@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, assign) CGPoint targetPoint;
@property (nonatomic, assign) CGFloat tipWidth;
@property (nonatomic, assign) NSTimeInterval position;

- (void)showWithTargetPoint:(CGPoint)targetPoint currentPosition:(NSTimeInterval)position;
- (void)hide;

@end

@implementation PLVSAMasterPlaybackSettingSheetTipsView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initUI];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self updateUIWithTargetPoint:self.targetPoint];
}

#pragma mark - Initialize

- (void)initUI {
    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
    [self addSubview:self.bubbleView];
    [self.bubbleView addSubview:self.tipLabel];
}

#pragma mark - Public

- (void)updateUIWithTargetPoint:(CGPoint)targetPoint {
    self.targetPoint = targetPoint;
    
    /// 气泡各组件左右边距
    CGFloat xPadding = 12;
    /// 文本相对气泡的上下边距
    CGFloat textYPadding = 9;
    
    CGFloat bubbleWidth = self.tipWidth + 2 * xPadding;
    CGFloat bubbleHeight = 43;
    CGFloat bubbleOriginX = self.targetPoint.x - bubbleWidth / 2;
    CGFloat bubbleOriginY = 0;
    
    
    bubbleOriginY = self.targetPoint.y - bubbleHeight;
    self.bubbleView.frame = CGRectMake(bubbleOriginX, bubbleOriginY, bubbleWidth, bubbleHeight);
    self.tipLabel.frame = CGRectMake(xPadding, textYPadding, self.tipWidth, 14);
    
    if (_shapeLayer.superlayer) {
        [_shapeLayer removeFromSuperlayer];
        _shapeLayer = nil;
    }
    CGFloat midX = bubbleWidth / 2;
    CGFloat maxY = CGRectGetHeight(self.bubbleView.frame);
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, CGRectGetWidth(self.bubbleView.frame), CGRectGetHeight(self.bubbleView.frame) - 5) cornerRadius:4];
    // triangle
    [maskPath moveToPoint:CGPointMake(midX,maxY)];
    [maskPath addLineToPoint:CGPointMake(midX - 5, maxY - 5)];
    [maskPath addLineToPoint:CGPointMake(midX + 5, maxY - 5)];
    [maskPath closePath];
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.7].CGColor;
    shapeLayer.path = maskPath.CGPath;
    _shapeLayer = shapeLayer;
    [self.bubbleView.layer insertSublayer:_shapeLayer atIndex:0];
}

- (void)showWithTargetPoint:(CGPoint)targetPoint currentPosition:(NSTimeInterval)position {
    self.position = position;
    NSInteger time = position;
    NSInteger hour = time / 3600;
    NSInteger min = (time / 60) % 60;
    NSInteger sec = time % 60;
    NSString *str = hour > 0 ? [NSString stringWithFormat:@"%02zd时", hour] : @"";
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%02zd分%02zd秒", min, sec]];
    NSString *tips = [NSString stringWithFormat:@"从%@开始播放", str];
    self.tipLabel.text = tips;
    self.tipWidth = [self.tipLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 14)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:@{NSFontAttributeName : self.tipLabel.font}
                                                           context:nil].size.width;
    [self updateUIWithTargetPoint:targetPoint];
    self.hidden = NO;
}

- (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = YES;
    });
}

#pragma mark - Loadlazy

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.text = @"从00分00秒开始播放";
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    }
    return _tipLabel;
}

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc]init];
        _bubbleView.backgroundColor = [UIColor clearColor];
    }
    return _bubbleView;
}

@end

@interface PLVSAMasterPlaybackSettingSheet()<
PLVProgressSliderDelegate,
PLVPlayerDelegate>

#pragma mark UI
@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIScrollView *scrollView; // 详情页滚动视图
@property (nonatomic, strong) UILabel *topTipLabel; // 顶部提示

@property (nonatomic, strong) UIView *playerPlaceholderView; // 播放器占位图
@property (nonatomic, strong) UIView *playerDisplayerView; // 播放器展示视图
@property (nonatomic, strong) UILabel *currentTimeLabel; // 回放视频当前时间
@property (nonatomic, strong) UILabel *durationLabel; // 回放视频总时长
@property (nonatomic, strong) PLVProgressSlider *progressSlider; // 进度条
@property (nonatomic, strong) PLVSAMasterPlaybackSettingSheetTipsView *tipsView; // 滑动提示页

@property (nonatomic, strong) UILabel *bottomTipLabel; // 底部提示
@property (nonatomic, strong) UIButton *saveButton; // 保存按钮

#pragma mark 对象
@property (nonatomic, strong) PLVPlayer *previewPlayer; // 预览播放器
@property (nonatomic, strong) NSTimer *progressTimer; // 进度定时器

#pragma mark 数据
@property (nonatomic, copy) NSString *previewUrl; // 预览视频url
@property (nonatomic, assign) NSTimeInterval startPosition; // 预览视频起播时间
@property (nonatomic, assign) BOOL didShow;

@end

@implementation PLVSAMasterPlaybackSettingSheet

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    [self.previewPlayer clearAllPlayer];
    _previewPlayer = nil;
    if (_progressTimer) {
        [_progressTimer invalidate];
        _progressTimer = nil;
    }
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth backgroundColor:nil showEffectView:NO];
    if (self) {
        [self initUI];
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(progressTimerEvent:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
        [self.previewPlayer setupDisplaySuperview:self.playerDisplayerView];
        self.startPosition = 0;
    }
    return self;
}

- (void)initUI {
    [self.contentView addSubview:self.sheetTitleLabel];
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    [self.scrollView addSubview:self.topTipLabel];
    [self.scrollView addSubview:self.playerPlaceholderView];
    
    [self.playerPlaceholderView addSubview:self.playerDisplayerView];
    [self.playerDisplayerView addSubview:self.currentTimeLabel];
    [self.playerDisplayerView addSubview:self.progressSlider];
    [self.playerDisplayerView addSubview:self.durationLabel];
    [self.playerPlaceholderView addSubview:self.tipsView];
    
    [self.scrollView addSubview:self.bottomTipLabel];
    [self.contentView addSubview:self.scrollView];
    [self.contentView addSubview:self.saveButton];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    CGFloat left = isPad ? 56 : 24;
    CGFloat contentWidth = self.contentView.frame.size.width;
    CGFloat contentHeight = self.contentView.frame.size.height;
    CGFloat bottom = isLandscape ? 0 : P_SafeAreaBottomEdgeInsets();
    
    self.sheetTitleLabel.frame = CGRectMake(0, 20, contentWidth, 18);
    self.saveButton.frame = CGRectMake(32, contentHeight - 36 - 12 - bottom, contentWidth - 64, 36);
    self.scrollView.frame = CGRectMake(0, CGRectGetMaxY(self.sheetTitleLabel.frame) + 20, contentWidth, CGRectGetMinY(self.saveButton.frame) - CGRectGetMaxY(self.sheetTitleLabel.frame) - 32);
    
    CGFloat playerDisplayViewWidth = contentWidth - left * 2;
    CGFloat playerDisplayViewHeight = (contentWidth - left * 2) * 9 / 16;

    CGRect boundingRect = [self.bottomTipLabel.text boundingRectWithSize:CGSizeMake(playerDisplayViewWidth, CGFLOAT_MAX)
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{NSFontAttributeName : self.bottomTipLabel.font}
                                                                 context:nil];

    CGFloat bottomTextViewHeight = CGRectGetHeight(boundingRect);
    
    self.scrollView.contentSize = CGSizeMake(contentWidth, playerDisplayViewHeight + bottomTextViewHeight + 12 * 3);
    
    self.topTipLabel.frame = CGRectMake(left, 0, contentWidth - left, 12);
    self.playerPlaceholderView.frame = CGRectMake(0, CGRectGetMaxY(self.topTipLabel.frame) + 12, contentWidth, playerDisplayViewHeight);
    self.tipsView.frame = self.playerPlaceholderView.bounds;
    self.playerDisplayerView.frame = CGRectMake(left, 0, playerDisplayViewWidth, playerDisplayViewHeight);
    self.currentTimeLabel.frame = CGRectMake(20, playerDisplayViewHeight - 31, 42, 14);
    self.durationLabel.frame = CGRectMake(playerDisplayViewWidth - 20 - 42, CGRectGetMinY(self.currentTimeLabel.frame), 42, 14);
    self.progressSlider.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame) + 13, CGRectGetMinY(self.currentTimeLabel.frame), CGRectGetMinX(self.durationLabel.frame) - 26 - CGRectGetMaxX(self.currentTimeLabel.frame), 14);
    self.bottomTipLabel.frame = CGRectMake(left, CGRectGetMaxY(self.playerPlaceholderView.frame) + 12, playerDisplayViewWidth, bottomTextViewHeight);
}

- (void)showInView:(UIView *)parentView {
    if (!self.didShow) {
        if (!_progressTimer) {
            self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(progressTimerEvent:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
        }
        
        [self.previewPlayer clearAllPlayer];
        if ([PLVFdUtil checkStringUseable:self.previewUrl]) {
            PLVOptions *options = [PLVOptions optionsByDefault];
            [options setPlayerOptionIntValue:1 forKey:@"loop"];
            [options setPlayerOptionIntValue:0 forKey:@"videotoolbox"];
            [options setPlayerOptionIntValue:0 forKey:@"enable-accurate-seek"];
            [options setPlayerOptionIntValue:1 forKey:@"framedrop"];
            [options setFormatOptionIntValue:1 forKey:@"dns_cache_clear"];
//            [options setFormatOptionIntValue:0 forKey:@"start-on-prepared"];
            [options setFormatOptionIntValue:1 forKey:@"render-on-prepared"];
            [options setPlayerOptionIntValue:20 * 1024 * 1024 forKey:@"max-buffer-size"];
            NSURL *url = [NSURL URLWithString:self.previewUrl];
            [self.previewPlayer loadMainContentToPlayWithContentURL:url withOptions:options];
        }
        self.didShow = YES;
    }

    [super showInView:parentView];
}

- (void)dismiss {
    [self.previewPlayer seekToTime:self.startPosition];
    [super dismiss];
}

#pragma mark - [ Public Method ]

- (void)setupPreviewUrl:(NSString *)previewUrl startPosition:(NSTimeInterval)startPosition {
    if ([PLVFdUtil checkStringUseable:previewUrl]) {
        self.previewUrl = [PLVFdUtil packageURLStringWithHTTPS:previewUrl];
    }
    if (startPosition > 0) {
        self.startPosition = startPosition;
    }
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _sheetTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _sheetTitleLabel.text = PLVLocalizedString(@"母流播放时间设置");
        _sheetTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _sheetTitleLabel;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.alwaysBounceVertical = YES;
    }
    return _scrollView;
}

- (UILabel *)topTipLabel {
    if (!_topTipLabel) {
        _topTipLabel = [[UILabel alloc] init];
        _topTipLabel.textColor = [PLVColorUtil colorFromHexString:@"#999999"];
        _topTipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _topTipLabel.text = PLVLocalizedString(@"拖动进度条可设置母流开始播放时间");
        _topTipLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _topTipLabel;
}

- (UIView *)playerPlaceholderView {
    if (!_playerPlaceholderView) {
        _playerPlaceholderView = [[UIView alloc] init];
    }
    return _playerPlaceholderView;
}

- (UIView *)playerDisplayerView {
    if (!_playerDisplayerView) {
        _playerDisplayerView = [[UIView alloc] init];
        _playerDisplayerView.backgroundColor = [UIColor blackColor];
    }
    return _playerDisplayerView;
}

- (UILabel *)currentTimeLabel{
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.text = @"00:00:00";
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:10];
    }
    return _currentTimeLabel;
}

- (UILabel *)durationLabel{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.text = @"00:00:00";
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:10];
    }
    return _durationLabel;
}

- (PLVProgressSlider *)progressSlider{
    if (!_progressSlider) {
        _progressSlider = [[PLVProgressSlider alloc] init];
        _progressSlider.delegate = self;
        _progressSlider.userInteractionEnabled = NO;
        _progressSlider.slider.minimumTrackTintColor = PLV_UIColorFromRGB(@"6DA7FF");
        [_progressSlider.slider setThumbImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_media_skin_slider_thumbimage"] forState:UIControlStateNormal];
    }
    return _progressSlider;
}

- (PLVSAMasterPlaybackSettingSheetTipsView *)tipsView {
    if (!_tipsView) {
        _tipsView = [[PLVSAMasterPlaybackSettingSheetTipsView alloc] init];
    }
    return _tipsView;
}

- (UILabel *)bottomTipLabel {
    if (!_bottomTipLabel) {
        _bottomTipLabel = [[UILabel alloc] init];
        _bottomTipLabel.textColor = [PLVColorUtil colorFromHexString:@"#999999"];
        _bottomTipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _bottomTipLabel.text = PLVLocalizedString(@"温馨提示：\n1、母流默认从00:00播放，可手动拖动进度条，更改开始播放的时间；\n2、开播后，需要手动触发，母流才会进行播放。");
        _bottomTipLabel.textAlignment = NSTextAlignmentLeft;
        _bottomTipLabel.numberOfLines = 0;
        _bottomTipLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return _bottomTipLabel;
}

- (UIButton *)saveButton {
    if (!_saveButton) {
        _saveButton = [[UIButton alloc] init];
        [_saveButton setTitle:PLVLocalizedString(@"保存") forState:UIControlStateNormal];
        [_saveButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFFFF"] forState:UIControlStateNormal];
        _saveButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _saveButton.layer.cornerRadius = 18;
        _saveButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
        [_saveButton addTarget:self action:@selector(saveButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveButton;
}

- (PLVPlayer *)previewPlayer {
    if (!_previewPlayer) {
        _previewPlayer = [[PLVPlayer alloc] init];
        _previewPlayer.delegate = self;
    }
    return _previewPlayer;
}

#pragma mark - [ Action ]

- (void)saveButtonAction {
    self.startPosition = self.previewPlayer.currentPlaybackTime;
    [super dismiss];
    if (self.delegate && [self.delegate respondsToSelector:@selector(masterPlaybackSettingSheet:didChangedStartPosition:)]) {
        [self.delegate masterPlaybackSettingSheet:self didChangedStartPosition:self.startPosition];
    }
}

#pragma mark - [ Event ]

#pragma mark Timer

- (void)progressTimerEvent:(NSTimer *)timer {
    self.durationLabel.text = [PLVFdUtil secondsToString2:self.previewPlayer.duration];
    self.currentTimeLabel.text = [PLVFdUtil secondsToString2:self.previewPlayer.currentPlaybackTime];
    if (self.previewPlayer.duration > 0) {
        [self.progressSlider setProgressWithCachedProgress:self.previewPlayer.videoCacheDuration / self.previewPlayer.duration playedProgress:self.previewPlayer.currentPlaybackTime / self.previewPlayer.duration];
        self.progressSlider.userInteractionEnabled = YES;
    } else {
        [self.progressSlider setProgressWithCachedProgress:0 playedProgress:0];
        self.progressSlider.userInteractionEnabled = NO;
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVProgressSlider

- (void)plvProgressSlider:(nonnull PLVProgressSlider *)progressSlider sliderDragEnd:(CGFloat)currentSliderProgress {
    if (self.previewPlayer.duration > 0) {
        [self.previewPlayer seekToTime:currentSliderProgress * self.previewPlayer.duration];
    }
    [self.tipsView hide];
}

- (void)plvProgressSlider:(nonnull PLVProgressSlider *)progressSlider sliderDragingProgressChange:(CGFloat)currentSliderProgress {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat left = isPad ? 56 : 24;
    if (self.previewPlayer.duration > 0) {
        [self.tipsView showWithTargetPoint:CGPointMake(currentSliderProgress * CGRectGetWidth(self.progressSlider.frame) + CGRectGetMinX(self.progressSlider.frame) + left, CGRectGetMinY(self.progressSlider.frame) - 16) currentPosition:currentSliderProgress * self.previewPlayer.duration];
    } else {
        [self.tipsView hide];
    }
}

#pragma mark PLVPlayerDelegate

/// 播放器 ’加载状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerLoadStateDidChange:(PLVPlayerMainSubType)mainSubType {

}

/// 播放器 已准备好播放
- (void)plvPlayer:(PLVPlayer *)player playerIsPreparedToPlay:(PLVPlayerMainSubType)mainSubType {
    if (self.startPosition >= self.previewPlayer.duration) {
        self.startPosition = 0;
    }
    [self.previewPlayer seekToTime:self.startPosition];
    [self.previewPlayer pause];
}

/// 播放器 ’播放状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackStateDidChange:(PLVPlayerMainSubType)mainSubType {

}

/// 播放器 播放结束
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackDidFinish:(PLVPlayerMainSubType)mainSubType finishReson:(IJKMPMovieFinishReason)finishReson {

}

@end
