//
//  PLVAlertViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/3/2.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVAlertViewController.h"

/// 确认按钮用到的回调类型
typedef void (^PLVAlertConfirmAction)(void);

/// alert 规范预定义
static int kMessageLabelMaxLine = 4; // 提示文本显示行数上限
static CGFloat kAlertFontSize = 14.0; // 提示文本、按钮标题字体大小

/// alert 尺寸预定义
static CGFloat kAlertWidth = 228.0; // 弹窗宽度
static CGFloat kAlertInnerLeftAndRightGap = 20.0; // 弹窗内部控件与弹窗边界的左右间距
static CGFloat kAlertButtonHeight = 40.0; // 按钮的高度

/// 弹窗类型
typedef NS_ENUM(NSUInteger, PLVAlertStyle) {
    PLVAlertStyleOneButton = 0, // 仅有一个按钮
    PLVAlertStyleTwoButtonInOneLine, // 两个按钮并列排列
    PLVAlertStyleTwoButtonInTwoLine // 两个按钮上下排列
};

@interface PLVAlertViewController ()

/// 弹窗总体相关属性
@property (nonatomic, assign) PLVAlertStyle alertStyle; // 弹窗类型枚举值
@property (nonatomic, strong) UIView *contentView; //黑色弹窗背景控件，宽度固定，高度根据内容自适应
@property (nonatomic, strong) UIView *splitLine; // 提示文本与按钮之间的分割线控件
@property (nonatomic, strong) UIView *buttonSplitLine; // 两个按钮之间的分割线控件

/// 提示文本相关属性
@property (nonatomic, strong) UILabel *messageLabel; // 提示文本控件，宽度固定，最多显示4行
@property (nonatomic, copy) NSString *message; // 提示文本字符串，为空时设置为 null
@property (nonatomic, strong) NSDictionary *messageLabelAttributesDict; // messageLabel 多属性文本显示属性
@property (nonatomic, assign) CGSize minMessageLabelSize; // messageLabel 最小显示宽高
@property (nonatomic, assign) CGSize maxMessageLabelSize; // messageLabel 最大显示宽高

/// 按钮相关属性
@property (nonatomic, strong) UIButton *cancelButton; // 取消按钮控件，响应事件仅为隐藏弹窗
@property (nonatomic, copy) NSString *cancelTitle; // 取消按钮标题字符串
@property (nonatomic, copy, nullable) PLVAlertConfirmAction cancelHandler; // 取消按钮响应时执行回调
@property (nonatomic, strong) UIButton *confirmButton; // 确认按钮控件，响应事件除了隐藏弹窗，还可由外部定制
@property (nonatomic, copy) NSString *confirmTitle; // 确认按钮标题字符串
@property (nonatomic, copy, nullable) PLVAlertConfirmAction confirmHandler; // 确认按钮响应时执行回调

@end

@implementation PLVAlertViewController

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
        
        self.minMessageLabelSize = CGSizeMake(kAlertWidth - kAlertInnerLeftAndRightGap * 2, 20);
        self.maxMessageLabelSize = CGSizeMake(kAlertWidth - kAlertInnerLeftAndRightGap * 2, 20 * kMessageLabelMaxLine);
        self.messageLabelAttributesDict = @{NSFontAttributeName : [UIFont systemFontOfSize:kAlertFontSize],
                                            NSForegroundColorAttributeName : [UIColor whiteColor]};
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.contentView];
    [self.contentView addSubview:self.messageLabel];
    [self.contentView addSubview:self.cancelButton];
    [self.contentView addSubview:self.confirmButton];
    [self.contentView addSubview:self.splitLine];
    [self.contentView addSubview:self.buttonSplitLine];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // 计算提示文本实际宽高，以及是否需要多行显示
    CGSize messageSize = [self.message boundingRectWithSize:self.maxMessageLabelSize
                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                 attributes:self.messageLabelAttributesDict
                                                    context:nil].size;
    BOOL multipleLine = messageSize.height > self.minMessageLabelSize.height;
    
    // 设置提示文本位置与大小
    CGFloat messageTopGap = multipleLine ? 20 - 3 : 27; // 比实际计算出的高度多预留出上下各3pt，作为计算误差的包容
    CGFloat messageLabelHeight = multipleLine ? messageSize.height + 3 * 2 : self.minMessageLabelSize.height;
    self.messageLabel.frame = CGRectMake(kAlertInnerLeftAndRightGap, messageTopGap, kAlertWidth - kAlertInnerLeftAndRightGap * 2, messageLabelHeight);
    
    // 设置提示文本与按钮之间的分割线位置与大小
    CGFloat topPartHeight = messageLabelHeight + messageTopGap * 2;
    self.splitLine.frame = CGRectMake(0, topPartHeight, kAlertWidth, 1.0);
    
    // 设置按钮与按钮之间的分割线(如果需要的话)位置与大小
    self.confirmButton.frame = CGRectZero;
    self.buttonSplitLine.frame = CGRectZero;
    if (self.alertStyle == PLVAlertStyleOneButton) {
        self.cancelButton.frame = CGRectMake(0, CGRectGetMaxY(self.splitLine.frame), kAlertWidth, kAlertButtonHeight);
    } else if (self.alertStyle == PLVAlertStyleTwoButtonInOneLine) {
        self.cancelButton.frame = CGRectMake(0, CGRectGetMaxY(self.splitLine.frame), kAlertWidth / 2.0, kAlertButtonHeight);
        self.buttonSplitLine.frame = CGRectMake(kAlertWidth / 2.0 - 0.5, CGRectGetMaxY(self.splitLine.frame), 1, kAlertButtonHeight);
        self.confirmButton.frame = CGRectMake(kAlertWidth / 2.0, CGRectGetMaxY(self.splitLine.frame), kAlertWidth / 2.0, kAlertButtonHeight);
    } else {
        self.confirmButton.frame = CGRectMake(0, CGRectGetMaxY(self.splitLine.frame), kAlertWidth, kAlertButtonHeight);
        self.buttonSplitLine.frame = CGRectMake(0, CGRectGetMaxY(self.confirmButton.frame) - 0.5, kAlertWidth, 1);
        self.cancelButton.frame = CGRectMake(0, CGRectGetMaxY(self.confirmButton.frame), kAlertWidth, kAlertButtonHeight);
    }
    
    // 设置弹窗黑色背景位置与大小
    self.contentView.frame = CGRectMake(0, 0, kAlertWidth, CGRectGetMaxY(self.cancelButton.frame));
    self.contentView.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
}

#pragma mark - Getter

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
        _contentView.layer.cornerRadius = 8.0;
    }
    return _contentView;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = kMessageLabelMaxLine;
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _messageLabel;
}

- (UIView *)splitLine {
    if (!_splitLine) {
        _splitLine = [[UIView alloc] init];
        _splitLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.1];
    }
    return _splitLine;
}

- (UIView *)buttonSplitLine {
    if (!_buttonSplitLine) {
        _buttonSplitLine = [[UIView alloc] init];
        _buttonSplitLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.1];
    }
    return _buttonSplitLine;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:kAlertFontSize];
        [_cancelButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.8] forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor colorWithWhite:1 alpha:1] forState:UIControlStateHighlighted];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:kAlertFontSize];
        [_confirmButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.8] forState:UIControlStateNormal];
        [_confirmButton setTitleColor:[UIColor colorWithWhite:1 alpha:1] forState:UIControlStateHighlighted];
        [_confirmButton addTarget:self action:@selector(confirmButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
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

+ (instancetype)alertControllerWithMessage:(NSString *)message
                         cancelActionTitle:(NSString *)cancelActionTitle
                             cancelHandler:(void(^)(void))cancelHandler {
    return [PLVAlertViewController alertControllerWithMessage:message cancelActionTitle:cancelActionTitle cancelHandler:cancelHandler confirmActionTitle:nil confirmHandler:nil];
}

+ (instancetype)alertControllerWithMessage:(NSString *)message
                         cancelActionTitle:(NSString *)cancelActionTitle
                             cancelHandler:(void(^)(void))cancelHandler
                        confirmActionTitle:(NSString *)confirmActionTitle
                            confirmHandler:(void(^)(void))confirmHandler {
    PLVAlertViewController *alert = [[PLVAlertViewController alloc] init];
    [alert setupAlertMessage:message];
    [alert setupButtonWithCancelTitle:cancelActionTitle confirmTitle:confirmActionTitle];
    alert.cancelHandler = cancelHandler;
    alert.confirmHandler = confirmHandler;
    return alert;
}

#pragma mark - Private

- (void)setupAlertMessage:(NSString *)message {
    // 传入文本容错处理
    if (!message || ![message isKindOfClass:[NSString class]] || message.length == 0) {
        message = @"null";
    }
    
    self.message = message;
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:message
                                                                       attributes:self.messageLabelAttributesDict];
}

- (void)setupButtonWithCancelTitle:(NSString *)cancelTitle confirmTitle:(NSString *)confirmTitle {
    // 传入文本容错处理
    if (!cancelTitle || ![cancelTitle isKindOfClass:[NSString class]] || cancelTitle.length == 0) {
        cancelTitle = @"取消";
    }
    if (![confirmTitle isKindOfClass:[NSString class]] || confirmTitle.length == 0) {
        confirmTitle = nil;
    }
    
    // 设置按钮文本
    [self.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
    if (confirmTitle) {
        [self.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
    }
    
    // 计算按钮文本宽度
    CGSize cancelTextSize = [cancelTitle boundingRectWithSize:CGSizeMake(kAlertWidth, 20) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:kAlertFontSize]} context:nil].size;
    CGSize confirmTextSize = CGSizeZero;
    if (confirmTitle) {
        confirmTextSize = [confirmTitle boundingRectWithSize:CGSizeMake(kAlertWidth, 20) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:kAlertFontSize]} context:nil].size;
    }
    
    // 根据上面的计算结果，获取弹窗类型
    if (!confirmTitle) {
        self.alertStyle = PLVAlertStyleOneButton;
    } else if (cancelTextSize.width < kAlertWidth / 2.0 && confirmTextSize.width < kAlertWidth / 2.0) {
        self.alertStyle = PLVAlertStyleTwoButtonInOneLine;
    } else {
        self.alertStyle = PLVAlertStyleTwoButtonInTwoLine;
    }
}

@end
