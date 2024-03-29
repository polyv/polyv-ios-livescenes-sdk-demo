//
//  PLVLSSendMessageView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/18.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSendMessageView.h"
#import "PLVLSSendMessageToolView.h"
#import "PLVLSEmojiSelectView.h"
#import "PLVLSSendMessageTextView.h"
#import "PLVLSRepliedMsgView.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLSChatroomViewModel.h"
#import "PLVEmoticonManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVImagePickerViewController.h"

#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

@interface PLVLSSendMessageView ()<
PLVLSEmojiSelectViewProtocol,
UITextViewDelegate
>

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) PLVLSRepliedMsgView *repliedMsgView; // 被回复消息视图
@property (nonatomic, strong) PLVLSSendMessageToolView *toolView;
@property (nonatomic, strong) PLVLSEmojiSelectView *emojiboard;
@property (nonatomic, strong) PLVImagePickerViewController *imagePicker;
@property (nonatomic, strong) UIView *tempInputView; // 使用局部变量代替属性会在 iOS 9.3.1 上产生内存问题

@property (nonatomic, assign) CGFloat bottomHeight; // 设备底部安全区域，默认为 10
@property (nonatomic, assign) CGFloat toolViewHeight; // toolView 高度
@property (nonatomic, assign) CGFloat emojiboardHeight; // emojiBoard 高度
@property (nonatomic, assign) CGFloat keyboardHeight; // keyboard 高度
@property (nonatomic, assign) BOOL remindMsg; // 是否为提醒消息
@property (nonatomic, assign) BOOL selectedEmojiboard; // 是否选择了表情键盘

@property (nonatomic, strong) PLVChatModel *replyModel;

@end

@implementation PLVLSSendMessageView 

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithRemindMsg:NO];
}

- (instancetype)initWithRemindMsg:(BOOL)remindMsg {
    self = [super init];
    if (self) {
        self.remindMsg = remindMsg;
        self.bottomHeight = MAX(10, P_SafeAreaBottomEdgeInsets());
        self.toolViewHeight = 44 + self.bottomHeight;
        self.emojiboardHeight = 209.0 + self.bottomHeight;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        
        // 提前初始化 sendMsgView，避免弹出时才初始化导致卡顿
        [self bgView];
        [self toolView];
        [self emojiboard];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getter && Setter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [_bgView addGestureRecognizer:gesture];
    }
    return _bgView;
}

- (PLVLSSendMessageToolView *)toolView {
    if (!_toolView) {
        _toolView = [[PLVLSSendMessageToolView alloc] init];
        _toolView.textView.delegate = self;
        
        __weak typeof(self) weakSelf = self;
        _toolView.didTapImagePickerButton = ^{
            [weakSelf imagePickerButtonAction];
            [weakSelf dismiss];
        };
        _toolView.didTapSendButton = ^{
            [weakSelf sendMessageAndClearTextView];
            [weakSelf dismiss];
        };
        _toolView.didTapEmojiButton = ^(BOOL selected) {
            weakSelf.selectedEmojiboard = selected;
            [weakSelf changeKeyboard:selected];
        };
    }
    return _toolView;
}

- (PLVLSEmojiSelectView *)emojiboard {
    if (!_emojiboard) {
        _emojiboard = [[PLVLSEmojiSelectView alloc] initWithRemindMsg:self.remindMsg];
        _emojiboard.delegate = self;
    }
    return _emojiboard;
}

- (PLVImagePickerViewController *)imagePicker {
    if (!_imagePicker) {
        _imagePicker = [[PLVImagePickerViewController alloc] initWithColumnNumber:8];
        
        __weak typeof(self)weakSelf = self;
        [_imagePicker setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
            if ([photos isKindOfClass:NSArray.class]) {
                [weakSelf sendImageWithImage:photos.firstObject];
                //clean选中缓存
                weakSelf.imagePicker.selectedAssets = [NSMutableArray array];
                [weakSelf.imagePicker popViewControllerAnimated:NO];
            }
        }];
        
        [_imagePicker setImagePickerControllerDidCancelHandle:^{
            //clean选中缓存
            weakSelf.imagePicker.selectedAssets = [NSMutableArray array];
            [weakSelf.imagePicker popViewControllerAnimated:NO];
        }];
    }
    return _imagePicker;
}

- (void)setImageEmotionArray:(NSArray *)imageEmotionArray {
    self.emojiboard.imageEmotions = imageEmotionArray;
}

#pragma mark - Action

- (void)tapAction {
    [self dismiss];
}

- (void)imagePickerButtonAction {
    __weak typeof(self)weakSelf = self;
    [PLVAuthorizationManager requestAuthorizationWithType:PLVAuthorizationTypePhotoLibrary completion:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [[PLVLSUtils sharedUtils].homeVC presentViewController:weakSelf.imagePicker animated:YES completion:nil];
            } else {
                [PLVLSUtils showAlertWithMessage:PLVLocalizedString(@"应用需要获取您的相册权限，请前往设置") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"设置") confirmActionBlock:^{
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }];
            }
        });
    }];
}

#pragma mark - Public

- (void)showWithChatModel:(PLVChatModel *)model {
    self.replyModel = model;
    
    if (self.replyModel) { // 需要的时候再初始化，消息回复完毕，或视图关闭了，则设为nil
        _repliedMsgView = [[PLVLSRepliedMsgView alloc] initWithChatModel:self.replyModel];
        __weak typeof(self) weakSelf = self;
        _repliedMsgView.closeButtonHandler = ^{
            weakSelf.replyModel = nil;
        };
    } else {
        _repliedMsgView = nil;
    }
    
    [self addToWindow];
    
    [self.toolView.textView becomeFirstResponder];
}

- (void)show {
    self.replyModel = nil;
    
    if (_repliedMsgView) {
        [_repliedMsgView removeFromSuperview];
        _repliedMsgView = nil;
    }
    
    [self addToWindow];
    
    [self.toolView.textView becomeFirstResponder];
}

- (void)dismiss {
    [self resignTextView];
    self.toolView.textView.inputView = nil;
    self.toolView.tapGesture.enabled = NO;
    [self.toolView.textView reloadInputViews];
    [self.toolView.textView becomeFirstResponder];
    [self.toolView.textView resignFirstResponder];
    
    [self removeFromWindow];
}

#pragma mark - Private

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
        self.repliedMsgView.frame = CGRectMake(0, kScreenHeight, kScreenWidth, _repliedMsgView.viewHeight);
    } completion:^(BOOL finished) {
        // 将各个视图从主窗口移除
        [self.bgView removeFromSuperview];
        [self.toolView removeFromSuperview];
        [self.emojiboard removeFromSuperview];
        
        if (_repliedMsgView) {
            [_repliedMsgView removeFromSuperview];
            _repliedMsgView = nil;
        }
        
        self.keyboardHeight = 0;
        self.selectedEmojiboard = NO;
    }];
}

- (void)resignTextView {
    self.toolView.textView.inputView = nil;
    [self.toolView.textView reloadInputViews];
    [self.toolView.textView becomeFirstResponder];
    [self.toolView.textView resignFirstResponder];
}

- (void)changeKeyboard:(BOOL)showEmoji {
    if (showEmoji) {// 在 iOS 9.3.1 上使用局部变量代替 tempInputView 在打开表情键盘退出时会出现内存问题
        [self resignTextView];
        [self.toolView.textView startEdit];
    } else {
        self.toolView.textView.inputView = nil;
        [self.toolView.textView reloadInputViews];
        [self.toolView.textView becomeFirstResponder];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        if (showEmoji) {
            self.toolView.frame = CGRectMake(0, kScreenHeight - self.toolViewHeight - self.emojiboardHeight + self.bottomHeight, kScreenWidth, self.toolViewHeight);
            self.emojiboard.frame = CGRectMake(0, kScreenHeight - self.emojiboardHeight, kScreenWidth, self.emojiboardHeight);
            self.repliedMsgView.frame = CGRectMake(0, CGRectGetMinY(self.toolView.frame) - _repliedMsgView.viewHeight + 1, kScreenWidth, _repliedMsgView.viewHeight);
        } else {
            self.toolView.frame = CGRectMake(0, kScreenHeight - self.toolViewHeight - self.keyboardHeight + self.bottomHeight, kScreenWidth, self.toolViewHeight);
            self.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.emojiboardHeight);
            self.repliedMsgView.frame = CGRectMake(0, CGRectGetMinY(self.toolView.frame) - _repliedMsgView.viewHeight + 1, kScreenWidth, _repliedMsgView.viewHeight);
        }
    }];
}

- (void)checkSendBtnEnable:(BOOL)enable {
    [self.emojiboard sendButtonEnable:enable]; // emoji 面板发送按钮
    self.toolView.sendButton.enabled = enable; // 工具栏右侧发送按钮
    self.toolView.textView.enablesReturnKeyAutomatically = enable; //键盘上的发送按钮
}

#pragma mark - Send Message

- (void)sendMessageAndClearTextView {
    if (self.toolView.textView.attributedText.length > 0) {
        NSString *text = [self.toolView.textView plvTextForRange:NSMakeRange(0, self.toolView.textView.attributedText.length)];
        
        BOOL success = NO;
        if (self.remindMsg) {
            success = [[PLVLSChatroomViewModel sharedViewModel] sendRemindSpeakMessage:text];
        } else {
            success = [[PLVLSChatroomViewModel sharedViewModel] sendSpeakMessage:text replyChatModel:self.replyModel];
        }
        
        if (!success) {
            [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"发送消息失败")];
        }
    }
    [self.toolView.textView clearText];
    [self textViewDidChange:self.toolView.textView];
}

- (void)sendImageWithImage:(UIImage *)image {
    BOOL success = NO;
    if (self.remindMsg) {
        success = [[PLVLSChatroomViewModel sharedViewModel] sendRemindImageMessage:image];
    } else {
        success = [[PLVLSChatroomViewModel sharedViewModel] sendImageMessage:image];
    }
    if (!success) {
        [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"消息发送失败")];
    }
}

#pragma mark - NSNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    CGFloat height = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    // 中文键盘或第三方键盘第一次弹出时会收到两至三次弹出事件通知
    self.keyboardHeight = height;
    [self showKeyboard];
}

- (void)showKeyboard {
    [UIView animateWithDuration:0.3 animations:^{
        self.toolView.frame = CGRectMake(0, PLVScreenHeight - self.toolViewHeight - self.keyboardHeight + self.bottomHeight , PLVScreenWidth, self.toolViewHeight);
        self.repliedMsgView.frame = CGRectMake(0, CGRectGetMinY(self.toolView.frame) - _repliedMsgView.viewHeight + 1, kScreenWidth, _repliedMsgView.viewHeight);
    }];
}

#pragma mark - PLVLSEmojiSelectView Protocol

- (void)emojiSelectView_didSelectEmoticon:(PLVEmoticon *)emoticon {
    if ([self.toolView.textView.text length] >= PLVLSSendMessageMaxTextLength) { // 字数超限
        return;
    }
    NSRange cursorRange = self.toolView.textView.selectedRange;
    NSAttributedString *emojiAttrStr = [self.toolView.textView convertTextWithEmoji:emoticon.text];
    [self.toolView.textView replaceCharactersInRange:cursorRange withAttributedString:emojiAttrStr];
    self.toolView.textView.selectedRange = NSMakeRange(cursorRange.location + emojiAttrStr.length, 0);
    [self textViewDidChange:self.toolView.textView];
}

- (void)emojiSelectView_didReceiveEvent:(PLVLSEmojiSelectViewEvent)event {
    if (event == PLVLSEmojiSelectViewEventDelete) {
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

- (void)emojiSelectView_sendImageEmoticon:(PLVImageEmotion *)emoticon {
    if (!emoticon.imageId || ![emoticon.imageId isKindOfClass:[NSString class]]) {
        return;
    }
    BOOL success = [[PLVLSChatroomViewModel sharedViewModel] sendImageEmotionMessage:emoticon.imageId imageUrl:emoticon.url];
     if (!success) {
         [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"发送消息失败")];
     } else {
         //隐藏面板
         [self dismiss];
     }
 }

#pragma mark - UITextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.toolView.emojiButton.selected = NO;
    [self.toolView.textView startEdit];
    [self checkSendBtnEnable:self.toolView.textView.attributedText.length > 0];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.toolView.textView.attributedText.length == 0) {
        [self.toolView.textView endEdit];
    }
    
    if (!self.selectedEmojiboard) {
        [self removeFromWindow];
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
    return (newLength <= PLVLSSendMessageMaxTextLength);// 字数超限
}

@end
