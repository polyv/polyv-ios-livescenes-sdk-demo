//
//  PLVSALinkMicAnchorPlaceholderView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/11/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicSpeakerPlaceholderView.h"
// 工具
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
// 框架
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface  PLVSALinkMicSpeakerPlaceholderView()

/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation PLVSALinkMicSpeakerPlaceholderView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    CGFloat placeholderViewWidth = isPad ? 240 : (isLandscape ? 200 : 140);
    CGFloat imageViewHeight = isPad ? 170 : (isLandscape ? 150 : 100);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.gradientLayer.frame = self.bounds;
    [CATransaction commit];
    self.placeholderView.frame = CGRectMake(0, 0, placeholderViewWidth, placeholderViewWidth);
    self.placeholderView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.imageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.placeholderView.frame), imageViewHeight);
    self.titleLabel.frame = CGRectMake(- 25, CGRectGetMaxY(self.imageView.frame), CGRectGetWidth(self.placeholderView.frame) + 50, 20);
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.layer addSublayer:self.gradientLayer];
    [self addSubview:self.placeholderView];
    [self.placeholderView addSubview:self.imageView];
    [self.placeholderView addSubview:self.titleLabel];
}

#pragma mark Getter

- (UIView *)placeholderView {
    if (!_placeholderView) {
        _placeholderView = [[UIView alloc] init];
    }
    return _placeholderView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_nolive_placeholder_icon"];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _titleLabel.text = PLVLocalizedString(@"当前暂无直播");
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.locations = @[@(0), @(1.0)];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
        UIColor *startColor = [PLVColorUtil colorFromHexString:@"#383F64"];
        UIColor *endColor = [PLVColorUtil colorFromHexString:@"#2D324C"];
        _gradientLayer.colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
    }
    return _gradientLayer;
}

@end
