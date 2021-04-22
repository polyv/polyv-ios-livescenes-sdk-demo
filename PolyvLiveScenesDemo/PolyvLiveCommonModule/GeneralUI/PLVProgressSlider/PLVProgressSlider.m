//
//  PLVProgressSlider.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/11/11.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVProgressSlider.h"

@interface PLVProgressSlider ()

#pragma mark 状态
@property (nonatomic, assign) BOOL sliderDragging; /// slider 是否处于拖动中 (YES:正在被拖动；NO:未被拖动)

#pragma mark UI
/// view hierarchy
///
/// (PLVProgressSlider) self
/// ├── (UIProgressView) progressView
/// └── (UISlider) slider
@property (nonatomic, strong) UIProgressView * progressView; /// 进度条
@property (nonatomic, strong) UISlider * slider; /// 滑杆条

@end

@implementation PLVProgressSlider

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
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
}


#pragma mark - [ Public Methods ]
- (void)setProgressWithCachedProgress:(CGFloat)cachedProgress playedProgress:(CGFloat)playedProgress{
    if (!self.sliderDragging) {
        self.progressView.progress = cachedProgress;
        self.slider.value = playedProgress;
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
