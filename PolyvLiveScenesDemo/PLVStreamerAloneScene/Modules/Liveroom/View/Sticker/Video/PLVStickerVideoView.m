//
//  PLVStickerVideoView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/8/14.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerVideoView.h"
#import "PLVStickerPlayer.h"
#import "PLVStickerVideoControl.h"
#import "PLVStickerAudioSet.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVStickerVideoView ()<
PLVStickerPlayerDelegate,
PLVStickerVideoControlDelegate,
PLVStickerAudioSetDelegate
>

/// 播放器
@property (nonatomic, strong) PLVStickerPlayer *player;

/// 内容视图（包含播放器视图）
@property (nonatomic, strong) UIView *contentView;

/// 边框层
@property (nonatomic, strong) CAShapeLayer *shapeLayer;

/// Done按钮
@property (nonatomic, strong) UIButton *doneButton;

/// 视频控制组件
@property (nonatomic, strong) PLVStickerVideoControl *videoControl;

/// 音频设置组件
@property (nonatomic, strong) PLVStickerAudioSet *audioSet;

/// 手势控制开关
@property (nonatomic, assign) BOOL enablePinchGesture;
@property (nonatomic, assign) BOOL enablePanGesture;

/// 移动区域限制
@property (nonatomic, assign) UIEdgeInsets moveEdgeInserts;
@property (nonatomic, assign) CGRect moveableRect;

/// 默认的最大宽度
@property (nonatomic, assign) CGFloat defaultMaxWidth;
/// 默认的最大高度
@property (nonatomic, assign) CGFloat defaultMaxHeight;
/// 视频尺寸
@property (nonatomic, assign) CGSize videoSize;

@end

@implementation PLVStickerVideoView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _videoURL = videoURL;
        _stickerMinScale = 0.1;
        _stickerMaxScale = 10;
        _enablePinchGesture = YES;
        _enablePanGesture = YES;
        _autoPlay = NO;
        _muted = YES;
        _videoVolume = 1.0;
        _microphoneVolume = 0.0;
        self.clipsToBounds = YES;
        
        // 设置默认的安全边距
        _moveEdgeInserts = UIEdgeInsetsMake(30, 20, 30, 20);
        
        [self setupContentViewWithFrame:frame];
        [self setupPlayer];
        [self initShapeLayer];
        [self setupVideoControl];
        [self setupConfig];
        [self attachGestures];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateMoveableRect];
    [self updateDoneButtonPosition];
}

- (void)dealloc {
    [self cleanup];
}

#pragma mark - Setup Methods

- (void)setupContentViewWithFrame:(CGRect)frame {
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.contentView.backgroundColor = [UIColor blackColor];
    self.contentView.clipsToBounds = YES;
    [self addSubview:self.contentView];
}

- (void)setupPlayer {
    if (!self.videoURL) {
        return;
    }
    
    self.player = [[PLVStickerPlayer alloc] initWithURL:self.videoURL];
    self.player.delegate = self;
    [self.player setupVolume:self.microphoneVolume];
    
    if (self.player.playerView) {
        self.player.playerView.frame = self.contentView.bounds;
        self.player.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.player.playerView];
    }
    
    if (self.autoPlay) {
        [self.player play];
    }
}

- (void)initShapeLayer {
    self.shapeLayer = [CAShapeLayer layer];
    CGRect shapeRect = self.contentView.frame;
    self.shapeLayer.bounds = shapeRect;
    self.shapeLayer.position = CGPointMake(self.contentView.frame.size.width / 2, self.contentView.frame.size.height / 2);
    self.shapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.shapeLayer.lineWidth = 2.0;
    self.shapeLayer.lineJoin = kCALineJoinRound;
    self.shapeLayer.allowsEdgeAntialiasing = YES;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, shapeRect);
    self.shapeLayer.path = path;
    CGPathRelease(path);
}

- (void)setupVideoControl {
    self.videoControl = [[PLVStickerVideoControl alloc] initWithFrame:CGRectZero];
    self.videoControl.delegate = self;
    
    // 初始状态隐藏控制栏
    [self.videoControl hideControls];
}

- (void)setupConfig {
    self.exclusiveTouch = YES;
    self.userInteractionEnabled = YES;
    self.contentView.userInteractionEnabled = YES;
    self.enabledControl = YES;
    self.enabledShakeAnimation = YES;
    self.enabledBorder = YES;
}

- (void)attachGestures {
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleScale:)];
    pinchGesture.delegate = self;
    [self.contentView addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMove:)];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 2;
    panGesture.delegate = self;
    [self.contentView addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.delegate = self;
    [self.contentView addGestureRecognizer:tapGesture];
}

#pragma mark - Lazy Loading

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneButton.frame = CGRectMake(0, 0, 24, 24);
        [_doneButton setTitle:@"✓" forState:UIControlStateNormal];
        [_doneButton setTitleColor:[PLVColorUtil colorFromHexString:@"#1D2129" alpha:1.0] forState:UIControlStateNormal];
        _doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        _doneButton.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        _doneButton.layer.cornerRadius = 12;
        _doneButton.layer.masksToBounds = YES;
        _doneButton.layer.borderWidth = 1;
        _doneButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [_doneButton addTarget:self action:@selector(handleDoneButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        
        // 初始状态隐藏
        _doneButton.hidden = YES;
        _doneButton.userInteractionEnabled = YES;
        
        // 添加到父视图而不是当前视图，避免受到 transform 影响
        if (self.superview) {
            [self.superview addSubview:_doneButton];
            [self.superview bringSubviewToFront:_doneButton];
        }
    }
    return _doneButton;
}

#pragma mark - Gesture Handlers

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (!self.delegate) {
        return;
    }
    
    [self handleTapContentView];
}

- (void)handleTapContentView {
    [self.superview bringSubviewToFront:self];
    
    // 确保按钮仍然在最上层
    if (self.doneButton && !self.doneButton.hidden) {
        [self.superview bringSubviewToFront:self.doneButton];
    }
    
    // 切换控制栏显示状态
    if (self.videoControl.showsControls) {
        [self.videoControl hideControls];
        [self.videoControl removeFromSuperview];
    } else {
        [self showVideoControlAtParentBottom];
    }
    
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoViewDidTapContentView:)]) {
        [self.delegate plv_StickerVideoViewDidTapContentView:self];
    }
}

- (void)showVideoControlAtParentBottom {
    if (!self.superview) return;
    
    // 从当前父视图移除（如果存在）
    [self.videoControl removeFromSuperview];
    
    // 添加到父组件
    [self.superview addSubview:self.videoControl];
    
    // 设置控制栏位置在父组件底部
    CGFloat controlHeight = 120;
    CGFloat safeBottomMargin = 0; // 底部安全区域
    CGRect parentBounds = self.superview.bounds;
    
    self.videoControl.frame = CGRectMake(0, 
                                        parentBounds.size.height - controlHeight - safeBottomMargin,
                                        parentBounds.size.width, 
                                        controlHeight);
    
    // 显示控制栏
    [self.videoControl showControls];
    
    // 确保控制栏在最上层
    [self.superview bringSubviewToFront:self.videoControl];
}

- (void)handleMove:(UIPanGestureRecognizer *)gesture {
    if (!self.enablePanGesture) return;
    
    CGPoint translation = [gesture translationInView:self.superview];
    
    // 计算新位置
    CGPoint newCenter = CGPointMake(self.center.x + translation.x,
                                  self.center.y + translation.y);
    
    // 限制在安全范围内
    CGPoint limitedPoint = [self limitPointInBounds:CGPointMake(newCenter.x - self.frame.size.width/2,
                                                              newCenter.y - self.frame.size.height/2)];
    self.center = CGPointMake(limitedPoint.x + self.frame.size.width/2,
                             limitedPoint.y + self.frame.size.height/2);
    
    // 重置手势的位移
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    // 实时更新按钮位置
    [self updateDoneButtonPosition];
    
    CGPoint touchPoint = [gesture locationInView:self.superview.superview];
    BOOL isEnded = gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateCancelled;
   
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoViewHandleMove:point:gestureEnded:)]) {
        [self.delegate plv_StickerVideoViewHandleMove:self point:touchPoint gestureEnded:isEnded];
    }
}

- (void)handleScale:(UIPinchGestureRecognizer *)gesture {
    if (!self.enablePinchGesture) return;
    
    CGFloat scale = gesture.scale;
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.transform = CGAffineTransformScale(self.transform, scale, scale);
        gesture.scale = 1.0;
        
        [self updateDoneButtonPosition];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || 
             gesture.state == UIGestureRecognizerStateCancelled) {
        
        self.transform = CGAffineTransformScale(self.transform, scale, scale);
        gesture.scale = 1.0;
        
        [self adjustAfterScaleGestureEnded];
    }
}

- (void)adjustAfterScaleGestureEnded {
    CGRect parentBounds = self.superview.bounds;
    CGRect currentFrame = self.frame;
    
    BOOL exceedsWidth = currentFrame.size.width > parentBounds.size.width;
    BOOL exceedsHeight = currentFrame.size.height > parentBounds.size.height;
    
    if (exceedsWidth || exceedsHeight) {
        CGFloat scaleToFitWidth = parentBounds.size.width / currentFrame.size.width;
        CGFloat scaleToFitHeight = parentBounds.size.height / currentFrame.size.height;
        
        CGFloat targetScale = MIN(scaleToFitWidth, scaleToFitHeight);
        targetScale += 0.01;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformScale(self.transform, targetScale, targetScale);
        } completion:^(BOOL finished) {
            [self adjustPositionToFitBounds];
            [self updateDoneButtonPosition];
        }];
    } else {
        [self adjustPositionToFitBounds];
    }
}

- (void)adjustPositionToFitBounds {
    CGRect parentBounds = self.superview.bounds;
    CGRect currentFrame = self.frame;
    
    CGPoint newCenter = self.center;
    BOOL needsAdjustment = NO;
    
    if (currentFrame.origin.x < 0) {
        newCenter.x = currentFrame.size.width / 2;
        needsAdjustment = YES;
    } else if (currentFrame.origin.x + currentFrame.size.width > parentBounds.size.width) {
        newCenter.x = parentBounds.size.width - currentFrame.size.width / 2;
        needsAdjustment = YES;
    }
    
    if (currentFrame.origin.y < 0) {
        newCenter.y = currentFrame.size.height / 2;
        needsAdjustment = YES;
    } else if (currentFrame.origin.y + currentFrame.size.height > parentBounds.size.height) {
        newCenter.y = parentBounds.size.height - currentFrame.size.height / 2;
        needsAdjustment = YES;
    }
    
    if (needsAdjustment) {
        [UIView animateWithDuration:0.3 
                              delay:0 
                            options:UIViewAnimationOptionCurveEaseOut 
                         animations:^{
            self.center = newCenter;
        } completion:^(BOOL finished) {
            [self updateDoneButtonPosition];
        }];
    }
}

#pragma mark - Button Event Handlers

- (void)handleDoneButtonTap:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoViewDidTapDoneButton:)]) {
        [self.delegate plv_StickerVideoViewDidTapDoneButton:self];
    }
}

#pragma mark - Button Position Updates

- (void)updateDoneButtonPosition {
    if (self.doneButton && !self.doneButton.hidden && self.superview) {
        CGRect transformedBounds = CGRectApplyAffineTransform(self.bounds, self.transform);
        
        CGPoint rightTopCorner = CGPointMake(self.center.x + transformedBounds.size.width / 2,
                                           self.center.y - transformedBounds.size.height / 2);
        
        CGFloat buttonSize = 24;
        CGFloat margin = 5;
        
        self.doneButton.frame = CGRectMake(rightTopCorner.x - buttonSize - margin,
                                          rightTopCorner.y + margin,
                                          buttonSize,
                                          buttonSize);
        
        [self.superview bringSubviewToFront:self.doneButton];
    }
}

#pragma mark - Public Methods

- (void)performTapOperation {
    [self handleTapContentView];
}

- (void)play {
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)stop {
    [self.player stop];
}

- (void)seekToTime:(NSTimeInterval)time {
    [self.player seekToTime:time];
}

- (void)hideVideoControl {
    if (self.videoControl && self.videoControl.showsControls) {
        [self.videoControl hideControls];
        [self.videoControl removeFromSuperview];
    }
}

#pragma mark - Property Setters

- (void)setEnabledControl:(BOOL)enabledControl {
    _enabledControl = enabledControl;
}

- (void)setEnabledBorder:(BOOL)enabledBorder {
    _enabledBorder = enabledBorder;
    if (enabledBorder) {
        [self.contentView.layer addSublayer:self.shapeLayer];
        
        // 显示Done按钮
        if (self.doneButton.superview != self.superview && self.superview) {
            [self.doneButton removeFromSuperview];
            [self.superview addSubview:self.doneButton];
        }
        self.doneButton.hidden = NO;
        [self updateDoneButtonPosition];
        [self.superview bringSubviewToFront:self.doneButton];
    } else {
        [self.shapeLayer removeFromSuperlayer];
        self.doneButton.hidden = YES;
    }
}

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    [self setupPlayer];
}

- (void)setEnableEdit:(BOOL)enableEdit {
    _enablePanGesture = enableEdit;
    _enablePinchGesture = enableEdit;
    [self setEnabledControl:enableEdit];
}

- (void)setAutoPlay:(BOOL)autoPlay {
    _autoPlay = autoPlay;
    if (autoPlay && self.player) {
        [self.player play];
    }
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    // 这里可以设置播放器的静音状态
    // self.player.muted = muted;
}

- (void)setVideoVolume:(CGFloat)videoVolume {
    _videoVolume = videoVolume;
    // 同步到音频设置组件
    if (self.audioSet) {
        self.audioSet.videoVolume = videoVolume;
    }
    // 这里可以设置播放器的音量
    // self.player.volume = videoVolume;
}

- (void)setMicrophoneVolume:(CGFloat)microphoneVolume {
    _microphoneVolume = microphoneVolume;
    // 同步到音频设置组件
    if (self.audioSet) {
        self.audioSet.microphoneVolume = microphoneVolume;
    }
    // 这里可以设置麦克风的音量
}

#pragma mark - Helper Methods

- (void)updateMoveableRect {
    CGRect parentBounds = self.superview.bounds;
    BOOL fullscreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullscreen) {
        self.moveEdgeInserts = UIEdgeInsetsMake(0, 0, 0, 0);
    } else {
        self.moveEdgeInserts = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    self.moveableRect = CGRectMake(self.moveEdgeInserts.left,
                                  self.moveEdgeInserts.top,
                                  parentBounds.size.width - self.moveEdgeInserts.left - self.moveEdgeInserts.right,
                                  parentBounds.size.height - self.moveEdgeInserts.top - self.moveEdgeInserts.bottom);
}

- (CGPoint)limitPointInBounds:(CGPoint)point {
    CGSize size = self.frame.size;
    
    CGFloat minX = self.moveableRect.origin.x;
    CGFloat maxX = CGRectGetMaxX(self.moveableRect) - size.width;
    CGFloat minY = self.moveableRect.origin.y;
    CGFloat maxY = CGRectGetMaxY(self.moveableRect) - size.height;
    
    point.x = MAX(minX, MIN(maxX, point.x));
    point.y = MAX(minY, MIN(maxY, point.y));
    
    return point;
}

- (void)performShakeAnimation:(UIView *)targetView {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    animation.values = @[@(-0.1), @(0.1), @(-0.1)];
    animation.duration = 0.25;
    animation.repeatCount = 1;
    [targetView.layer addAnimation:animation forKey:@"shakeAnimation"];
}

/// 根据视频尺寸调整视图大小
/// @param videoSize 视频原始尺寸
- (void)adjustViewSizeWithVideoSize:(CGSize)videoSize {
    _videoSize = videoSize;

    self.defaultMaxWidth = self.superview.bounds.size.width;
    self.defaultMaxHeight = self.superview.bounds.size.height;
    
    // 计算视频的宽高比
    CGFloat videoAspectRatio = videoSize.width / videoSize.height;
    
    CGFloat newWidth, newHeight;
    
    // 判断视频是横向还是纵向
    if (videoAspectRatio > 1.0) {
        // 横向视频（宽度 > 高度）：铺满宽度
        newWidth = self.defaultMaxWidth;
        newHeight = newWidth / videoAspectRatio;
        
        // 如果计算出的高度超过最大高度，则改为铺满高度
        if (newHeight > self.defaultMaxHeight) {
            newHeight = self.defaultMaxHeight;
            newWidth = newHeight * videoAspectRatio;
        }
    } else {
        // 纵向视频（高度 >= 宽度）：铺满高度
        newHeight = self.defaultMaxHeight;
        newWidth = newHeight * videoAspectRatio;
        
        // 如果计算出的宽度超过最大宽度，则改为铺满宽度
        if (newWidth > self.defaultMaxWidth) {
            newWidth = self.defaultMaxWidth;
            newHeight = newWidth / videoAspectRatio;
        }
    }
    
    // 计算新的中心点（保持在父视图中心）
    CGPoint newCenter = CGPointZero;
    if (self.superview) {
        newCenter = CGPointMake(self.superview.bounds.size.width / 2.0,
                               self.superview.bounds.size.height / 2.0);
    } else {
        newCenter = self.center;
    }
    
    NSLog(@"PLVStickerVideoView: Adjusting size - Video: %@, AspectRatio: %.2f, New size: %.0fx%.0f", 
          NSStringFromCGSize(videoSize), videoAspectRatio, newWidth, newHeight);
    
    // 直接调整大小（不使用动画）
    self.bounds = CGRectMake(0, 0, newWidth, newHeight);
    self.center = newCenter;
    
    // 更新内容视图的frame
    self.contentView.frame = self.bounds;
    
    // 更新边框层
    self.shapeLayer.bounds = self.bounds;
    self.shapeLayer.position = CGPointMake(newWidth / 2, newHeight / 2);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    self.shapeLayer.path = path;
    CGPathRelease(path);
    
    // 调整完成后更新可移动区域和按钮位置
    [self updateMoveableRect];
    [self updateDoneButtonPosition];
}

- (void)resetRect {
    [self adjustViewSizeWithVideoSize:self.videoSize];
}

- (void)cleanup {
    if (self.doneButton) {
        [self.doneButton removeFromSuperview];
        self.doneButton = nil;
    }
    
    if (self.videoControl) {
        [self.videoControl removeFromSuperview];
        self.videoControl = nil;
    }
    
    if (self.audioSet) {
        [self.audioSet dismiss];
        self.audioSet = nil;
    }
    
    if (self.player) {
        [self.player destroy];
        self.player = nil;
    }
}

#pragma mark - PLVStickerPlayerDelegate

- (void)stickerPlayer:(PLVStickerPlayer *)player didChangeState:(PLVStickerPlayerState)state {
    switch (state) {
        case PLVStickerPlayerStatePlaying:
            [self.videoControl updatePlayingState:YES];
            break;
        case PLVStickerPlayerStatePaused:
        case PLVStickerPlayerStateStopped:
        case PLVStickerPlayerStateCompleted:
            [self.videoControl updatePlayingState:NO];
            break;
        default:
            break;
    }
}

- (void)stickerPlayer:(PLVStickerPlayer *)player didUpdateProgress:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    // 更新控制组件的进度
    [self.videoControl updateProgress:currentTime totalTime:totalTime];
}

- (void)stickerPlayer:(PLVStickerPlayer *)player didFailWithError:(NSError *)error {
    NSLog(@"PLVStickerVideoView: Player error - %@", error.localizedDescription);
}

- (void)stickerPlayer:(PLVStickerPlayer *)player didUpdateAudioPacket:(NSDictionary *)audioPacket {
    // 可以在这里处理音频数据包，比如播放音频
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoViewDidUpdateAudioPacket:audioPacket:)]) {
        [self.delegate plv_StickerVideoViewDidUpdateAudioPacket:self audioPacket:audioPacket];
    }
}

- (void)stickerPlayer:(PLVStickerPlayer *)player didPrepareWithVideoSize:(CGSize)videoSize {
    // 视频准备完成，根据视频宽高比调整视图大小
    if (videoSize.width <= 0 || videoSize.height <= 0) {
        NSLog(@"PLVStickerVideoView: Invalid video size - %@", NSStringFromCGSize(videoSize));
        return;
    }
    
    [self adjustViewSizeWithVideoSize:videoSize];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 不允许pinch手势同时识别，避免与底层的摄像头缩放手势冲突
    // 参考图片贴图的实现方式，阻止手势传递到底层
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ||
        [otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - PLVStickerVideoControlDelegate

- (void)stickerVideoControl:(PLVStickerVideoControl *)control didTapPlayButton:(BOOL)isPlaying {
    if (isPlaying) {
        [self play];
    } else {
        [self pause];
    }
    
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoViewDidTapPlayButton:isPlaying:)]) {
        [self.delegate plv_StickerVideoViewDidTapPlayButton:self isPlaying:isPlaying];
    }
}

- (void)stickerVideoControlDidTapDeleteButton:(PLVStickerVideoControl *)control {
    // 隐藏控制栏
    [self.videoControl hideControls];
    [self.videoControl removeFromSuperview];
   
    // 恢复底层SDK 音量默认设置
    self.videoVolume = 1.0;
    self.microphoneVolume = 0.0;
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoView:didChangeAudioVolume:microphoneVolume:)]) {
        [self.delegate plv_StickerVideoView:self didChangeAudioVolume:self.videoVolume microphoneVolume:self.microphoneVolume];
    }
    
    // 删除当前视频贴图
    [self removeFromSuperview];
    
    // 通知代理
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoViewDidTapDeleteButton:)]) {
        [self.delegate plv_StickerVideoViewDidTapDeleteButton:self];
    }
}

- (void)stickerVideoControlDidTapBackwardButton:(PLVStickerVideoControl *)control {
    // 快退10秒
    NSTimeInterval currentTime = self.player.currentTime;
    NSTimeInterval newTime = MAX(0, currentTime - 10);
    [self seekToTime:newTime];
}

- (void)stickerVideoControlDidTapForwardButton:(PLVStickerVideoControl *)control {
    // 快进10秒
    NSTimeInterval currentTime = self.player.currentTime;
    NSTimeInterval totalTime = self.player.totalTime;
    NSTimeInterval newTime = MIN(totalTime, currentTime + 10);
    [self seekToTime:newTime];
}

- (void)stickerVideoControl:(PLVStickerVideoControl *)control didTapVolumeButton:(BOOL)isMuted {
    // 点击音量按钮时弹出音频设置组件
    [self showAudioSettings];
}

- (void)stickerVideoControlDidTapFullscreenButton:(PLVStickerVideoControl *)control {
    // 全屏功能 - 这里可以实现全屏逻辑
    NSLog(@"PLVStickerVideoView: Fullscreen button tapped");
}

- (void)stickerVideoControl:(PLVStickerVideoControl *)control didSeekToProgress:(CGFloat)progress {
    NSTimeInterval totalTime = self.player.totalTime;
    NSTimeInterval targetTime = totalTime * progress;
    [self seekToTime:targetTime];
}

#pragma mark - PLVStickerAudioSetDelegate

- (void)stickerAudioSet:(PLVStickerAudioSet *)audioSet didChangeVideoVolume:(CGFloat)volume {
    // 更新当前的视频音量
    _videoVolume = volume;
    
    // 更新推流音量大小
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoView:didChangeAudioVolume:microphoneVolume:)]) {
        [self.delegate plv_StickerVideoView:self didChangeAudioVolume:volume microphoneVolume:self.microphoneVolume];
    }
}

- (void)stickerAudioSet:(PLVStickerAudioSet *)audioSet didChangeMicrophoneVolume:(CGFloat)volume {
    // 更新当前的麦克风音量
    _microphoneVolume = volume;
    
    // 同时回调音频音量设置改变
    if ([self.delegate respondsToSelector:@selector(plv_StickerVideoView:didChangeAudioVolume:microphoneVolume:)]) {
        [self.delegate plv_StickerVideoView:self didChangeAudioVolume:self.videoVolume microphoneVolume:volume];
    }
}

#pragma mark - Audio Settings

- (void)showAudioSettings {
    if (!self.audioSet) {
        // 使用带width和height参数的初始化方法
        // 设置弹层高度为200，横屏宽度为320
        BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
        NSUInteger sheetWidth  = isLandscape ? self.superview.bounds.size.height : self.superview.bounds.size.width;
        self.audioSet = [[PLVStickerAudioSet alloc] initWithSheetHeight:200 sheetLandscapeWidth:sheetWidth];
        self.audioSet.delegate = self;
    }
    
    // 同步当前音量值到音频设置组件
    self.audioSet.videoVolume = self.videoVolume;
    self.audioSet.microphoneVolume = self.microphoneVolume;
    
    // 显示音频设置组件
    [self.audioSet showInView:self.superview];
}

@end
