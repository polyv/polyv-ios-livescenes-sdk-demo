//
//  PLVHCBroadcastAlertView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/12/17.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCBroadcastAlertView.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kPLVHCBroadcastAlertViewWidth = 320.0; // 弹窗宽度限制
static CGFloat kPLVHCBroadcastAlertViewMaxHeight = 254.0; // 弹窗最大高度

@interface PLVHCBroadcastAlertView()

#pragma mark UI
/// view hierarchy
///
/// (UIView) frontWindow (lowest)
///  └──(PLVHCBroadcastAlertView) self
///     └── (UIView) backgroundView
///         ├── (UILabel) titleLabel
///         ├── (UIView) lineView
///         ├── (UITextView) messageTextView
///         └──  (UIButton) confirmButton (top)
@property (nonatomic, strong) UIWindow *frontWindow; // alert需要添加到的window
@property (nonatomic, strong) UIView *backgroundView; // 弹窗承载视图
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UITextView *messageTextView;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

#pragma mark 数据
@property (nonatomic, assign) CGFloat backgroundViewHeight;
@property (nonatomic, copy) PLVHCBroadcastAlertViewBlock confirmBlock; // 确认操作的回调

@end

@implementation PLVHCBroadcastAlertView

#pragma mark - [ Life Cycle ]

+ (PLVHCBroadcastAlertView *)sharedView {
    static dispatch_once_t once;
    static PLVHCBroadcastAlertView *sharedView;
    dispatch_once(&once, ^{
        sharedView = [[self alloc] init];
    });
    [sharedView setupUI];
    return sharedView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat left = 26;
    
    self.backgroundView.frame = CGRectMake((self.bounds.size.width - kPLVHCBroadcastAlertViewWidth) / 2, (self.bounds.size.height - self.backgroundViewHeight ) / 2 , kPLVHCBroadcastAlertViewWidth, self.backgroundViewHeight);
    self.gradientLayer.frame = self.backgroundView.bounds;
    self.titleLabel.frame = CGRectMake(left, 16, kPLVHCBroadcastAlertViewWidth - left * 2, 22);
    self.lineView.frame = CGRectMake(left, CGRectGetMaxY(self.titleLabel.frame) + 12, kPLVHCBroadcastAlertViewWidth - left * 2, 1);
    self.messageTextView.frame = CGRectMake(left, CGRectGetMaxY(self.lineView.frame) + 12, kPLVHCBroadcastAlertViewWidth - left * 2, CGRectGetHeight(self.backgroundView.frame) - CGRectGetMaxY(self.lineView.frame) - 12 - 17 - 36 - 16);
    self.confirmButton.frame = CGRectMake((kPLVHCBroadcastAlertViewWidth - 100) / 2, CGRectGetHeight(self.backgroundView.frame) - 36 - 16, 100, 36);
}

#pragma mark - [ Public Method ]

+ (void)showAlertViewWithMessage:(NSString *)message confirmActionBlock:(PLVHCBroadcastAlertViewBlock)confirmActionBlock {
    PLVHCBroadcastAlertView *alertView = [PLVHCBroadcastAlertView sharedView]; // 只显示最后一个通知，使用单例是为了避免创建多个通知
    if (![PLVFdUtil checkStringUseable:message]) {
        message = @"";
    }
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setMinimumLineHeight:22];
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:message attributes:@{NSFontAttributeName:alertView.messageTextView.font,NSParagraphStyleAttributeName:style}];
    CGFloat messageHeight = [attr boundingRectWithSize:CGSizeMake(kPLVHCBroadcastAlertViewWidth - 26 * 2, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
    CGFloat otherViewHeight = 16 + 22 + 12 + 1 + 12 + 17 + 36 + 16;
    alertView.backgroundViewHeight = MIN(messageHeight + otherViewHeight, kPLVHCBroadcastAlertViewMaxHeight);
    alertView.messageTextView.text = message;
    [alertView showAlertView];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

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
        _backgroundView.layer.cornerRadius = 16.0f;
        _backgroundView.layer.masksToBounds = YES;
        [_backgroundView.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return _backgroundView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:18.0f];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.text = @"广播通知";
    }
    return _titleLabel;
}

- (UITextView *)messageTextView {
    if (!_messageTextView) {
        _messageTextView = [[UITextView alloc]init];
        _messageTextView.font = [UIFont fontWithName:@"PingFang SC" size:14.0f];
        _messageTextView.textColor = [UIColor whiteColor];
        _messageTextView.textContainerInset = UIEdgeInsetsZero;
        _messageTextView.backgroundColor = [UIColor clearColor];
        _messageTextView.editable = NO;
    }
    return _messageTextView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = PLV_UIColorFromRGB(@"#40445a");
    }
    return _lineView;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
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

#pragma mark setupUI

- (void)setupUI {
    self.frame = [UIScreen mainScreen].bounds;
    self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.75/1.0];
    self.alpha = 0;
    [self.frontWindow addSubview:self];
    [self addSubview:self.backgroundView];
    [self.backgroundView addSubview:self.titleLabel];
    [self.backgroundView addSubview:self.lineView];
    [self.backgroundView addSubview:self.messageTextView];
    [self.backgroundView addSubview:self.confirmButton];
}

#pragma mark showAlertView

- (void)showAlertView {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0f;
        self.backgroundView.alpha = 1.0f;
    }];
}

#pragma mark dismissAlertView

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

- (void)confirmAction {
    [self dismissAlertView];
    self.confirmBlock ? self.confirmBlock() : nil;
}

@end
