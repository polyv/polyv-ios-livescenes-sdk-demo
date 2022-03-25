//
//  PLVSAStreamAlertController.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStreamAlertController.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

/**
 弹窗类型
 */

///（文本）
typedef NS_ENUM(NSUInteger, PLVSAAlertTextStyle) {
    PLVSAAlertTextStyleOnlyTitle = 0, // 仅标题
    PLVSAAlertTextStyleOnlyMessage, // 仅提示内容
    PLVSAAlertTextStyleAllText // 标题和提示内容
};
/// （按钮）
typedef NS_ENUM(NSUInteger, PLVSAAlertClickStyle) {
    PLVSAAlertClickStyleOneButton = 0, // 仅有一个按钮
    PLVSAAlertClickStyleTwoButton, // 两个按钮并列排列
};

/// 确认按钮用到的回调类型
typedef void (^PLVAlertConfirmAction)(void);

/// alert 规范预定义
static int kTitleLabelMaxLine = 3; // 提示标题显示行数上限
static int kMessageLabelMaxLine = 4; // 提示文本显示行数上限
static CGFloat kAlertFontSize = 14.0; // 提示文本、按钮标题字体大小

/// alert 尺寸预定义
static CGFloat kAlertWidth = 260.0; // 弹窗宽度
static CGFloat kAlertInnerLeftAndRightGap = 24.0; // 弹窗内部控件与弹窗边界的左右间距
static CGFloat kAlertButtonHeight = 36.0; // 按钮的高度


@interface PLVSAStreamAlertController ()

/// 弹窗总体相关属性
@property (nonatomic, assign) PLVSAAlertTextStyle alertTextStyle; // 弹窗文本类型枚举值
@property (nonatomic, assign) PLVSAAlertClickStyle alertClickStyle; // 弹窗按钮类型枚举值
@property (nonatomic, strong) UIView *contentView; //黑色弹窗背景控件，宽度固定，高度根据内容自适应

/// 提示文本相关属性
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UILabel *messageLabel; // 提示文本控件，宽度固定，最多显示4行
@property (nonatomic, copy) NSString *message; // 提示文本字符串，为空时设置为 null
@property (nonatomic, strong) NSDictionary *messageLabelAttributesDict; // messageLabel 多属性文本显示属性
@property (nonatomic, assign) CGSize minMessageLabelSize; // messageLabel 最小显示宽高
@property (nonatomic, assign) CGSize maxMessageLabelSize; // messageLabel 最大显示宽高

@property (nonatomic, assign) CGSize minTitleLabelSize; // titleLabel 最小显示宽高
@property (nonatomic, assign) CGSize maxTitleLabelSize; // titleLabel 最大显示宽高

/// 按钮相关属性
@property (nonatomic, strong) UIButton *cancelButton; // 取消按钮控件，响应事件仅为隐藏弹窗
@property (nonatomic, copy) NSString *cancelTitle; // 取消按钮标题字符串
@property (nonatomic, copy, nullable) PLVAlertConfirmAction cancelHandler; // 取消按钮响应时执行回调
@property (nonatomic, strong) UIButton *confirmButton; // 确认按钮控件，响应事件除了隐藏弹窗，还可由外部定制
@property (nonatomic, copy) NSString *confirmTitle; // 确认按钮标题字符串
@property (nonatomic, copy, nullable) PLVAlertConfirmAction confirmHandler; // 确认按钮响应时执行回调
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation PLVSAStreamAlertController

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        if (@available(iOS 8.0, *)) {
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        } else {
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
        }
        self.providesPresentationContextTransitionStyle = YES;
        self.definesPresentationContext = YES;
        
        self.minTitleLabelSize = CGSizeMake(kAlertWidth - kAlertInnerLeftAndRightGap * 2, 30);
        self.maxTitleLabelSize = CGSizeMake(kAlertWidth - kAlertInnerLeftAndRightGap * 2, 30 * kTitleLabelMaxLine);

        self.minMessageLabelSize = CGSizeMake(kAlertWidth - kAlertInnerLeftAndRightGap * 2, 20);
        self.maxMessageLabelSize = CGSizeMake(kAlertWidth - kAlertInnerLeftAndRightGap * 2, 20 * kMessageLabelMaxLine);
        self.messageLabelAttributesDict = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Regular" size:kAlertFontSize],
                                            NSForegroundColorAttributeName : PLV_UIColorFromRGB(@"#FFFFFFFF")};
        self.view.backgroundColor = PLV_UIColorFromRGBA(@"#000000",0.5);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.contentView];
    [self.contentView addSubview:self.titleLable];
    [self.contentView addSubview:self.messageLabel];
    [self.contentView addSubview:self.cancelButton];
    [self.contentView addSubview:self.confirmButton];
    [self.confirmButton.layer insertSublayer:self.gradientLayer atIndex:0];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.titleLable.frame = CGRectZero;
    self.messageLabel.frame = CGRectZero;
    // 计算标题和提示文本实际宽高，以及是否需要多行显示
    CGSize titleSize = [self.titleLable.text boundingRectWithSize:self.maxTitleLabelSize
                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                       attributes:@{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:18]}
                                                    context:nil].size;
    BOOL multipleLine = titleSize.height > self.minTitleLabelSize.height;
    CGFloat titleLabelHeight = multipleLine ? titleSize.height + 3 * 2 : self.minTitleLabelSize.height;
    CGSize messageSize = [self.message boundingRectWithSize:self.maxMessageLabelSize
                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                 attributes:self.messageLabelAttributesDict
                                                    context:nil].size;
    multipleLine = messageSize.height > self.minMessageLabelSize.height;
    CGFloat messageLabelHeight = multipleLine ? messageSize.height + 3 * 2 : self.minMessageLabelSize.height;
    // 根据Alert文本类型设置标题和提示文本
    if (self.alertTextStyle == PLVSAAlertTextStyleOnlyTitle) { // 只有标题
        messageLabelHeight = 0;
        self.titleLable.frame = CGRectMake(kAlertInnerLeftAndRightGap, 31, kAlertWidth - kAlertInnerLeftAndRightGap * 2, titleLabelHeight);
    } else if (self.alertTextStyle == PLVSAAlertTextStyleOnlyMessage) { // 只有提示文本
        titleLabelHeight = 0;
        self.messageLabel.frame = CGRectMake(kAlertInnerLeftAndRightGap, 30, kAlertWidth - kAlertInnerLeftAndRightGap * 2, messageLabelHeight);
    } else { // 标题和提示文本都有
        self.titleLable.frame = CGRectMake(kAlertInnerLeftAndRightGap, 31, kAlertWidth - kAlertInnerLeftAndRightGap * 2, titleLabelHeight);
        self.messageLabel.frame = CGRectMake(kAlertInnerLeftAndRightGap, UIViewGetBottom(self.titleLable) + 12, kAlertWidth - kAlertInnerLeftAndRightGap * 2, messageLabelHeight);
    }
    
    CGFloat alertHeight = 120 + titleLabelHeight + messageLabelHeight;
    // 设置弹窗黑色背景位置与大小
    self.contentView.frame = CGRectMake(0, 0, kAlertWidth, alertHeight);
    self.contentView.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    
    // 根据Alert按钮类型设置按钮位置
    if (self.alertClickStyle == PLVSAAlertClickStyleTwoButton) {
        self.cancelButton.frame = CGRectMake(kAlertInnerLeftAndRightGap, CGRectGetMaxY(self.contentView.bounds) - kAlertButtonHeight - 22.7, 100, kAlertButtonHeight);
        self.confirmButton.frame = CGRectMake(CGRectGetMaxX(self.contentView.bounds) -  kAlertInnerLeftAndRightGap - 100, CGRectGetMaxY(self.contentView.bounds) - kAlertButtonHeight - 22.7, 100, kAlertButtonHeight);
        self.gradientLayer.frame = self.confirmButton.bounds;
    } else {
        self.cancelButton.frame = CGRectZero;
        self.confirmButton.frame = CGRectMake(CGRectGetMaxX(self.contentView.bounds) -  67 - 126, CGRectGetMaxY(self.contentView.bounds) - 36 - 23, 126, 36);
        self.gradientLayer.frame = self.confirmButton.bounds;
    }

    
}

#pragma mark - Getter

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = PLV_UIColorFromRGB(@"#2C2C2C");
        _contentView.layer.cornerRadius = 8.0;
    }
    return _contentView;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] init];
        _titleLable.numberOfLines = kTitleLabelMaxLine;
        _titleLable.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18];
        _titleLable.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _titleLable.textAlignment = NSTextAlignmentCenter;
        _titleLable.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _titleLable;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = kMessageLabelMaxLine;
        _messageLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _messageLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:kAlertFontSize];
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _messageLabel;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:kAlertFontSize];
        [_cancelButton setTitleColor:PLV_UIColorFromRGB(@"#0382FF") forState:UIControlStateNormal];
        _cancelButton.backgroundColor = PLV_UIColorFromRGB(@"#2C2C2C");
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.layer.borderColor = PLV_UIColorFromRGB(@"#FF3399FF").CGColor;
        _cancelButton.layer.masksToBounds = YES;
        _cancelButton.layer.borderWidth = 1;
        _cancelButton.layer.cornerRadius = 18;
    }
    return _cancelButton;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:kAlertFontSize];
        [_confirmButton setTitleColor:PLV_UIColorFromRGB(@"#FFFFFF") forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#0080FF").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#3399FF").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
        _gradientLayer.cornerRadius = 18;
    }
    return _gradientLayer;
}

#pragma mark - Action

- (void)cancelButtonAction {
    [self dismissViewControllerAnimated:NO completion:^{
        if (self.cancelHandler) {
            self.cancelHandler();
        }
    }];
}

- (void)confirmButtonAction {
    [self dismissViewControllerAnimated:NO completion:^{
        if (self.confirmHandler) {
            self.confirmHandler();
        }
    }];
}

#pragma mark - Pulbic

+ (instancetype)alertControllerWithTitle:(NSString *)title
                                 Message:(NSString *)message
                       cancelActionTitle:(NSString *)cancelActionTitle
                           cancelHandler:(void(^)(void))cancelHandler
                      confirmActionTitle:(NSString *)confirmActionTitle
                          confirmHandler:(void(^)(void))confirmHandler {
    PLVSAStreamAlertController *alert = [[PLVSAStreamAlertController alloc] init];
    [alert setupAlertTitle:title message:message];
    [alert setupButtonWithCancelTitle:cancelActionTitle confirmTitle:confirmActionTitle];
    alert.cancelHandler = cancelHandler;
    alert.confirmHandler = confirmHandler;
    return alert;
}

#pragma mark - Private

- (void)setupAlertTitle:(NSString *)title message:(NSString *)message {
    // 传入文本容错处理
    if (!title || ![title isKindOfClass:[NSString class]] || title.length == 0) {
        title = @"";
        self.alertTextStyle = PLVSAAlertTextStyleOnlyMessage;
    } else if (!message || ![message isKindOfClass:[NSString class]] || message.length == 0) {
        message = @"null";
        self.alertTextStyle = PLVSAAlertTextStyleOnlyTitle;
    } else {
        self.alertTextStyle = PLVSAAlertTextStyleAllText;
    }
    
    self.titleLable.text = title;
    self.message = message;
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:message
                                                                       attributes:self.messageLabelAttributesDict];
}

- (void)setupButtonWithCancelTitle:(NSString *)cancelTitle confirmTitle:(NSString *)confirmTitle {
    // 传入文本容错处理
    self.alertClickStyle = PLVSAAlertClickStyleTwoButton;
    
    if (!cancelTitle || ![cancelTitle isKindOfClass:[NSString class]] || cancelTitle.length == 0) {
        cancelTitle = @"";
        self.alertClickStyle = PLVSAAlertClickStyleOneButton;
    }
    if (![confirmTitle isKindOfClass:[NSString class]] || confirmTitle.length == 0) {
        confirmTitle = @"确定";
        self.alertClickStyle = PLVSAAlertClickStyleOneButton;
    }
    
    // 设置按钮文本
    [self.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
    [self.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
}


@end
