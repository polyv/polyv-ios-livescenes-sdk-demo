//
//  PLVSALinkMicGuideView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/6/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicGuideView.h"

// 工具
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

// 框架
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface  PLVSALinkMicGuideView()

/// UI
@property (nonatomic, strong) UIImageView *tipImageView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;

///数据
@property (nonatomic, assign) BOOL hadShowedLinkMicGuide; //是否显示过连麦新手引导
@property (nonatomic, assign) BOOL showingLinkMicGuide;    //是否正在显示连麦新手引导
@property (nonatomic, assign) CGRect shapeLayerRect; //中间镂空的尺寸

@end

@implementation PLVSALinkMicGuideView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hadShowedLinkMicGuide = NO;
        self.showingLinkMicGuide = NO;
        [self setupUI];
    }
    return self;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    [self hideGuideView];
    if (CGRectContainsPoint(self.shapeLayerRect, point)) {
        return nil;
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)updateGuideViewWithSuperview:(UIView *)superview focusViewFrame:(CGRect)frame {
    CGFloat tipViewHeight = 60;
    CGFloat tipViewWidth = 173;
    CGFloat tipViewY = CGRectGetMaxY(frame) + 6;
    CGFloat tipViewX = CGRectGetMidX(frame) - tipViewWidth/2;
    if (tipViewWidth > CGRectGetWidth(frame)) {
        tipViewX = CGRectGetMidX(frame) - tipViewWidth + 32;
    }
    if (tipViewHeight + tipViewY + 15 > CGRectGetHeight(superview.bounds)) { //显示的Tip 超过窗口的位置时，则在提示窗口的内部显示
        tipViewY = CGRectGetMaxY(frame) - tipViewHeight/2;
    }
    self.hadShowedLinkMicGuide = YES;
    self.showingLinkMicGuide = YES;
    self.frame = superview.bounds;
    self.shapeLayerRect = frame;
    self.tipImageView.frame = CGRectMake(tipViewX, tipViewY, tipViewWidth, tipViewHeight);
    self.tipLabel.frame = self.tipImageView.bounds;
    [self updateShapeLayer];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1.0;
    } completion:nil];
}

- (void)hideGuideView {
    if (!self.showingLinkMicGuide || !self.superview) {
        return;
    }
    self.showingLinkMicGuide = NO;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    self.alpha = 0.0;
    [self addSubview:self.tipImageView];
    [self.tipImageView addSubview:self.tipLabel];
    [self.layer insertSublayer:self.shapeLayer atIndex:0];
}

- (void)updateShapeLayer {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:0];
    [maskPath appendPath:[[UIBezierPath bezierPathWithRoundedRect:self.shapeLayerRect cornerRadius:0] bezierPathByReversingPath]];
    self.shapeLayer.path = maskPath.CGPath;
}

#pragma mark Getter

- (UIImageView *)tipImageView {
    if (!_tipImageView) {
        _tipImageView = [[UIImageView alloc] init];
        _tipImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_bg_linkmic_guide"];
    }
    return _tipImageView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        if (@available(iOS 8.2, *)) {
        _tipLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        } else {
            _tipLabel.font = [UIFont systemFontOfSize:14];
        }
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.text = PLVLocalizedString(@"点击可管理上麦成员哦");
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
    }
    return _tipLabel;
}

- (CAShapeLayer *)shapeLayer {
    if (!_shapeLayer) {
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.fillColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.5].CGColor;
    }
    return _shapeLayer;
}

@end
