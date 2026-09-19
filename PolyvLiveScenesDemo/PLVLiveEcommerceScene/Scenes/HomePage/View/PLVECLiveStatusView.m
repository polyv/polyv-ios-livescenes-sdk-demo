//
//  PLVECLiveStatusView.m
//  PLVLiveScenesDemo
//
//  Created by polyv on 2026/09/04.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVECLiveStatusView.h"

static NSString *const PLVECLiveSignalAnimationKey = @"PLVECLiveSignalAnimation";
static const NSUInteger PLVECLiveSignalBarCount = 3;
static const CGFloat PLVECLiveSignalWidth = 11.0;
static const CGFloat PLVECLiveSignalHeight = 12.0;
static const CGFloat PLVECLiveSignalPadding = 2.0;
static const CGFloat PLVECLiveSignalBarWidth = 1.0;
static const CGFloat PLVECLiveSignalMinimumHeightRatio = 0.3;
static const CGFloat PLVECLiveSignalMaximumHeightRatio = 0.9;
static const NSTimeInterval PLVECLiveSignalAnimationDuration = 1.2;
static const CGFloat PLVECLiveSignalStaticHeightRatios[] = {0.3, 0.9, 0.6};
static const NSTimeInterval PLVECLiveSignalAnimationDelays[] = {0.0, 0.9, 0.6};

@interface PLVECLiveSignalView : UIView

@property (nonatomic, copy) NSArray<CALayer *> *barLayers;
@property (nonatomic, assign, getter=isActive) BOOL active;
@property (nonatomic, assign) CGSize lastLayoutSize;

@end

@implementation PLVECLiveSignalView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.hidden = YES;

        NSMutableArray<CALayer *> *barLayers = [NSMutableArray arrayWithCapacity:PLVECLiveSignalBarCount];
        for (NSUInteger index = 0; index < PLVECLiveSignalBarCount; index++) {
            CALayer *barLayer = [CALayer layer];
            barLayer.anchorPoint = CGPointMake(0.5, 1.0);
            barLayer.backgroundColor = UIColor.whiteColor.CGColor;
            barLayer.cornerRadius = PLVECLiveSignalBarWidth / 2.0;
            [self.layer addSublayer:barLayer];
            [barLayers addObject:barLayer];
        }
        self.barLayers = barLayers;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reduceMotionStatusDidChange:)
                                                     name:UIAccessibilityReduceMotionStatusDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopBarAnimations];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    BOOL sizeChanged = !CGSizeEqualToSize(self.lastLayoutSize, self.bounds.size);
    self.lastLayoutSize = self.bounds.size;

    CGFloat contentWidth = MAX(0.0, CGRectGetWidth(self.bounds) - PLVECLiveSignalPadding * 2.0);
    CGFloat contentHeight = MAX(0.0, CGRectGetHeight(self.bounds) - PLVECLiveSignalPadding * 2.0);
    CGFloat barSpacing = MAX(0.0, (contentWidth - PLVECLiveSignalBarWidth * self.barLayers.count) / MAX(1, self.barLayers.count - 1));
    BOOL reduceMotionEnabled = UIAccessibilityIsReduceMotionEnabled();

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.barLayers enumerateObjectsUsingBlock:^(CALayer *barLayer, NSUInteger index, BOOL *stop) {
        CGFloat heightRatio = reduceMotionEnabled ? PLVECLiveSignalStaticHeightRatios[index] : PLVECLiveSignalMinimumHeightRatio;
        CGFloat barHeight = contentHeight * heightRatio;
        CGFloat originX = PLVECLiveSignalPadding + index * (PLVECLiveSignalBarWidth + barSpacing);
        barLayer.bounds = CGRectMake(0.0, 0.0, PLVECLiveSignalBarWidth, barHeight);
        barLayer.position = CGPointMake(originX + PLVECLiveSignalBarWidth / 2.0,
                                        CGRectGetHeight(self.bounds) - PLVECLiveSignalPadding);
    }];
    [CATransaction commit];

    if (!self.window || !self.isActive || reduceMotionEnabled) {
        [self stopBarAnimations];
    } else if (sizeChanged || ![self hasBarAnimations]) {
        [self startBarAnimations];
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && self.isActive) {
        [self setNeedsLayout];
    } else {
        [self stopBarAnimations];
    }
}

- (void)setActive:(BOOL)active {
    if (_active == active) {
        return;
    }
    _active = active;
    self.hidden = !active;
    [self setNeedsLayout];

    if (!active) {
        [self stopBarAnimations];
    }
}

#pragma mark - Private

- (BOOL)hasBarAnimations {
    for (CALayer *barLayer in self.barLayers) {
        if (![barLayer animationForKey:PLVECLiveSignalAnimationKey]) {
            return NO;
        }
    }
    return self.barLayers.count > 0;
}

- (void)startBarAnimations {
    [self stopBarAnimations];
    if (!self.window || !self.isActive || UIAccessibilityIsReduceMotionEnabled()) {
        return;
    }

    CGFloat contentHeight = MAX(0.0, CGRectGetHeight(self.bounds) - PLVECLiveSignalPadding * 2.0);
    if (contentHeight <= 0.0) {
        return;
    }

    CGFloat minimumBarHeight = contentHeight * PLVECLiveSignalMinimumHeightRatio;
    CGFloat maximumBarHeight = contentHeight * PLVECLiveSignalMaximumHeightRatio;
    [self.barLayers enumerateObjectsUsingBlock:^(CALayer *barLayer, NSUInteger index, BOOL *stop) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"bounds.size.height"];
        animation.values = @[@(minimumBarHeight), @(maximumBarHeight), @(minimumBarHeight)];
        animation.keyTimes = @[@0.0, @0.5, @1.0];
        animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        animation.duration = PLVECLiveSignalAnimationDuration;
        animation.beginTime = [barLayer convertTime:CACurrentMediaTime() fromLayer:nil] + PLVECLiveSignalAnimationDelays[index];
        animation.repeatCount = HUGE_VALF;
        [barLayer addAnimation:animation forKey:PLVECLiveSignalAnimationKey];
    }];
}

- (void)stopBarAnimations {
    for (CALayer *barLayer in self.barLayers) {
        [barLayer removeAnimationForKey:PLVECLiveSignalAnimationKey];
    }
}

- (void)reduceMotionStatusDidChange:(NSNotification *)notification {
    [self stopBarAnimations];
    [self setNeedsLayout];
}

@end

@interface PLVECLiveStatusView ()

@property (nonatomic, strong) PLVECLiveSignalView *signalView;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation PLVECLiveStatusView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _signalView = [[PLVECLiveSignalView alloc] init];
        [self addSubview:_signalView];

        _textLabel = [[UILabel alloc] init];
        _textLabel.font = [UIFont systemFontOfSize:12.0];
        _textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.minimumScaleFactor = 0.6;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = UIColor.whiteColor;
        [self addSubview:_textLabel];

        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitStaticText;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    BOOL showsLiveSignal = self.signalView.isActive;
    CGFloat signalWidth = showsLiveSignal ? PLVECLiveSignalWidth : 0.0;
    CGFloat itemSpacing = showsLiveSignal ? 4.0 : 0.0;
    CGFloat maximumTextWidth = MAX(0.0, CGRectGetWidth(self.bounds) - signalWidth - itemSpacing);
    CGFloat textWidth = MIN(ceil([self.textLabel sizeThatFits:CGSizeMake(MAXFLOAT, CGRectGetHeight(self.bounds))].width),
                            maximumTextWidth);
    CGFloat contentWidth = signalWidth + itemSpacing + textWidth;
    CGFloat contentOriginX = floor((CGRectGetWidth(self.bounds) - contentWidth) / 2.0);

    if (showsLiveSignal) {
        self.signalView.frame = CGRectMake(contentOriginX,
                                           floor((CGRectGetHeight(self.bounds) - PLVECLiveSignalHeight) / 2.0),
                                           PLVECLiveSignalWidth,
                                           PLVECLiveSignalHeight);
    } else {
        self.signalView.frame = CGRectZero;
    }
    self.textLabel.frame = CGRectMake(contentOriginX + signalWidth + itemSpacing,
                                      0.0,
                                      textWidth,
                                      CGRectGetHeight(self.bounds));
}

- (void)updateStatusText:(NSString *)statusText showsLiveSignal:(BOOL)showsLiveSignal {
    BOOL statusTextChanged = ![self.textLabel.text isEqualToString:statusText];
    BOOL liveSignalChanged = self.signalView.isActive != showsLiveSignal;
    if (!statusTextChanged && !liveSignalChanged) {
        return;
    }

    if (statusTextChanged) {
        self.textLabel.text = statusText;
        self.accessibilityLabel = statusText;
    }
    if (liveSignalChanged) {
        self.signalView.active = showsLiveSignal;
    }
    [self setNeedsLayout];
}

@end
