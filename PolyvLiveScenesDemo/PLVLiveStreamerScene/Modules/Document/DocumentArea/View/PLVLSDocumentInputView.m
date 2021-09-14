//
//  PLVLSDocumentInputView.m
//  PLVCloudClassStreamerModul
//
//  Created by MissYasiky on 2019/12/18.
//  Copyright © 2019 easefun. All rights reserved.
//  PPT文字输入视图

#import "PLVLSDocumentInputView.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

static int kMaxLength = 100;

@interface PLVLSDocumentInputView ()<
UITextViewDelegate
>

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *topBarView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) NSRange selectedRange; //textview光标位置

@end

@implementation PLVLSDocumentInputView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        
        [self addSubview:self.maskView];
        [self addSubview:self.topBarView];
        [self addSubview:self.textView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeText:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Getter & Setter ]

- (UIView *)maskView {
    if (_maskView == nil) {
        _maskView = [[UIView alloc] initWithFrame:self.bounds];
        _maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    }
    return _maskView;
}

- (UIView *)topBarView {
    if (_topBarView == nil) {
        _topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 32)];
        _topBarView.backgroundColor = PLV_UIColorFromRGB(@"#1A1B1F");
        [_topBarView addSubview:self.cancelButton];
        [_topBarView addSubview:self.doneButton];
    }
    return _topBarView;
}

- (UIButton *)cancelButton {
    if (_cancelButton == nil) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.frame = CGRectMake(53, 0, 44, 32);
        [_cancelButton setTitleColor:PLV_UIColorFromRGB(@"#999999") forState:UIControlStateNormal];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIButton *)doneButton {
    if (_doneButton == nil) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneButton.frame = CGRectMake(self.bounds.size.width - 53 - 44, 0, 44, 32);
        [_doneButton setTitleColor:PLV_UIColorFromRGB(@"#366BEE") forState:UIControlStateNormal];
        [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
        _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_doneButton addTarget:self action:@selector(doneButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneButton;
}

- (UITextView *)textView {
    if (_textView == nil) {
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(76, self.topBarView.frame.origin.y + self.topBarView.frame.size.height, self.bounds.size.width - 76 * 2, 100)];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:18];
        _textView.textColor = [UIColor whiteColor];//[PLVColorUtil colorFromHexString:@"#3D3D3D"];
        _textView.returnKeyType = UIReturnKeyDone;
        _textView.keyboardAppearance = UIKeyboardAppearanceDark;
        _textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _textView.delegate = self;
    }
    return _textView;
}

#pragma mark - [ Notification ]

- (void)keyboardDidShow:(NSNotification *)notification {
    CGRect keyBoardBounds  = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyBoardHeight = keyBoardBounds.size.height;

    CGRect textViewRect = self.textView.frame;
    textViewRect.size.height = self.bounds.size.height - textViewRect.origin.y - keyBoardHeight;
    self.textView.frame = textViewRect;
}

- (void)textViewDidChangeText:(NSNotification *)notification {
    NSString *lang = [[UIApplication sharedApplication].textInputMode primaryLanguage]; // 获取键盘输入模式
    if ([lang isEqualToString:@"zh-Hans"]) { // zh-Hans表示简体中文输入, 包括简体拼音，健体五笔，简体手写
        UITextRange *selectedRange = [self.textView markedTextRange];
        UITextPosition *position = [self.textView positionFromPosition:selectedRange.start offset:0];//获取高亮选择部分
        if (position) { // 中文输入的时候,可能有markedText(高亮选择的文字)，如果有高亮选择的字，表明输入还未结束,暂不对输入的文字进行字数统计和限制
            return;
        }
    }

    NSString *toBeString = self.textView.text;
    self.textView.text = [self cutInputTextToAllowableLength:toBeString];
    //将光标放到最新内容后面
    self.textView.selectedRange = self.selectedRange;
}

- (NSString *)cutInputTextToAllowableLength:(NSString *)inputText {
    if (inputText && inputText.length > kMaxLength) {// 截取子串
        return [inputText substringToIndex:kMaxLength];
    } else {
        return inputText;
    }
}


#pragma mark - [ Delegate ]
#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]){ //判断输入的字是否是回车，即按下return
        [self doneButtonAction:nil];
        return NO; // 不进行换行
    }
    if ([text isEqualToString:@""]) { //判断输入是否为删除
        self.selectedRange = NSMakeRange(range.location, 0);;
    } else {
        self.selectedRange = NSMakeRange(range.location + text.length, range.length);
    }
    return YES;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)cancelButtonAction:(id)sender {
    [self dismiss];
}

- (void)doneButtonAction:(id)sender {
    !self.documentInputCompleteHandler ?: self.documentInputCompleteHandler(self.textView.text);
    [self dismiss];
}

#pragma mark - [ Public ]

- (void)presentWithText:(NSString *)content textColor:(NSString *)hexColor inViewController:(UIViewController *)vctrl {
    [vctrl.view addSubview:self];
    self.textView.text = content;
    self.textView.textColor = [PLVColorUtil colorFromHexString:hexColor];
    [self.textView becomeFirstResponder];
}

- (void)dismiss {
    [self removeFromSuperview];
    [self.textView resignFirstResponder];
}

@end
