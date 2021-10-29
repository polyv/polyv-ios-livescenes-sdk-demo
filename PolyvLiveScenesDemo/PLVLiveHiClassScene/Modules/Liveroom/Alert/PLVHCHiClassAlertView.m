//
//  PLVHCHiClassAlertView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCHiClassAlertView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>


static CGFloat kAlertViewWidth = 260.0; // 弹窗宽度限制

@interface PLVHCHiClassAlertView ()

#pragma mark - UI

//alert需要添加到的window
@property (nonatomic, strong, readonly) UIWindow *frontWindow;
//弹窗承载视图
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

#pragma mark - Block
//撤销操作的回调
@property (nonatomic, copy) PLVHCHiClassAlertViewBlock cancelBlock;
//确认操作的回调
@property (nonatomic, copy) PLVHCHiClassAlertViewBlock confirmBlock;

@end


@implementation PLVHCHiClassAlertView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setUpUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.backgroundView.bounds;
}

#pragma mark - Getter && Setter

- (UIWindow *)frontWindow {
    if ([UIApplication sharedApplication].delegate.window) {
        return [UIApplication sharedApplication].delegate.window;
    } else {
        if (@available(iOS 13.0, *)) { // iOS 13.0+
            NSArray *array = [[[UIApplication sharedApplication] connectedScenes] allObjects];
            UIWindowScene *windowScene = (UIWindowScene *)array[0];
            UIWindow *window = [windowScene valueForKeyPath:@"delegate.window"];
            if (!window) {
                window = [UIApplication sharedApplication].windows.firstObject;
            }
            return window;
        } else {
            return [UIApplication sharedApplication].keyWindow;
        }
    }
}
- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundView.layer.cornerRadius = 16.0f;
        _backgroundView.layer.masksToBounds = YES;
        [_backgroundView.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return _backgroundView;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:18.0f];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}
- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.font = [UIFont fontWithName:@"PingFang SC" size:14.0f];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = 0;
    }
    return _messageLabel;
}
- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
        _cancelButton.layer.masksToBounds = YES;
        _cancelButton.layer.cornerRadius = 18.0f;
        _cancelButton.layer.borderWidth = 1.0f;
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        UIColor *textColor = PLV_UIColorFromRGB(@"#00C679");
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
        _confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.layer.cornerRadius = 18.0f;
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        CAGradientLayer *btnGradientLayer = [CAGradientLayer layer];
        btnGradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#00B16C").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#00E78D").CGColor];
        btnGradientLayer.locations = @[@0.5, @1.0];
        btnGradientLayer.startPoint = CGPointMake(0, 0);
        btnGradientLayer.endPoint = CGPointMake(1.0, 0);
        btnGradientLayer.frame = CGRectMake(0, 0, 100, 36);
        [_confirmButton.layer insertSublayer:btnGradientLayer atIndex:0];
        [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}
- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#30344F").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#2D324C").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

#pragma mark - [ Public Methods ]

///显示通用alert弹窗
+ (instancetype)alertViewWithTitle:(NSString * _Nullable)title
                           message:(NSString *)message
                       cancelTitle:(NSString * _Nullable)cancelTitle
                      confirmTitle:(NSString * _Nullable)confirmTitle
                 cancelActionBlock:(PLVHCHiClassAlertViewBlock _Nullable)cancelActionBlock
                confirmActionBlock:(PLVHCHiClassAlertViewBlock _Nullable)confirmActionBlock {
    PLVHCHiClassAlertView *alertView = [[PLVHCHiClassAlertView alloc] init];
    if ([PLVFdUtil checkStringUseable:title] ) {
        alertView.titleLabel.text = title;
    }
    if ([PLVFdUtil checkStringUseable:cancelTitle] ) {
        [alertView.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
    }
    if ([PLVFdUtil checkStringUseable:confirmTitle] ) {
        [alertView.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
    }
    alertView.messageLabel.text = message;
    alertView.cancelBlock = cancelActionBlock;
    alertView.confirmBlock = confirmActionBlock;
    [alertView showAlertView];
    return alertView;
}

#pragma mark - [ Private Methods ]

- (void)setUpUI {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.75/1.0];
    self.alpha = 0;
    [self.frontWindow addSubview:self];
    [self addSubview:self.backgroundView];
    [self.backgroundView addSubview:self.titleLabel];
    [self.backgroundView addSubview:self.messageLabel];
    [self.backgroundView addSubview:self.cancelButton];
    [self.backgroundView addSubview:self.confirmButton];
    [self addLayoutConstraints];
}

- (void)addLayoutConstraints {
    NSLayoutConstraint *bgViewLayoutCenterX = [NSLayoutConstraint constraintWithItem:self.backgroundView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant: 0];
    NSLayoutConstraint *bgViewLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.backgroundView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant: 0];
    NSLayoutConstraint *bgViewLayoutWidth = [NSLayoutConstraint constraintWithItem:self.backgroundView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant: kAlertViewWidth];
    NSLayoutConstraint *bgViewLayoutHeight = [NSLayoutConstraint constraintWithItem:self.backgroundView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:0.7f constant: 0.0];

    NSLayoutConstraint *tittleLayoutCenterX = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.backgroundView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant: 0];
    NSLayoutConstraint *tittleLayoutTop = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.backgroundView attribute:NSLayoutAttributeTop multiplier:1.0 constant: 20];
    NSLayoutConstraint *tittleLayoutWidth = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.backgroundView attribute:NSLayoutAttributeWidth multiplier:1.0 constant: -(24 * 2)];

    NSLayoutConstraint *messageLayoutTop = [NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.titleLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant: 12];
    NSLayoutConstraint *messageLayoutLeft = [NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.backgroundView attribute:NSLayoutAttributeLeft multiplier:1.0 constant: 24];
    NSLayoutConstraint *messageLayoutRight = [NSLayoutConstraint constraintWithItem:self.messageLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.backgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant: -24];
    
    NSLayoutConstraint *cancelLayoutWidth = [NSLayoutConstraint constraintWithItem:self.cancelButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant: 100.0];
    NSLayoutConstraint *cancelLayoutHeight= [NSLayoutConstraint constraintWithItem:self.cancelButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant: 36.0];
    NSLayoutConstraint *cancelLayoutLeft= [NSLayoutConstraint constraintWithItem:self.cancelButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.backgroundView attribute:NSLayoutAttributeLeft multiplier:1.0 constant: 24.0];
    NSLayoutConstraint *cancelLayoutTop = [NSLayoutConstraint constraintWithItem:self.cancelButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.messageLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant: 20.0];
    NSLayoutConstraint *cancelLayoutBottom = [NSLayoutConstraint constraintWithItem:self.backgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.cancelButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant: 18.0];
    NSLayoutConstraint *confirmBtnLayoutWidth = [NSLayoutConstraint constraintWithItem:self.confirmButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.cancelButton attribute:NSLayoutAttributeWidth multiplier:1.0 constant: 0];
    NSLayoutConstraint *confirmBtnLayoutHeight = [NSLayoutConstraint constraintWithItem:self.confirmButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.cancelButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant: 0];
    NSLayoutConstraint *confirmBtnLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.confirmButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.cancelButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant: 0];
    NSLayoutConstraint *confirmBtnLayoutRight = [NSLayoutConstraint constraintWithItem:self.confirmButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.backgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant: -24.0];
    
    [self addConstraints:@[bgViewLayoutCenterX,
                           bgViewLayoutCenterY,
                           bgViewLayoutWidth,
                           bgViewLayoutHeight]];
    [self.backgroundView addConstraints:@[tittleLayoutCenterX,
                                          tittleLayoutTop,
                                          tittleLayoutWidth,
                                          messageLayoutTop,
                                          messageLayoutLeft,
                                          messageLayoutRight,
                                          cancelLayoutWidth,
                                          cancelLayoutHeight,
                                          cancelLayoutTop,
                                          cancelLayoutLeft,
                                          cancelLayoutBottom,
                                          confirmBtnLayoutWidth,
                                          confirmBtnLayoutHeight,
                                          confirmBtnLayoutCenterY,
                                          confirmBtnLayoutRight]];
}

#pragma mark - show

- (void)showAlertView {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0f;
    }];
}

#pragma mark - dismiss

- (void)dismissAlertView {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0.0f;
        self.backgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)cancelAction {
    [self dismissAlertView];
    _cancelBlock ? _cancelBlock() : nil;
}
- (void)confirmAction {
    [self dismissAlertView];
    _confirmBlock ? _confirmBlock() :nil;
}

@end
