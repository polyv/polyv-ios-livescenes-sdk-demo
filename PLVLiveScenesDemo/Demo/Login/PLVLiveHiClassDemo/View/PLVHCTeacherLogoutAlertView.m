//
//  PLVHCTeacherLogoutAlertView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/9/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCTeacherLogoutAlertView.h"

@interface PLVHCTeacherLogoutAlertView ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, copy)  void(^confirmCallback) (void);

@end

@implementation PLVHCTeacherLogoutAlertView

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
    self.contentView.center = CGPointMake(self.center.x, self.center.y - 25);
    self.gradientLayer.frame = self.contentView.bounds;
    self.titleLabel.center = CGPointMake(CGRectGetWidth(self.contentView.bounds)/2, 20 + CGRectGetHeight(self.titleLabel.bounds)/2);
    self.messageLabel.center = CGPointMake(self.titleLabel.center.x, CGRectGetMaxY(self.titleLabel.frame) + 12 + CGRectGetHeight(self.titleLabel.bounds)/2);
    if (self.cancelButton.isHidden) {
        self.confirmButton.center = CGPointMake(self.titleLabel.center.x, CGRectGetHeight(self.contentView.bounds) - 18 - CGRectGetHeight(self.cancelButton.bounds)/2);
    } else {
        self.cancelButton.center = CGPointMake(self.titleLabel.center.x - 5 - CGRectGetWidth(self.cancelButton.bounds)/2, CGRectGetHeight(self.contentView.bounds) - 18 - CGRectGetHeight(self.cancelButton.bounds)/2);
        self.confirmButton.center = CGPointMake(self.titleLabel.center.x + 5 + CGRectGetWidth(self.cancelButton.bounds)/2, self.cancelButton.center.y);
    }
}

#pragma mark - [ Public Method ]

+ (void)showLogoutConfirmViewInView:(UIView *)view
                    confirmCallback:(void(^)(void))confirmCallback {
    PLVHCTeacherLogoutAlertView *logoutAlertView = [[PLVHCTeacherLogoutAlertView alloc] init];
    [view addSubview:logoutAlertView];
    logoutAlertView.frame = view.bounds;
    logoutAlertView.confirmCallback = confirmCallback;
}

+ (void)alertViewInView:(UIView *)view
                  title:(NSString *)title
                message:(NSString *)message
           confirmTitle:(NSString * _Nullable)confirmTitle
        confirmCallback:(void(^)(void))confirmCallback {
    PLVHCTeacherLogoutAlertView *alertView = [[PLVHCTeacherLogoutAlertView alloc] init];
    [view addSubview:alertView];
    alertView.titleLabel.text = title;
    alertView.messageLabel.text = message;
    alertView.cancelButton.hidden = YES;
    if (confirmTitle) {
        [alertView.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
    }
    alertView.frame = view.bounds;
    alertView.confirmCallback = confirmCallback;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.75];
    [self addSubview:self.contentView];
    [self.contentView.layer addSublayer:self.gradientLayer];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.messageLabel];
    [self.contentView addSubview:self.cancelButton];
    [self.contentView addSubview:self.confirmButton];
}

#pragma mark Getter & Setter

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.bounds = CGRectMake(0, 0, 260, 144);
        _contentView.layer.cornerRadius = 16.0f;
        _contentView.layer.masksToBounds = YES;
    }
    return _contentView;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.bounds = CGRectMake(0, 0, 40, 18);
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18.0f];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"提示";
    }
    return _titleLabel;
}
- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.bounds = CGRectMake(0, 0, 200, 22);
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0f];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.text = @"是否要退出登录";
    }
    return _messageLabel;
}
- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.bounds = CGRectMake(0, 0, 100, 36);
        _cancelButton.layer.masksToBounds = YES;
        _cancelButton.layer.cornerRadius = 18.0f;
        _cancelButton.layer.borderWidth = 1.0f;
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        UIColor *textColor = [UIColor colorWithRed:0/255.0 green:198/255.0 blue:121/255.0 alpha:1];
        _cancelButton.layer.borderColor = textColor.CGColor;
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:textColor forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}
- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.bounds = CGRectMake(0, 0, 100, 36);
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.layer.cornerRadius = 18.0f;
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        CAGradientLayer *btnGradientLayer = [CAGradientLayer layer];
        btnGradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:177/255.0 blue:108/255.0 alpha:1].CGColor,(__bridge id)[UIColor colorWithRed:0/255.0 green:231/255.0 blue:141/255.0 alpha:1].CGColor];
        btnGradientLayer.locations = @[@0.5, @1.0];
        btnGradientLayer.startPoint = CGPointMake(0, 0);
        btnGradientLayer.endPoint = CGPointMake(1.0, 0);
        btnGradientLayer.frame = _confirmButton.bounds;
        [_confirmButton.layer insertSublayer:btnGradientLayer atIndex:0];
        [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:48/255.0 green:52/255.0 blue:79/255.0 alpha:1.0].CGColor,(__bridge id)[UIColor colorWithRed:45/255.0 green:50/255.0 blue:76/255.0 alpha:1.0].CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(0, 1.0);
    }
    return _gradientLayer;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)cancelAction {
    [self removeFromSuperview];
}

- (void)confirmAction {
    [self removeFromSuperview];
    self.confirmCallback ? self.confirmCallback() : nil;
}

@end
