//
//  PLVLCLiveRoomLandscapeInputView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/10/16.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLiveRoomLandscapeInputView.h"
#import "PLVLCLandscapeRepliedMsgView.h"
#import "PLVLCKeyboardTextView.h"
#import "PLVLCUtils.h"
#import "PLVChatModel.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCLiveRoomLandscapeInputView () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField * textField;
@property (nonatomic, strong) UIButton * sendButton;
@property (nonatomic, strong) PLVLCLandscapeRepliedMsgView * _Nullable replyModelView; /// 显示被引用回复消息UI
@property (nonatomic, strong) PLVChatModel * _Nullable replyModel; /// 引用回复消息

@end

@implementation PLVLCLiveRoomLandscapeInputView

#pragma mark - [ Life Period ]
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    PLV_LOG_INFO(PLVConsoleLogModuleTypeChatRoom,@"%s", __FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        if (!self.replyModelView) {
            [self layoutRefreshForKeyboardShow:NO keyboardHeight:0];
        }
    } else {
        [self showInputView:NO];
    }
}


#pragma mark - [ Public Methods ]
- (void)showInputView:(BOOL)show{
    if (show) {
        if (self.replyModel) {
            self.replyModelView = [[PLVLCLandscapeRepliedMsgView alloc] initWithChatModel:self.replyModel];
            __weak typeof(self) weakSelf = self;
            [self.replyModelView setCloseButtonHandler:^{
                weakSelf.replyModel = nil;
            }];
            [self addSubview:self.replyModelView];
        }
        
        self.userInteractionEnabled = YES;
        [self.textField becomeFirstResponder];
        
        [UIView animateWithDuration:0.33 animations:^{
            self.alpha = 1;
        }];
    }else{
        if (self.replyModel) {
            [self.replyModelView removeFromSuperview];
            self.replyModelView = nil;
            self.replyModel = nil;
        }
        
        self.userInteractionEnabled = NO;
        [self.textField resignFirstResponder];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0;
        }];
    }
}

- (void)showWithReplyChatModel:(PLVChatModel *)model {
    self.replyModel = model;
    
    [self showInputView:YES];
}

#pragma mark - [ Private Methods ]
- (void)setup{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
    
- (void)setupUI{
    self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.85];
    self.userInteractionEnabled = NO;
    self.alpha = 0;

    // 添加视图
    [self addSubview:self.textField];
    [self addSubview:self.sendButton];
    
    // 添加手势
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self addGestureRecognizer:tap];
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForLiveRoomResource:imageName];
}

- (void)layoutRefreshForKeyboardShow:(BOOL)show keyboardHeight:(CGFloat)keyboardHeight{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);

    CGFloat textFieldWidth = viewWidth * 0.5541;
    CGFloat textFieldHeight = 32.0;
    CGFloat textFieldX = viewWidth * 0.1749;
    CGFloat textFieldY = show ? (viewHeight - keyboardHeight - 16 - textFieldHeight) : (viewHeight - 26.0 - textFieldHeight);
    CGFloat replyModelViewHeight = self.replyModelView.viewHeight;
    
    __weak typeof(self) weakSelf = self;
    NSTimeInterval animationTime = show ? 0.2 : 0.1;
    [UIView animateWithDuration:animationTime animations:^{
        weakSelf.replyModelView.frame = CGRectMake(0, textFieldY - replyModelViewHeight, viewWidth, replyModelViewHeight);
        weakSelf.textField.frame = CGRectMake(textFieldX, textFieldY, textFieldWidth, textFieldHeight);
        weakSelf.sendButton.frame = CGRectMake(CGRectGetMaxX(weakSelf.textField.frame) + 10, CGRectGetMinY(weakSelf.textField.frame), 64, CGRectGetHeight(weakSelf.textField.frame));
    }];
}

#pragma mark Getter
- (UITextField *)textField{
    if (_textField == nil) {
        _textField = [[UITextField alloc]init];
        _textField.textColor = [UIColor whiteColor];
        _textField.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        _textField.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.65];
        _textField.layer.cornerRadius = 17;
        _textField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 16, 0)];
        _textField.leftViewMode = UITextFieldViewModeAlways;
        _textField.delegate = self;
        [_textField addTarget:self action:@selector(textFieldDidChangeAction:) forControlEvents:UIControlEventEditingChanged];
    }
    return _textField;
}

- (UIButton *)sendButton{
    if (_sendButton == nil) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:13];
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [_sendButton setTitle:PLVLocalizedString(@"发送") forState:UIControlStateNormal];
        [_sendButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.3]];
        _sendButton.layer.cornerRadius = 16;
        _sendButton.layer.masksToBounds = YES;
        _sendButton.enabled = NO;
        [_sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

#pragma mark - [ Event ]
#pragma mark Action
- (void)tapGestureAction:(UITapGestureRecognizer *)tapGes{
    [self showInputView:NO];
}

- (void)sendButtonAction:(UIButton *)button{
    if (self.textField.text.length > 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomLandscapeInputView:SendButtonClickedWithSendContent:replyModel:)]) {
            [self.delegate plvLCLiveRoomLandscapeInputView:self SendButtonClickedWithSendContent:self.textField.text replyModel:self.replyModel];
        }
        
        self.replyModel = nil;
        self.textField.text = @"";
        [self textFieldDidChangeAction:self.textField];
        [self showInputView:NO];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeChatRoom,@"PLVLCLiveRoomLandscapeInputView - send button callback failed, textField is no content");
    }
}

- (void)textFieldDidChangeAction:(UITextField *)textField{
    NSString *toBeString = textField.text;
    UITextRange *selectedRange = [textField markedTextRange];
    UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
    
    if (!position){
        if (toBeString.length > 0) {
            self.sendButton.enabled = YES;
            [self.sendButton setBackgroundColor:PLV_UIColorFromRGB(@"2196F3")];
            
            if (toBeString.length > PLVLCKeyboardMaxTextLength) {
                textField.text = [toBeString substringToIndex:PLVLCKeyboardMaxTextLength];
            }
        }else{
            self.sendButton.enabled = NO;
            [self.sendButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.3]];
        }
    }
}

#pragma mark Notification
- (void)keyboardWasShow:(NSNotification *)noti{
    NSValue *value = [noti userInfo][UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [value CGRectValue].size.height;
    
    [self layoutRefreshForKeyboardShow:YES keyboardHeight:keyboardHeight];
}

- (void)keyboardWillHide:(NSNotification *)noti {
    [self layoutRefreshForKeyboardShow:NO keyboardHeight:0];
}

@end
