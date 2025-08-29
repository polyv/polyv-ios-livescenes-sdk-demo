//
//  PLVStickerTextEditorView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVStickerTextEditorView.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVSAUtils.h"
#import "PLVStickerEffectText.h"
#import "PLVMultiLanguageManager.h"

// 最大文本长度限制
static NSInteger const kMaxTextLength = 8;
// 文本输入工具栏的高度
static CGFloat const kInputToolBarHeight = 62.0;

@interface PLVStickerTextEditorView () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *inputToolBar;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) PLVStickerEffectText *previewEffectText;
@property (nonatomic, strong) PLVStickerTextModel *textModel;
@property (nonatomic, copy) NSString *initialText;
@property (nonatomic, assign) CGFloat keyboardHeight;

@end

@implementation PLVStickerTextEditorView

#pragma mark - Life Cycle

- (instancetype)initWithTextModel:(PLVStickerTextModel *)model height:(CGFloat)height {
    self = [super initWithSheetHeight:height];
    if (self) {
        _textModel = model;
        _initialText = model.editText ?: @"";
        _keyboardHeight = 0;
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        
        [self setupUI];
        [self addKeyboardNotifications];
    }
    return self;
}

- (void)dealloc {
    [self removeKeyboardNotifications];
}

- (void)showInView:(UIView *)parentView {
    [super showInView:parentView];
    [self.textField becomeFirstResponder];
}

- (void)dismiss {
    [self.textField resignFirstResponder];
    [super dismiss];
}

#pragma mark - UI Setup

- (void)setupUI {
    [self.contentView addSubview:self.previewEffectText];
    
    [self.contentView addSubview:self.inputToolBar];
    [self.inputToolBar addSubview:self.textField];
    [self.inputToolBar addSubview:self.doneButton];
    
    // 为 countLabel 创建一个容器视图以实现内边距
    UIView *rightViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 44)];
    self.countLabel.frame = CGRectMake(0, 0, 42, 44);
    [rightViewContainer addSubview:self.countLabel];
    
    self.textField.rightView = rightViewContainer;
    self.textField.rightViewMode = UITextFieldViewModeAlways;
    
    // 设置初始文本，如果超过长度限制则截断
    NSString *displayText = self.initialText;
    CGFloat textLength = [self calculateTextLength:displayText];
    if (textLength > kMaxTextLength) {
        displayText = [self truncateText:displayText toLength:kMaxTextLength];
    }
    self.textField.text = displayText;
    [self updateCountLabel];
    
    __weak typeof(self) weakSelf = self;
    self.didCloseSheet = ^{
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(textEditorViewDidCancel:)]) {
            [weakSelf.delegate textEditorViewDidCancel:weakSelf];
        }
    };
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // inputToolBar 随键盘在 full-screen view 的底部移动
    CGFloat toolBarY = self.bounds.size.height - self.keyboardHeight - kInputToolBarHeight;
    self.inputToolBar.frame = CGRectMake(0, toolBarY, self.bounds.size.width, kInputToolBarHeight);

    // 布局预览标签，使其位于输入框上方的可见区域居中
    CGFloat previewAreaHeight = toolBarY;
    self.previewEffectText.bounds = CGRectMake(0, 0, self.textModel.defaultSize.width, self.textModel.defaultSize.height);
    self.previewEffectText.center = CGPointMake(self.bounds.size.width / 2, previewAreaHeight / 2);

    CGFloat margin = 16 + [PLVSAUtils sharedUtils].areaInsets.left;
    CGFloat buttonWidth = 60;
    CGFloat spacing = 8;
    
    CGFloat textFieldWidth = self.inputToolBar.bounds.size.width - margin * 2 - buttonWidth - spacing;
    self.textField.frame = CGRectMake(margin, (kInputToolBarHeight - 44) / 2, textFieldWidth, 44);
    self.doneButton.frame = CGRectMake(CGRectGetMaxX(self.textField.frame) + spacing, (kInputToolBarHeight - 26) / 2, buttonWidth, 26);
}

#pragma mark - Private Methods

/**
 * 计算文本的实际字符长度
 * ASCII字符计为0.5个字符，其他字符计为1个字符
 */
- (CGFloat)calculateTextLength:(NSString *)text {
    if (!text || text.length == 0) {
        return 0.0;
    }
    
    __block CGFloat totalLength = 0.0;
    
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (substring.length > 0) {
            unichar firstChar = [substring characterAtIndex:0];
            
            // ASCII字符范围：0-127
            if (firstChar >= 0 && firstChar <= 127) {
                totalLength += 0.5; // ASCII字符计为0.5个字符
            } else {
                totalLength += 1.0; // 其他字符计为1个字符
            }
        }
    }];
    
    return totalLength;
}

/**
 * 截断文本到指定长度
 */
- (NSString *)truncateText:(NSString *)text toLength:(CGFloat)maxLength {
    if (!text || text.length == 0) {
        return text;
    }
    
    NSMutableString *result = [NSMutableString string];
    __block CGFloat currentLength = 0.0;
    
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (substring.length > 0) {
            unichar firstChar = [substring characterAtIndex:0];
            CGFloat charLength = 0.0;
            
            // ASCII字符范围：0-127
            if (firstChar >= 0 && firstChar <= 127) {
                charLength = 0.5;
            } else {
                charLength = 1.0;
            }
            
            if (currentLength + charLength <= maxLength) {
                [result appendString:substring];
                currentLength += charLength;
            } else {
                *stop = YES;
            }
        }
    }];
    
    return [result copy];
}

#pragma mark - Actions

- (void)doneButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textEditorView:didFinishEditingWithText:)]) {
        [self.delegate textEditorView:self didFinishEditingWithText:self.textField.text];
    }
    [self dismiss];
}

- (void)updateCountLabel {
    // 获取实际已确定的文本（不包括拼音标记文本）
    NSString *actualText = self.textField.text;
    UITextRange *markedRange = self.textField.markedTextRange;
    
    NSString *confirmedText = actualText;
    
    // 如果存在标记文本，获取已确定的部分（排除标记文本）
    if (markedRange) {
        NSString *markedText = [self.textField textInRange:markedRange];
        if (markedText && markedText.length > 0) {
            NSRange markedNSRange = [actualText rangeOfString:markedText options:NSBackwardsSearch];
            if (markedNSRange.location != NSNotFound) {
                confirmedText = [actualText substringToIndex:markedNSRange.location];
            }
        }
    }
    
    // 计算已确定文本的实际长度
    CGFloat currentLength = [self calculateTextLength:confirmedText];
    
    // 向上取整显示字数
    NSInteger displayLength = ceil(currentLength);
    self.countLabel.text = [NSString stringWithFormat:@"%ld/%d", (long)displayLength, kMaxTextLength];
    
    self.countLabel.textColor = (displayLength > kMaxTextLength) ? [UIColor redColor] : [PLVColorUtil colorFromHexString:@"#999999"];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // 如果存在标记文本（如拼音输入过程中），允许继续输入
    if (textField.markedTextRange) {
        return YES;
    }
    
    // 计算替换后的文本
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // 如果是删除操作，允许删除
    if ([string isEqualToString:@""]) {
        return YES;
    }
    
    // 计算新文本的实际长度
    CGFloat newTextLength = [self calculateTextLength:newText];
    
    // 如果新文本超过限制，截断到最大长度后再设置
    if (newTextLength > kMaxTextLength) {
        // NSString *truncatedText = [self truncateText:newText toLength:kMaxTextLength];
        // textField.text = truncatedText;
        
        // // 手动触发文本变化事件
        // [self textFieldDidChange:textField];
        
        return NO; // 阻止默认的文本替换
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self doneButtonAction];
    return NO;
}

- (void)textFieldDidChange:(UITextField *)textField {
    // 检查是否需要截断文本
    if (!textField.markedTextRange) {
        CGFloat textLength = [self calculateTextLength:textField.text];
        if (textLength > kMaxTextLength) {
            // 没有标记文本且超过长度限制，进行截断
            NSString *truncatedText = [self truncateText:textField.text toLength:kMaxTextLength];
            textField.text = truncatedText;
        }
    }
    
    // 不含标记文本的显示计数
    [self updateCountLabel];
    
    // 更新内部预览
    CGFloat effectWidth = [self.previewEffectText getBoundWidthForText];
    self.previewEffectText.bounds = CGRectMake(0, 0, effectWidth, self.textModel.defaultSize.height);
    [self.previewEffectText updateText:textField.text];
    
    // 通过代理更新外部真实视图
    if (self.delegate && [self.delegate respondsToSelector:@selector(textEditorView:didUpdateText:)]) {
        [self.delegate textEditorView:self didUpdateText:textField.text];
    }
}

#pragma mark - Keyboard Notifications

- (void)addKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGFloat keyboardHeight = CGRectGetHeight(keyboardFrame);
    
    if (self.keyboardHeight != keyboardHeight) {
        self.keyboardHeight = keyboardHeight;
        
        [UIView animateWithDuration:animationDuration delay:0 options:(animationCurve << 16) animations:^{
            [self setNeedsLayout];
            [self layoutIfNeeded];
        } completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    self.keyboardHeight = 0;
    
    [UIView animateWithDuration:animationDuration delay:0 options:(animationCurve << 16) animations:^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    } completion:nil];
}

#pragma mark - Lazy Loading

- (PLVStickerEffectText *)previewEffectText{
    if (!_previewEffectText){
        _previewEffectText = [[PLVStickerEffectText alloc] initWithText:self.textModel.editText templateType:self.textModel.editTemplateType];
    }
    return _previewEffectText;
}

- (UIView *)inputToolBar {
    if (!_inputToolBar) {
        _inputToolBar = [[UIView alloc] init];
        _inputToolBar.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35" alpha:0.8];
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.frame = _inputToolBar.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_inputToolBar addSubview:blurView];
    }
    return _inputToolBar;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.font = [UIFont systemFontOfSize:14];
        _textField.textColor = [UIColor whiteColor];
        _textField.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        _textField.layer.cornerRadius = 22;
        _textField.layer.masksToBounds = YES;
        _textField.delegate = self;
        _textField.returnKeyType = UIReturnKeyDone;
        
        NSAttributedString *placeholder = [[NSAttributedString alloc] initWithString:@"关注主播赠送好礼" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.6]}];
        _textField.attributedPlaceholder = placeholder;

        _textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 0)];
        _textField.leftViewMode = UITextFieldViewModeAlways;
        
        [_textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return _textField;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:12];
        _countLabel.textColor = [PLVColorUtil colorFromHexString:@"#999999"];
        _countLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _countLabel;
}

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneButton setTitle:PLVLocalizedString(@"完成") forState:UIControlStateNormal];
        [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _doneButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _doneButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#409EFF"];
        _doneButton.layer.cornerRadius = 13;
        _doneButton.layer.masksToBounds = YES;
        
        [_doneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneButton;
}

@end
