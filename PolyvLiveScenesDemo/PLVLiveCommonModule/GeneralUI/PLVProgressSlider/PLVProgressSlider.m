//
//  PLVProgressSlider.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/11/11.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVProgressSlider.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVProgressSlider ()

#pragma mark 状态
@property (nonatomic, assign) BOOL sliderDragging; /// slider 是否处于拖动中 (YES:正在被拖动；NO:未被拖动)

#pragma mark UI
/// view hierarchy
///
/// (PLVProgressSlider) self
/// ├── (UIProgressView) progressView
/// ├── (UISlider) slider
/// └── (UIButton[]) momentMarkers
@property (nonatomic, strong) UIProgressView * progressView; /// 进度条
@property (nonatomic, strong) UISlider * slider; /// 滑杆条

/// 精彩看点标记视图数组
@property (nonatomic, strong) NSMutableArray<UIButton *> *momentMarkers;
/// 视频总时长
@property (nonatomic, assign) NSTimeInterval videoDuration;

@end

@implementation PLVProgressSlider

#pragma mark - [ Life Period ]
- (void)dealloc{
    PLV_LOG_DEBUG(PLVConsoleLogModuleTypePlayer, @"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        self.momentMarkers = [NSMutableArray array];
    }
    return self;
}

- (void)layoutSubviews{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);

    CGFloat progressViewHeight = 2.5;
    CGFloat progressViewY = (viewHeight - progressViewHeight) / 2.0;
    CGFloat progressViewX = 3.0;
    CGFloat progressViewWidth = viewWidth - progressViewX * 2;
    self.progressView.frame = CGRectMake(progressViewX, progressViewY, progressViewWidth, progressViewHeight);
    
    self.slider.frame = self.bounds;
    CGFloat midY =  ceilf(CGRectGetMidY(self.slider.frame));
    self.progressView.center = CGPointMake(CGRectGetMidX(self.progressView.frame), midY);
    
    // 布局精彩看点标记点
    [self layoutMomentMarkers];
}


#pragma mark - [ Public Methods ]
- (void)setProgressWithCachedProgress:(CGFloat)cachedProgress playedProgress:(CGFloat)playedProgress{
    if (!self.sliderDragging) {
        self.progressView.progress = cachedProgress;
        self.slider.value = playedProgress;
    }
}

#pragma mark - 精彩看点功能

- (void)setKeyMoments:(NSArray<PLVKeyMomentModel *> *)keyMoments duration:(NSTimeInterval)duration {
    _keyMoments = keyMoments;
    self.videoDuration = duration;
    [self updateMomentMarkers];
}

- (void)updateMomentMarkers {
    // 清除旧的标记点
    for (UIButton *marker in self.momentMarkers) {
        [marker removeFromSuperview];
    }
    [self.momentMarkers removeAllObjects];
    
    // 创建新的标记点
    for (PLVKeyMomentModel *moment in self.keyMoments) {
        UIButton *marker = [self createMomentMarkerForMoment:moment];
        [self addSubview:marker];
        [self.momentMarkers addObject:marker];
    }
    
    [self layoutMomentMarkers];
}

- (UIButton *)createMomentMarkerForMoment:(PLVKeyMomentModel *)moment {
    UIButton *marker = [UIButton buttonWithType:UIButtonTypeCustom];
    marker.backgroundColor = [UIColor whiteColor];
    marker.layer.cornerRadius = 3.0;
    marker.layer.masksToBounds = YES;
    marker.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
    marker.layer.borderWidth = 1.0;
    
    // 存储精彩看点数据
    marker.tag = [self.keyMoments indexOfObject:moment];
    [marker addTarget:self action:@selector(momentMarkerTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return marker;
}

- (void)layoutMomentMarkers {
    CGFloat progressViewX = 3.0;
    CGFloat progressViewWidth = CGRectGetWidth(self.bounds) - progressViewX * 2;
    CGFloat markerSize = 6.0;
    CGFloat progressViewY = (CGRectGetHeight(self.bounds) - 2.5) / 2.0;
    
    for (UIButton *marker in self.momentMarkers) {
        NSInteger index = marker.tag;
        if (index < self.keyMoments.count && self.videoDuration > 0) {
            PLVKeyMomentModel *moment = self.keyMoments[index];
            
            // 根据时间戳计算标记点在进度条上的位置
            CGFloat progress = moment.markTime / self.videoDuration;
            progress = MAX(0, MIN(1, progress)); // 限制在0-1范围内
            
            CGFloat markerX = progressViewX + (progressViewWidth * progress) - (markerSize / 2.0);
            CGFloat markerY = progressViewY - (markerSize - 2.5) / 2.0;
            
            marker.frame = CGRectMake(markerX, markerY, markerSize, markerSize);
        }
    }
}

- (void)momentMarkerTapped:(UIButton *)marker {
    NSInteger index = marker.tag;
    if (index < self.keyMoments.count) {
        PLVKeyMomentModel *moment = self.keyMoments[index];
        if ([self.delegate respondsToSelector:@selector(plvProgressSlider:didTapKeyMoment:)]) {
            [self.delegate plvProgressSlider:self didTapKeyMoment:moment];
        }
    }
}


#pragma mark - [ Private Methods ]
- (void)setupUI{
    [self addSubview:self.progressView];
    [self addSubview:self.slider];
}


#pragma mark Getter
- (UIProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.progressViewStyle = UIProgressViewStyleBar;
        _progressView.progress = 0;
        _progressView.progressTintColor = [UIColor colorWithWhite:1 alpha:0.5];
        _progressView.trackTintColor = [UIColor colorWithWhite:1 alpha:0.3];
        _progressView.layer.cornerRadius = 1.5;
        _progressView.clipsToBounds = YES;
    }
    return _progressView;
}

- (UISlider *)slider{
    if (!_slider) {
        _slider = [[UISlider alloc] init];
        _slider.maximumTrackTintColor = [UIColor clearColor];
        [_slider addTarget:self action:@selector(sliderTouchDownAction:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDownRepeat | UIControlEventTouchDragInside | UIControlEventTouchDragOutside | UIControlEventTouchDragEnter | UIControlEventTouchDragExit];
        [_slider addTarget:self action:@selector(sliderTouchEndAction:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [_slider addTarget:self action:@selector(sliderValueChangedAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}


#pragma mark - [ Event ]
#pragma mark Action
- (IBAction)sliderTouchDownAction:(UISlider *)sender {
    self.sliderDragging = YES;
}

- (IBAction)sliderTouchEndAction:(UISlider *)sender {
    if ([self.delegate respondsToSelector:@selector(plvProgressSlider:sliderDragEnd:)]) {
        [self.delegate plvProgressSlider:self sliderDragEnd:self.slider.value];
    }
    self.sliderDragging = NO;
}

- (IBAction)sliderValueChangedAction:(UISlider *)sender {
    if ([self.delegate respondsToSelector:@selector(plvProgressSlider:sliderDragingProgressChange:)]) {
        [self.delegate plvProgressSlider:self sliderDragingProgressChange:self.slider.value];
    }
}

@end
