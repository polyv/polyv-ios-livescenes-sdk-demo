//
//  PLVHCSendMsgView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCSendMessageView.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import "PLVHCSendMessageToolView.h"
#import "PLVHCEmojiSelectView.h"
#import "PLVHCSendMessageTextView.h"
#import "PLVHCRepliedMsgView.h"
#import "PLVEmoticonManager.h"

// 模块
#import "PLVHCChatroomViewModel.h"
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

@interface PLVHCSendMessageView()<
PLVHCEmojiSelectViewDelegate,
UITextViewDelegate
>

#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  └── (UIWindow) window (lowest)
///    ├── (UIView) bgView
///    ├── (PLVHCSendMessageToolView) toolView
///    ├── (PLVHCEmojiSelectView) emojiboard
///    └──  (PLVHCRepliedMsgView) repliedMsgView (懒加载)

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) PLVHCRepliedMsgView *repliedMsgView; // 被回复消息视图
@property (nonatomic, strong) PLVHCEmojiSelectView *emojiboard;
@property (nonatomic, strong) UIView *tempInputView; // 使用局部变量代替属性会在 iOS 9.3.1 上产生内存问题
@property (nonatomic, strong) PLVHCSendMessageToolView *toolView;

#pragma mark 数据
@property (nonatomic, assign) CGFloat bottomHeight; // 设备底部安全区域，默认为 10
@property (nonatomic, assign) CGFloat toolViewHeight; // toolView 高度
@property (nonatomic, assign) CGFloat emojiboardHeight; // emojiBoard 高度
@property (nonatomic, assign) CGFloat keyboardHeight; // keyboard 高度
@property (nonatomic, strong) PLVChatModel *replyModel;
// 当前是否允许使用自定义键盘的隐藏按钮，用于处理搜狗等第三方键盘隐藏按钮事件
@property (nonatomic, assign) BOOL customKeyboardHide;
@property (nonatomic, assign) PLVRoomUserType userType; // 身份类型

@end

/// 设置允许自定义键盘的隐藏延迟时间
static NSInteger kSetCustomKeyboardHideDelayTime = 0.5;

@implementation PLVHCSendMessageView


#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        
        self.bottomHeight = MAX(10, P_SafeAreaBottomEdgeInsets());
        self.toolViewHeight = 44 + self.bottomHeight;
        
        CGFloat emojiboardHeight = 209.0 + self.bottomHeight;
        if ([@"iPad" isEqualToString:[UIDevice currentDevice].model]) {
            emojiboardHeight += 55.0;
        }
        self.emojiboardHeight = emojiboardHeight;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHidden:) name:UIKeyboardWillHideNotification object:nil];
        
        // 提前初始化 sendMsgView，避免弹出时才初始化导致卡顿
        [self bgView];
        [self toolView];
        [self emojiboard];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Public Method ]

- (void)showWithChatModel:(PLVChatModel *)model {
    self.replyModel = model;
    
    if (self.replyModel) { // 需要的时候再初始化，消息回复完毕，或视图关闭了，则设为nil
        _repliedMsgView = [[PLVHCRepliedMsgView alloc] initWithChatModel:self.replyModel];
        __weak typeof(self) weakSelf = self;
        _repliedMsgView.closeButtonHandler = ^{
            weakSelf.replyModel = nil;
        };
    } else {
        _repliedMsgView = nil;
    }
    
    [self addToWindow];
    
    [self.toolView.textView becomeFirstResponder];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSetCustomKeyboardHideDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.customKeyboardHide = YES;
    });
}

- (void)show {
    self.replyModel = nil;
    
    if (_repliedMsgView) {
        [_repliedMsgView removeFromSuperview];
        _repliedMsgView = nil;
    }
    
    [self addToWindow];
    
    [self.toolView.textView becomeFirstResponder];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSetCustomKeyboardHideDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.customKeyboardHide = YES;
    });
}

- (void)showWithAttributedString:(NSAttributedString *)attributedString {
    [self show];
    if (attributedString) {
        self.toolView.textView.attributedText = attributedString;
    }
}

- (void)dismiss {
    self.customKeyboardHide = NO;
    self.toolView.textView.inputView = nil;
    self.toolView.emojiButton.selected = NO;
    [self.toolView.textView reloadInputViews];
    [self.toolView.textView becomeFirstResponder];
    [self.toolView.textView resignFirstResponder];

    [self removeFromWindow];
}

- (void)startClass {
    [self.toolView.textView startClass];
}

- (void)finishClass {
    [self.toolView.textView finishClass];
}

#pragma mark - [ Private Method ]

- (void)addToWindow {
    if (self.bgView.superview) {
        return;
    }
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;

    // 将各个视图添加到主窗口
    [window addSubview:self.bgView];
    [window addSubview:self.toolView];
    [window addSubview:self.emojiboard];
    if (_repliedMsgView) {
        [window addSubview:_repliedMsgView];
    }
    
    // 设置视图 frame 值
    self.bgView.frame = window.bounds;
    self.toolView.frame = CGRectMake(0, kScreenHeight - self.toolViewHeight, kScreenWidth, self.toolViewHeight);
    self.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.emojiboardHeight);
    self.repliedMsgView.frame = CGRectMake(0, CGRectGetMinY(self.toolView.frame) - _repliedMsgView.viewHeight + 1, kScreenWidth, _repliedMsgView.viewHeight);
}

- (void)removeFromWindow {
    [UIView animateWithDuration:0.3 animations:^{
        self.toolView.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.toolViewHeight);
        self.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.emojiboardHeight);
        self.repliedMsgView.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.repliedMsgView.viewHeight);
    } completion:^(BOOL finished) {
        // 将各个视图从主窗口移除
        self.customKeyboardHide = YES;
        [self checkSendBtnEnable:NO];
        [self.bgView removeFromSuperview];
        [self.toolView removeFromSuperview];
        [self.emojiboard removeFromSuperview];
        
        if (self.repliedMsgView) {
            [self.repliedMsgView removeFromSuperview];
            self.repliedMsgView = nil;
        }
        
        self.keyboardHeight = 0;
    }];
}

- (void)changeKeyboard:(BOOL)showEmoji {
    self.customKeyboardHide = NO;
    if (showEmoji) {// 在 iOS 9.3.1 上使用局部变量代替 tempInputView 在打开表情键盘退出时会出现内存问题
        self.tempInputView = [[UIView alloc] initWithFrame:CGRectZero];
        self.toolView.textView.inputView = self.tempInputView;
        [self.toolView.textView reloadInputViews];
        [self.toolView.textView becomeFirstResponder];
    } else {
        self.toolView.textView.inputView = nil;
        [self.toolView.textView reloadInputViews];
        [self.toolView.textView becomeFirstResponder];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        if (showEmoji) {
            self.toolView.frame = CGRectMake(0, kScreenHeight - self.toolViewHeight - self.emojiboardHeight + self.bottomHeight, kScreenWidth, self.toolViewHeight);
            self.emojiboard.frame = CGRectMake(0, kScreenHeight - self.emojiboardHeight, kScreenWidth, self.emojiboardHeight);
            self.repliedMsgView.frame = CGRectMake(0, CGRectGetMinY(self.toolView.frame) - self.repliedMsgView.viewHeight + 1, kScreenWidth, self.repliedMsgView.viewHeight);
        } else {
            self.toolView.frame = CGRectMake(0, kScreenHeight - self.toolViewHeight - self.keyboardHeight + self.bottomHeight, kScreenWidth, self.toolViewHeight);
            self.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.emojiboardHeight);
            self.repliedMsgView.frame = CGRectMake(0, CGRectGetMinY(self.toolView.frame) - self.repliedMsgView.viewHeight + 1, kScreenWidth, self.repliedMsgView.viewHeight);
        }
    }];
    if (!showEmoji) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSetCustomKeyboardHideDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.customKeyboardHide = YES;
        });
    }
}

- (void)checkSendBtnEnable:(BOOL)enable {
    [self.emojiboard sendButtonEnable:enable]; // emoji 面板发送按钮
    self.toolView.textView.enablesReturnKeyAutomatically = enable; //键盘上的发送按钮
}

#pragma mark Getter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [_bgView addGestureRecognizer:gesture];
    }
    return _bgView;
}

- (PLVHCSendMessageToolView *)toolView {
    if (!_toolView) {
        _toolView = [[PLVHCSendMessageToolView alloc] init];
        _toolView.textView.delegate = self;
        
        __weak typeof(self) weakSelf = self;
        _toolView.didTapImagePickerButton = ^{
            [weakSelf imagePickerButtonAction];
            [weakSelf dismiss];
        };
        
        _toolView.didTapEmojiButton = ^(BOOL selected) {
            [weakSelf changeKeyboard:selected];
        };
    }
    return _toolView;
}

- (PLVHCEmojiSelectView *)emojiboard {
    if (!_emojiboard) {
        _emojiboard = [[PLVHCEmojiSelectView alloc] init];
        _emojiboard.delegate = self;
    }
    return _emojiboard;
}

#pragma mark 网络是否可用
- (BOOL)netCan{
    return self.netState > 0 && self.netState < 4;
}

#pragma mark sendMessageAndClearTextView

- (void)sendMessageAndClearTextView {
    if (self.toolView.textView.attributedText.length > 0) {
        NSString *text = [self.toolView.textView plvTextForRange:NSMakeRange(0, self.toolView.textView.attributedText.length)];
        
        if (![self netCan]) {
            [PLVHCUtils showToastInWindowWithMessage:@"当前网络不可用，请检查网络设置"];
        } else {
            BOOL success = [[PLVHCChatroomViewModel sharedViewModel] sendSpeakMessage:text replyChatModel:self.replyModel];
            if (!success) {
                [PLVHCUtils showToastInWindowWithMessage:@"发送消息失败"];
            }
        }
    }
    [self.toolView.textView clearText];
    [self textViewDidChange:self.toolView.textView];
}

#pragma mark Keyboard

- (void)keyboardWillHidden:(NSNotification *)notification {
    if (self.customKeyboardHide) {
        [self removeFromWindow];
    }
}

- (void)showKeyboard {
    [UIView animateWithDuration:0.3 animations:^{
        self.toolView.frame = CGRectMake(0, PLVScreenHeight - self.toolViewHeight - self.keyboardHeight + self.bottomHeight , PLVScreenWidth, self.toolViewHeight);
        self.repliedMsgView.frame = CGRectMake(0, CGRectGetMinY(self.toolView.frame) - self.repliedMsgView.viewHeight + 1, kScreenWidth, self.repliedMsgView.viewHeight);
    }];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapAction {
    [self dismiss];
}

- (void)imagePickerButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(sendMessageViewDidTapImageButton:)]) {
        [self.delegate sendMessageViewDidTapImageButton:self];
    }
}

#pragma mark NSNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    CGFloat height = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    // 中文键盘或第三方键盘第一次弹出时会收到两至三次弹出事件通知
    self.keyboardHeight = height;
    [self showKeyboard];
}

#pragma mark - [ Delegate ]

#pragma mark PLVHCEmojiSelectViewDelegate

- (void)emojiSelectView:(PLVHCEmojiSelectView *)emojiSelectView didSelectEmoticon:(PLVEmoticon *)emoticon {
    if ([self.toolView.textView.text length] >= PLVHCSendMessageMaxTextLength) { // 字数超限
        return;
    }
    NSRange cursorRange = self.toolView.textView.selectedRange;
    NSAttributedString *emojiAttrStr = [self.toolView.textView convertTextWithEmoji:emoticon.text];
    [self.toolView.textView replaceCharactersInRange:cursorRange withAttributedString:emojiAttrStr];
    self.toolView.textView.selectedRange = NSMakeRange(cursorRange.location + emojiAttrStr.length, 0);
    [self textViewDidChange:self.toolView.textView];
}

- (void)emojiSelectView:(PLVHCEmojiSelectView *)emojiSelectView didReceiveEvent:(PLVHCEmojiSelectViewEvent)event {
    if (event == PLVHCEmojiSelectViewEventDelete) {
        NSRange cursorRange = self.toolView.textView.selectedRange;
        if (self.toolView.textView.attributedText.length > 0 && cursorRange.location > 0) {
            [self.toolView.textView replaceCharactersInRange:NSMakeRange(cursorRange.location - 1, 1) withAttributedString:self.toolView.textView.emptyContent];
             self.toolView.textView.selectedRange = NSMakeRange(cursorRange.location - 1, 0);
            [self textViewDidChange:self.toolView.textView];
        }
    } else { // 发送消息
        [self sendMessageAndClearTextView];
        [self dismiss];
    }
}

#pragma mark UITextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self.toolView.textView startEdit];
    [self checkSendBtnEnable:self.toolView.textView.attributedText.length > 0];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.toolView.textView.attributedText.length == 0) {
        [self.toolView.textView endEdit];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [self checkSendBtnEnable:self.toolView.textView.attributedText.length > 0];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(range.length + range.location > textView.text.length) { // Prevent crashing undo bug
        return NO;
    }
    
    if ([text isEqualToString:@"\n"]) {// 点击【发送】按钮
        [self sendMessageAndClearTextView];
        [self dismiss];
        return NO;
    }
    
    // 当前文本框字符长度（中英文、表情键盘上表情为一个字符，系统emoji为两个字符）
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength <= PLVHCSendMessageMaxTextLength);// 字数超限
}

@end
