//
//  PLVLSSipNewIncomingTelegramView.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2022/3/30.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSSipNewIncomingTelegramView.h"

/// 工具
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSSipNewIncomingTelegramView()

@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, strong) CAShapeLayer *maskLayer;

@end

@implementation PLVLSSipNewIncomingTelegramView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat selfMidY = CGRectGetMidY(self.bounds);
    self.iconImageView.frame = CGRectMake(44, selfMidY - 16 / 2, 16, 16);
    CGFloat textLabelWidth = [self.textLabel sizeThatFits:CGSizeMake(MAXFLOAT, 17)].width + 2;
    self.textLabel.frame = CGRectMake(CGRectGetMaxX(self.iconImageView.frame) + 4, selfMidY - 17 / 2, textLabelWidth, 17);
    self.sendButton.frame = CGRectMake(CGRectGetMaxX(self.textLabel.frame) + 24, selfMidY - 24 / 2, 52, 24);
    self.cancelButton.frame = CGRectMake(CGRectGetMaxX(self.sendButton.frame) + 12, selfMidY - 20 / 2, 40, 20);
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerBottomRight | UIRectCornerTopRight cornerRadii:CGSizeMake(20, 20)];
    self.maskLayer.frame = self.bounds;
    self.maskLayer.path = maskPath.CGPath;
    self.layer.mask = self.maskLayer;
}

#pragma mark - [ Private Method ]

- (void)initUI {
    self.backgroundColor = PLV_UIColorFromRGBA(@"#313540", 0.8);
    
    [self addSubview:self.iconImageView];
    [self addSubview:self.textLabel];
    [self addSubview:self.sendButton];
    [self addSubview:self.cancelButton];
}

#pragma mark Getter & Setter

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.image = [PLVLSUtils imageForMemberResource:@"plvls_member_sip_new_incoming_telegram_icon"];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconImageView;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.text = @"您有10个来电待接听";
        _textLabel.font = [UIFont systemFontOfSize:12];
        _textLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
    }
    return _textLabel;
}

- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[UIButton alloc] init];
        _sendButton.backgroundColor = PLV_UIColorFromRGB(@"#4399FF");
        [_sendButton setTitle:PLVLocalizedString(@"去接听") forState:UIControlStateNormal];
        _sendButton.layer.masksToBounds = YES;
        _sendButton.layer.cornerRadius = 12;
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_sendButton setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(sendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[UIButton alloc] init];
        [_cancelButton setTitle:PLVLocalizedString(@"忽略") forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_cancelButton setTitleColor:PLV_UIColorFromRGB(@"#CFD1D6") forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (CAShapeLayer *)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [[CAShapeLayer alloc] init];
    }
    return _maskLayer;
}

#pragma mark - [ Public Method ]

- (void)show {
    UIView *parentView = [PLVLSUtils sharedUtils].homeVC.view;
    
    [parentView addSubview:self];
    [parentView insertSubview:self atIndex:parentView.subviews.count - 1];
    self.frame = CGRectMake(-310, 107, 315, 40);

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        weakSelf.frame = CGRectMake(0, 107, 315, 40);
        weakSelf.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hide {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        weakSelf.frame = CGRectMake(-310, 107, 315, 40);
        weakSelf.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)sendButtonAction {
    [self hide];
    
}

- (void)cancelButtonAction {
    [self hide];
}

@end
