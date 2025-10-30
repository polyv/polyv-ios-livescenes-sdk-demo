//
//  PLVStickerVideoControl.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/8/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerVideoControl.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVSAUtils.h"

@interface PLVStickerVideoControl ()

/// 控制栏容器视图
@property (nonatomic, strong) UIView *controlsContainerView;

/// 删除按钮
@property (nonatomic, strong) UIButton *deleteButton;

/// 快退10秒按钮
@property (nonatomic, strong) UIButton *backwardButton;

/// 播放/暂停按钮
@property (nonatomic, strong) UIButton *playButton;

/// 快进10秒按钮
@property (nonatomic, strong) UIButton *forwardButton;

/// 音量按钮
@property (nonatomic, strong) UIButton *volumeButton;

/// 全屏按钮
@property (nonatomic, strong) UIButton *fullscreenButton;

/// 进度条背景视图
@property (nonatomic, strong) UIView *progressBackgroundView;

/// 进度条
@property (nonatomic, strong) UISlider *progressSlider;

/// 当前时间标签
@property (nonatomic, strong) UILabel *currentTimeLabel;

/// 总时长标签
@property (nonatomic, strong) UILabel *totalTimeLabel;

/// 自动隐藏定时器
@property (nonatomic, strong) NSTimer *autoHideTimer;

@end

@implementation PLVStickerVideoControl

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupInitialState];
        [self setupUI];
    }
    return self;
}

- (void)dealloc {
    [self invalidateAutoHideTimer];
}

#pragma mark - Lazy Loading

- (UIView *)controlsContainerView {
    if (!_controlsContainerView) {
        _controlsContainerView = [[UIView alloc] init];
        _controlsContainerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        _controlsContainerView.layer.cornerRadius = 8;
        _controlsContainerView.layer.masksToBounds = YES;
    }
    return _controlsContainerView;
}

- (UIView *)progressBackgroundView {
    if (!_progressBackgroundView) {
        _progressBackgroundView = [[UIView alloc] init];
        _progressBackgroundView.backgroundColor = [UIColor clearColor];
    }
    return _progressBackgroundView;
}

- (UILabel *)currentTimeLabel {
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.text = @"00:00";
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:12];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel {
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.text = @"00:00";
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:12];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UISlider *)progressSlider {
    if (!_progressSlider) {
        _progressSlider = [[UISlider alloc] init];
        _progressSlider.minimumValue = 0.0;
        _progressSlider.maximumValue = 1.0;
        _progressSlider.value = 0.38; // 32:28 / 1:25:32 ≈ 0.38
        _progressSlider.minimumTrackTintColor = [UIColor whiteColor];
        _progressSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _progressSlider.thumbTintColor = [UIColor whiteColor];
        [_progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_progressSlider addTarget:self action:@selector(progressSliderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _progressSlider;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [self createButtonWithImage:@"plvsa_video_control_del" action:@selector(deleteButtonTapped:)];
    }
    return _deleteButton;
}

- (UIButton *)backwardButton {
    if (!_backwardButton) {
        _backwardButton = [self createButtonWithImage:@"plvsa_video_control_seek_back" action:@selector(backwardButtonTapped:)];
    }
    return _backwardButton;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [self createButtonWithImage:@"plvsa_video_control_play" action:@selector(playButtonTapped:)];
    }
    return _playButton;
}

- (UIButton *)forwardButton {
    if (!_forwardButton) {
        _forwardButton = [self createButtonWithImage:@"plvsa_video_control_seek_forward" action:@selector(forwardButtonTapped:)];
    }
    return _forwardButton;
}

- (UIButton *)volumeButton {
    if (!_volumeButton) {
        _volumeButton = [self createButtonWithImage:@"plvsa_video_control_audio" action:@selector(volumeButtonTapped:)];
    }
    return _volumeButton;
}

- (UIButton *)fullscreenButton {
    if (!_fullscreenButton) {
        _fullscreenButton = [self createButtonWithImage:@"plvsa_video_control_fullscreen" action:@selector(fullscreenButtonTapped:)];
    }
    return _fullscreenButton;
}

#pragma mark - Setup Methods

- (void)setupUI {
    // 创建并添加控制栏容器
    [self addSubview:self.controlsContainerView];
    
    // 创建并添加进度区域组件
    [self.controlsContainerView addSubview:self.progressBackgroundView];
    [self.progressBackgroundView addSubview:self.currentTimeLabel];
    [self.progressBackgroundView addSubview:self.totalTimeLabel];
    [self.progressBackgroundView addSubview:self.progressSlider];
    
    // 创建并添加控制按钮
    [self.controlsContainerView addSubview:self.deleteButton];
    [self.controlsContainerView addSubview:self.backwardButton];
    [self.controlsContainerView addSubview:self.playButton];
    [self.controlsContainerView addSubview:self.forwardButton];
    [self.controlsContainerView addSubview:self.volumeButton];
    [self.controlsContainerView addSubview:self.fullscreenButton];
    
    // 隐藏全屏按钮
    self.fullscreenButton.hidden = YES;
}

#pragma mark - Helper Methods

- (UIButton *)createButtonWithImage:(NSString *)imageText action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    [button setImage:[PLVSAUtils imageForLiveroomResource:imageText] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    // 添加圆形背景
    button.layer.cornerRadius = 22;
    button.layer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
    
    return button;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateFrameLayout];
}

- (void)updateFrameLayout {
    CGFloat containerHeight = 100;
    CGFloat margin = 16;
    CGFloat spacing = 8;
    CGFloat buttonSize = 44;
    
    // 控制栏容器
    self.controlsContainerView.frame = CGRectMake(0, self.bounds.size.height - containerHeight, 
                                                 self.bounds.size.width, containerHeight);
    
    // 进度区域
    CGFloat progressHeight = 30;
    self.progressBackgroundView.frame = CGRectMake(margin, 8, 
                                                  self.controlsContainerView.bounds.size.width - 2 * margin, 
                                                  progressHeight);
    
    // 时间标签
    CGFloat labelWidth = 65;
    self.currentTimeLabel.frame = CGRectMake(0, 0, labelWidth, progressHeight);
    self.totalTimeLabel.frame = CGRectMake(self.progressBackgroundView.bounds.size.width - labelWidth, 0, 
                                         labelWidth, progressHeight);
    
    // 进度条
    CGFloat sliderX = labelWidth + 8;
    CGFloat sliderWidth = self.progressBackgroundView.bounds.size.width - 2 * labelWidth - 16;
    self.progressSlider.frame = CGRectMake(sliderX, (progressHeight - 30) / 2, sliderWidth, 30);
    
    // 控制按钮
    CGFloat buttonY = progressHeight + spacing + 8;
    
    // 删除按钮
    self.deleteButton.frame = CGRectMake(margin, buttonY, buttonSize, buttonSize);
        
    // 播放按钮 (居中)
    CGFloat playButtonX = (self.controlsContainerView.bounds.size.width - buttonSize) / 2;
    self.playButton.frame = CGRectMake(playButtonX, buttonY, buttonSize, buttonSize);
    
    // 快退按钮 (在播放按钮左侧)
    self.backwardButton.frame = CGRectMake(CGRectGetMinX(self.playButton.frame) - spacing - buttonSize, buttonY,
                                         buttonSize, buttonSize);
    
    // 快进按钮 (在播放按钮右侧)
    self.forwardButton.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame) + spacing, buttonY,
                                        buttonSize, buttonSize);
    
    // 音量按钮 (在最右侧，原全屏按钮位置)
    self.volumeButton.frame = CGRectMake(self.controlsContainerView.bounds.size.width - margin - buttonSize, 
                                       buttonY, buttonSize, buttonSize);
    
    // 全屏按钮 (已隐藏，但保留frame设置)
    self.fullscreenButton.frame = CGRectMake(self.controlsContainerView.bounds.size.width - margin - buttonSize, 
                                           buttonY, buttonSize, buttonSize);
}

- (void)setupInitialState {
    self.showsControls = YES;
    self.isPlaying = YES; // 默认播放状态
    self.isMuted = NO;
    self.currentTime = 0; // 
    self.totalTime = 0;   // 
    self.progress = 0;
    
    [self updateUI];
}

#pragma mark - Button Actions

- (void)deleteButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(stickerVideoControlDidTapDeleteButton:)]) {
        [self.delegate stickerVideoControlDidTapDeleteButton:self];
    }
}

- (void)backwardButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(stickerVideoControlDidTapBackwardButton:)]) {
        [self.delegate stickerVideoControlDidTapBackwardButton:self];
    }
    [self resetAutoHideTimer];
}

- (void)playButtonTapped:(UIButton *)sender {
    self.isPlaying = !self.isPlaying;
    [self updatePlayButtonState];
    
    if ([self.delegate respondsToSelector:@selector(stickerVideoControl:didTapPlayButton:)]) {
        [self.delegate stickerVideoControl:self didTapPlayButton:self.isPlaying];
    }
    [self resetAutoHideTimer];
}

- (void)forwardButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(stickerVideoControlDidTapForwardButton:)]) {
        [self.delegate stickerVideoControlDidTapForwardButton:self];
    }
    [self resetAutoHideTimer];
}

- (void)volumeButtonTapped:(UIButton *)sender {
    // 点击音频按钮时调用现有的音量按钮回调
    if ([self.delegate respondsToSelector:@selector(stickerVideoControl:didTapVolumeButton:)]) {
        [self.delegate stickerVideoControl:self didTapVolumeButton:self.isMuted];
    }
    [self resetAutoHideTimer];
}

- (void)fullscreenButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(stickerVideoControlDidTapFullscreenButton:)]) {
        [self.delegate stickerVideoControlDidTapFullscreenButton:self];
    }
    [self resetAutoHideTimer];
}

#pragma mark - Progress Slider Actions

- (void)progressSliderValueChanged:(UISlider *)slider {
    self.progress = slider.value;
    self.currentTime = self.progress * self.totalTime;
    [self updateTimeLabels];
}

- (void)progressSliderTouchUpInside:(UISlider *)slider {
    if ([self.delegate respondsToSelector:@selector(stickerVideoControl:didSeekToProgress:)]) {
        [self.delegate stickerVideoControl:self didSeekToProgress:slider.value];
    }
    [self resetAutoHideTimer];
}

#pragma mark - Public Methods

- (void)showControls {
    self.showsControls = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.controlsContainerView.alpha = 1.0;
    }];
    [self resetAutoHideTimer];
}

- (void)hideControls {
    self.showsControls = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.controlsContainerView.alpha = 0.0;
    }];
    [self invalidateAutoHideTimer];
}

- (void)updatePlayingState:(BOOL)isPlaying {
    self.isPlaying = isPlaying;
    [self updatePlayButtonState];
}

- (void)updateProgress:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    self.currentTime = currentTime;
    self.totalTime = totalTime;
    self.progress = totalTime > 0 ? currentTime / totalTime : 0;
    [self updateUI];
}

#pragma mark - Private Methods

- (void)updateUI {
    [self updatePlayButtonState];
    [self updateVolumeButtonState];
    [self updateProgressSlider];
    [self updateTimeLabels];
}

- (void)updatePlayButtonState {
    NSString *title = self.isPlaying ? @"plvsa_video_control_pause" : @"plvsa_video_control_play";
    UIImage *image = [PLVSAUtils imageForLiveroomResource:title];
    [self.playButton setImage:image forState:UIControlStateNormal];
}

- (void)updateVolumeButtonState {
   
}

- (void)updateProgressSlider {
    self.progressSlider.value = self.progress;
}

- (void)updateTimeLabels {
    self.currentTimeLabel.text = [self formatTime:self.currentTime];
    self.totalTimeLabel.text = [self formatTime:self.totalTime];
}

- (NSString *)formatTime:(NSTimeInterval)timeInterval {
    NSInteger totalSeconds = (NSInteger)timeInterval;
    NSInteger hours = totalSeconds / 3600;
    NSInteger minutes = (totalSeconds % 3600) / 60;
    NSInteger seconds = totalSeconds % 60;
    
    if (hours > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
    } else {
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
}

#pragma mark - Auto Hide Timer

- (void)resetAutoHideTimer {
    [self invalidateAutoHideTimer];
    if (self.showsControls) {
        self.autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                              target:self
                                                            selector:@selector(autoHideControls)
                                                            userInfo:nil
                                                             repeats:NO];
    }
}

- (void)invalidateAutoHideTimer {
    if (self.autoHideTimer) {
        [self.autoHideTimer invalidate];
        self.autoHideTimer = nil;
    }
}

- (void)autoHideControls {
    if (self.isPlaying) {
        [self hideControls];
    }
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (self.showsControls) {
        [self hideControls];
    } else {
        [self showControls];
    }
}

@end
