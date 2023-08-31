//
//  PLVECKeyboardToolView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/8/8.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECKeyboardToolView.h"
#import "PLVECKeyboardTextView.h"
#import "PLVECRepliedMsgView.h"
#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECKeyboardToolView ()<UITextViewDelegate>

#pragma mark 数据
/// keyboard 高度
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) CGRect normalFrame;
@property (nonatomic, assign) BOOL keyboardActivated;
@property (nonatomic, assign) PLVECKeyboardToolMode keyboardToolMode;
@property (nonatomic, copy) NSString *placeholderText;
@property (nonatomic, assign) CGFloat activatedKeyboardToolRectY;
/// 引用回复消息
@property (nonatomic, strong) PLVChatModel * _Nullable replyModel;
/// 当前聊天室键盘是否开启 只对公聊有效 私聊不受影响【默认启用YES】
@property (nonatomic, assign, readonly) BOOL enabledChatKeyboardTool;

#pragma mark UI
/// 文本输入框
@property (nonatomic, strong) PLVECKeyboardTextView *textView;
/// 弹出键盘时，添加在 keyWindow 上，用来响应手势缩起键盘
@property (nonatomic, strong) UIView *gestureView;
@property (nonatomic, strong) UIButton *askQuestionButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UILabel *placeholderLB;

@property (nonatomic, strong) UIView *normalSuperView;
@property (nonatomic, strong) UIView *inactivatedTextAreaView;
@property (nonatomic, strong) UIImageView *leftImageView;
/// 显示被引用回复消息UI
@property (nonatomic, strong) PLVECRepliedMsgView * _Nullable replyModelView;

@end

@implementation PLVECKeyboardToolView

#pragma mark - [ Life Cycle ]
- (instancetype)init {
    self = [super init];
    if (self) {
        _enabledKeyboardTool = YES;
        _activatedKeyboardToolRectY = 0.0;
        [self setupUI];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    UIEdgeInsets areaInsets = [PLVECUtils sharedUtils].areaInsets;
    self.gestureView.frame = [UIScreen mainScreen].bounds;
    self.inactivatedTextAreaView.frame = self.normalFrame;
    self.leftImageView.frame = CGRectMake(8, 8, 16, 16);
  
    if ([self.askQuestionButton.superview isEqual:self.inactivatedTextAreaView]) {
        CGFloat buttonWidth = self.askQuestionButton.hidden ? 0 : 20;
        self.askQuestionButton.frame = CGRectMake(CGRectGetWidth(self.normalFrame) - buttonWidth - 8, CGRectGetHeight(self.normalFrame)/2 - 10, buttonWidth, buttonWidth);
    } else {
        CGFloat buttonWidth = self.askQuestionButton.hidden ? 0 : 26;
        self.askQuestionButton.frame = CGRectMake(areaInsets.left + 16, CGRectGetHeight(self.bounds)/2 - 13, buttonWidth, buttonWidth);
    }
    self.placeholderLB.frame = CGRectMake(CGRectGetMaxX(self.leftImageView.frame) + 6, 0, CGRectGetMinX(self.askQuestionButton.frame) - CGRectGetMaxX(self.leftImageView.frame) - 12, CGRectGetHeight(self.inactivatedTextAreaView.bounds));
    self.sendButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - 46 - areaInsets.right, 0, 30, CGRectGetHeight(self.bounds));
    CGFloat textViewWidth = CGRectGetMinX(self.sendButton.frame) -  CGRectGetMaxX(self.askQuestionButton.frame) - 8 - 16;
    [self.textView setupWithFrame:CGRectMake(CGRectGetMaxX(self.askQuestionButton.frame) + 8, CGRectGetHeight(self.bounds)/2 - 18, textViewWidth, 36)];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Public Method ]

- (void)switchKeyboardToolMode:(PLVECKeyboardToolMode)keyboardToolMode {
    _keyboardToolMode = keyboardToolMode;
    
    self.askQuestionButton.selected = (self.keyboardToolMode == PLVECKeyboardToolModeAskQuestion);
    [self updatePlaceholderLabelText];
}

- (void)setEnableAskQuestion:(BOOL)enableAskQuestion {
    _enableAskQuestion = enableAskQuestion;
    self.askQuestionButton.hidden = !enableAskQuestion;
}

- (void)addTextViewToParentView:(UIView *)parentView {
    self.normalSuperView = parentView;
    [self.normalSuperView addSubview:self.inactivatedTextAreaView];
    [self.normalSuperView addSubview:self];
}

/// 更新布局
- (void)updateTextViewFrame:(CGRect)rect {
    self.normalFrame = rect;
    self.inactivatedTextAreaView.frame = rect;
    [self layoutSubviews];
}

/// 回复某条消息
- (void)replyChatModel:(PLVChatModel *)model {
    [self updateReplyModel:model];
    
    [self textAreaViewTapAction:nil];
}

- (void)changePlaceholderText:(NSString *)text {
    self.placeholderText = text;
    [self updatePlaceholderLabelText];
}

- (void)setEnabledKeyboardTool:(BOOL)enabledKeyboardTool {
    _enabledKeyboardTool = enabledKeyboardTool;
    
    if (!self.enabledChatKeyboardTool) {
        [self tapAction:nil];
    }
    [self updatePlaceholderLabelText];
}

#pragma mark - [ Private Method ]
- (void)setupUI {
    self.keyboardToolMode = PLVECKeyboardToolModeNormal;
    self.placeholderText = @"聊点什么吧~";
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#262523"];
    self.hidden = YES;
    self.frame = CGRectMake(0, PLVScreenHeight, PLVScreenWidth, 52);
    
    [self addSubview:self.textView];
    [self addSubview:self.sendButton];
    [self.inactivatedTextAreaView addSubview:self.leftImageView];
    [self.inactivatedTextAreaView addSubview:self.askQuestionButton];
    [self.inactivatedTextAreaView addSubview:self.placeholderLB];
}

/// 触发发送消息回调，隐藏面板
- (void)sendTextAndClearTextView {
    if (self.textView.attributedText.length > 0) {
        NSString *text = [self.textView plvTextForRange:NSMakeRange(0, self.textView.attributedText.length)];
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:sendText:replyModel:)]) {
            [self.delegate keyboardToolView:self sendText:text replyModel:self.replyModel];
        }
    }
    [self.textView clearText];
    [self tapAction:nil];
    [self textViewDidChange:self.textView];
}

- (void)updateReplyModel:(PLVChatModel *)model {
    self.replyModel = model;
    
    if (self.replyModel) {
        self.replyModelView = [[PLVECRepliedMsgView alloc] initWithChatModel:model];
        self.replyModelView.frame = CGRectMake(0, CGRectGetMinY(self.frame), CGRectGetWidth(self.frame), self.replyModelView.viewHeight);
        __weak typeof(self) weakSelf = self;
        [self.replyModelView setCloseButtonHandler:^{
            [weakSelf updateReplyModel:nil];
        }];
    } else {
        [self.replyModelView removeFromSuperview];
        self.replyModelView = nil;
    }
}

- (void)checkSendBtnEnable:(BOOL)enable {
    self.sendButton.enabled = enable; // 发送按钮
    self.textView.enablesReturnKeyAutomatically = enable; //输入 textView 发送按钮
}

- (void)animateAddToWindow {
    self.activatedKeyboardToolRectY = PLVScreenHeight - self.bounds.size.height - self.keyboardHeight;
    [self addViewInWindow];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{ // 动画效果有点问题，暂时移除动画
        // 设置视图 frame 值
        CGRect selfRect = weakSelf.frame;
        weakSelf.frame = CGRectMake(0, weakSelf.activatedKeyboardToolRectY, PLVScreenWidth, selfRect.size.height);
        if (weakSelf.replyModelView) {
            CGFloat replyModelViewHeight = weakSelf.replyModelView.viewHeight;
            weakSelf.replyModelView.frame = CGRectMake(0, weakSelf.frame.origin.y - replyModelViewHeight, CGRectGetWidth(weakSelf.bounds), replyModelViewHeight);
        }
    }];
}

- (void)addViewInWindow {
    self.hidden = NO;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (self.superview == window) {
        return;
    }
        
    // 将各个视图添加到主窗口
    [window addSubview:self.gestureView];
    [window addSubview:self.replyModelView];
    [window addSubview:self];
    [self addSubview:self.askQuestionButton];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:popBoard:)]) {
        [self.delegate keyboardToolView:self popBoard:YES];
    }
}

- (void)animateRemoveFromWindow {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (self.superview != window) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect selfRect = weakSelf.frame;
        weakSelf.frame = CGRectMake(0, PLVScreenHeight - selfRect.size.height, PLVScreenWidth, selfRect.size.height);
    } completion:^(BOOL finished) {
        [weakSelf addViewInOriginView];
    }];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:popBoard:)]) {
        [self.delegate keyboardToolView:self popBoard:NO];
    }
}


- (void)addViewInOriginView {
    if (self.superview == self.normalSuperView) {
        return;
    }
    
    // 将各个视图从主窗口移除
    [self removeFromSuperview];
    [self.gestureView removeFromSuperview];
    // 将 self 和 askQuestionButton 添加到原先的父视图
    self.hidden = YES;
    [self.normalSuperView addSubview:self];
    [self.inactivatedTextAreaView addSubview:self.askQuestionButton];
    // 设置视图 frame 值
    CGRect selfRect = self.frame;
    self.frame = CGRectMake(0, PLVScreenHeight, PLVScreenWidth, selfRect.size.height);
}

- (void)updatePlaceholderLabelText {
    if ((self.keyboardToolMode == PLVECKeyboardToolModeAskQuestion)) {
        self.placeholderLB.text = @"发起提问";
    } else if ([PLVFdUtil checkStringUseable:self.placeholderText]) {
        self.placeholderLB.text = self.placeholderText;
    } else {
        self.placeholderLB.text = @"聊点什么吧~";
    }
    [self.textView changePlaceholderText:self.placeholderLB.text];
}

#pragma mark - Getterr & Setter
- (UIView *)inactivatedTextAreaView {
    if (!_inactivatedTextAreaView) {
        _inactivatedTextAreaView = [[UIView alloc] init];
        _inactivatedTextAreaView.layer.cornerRadius = 16.0;
        _inactivatedTextAreaView.layer.masksToBounds = YES;
        _inactivatedTextAreaView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textAreaViewTapAction:)];
        [_inactivatedTextAreaView addGestureRecognizer:tapGesture];
    }
    return _inactivatedTextAreaView;
}

- (UIImageView *)leftImageView {
    if (!_leftImageView) {
        _leftImageView = [[UIImageView alloc] init];
        _leftImageView.image = [PLVECUtils imageForWatchResource:@"plv_chat_img"];
    }
    return _leftImageView;
}

- (UILabel *)placeholderLB {
    if (!_placeholderLB) {
        _placeholderLB = [[UILabel alloc] init];
        _placeholderLB.text = self.placeholderText;
        _placeholderLB.font = [UIFont systemFontOfSize:14];
        _placeholderLB.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        _placeholderLB.lineBreakMode = NSLineBreakByCharWrapping;
    }
    return _placeholderLB;
}

- (UIButton *)askQuestionButton {
    if (!_askQuestionButton) {
        _askQuestionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *defaultImage = [PLVECUtils imageForWatchResource:@"plv_chatroom_askquestion_default_btn"];
        UIImage *selectedImage = [PLVECUtils imageForWatchResource:@"plv_chatroom_askquestion_selected_btn"];
        [_askQuestionButton setImage:defaultImage forState:UIControlStateNormal];
        [_askQuestionButton setImage:selectedImage forState:UIControlStateSelected];
        [_askQuestionButton addTarget:self action:@selector(askQuestionButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _askQuestionButton;
}

- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFA611"] forState:UIControlStateNormal];
        [_sendButton setTitleColor:[PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.4] forState:UIControlStateDisabled];
        [_sendButton addTarget:self action:@selector(sendButtonButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

- (PLVECKeyboardTextView *)textView {
    if (!_textView) {
        _textView = [[PLVECKeyboardTextView alloc] init];
        _textView.delegate = self;
        _textView.backgroundColor = [PLVColorUtil colorFromHexString:@"#373635"];
    }
    return _textView;
}

- (UIView *)gestureView {
    if (!_gestureView) {
        _gestureView = [[UIView alloc] init];
        _gestureView.frame = [UIScreen mainScreen].bounds;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [_gestureView addGestureRecognizer:tap];
    }
    return _gestureView;
}

- (BOOL)enabledChatKeyboardTool {
    return (_enabledKeyboardTool || self.keyboardToolMode == PLVECKeyboardToolModeAskQuestion);
}

#pragma mark - [ Event ]
#pragma mark - Action
- (void)askQuestionButton:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    self.keyboardToolMode = (sender.selected ? PLVECKeyboardToolModeAskQuestion : PLVECKeyboardToolModeNormal);
    [self updatePlaceholderLabelText];
    if (!self.enabledChatKeyboardTool) {
        [self tapAction:nil];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:keyboardToolModeChanged:)]) {
        [self.delegate keyboardToolView:self keyboardToolModeChanged:self.keyboardToolMode];
    }
}

- (void)sendButtonButton:(UIButton *)sender {
    [self sendTextAndClearTextView];
}

- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer {
    if (!self.keyboardActivated) {
        return;
    }
    
    self.keyboardActivated = NO;
    [self animateRemoveFromWindow];
    [self updateReplyModel:nil];
    [self updatePlaceholderLabelText];
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
    }
}

- (void)textAreaViewTapAction:(UIGestureRecognizer *)gestureRecognizer {
    if (!self.enabledChatKeyboardTool) {
        return;
    }
    
    self.keyboardActivated = YES;
    if (!self.textView.isFirstResponder) {
        [self.textView becomeFirstResponder];
    }
}

#pragma mark - NSNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    self.keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    // 中文键盘或第三方键盘第一次弹出时会收到两至三次弹出事件通知，会导致动画效果不连续流畅，暂无更好解决方案
    if (self.textView.isFirstResponder && self.keyboardActivated) {
        [self animateAddToWindow];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    
}

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    if (self.keyboardActivated) {
        [self tapAction:nil];
    }
}

#pragma mark - UITextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self.textView startEdit];
    [self checkSendBtnEnable:self.textView.attributedText.length > 0];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.textView.attributedText.length == 0) {
        [self.textView endEdit];
    }
    [self tapAction:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(range.length + range.location > textView.text.length) { // Prevent crashing undo bug
        return NO;
    }
    
    if ([text isEqualToString:@"\n"]) {// 点击【发送】按钮
        [self sendTextAndClearTextView];
        return NO;
    }
    
    // 当前文本框字符长度（中英文、表情键盘上表情为一个字符，系统emoji为两个字符）
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength <= PLVECKeyboardMaxTextLength);// 字数超限
}

- (void)textViewDidChange:(UITextView *)textView {
    [self checkSendBtnEnable:self.textView.attributedText.length > 0];
    [self.textView attributedTextDidChange];
}

@end
