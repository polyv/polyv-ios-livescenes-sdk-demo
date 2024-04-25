//
//  PLVLSLinkMicUpdateTipsView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/4/10.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLSLinkMicUpdateTipsView.h"

// 工具
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

// 框架
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSLinkMicUpdateTipsView ()

/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@end

@implementation PLVLSLinkMicUpdateTipsView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.titleLabel];
        [self addSubview:self.tipLabel];
        [self addSubview:self.confirmButton];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize titleLabelSize = [self.tipLabel sizeThatFits:CGSizeMake(MAXFLOAT, 20)];
    self.titleLabel.frame = CGRectMake((self.viewSize.width - titleLabelSize.width) / 2, 32, titleLabelSize.width, 20);
    self.tipLabel.frame = CGRectMake(44, CGRectGetMaxY(self.titleLabel.frame) + 6, self.viewSize.width - 88 , 20);
    self.confirmButton.frame = CGRectMake(self.viewSize.width / 2 - 45, CGRectGetMaxY(self.tipLabel.frame) + 14, 90 , 36);
    [self drawLayer];
}

#pragma mark - [ Public Method ]

- (CGSize)viewSize {
    CGSize tipLabelSize = [self.tipLabel sizeThatFits:CGSizeMake(MAXFLOAT, 17)];
    return CGSizeMake(tipLabelSize.width + 88, 139);
}

#pragma mark - [ Private Method ]

- (void)drawLayer {
    if (_shapeLayer.superlayer) {
        [_shapeLayer removeFromSuperlayer];
        _shapeLayer = nil;
    }
    
    CGFloat midX = CGRectGetMidX(self.bounds);
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 8, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - 8) cornerRadius:16];
    // triangle
    
    [maskPath moveToPoint:CGPointMake(midX, 0)];
    [maskPath addLineToPoint:CGPointMake(midX - 8, 8)];
    [maskPath addLineToPoint:CGPointMake(midX + 8, 8)];
    [maskPath closePath];
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = UIColor.whiteColor.CGColor;
    shapeLayer.path = maskPath.CGPath;
    _shapeLayer = shapeLayer;
    [self.layer insertSublayer:_shapeLayer atIndex:0];
}

#pragma mark Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#3D3D3D"];
        _titleLabel.text = PLVLocalizedString(@"“连麦”功能更新啦");
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _tipLabel.textColor = [PLVColorUtil colorFromHexString:@"#999999"];
        _tipLabel.text = PLVLocalizedString(@"点击此功能按钮可开启观众连麦");
        _tipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipLabel;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.layer.cornerRadius = 18.0;
        [_confirmButton setTitle:PLVLocalizedString(@"知道了") forState:UIControlStateNormal];
         [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
         [_confirmButton setBackgroundColor:[PLVColorUtil colorFromHexString:@"#0080FF"]];
        [_confirmButton addTarget:self action:@selector(confirmButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

#pragma mark Action

- (void)confirmButtonAction {
    self.hidden = YES;
}


@end
