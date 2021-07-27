//
//  PLVSlideRightTipsView.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/31.
//  Copyright © 2021 PLV. All rights reserved.
//  开播时清屏提示视图，覆盖在 PLVSAStreamerHomeView 之上

#import "PLVSASlideRightTipsView.h"
#import "PLVSAUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSASlideRightTipsView()

@property (nonatomic, strong) UIImageView *tipsImageView;
@property (nonatomic, strong) UILabel *tipsLable;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CAKeyframeAnimation *animation;

@end


@implementation PLVSASlideRightTipsView

#pragma mark - [ Life Cycle ]
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.tipsImageView];
    [self addSubview:self.tipsLable];
    [self addSubview:self.closeButton];
}

#pragma mark - layout
- (void)layoutSubviews {
    CGFloat originY = [PLVSAUtils sharedUtils].areaInsets.top;
    self.tipsImageView.frame = CGRectMake(0, originY + 220, 123, 85);
    self.tipsLable.frame = CGRectMake(CGRectGetMidX(self.bounds) - 72 / 2, UIViewGetBottom(self.tipsImageView) + 24, 72, 20);
    self.closeButton.frame = CGRectMake(CGRectGetMidX(self.bounds) - 100 / 2, UIViewGetBottom(self.tipsLable) + 25, 100, 36);
    self.gradientLayer.frame = self.closeButton.bounds;
    
    [self setupAnimation];
}

#pragma mark - [ Private Method ]
- (void)setupAnimation {
    CGRect rect = self.tipsImageView.frame;
    CGFloat safeArea = 50.0;
    CGFloat xPadding = self.tipsImageView.frame.size.width / 2;
    CGFloat yPadding = self.tipsImageView.frame.size.height / 2;
    /// 处理关键帧动画origin偏移度
    rect.origin.x += xPadding + safeArea;
    rect.origin.y += yPadding;
    NSValue *startPoint = [NSValue valueWithCGPoint:rect.origin];
    rect.origin.x = CGRectGetMaxX(self.bounds) - xPadding - safeArea;
    NSValue *endPoint = [NSValue valueWithCGPoint:rect.origin];
    self.animation.values = @[startPoint, endPoint];
    [self.tipsImageView.layer addAnimation:self.animation forKey:nil];

}

#pragma mark - getter
- (UIImageView *)tipsImageView {
    if (!_tipsImageView) {
        _tipsImageView = [[UIImageView alloc] initWithImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_live_slide_right_tips"]];
    }
    return _tipsImageView;
}

- (UILabel *)tipsLable {
    if (!_tipsLable) {
        _tipsLable = [[UILabel alloc] init];
        _tipsLable.text = @"右滑清屏";
        _tipsLable.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _tipsLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
    }
    return _tipsLable;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] init];
        _closeButton.layer.cornerRadius = 18;
        _closeButton.layer.masksToBounds = YES;
        [_closeButton setTitle:@"我知道了" forState:UIControlStateNormal];
        _closeButton.titleLabel.font =  [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        [_closeButton setTitleColor:PLV_UIColorFromRGB(@"#FFFFFF") forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(confirmButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return _closeButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#0080FF").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#3399FF").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (CAKeyframeAnimation *)animation {
    if (!_animation) {
        _animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        _animation.autoreverses = YES;
        _animation.duration = 1.0f;
        _animation.repeatCount = MAXFLOAT;
        _animation.fillMode = kCAFillModeForwards;
    }
    return _animation;
}

#pragma mark - Action
- (void)confirmButtonAction {
    if (self.closeButtonHandler) {
        self.closeButtonHandler();
    }
}


@end
