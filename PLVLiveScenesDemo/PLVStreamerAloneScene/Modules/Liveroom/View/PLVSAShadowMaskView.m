//
//  PLVSAShadowMaskView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAShadowMaskView.h"
#import "PLVSAUtils.h"

@interface PLVSAShadowMaskView ()

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) CAGradientLayer *topGradientLayer;
@property (nonatomic, strong) CAGradientLayer *bottomGradientLayer;

@end

@implementation PLVSAShadowMaskView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = NO;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat top = [PLVSAUtils sharedUtils].areaInsets.top;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    self.topView.frame = CGRectMake(0, 0, self.bounds.size.width, top + 72.0);
    self.bottomView.frame = CGRectMake(0, self.bounds.size.height - 76 - bottom, self.bounds.size.width, 76 + bottom);
    
    self.topGradientLayer.frame = self.topView.bounds;
    self.bottomGradientLayer.frame = self.bottomView.bounds;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.topView];
    [self addSubview:self.bottomView];
    
    [self.topView.layer addSublayer:self.topGradientLayer];
    [self.bottomView.layer addSublayer:self.bottomGradientLayer];
}

#pragma mark Getter & Setter

- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] init];
    }
    return _topView;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
    }
    return _bottomView;
}

- (CAGradientLayer *)topGradientLayer {
    if (!_topGradientLayer) {
        _topGradientLayer = [CAGradientLayer layer];
        _topGradientLayer.locations = @[@(0), @(1.0)];
        _topGradientLayer.startPoint = CGPointMake(0, 0);
        _topGradientLayer.endPoint = CGPointMake(0, 1);
        UIColor *startColor = [UIColor colorWithWhite:0 alpha:0.2];
        UIColor *endColor = [UIColor colorWithWhite:0 alpha:0];
        _topGradientLayer.colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
    }
    return _topGradientLayer;
}

- (CAGradientLayer *)bottomGradientLayer {
    if (!_bottomGradientLayer) {
        _bottomGradientLayer = [CAGradientLayer layer];
        _bottomGradientLayer.locations = @[@(0), @(1.0)];
        _bottomGradientLayer.startPoint = CGPointMake(0, 0);
        _bottomGradientLayer.endPoint = CGPointMake(0, 1);
        UIColor *startColor = [UIColor colorWithWhite:0 alpha:0];
        UIColor *endColor = [UIColor colorWithWhite:0 alpha:0.6];
        _bottomGradientLayer.colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
    }
    return _bottomGradientLayer;
}

@end
