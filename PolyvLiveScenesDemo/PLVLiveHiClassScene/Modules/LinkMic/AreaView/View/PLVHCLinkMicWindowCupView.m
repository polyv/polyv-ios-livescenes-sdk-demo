//
//  PLVHCLinkMicWindowCupView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/11/16.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicWindowCupView.h"

#import "PLVHCUtils.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>
@interface PLVHCLinkMicWindowCupView ()

#pragma mark UI
@property (nonatomic, strong) UIImageView *imageView; //奖杯
@property (nonatomic, strong) UILabel *countLabel; //奖杯数量
@property (nonatomic, strong) CAGradientLayer *gradientLayer;//背景

@end

@implementation PLVHCLinkMicWindowCupView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.layer.masksToBounds = YES;
        [self.layer addSublayer:self.gradientLayer];
        [self addSubview:self.imageView];
        [self addSubview:self.countLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = CGRectGetHeight(self.bounds)/2;
    self.gradientLayer.frame = self.bounds;
    self.imageView.frame = CGRectMake(4,(CGRectGetHeight(self.bounds) - 8)/2, 8, 8);
    self.countLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 2 , CGRectGetMinY(self.imageView.frame), 10, 8);
}

#pragma mark Getter & Setter

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_cup_icon"];
    }
    return _imageView;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _countLabel.font = [UIFont fontWithName:@"DINAlternate-Bold" size:8];
    }
    return _countLabel;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#F5BB4B"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#FFB21F"].CGColor];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}


#pragma mark - [ Public Method ]

- (void)updateCupCount:(NSInteger)count {
    count = MIN(99, count);
    self.countLabel.text = [NSString stringWithFormat:@"%ld",(long)count];
}

@end

