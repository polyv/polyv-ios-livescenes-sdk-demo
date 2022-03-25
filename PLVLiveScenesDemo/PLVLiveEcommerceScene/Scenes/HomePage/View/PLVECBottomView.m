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

@end

@implementation PLVECBottomView

#pragma mark - Override

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
        effectView.frame = self.bounds;
        [self addSubview:effectView];
        
        [self drawViewCornerRadius:self size:frame.size cornerRadii:CGSizeMake(10.f, 10.f) corners:UIRectCornerTopLeft|UIRectCornerTopRight];
        
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeButton.frame = CGRectMake(CGRectGetWidth(frame)-36, 15, 28, 28);
        [self.closeButton setImage:[PLVECUtils imageForWatchResource:@"plv_floatView_close_btn"] forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeButton];
    }
    return self;
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
