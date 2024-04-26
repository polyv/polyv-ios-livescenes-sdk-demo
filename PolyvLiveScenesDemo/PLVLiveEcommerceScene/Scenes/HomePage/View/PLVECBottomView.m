//
//  PLVECBottomView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/6/28.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECBottomView.h"
#import "PLVECUtils.h"

@interface PLVECBottomView ()

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图

@end

@implementation PLVECBottomView

#pragma mark - Override

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.effectView];
        
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeButton setImage:[PLVECUtils imageForWatchResource:@"plv_floatView_close_btn"] forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeButton];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.effectView.frame = self.bounds;
    UIRectCorner corners = [PLVECUtils sharedUtils].isLandscape ? UIRectCornerTopLeft|UIRectCornerBottomLeft : UIRectCornerTopLeft|UIRectCornerTopRight;
    [self drawViewCornerRadius:self size:self.frame.size cornerRadii:CGSizeMake(10.f, 10.f) corners:corners];
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.frame)-36, 15, 28, 28);
}

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}

#pragma mark - Action

- (void)closeButtonAction:(UIButton *)button {
    self.hidden = YES;
    if (self.closeButtonActionBlock) {
        self.closeButtonActionBlock(self);
    }
}

- (void)drawViewCornerRadius:(UIView *)view size:(CGSize)size cornerRadii:(CGSize)cornerRadii corners:(UIRectCorner)corners {
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:cornerRadii];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    view.layer.mask = maskLayer;
}

@end
