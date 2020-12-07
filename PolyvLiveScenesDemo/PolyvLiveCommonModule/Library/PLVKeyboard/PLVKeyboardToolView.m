//
//  PLVKeyboardToolView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/6.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVKeyboardToolView.h"
#import "PLVKeyboardTextView.h"
#import "PLVEmojiSelectView.h"
#import "PLVKeyboardMoreView.h"
#import "PLVEmoticonManager.h"
#import "PLVKeyboardUtils.h"

#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

static CGFloat kMaxTextViewHeight = 120.0;

@interface PLVKeyboardToolView ()<
UITextViewDelegate,
PLVEmojiSelectViewDelegate,
PLVKeyboardMoreViewDelegate
>
/// 不同的 mode，决定不同的 UI
@property (nonatomic, assign) PLVKeyboardToolMode mode;

@property (nonatomic, assign) PLVKeyboardToolState toolState;
/// 使用局部变量代替属性会在 iOS 9.3.1 上产生内存问题
@property (nonatomic, strong) UIView *tempInputView;
/// 文本输入框
@property (nonatomic, strong) PLVKeyboardTextView *textView;
/// emoji 按钮
@property (nonatomic, strong) UIButton *emojiButton;
/// 打开更多面板按钮
@property (nonatomic, strong) UIButton *moreButton;
/// emoji 选择面板
@property (nonatomic, strong) PLVEmojiSelectView *emojiboard;
/// 查看更多面板
@property (nonatomic, strong) PLVKeyboardMoreView *moreboard;
/// 弹出键盘时，添加在 keyWindow 上，用来响应手势缩起键盘
@property (nonatomic, strong) UIView *gestureView;
/// 未弹出键盘时，当前控件原先的父视图
@property (nonatomic, weak) UIView *normalSuperView;
/// 设置当前控件未弹出键盘时的坐标 Y 值
@property (nonatomic, assign) CGFloat originY;
/// 设备底部安全区域，默认为 0
@property (nonatomic, assign) CGFloat bottomHeight;
/// emojiBoard 高度
@property (nonatomic, assign) CGFloat emojiboardHeight;
/// moreBoard高度
@property (nonatomic, assign) CGFloat moreboardHeight;
/// keyboard 高度
@property (nonatomic, assign) CGFloat keyboardHeight;
/// 输入框高度
@property (nonatomic, assign) CGFloat lastTextViewHeight;
/// 当前状态是否只看教师，默认 NO
@property (nonatomic, assign) BOOL onlySeeTeacher;
/// 当前是否正在切换 toolState，否则切换emoji键盘会触发keyboardHidden通知导致输入栏下移
@property (nonatomic, assign) BOOL changingToolState;

@end

@implementation PLVKeyboardToolView

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithMode:PLVKeyboardToolModeDefault];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Initialize

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRed:0x1a/255.0 green:0x1b/255.0 blue:0x1f/255.0 alpha:1.0];
    
    [self addSubview:self.textView];
    [self addSubview:self.emojiButton];
    if (self.mode == PLVKeyboardToolModeDefault) {
        [self addSubview:self.moreButton];
    }
}

#pragma mark - Getterr & Setter

- (PLVKeyboardTextView *)textView {
    if (!_textView) {
        _textView = [[PLVKeyboardTextView alloc] init];
        _textView.delegate = self;
    }
    return _textView;
}

- (UIButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVKeyboardUtils imageForKeyboardResource:@"plv_keyboard_btn_emoji"];
        [_emojiButton setImage:image forState:UIControlStateNormal];
        [_emojiButton setImage:image forState:UIControlStateSelected];
        [_emojiButton addTarget:self action:@selector(emojiAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _emojiButton;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *moreBtnImage = [PLVKeyboardUtils imageForKeyboardResource:@"plv_keyboard_btn_more"];
        [_moreButton setImage:moreBtnImage forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (PLVEmojiSelectView *)emojiboard {
    if (!_emojiboard) {
        _emojiboard = [[PLVEmojiSelectView alloc] init];
        _emojiboard.delegate = self;
    }
    return _emojiboard;
}

- (PLVKeyboardMoreView *)moreboard {
    if (!_moreboard) {
        _moreboard = [[PLVKeyboardMoreView alloc] init];
        _moreboard.delegate = self;
        _moreboard.sendImageEnable = self.enableSendImage;
        _moreboard.hiddenBulletin = self.hiddenBulletin;
    }
    return _moreboard;
}

- (UIView *)gestureView {
    if (!_gestureView) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        _gestureView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_gestureView addGestureRecognizer:tap];
    }
    return _gestureView;
}

- (void)setEnableSendImage:(BOOL)enableSendImage {
    if (_enableSendImage == enableSendImage) {
        return;
    }
    _enableSendImage = enableSendImage;
    self.moreboard.sendImageEnable = enableSendImage;
}

- (void)setDisableOtherButtonsInTeacherMode:(BOOL)disableOtherButtonsInTeacherMode {
    if (_disableOtherButtonsInTeacherMode == disableOtherButtonsInTeacherMode) {
        return;
    }
    _disableOtherButtonsInTeacherMode = disableOtherButtonsInTeacherMode;
    if (disableOtherButtonsInTeacherMode && self.onlySeeTeacher) {
        self.textView.editable = NO;
        self.emojiButton.enabled = self.moreButton.enabled = NO;
    }
}

- (void)setToolState:(PLVKeyboardToolState)toolState {
    if (toolState == _toolState) {
        return;
    }
    
    if (self.changingToolState) {
        return;
    }
    self.changingToolState = YES;
    
    PLVKeyboardToolState originState = _toolState;
    
    self.emojiButton.selected = (toolState == PLVKeyboardToolStateEmojiboard);
    
    if (toolState != PLVKeyboardToolStateEmojiboard && toolState != PLVKeyboardToolStateKeyboard) {
        if (self.textView.isFirstResponder) {
            self.textView.inputView = nil;
            [self.textView reloadInputViews];
            [self.textView becomeFirstResponder];
            [self.textView resignFirstResponder];
        }
    } else if (toolState == PLVKeyboardToolStateKeyboard && originState == PLVKeyboardToolStateEmojiboard) {
        self.textView.inputView = nil;
        [self.textView reloadInputViews];
        [self.textView becomeFirstResponder];
    } else if (toolState == PLVKeyboardToolStateEmojiboard) {
        // 在 iOS 9.3.1 上使用局部变量代替 tempInputView 在打开表情键盘退出时会出现内存问题
        self.tempInputView = [[UIView alloc] initWithFrame:CGRectZero];
        self.textView.inputView = self.tempInputView;
        [self.textView reloadInputViews];
        [self.textView becomeFirstResponder];
    }
    
    _toolState = toolState;
    
    if (_toolState == PLVKeyboardToolStateNormal) {
        [self animateRemoveFromWindow];
    } else if (_toolState != PLVKeyboardToolStateKeyboard) {
        [self animateAddToWindow];
    } else if (_toolState == PLVKeyboardToolStateKeyboard && originState == PLVKeyboardToolStateEmojiboard) {
        [self animateAddToWindow];
    }
    self.changingToolState = NO;
}

#pragma mark - Action

- (void)emojiAction:(UIButton *)sender {
    if (![self shouldInteract]) {
        return;
    }
    self.emojiButton.selected = !self.emojiButton.selected;
    self.toolState = self.emojiButton.selected ? PLVKeyboardToolStateEmojiboard : PLVKeyboardToolStateKeyboard;
}

- (void)moreAction:(UIButton *)sender {
    if (![self shouldInteract]) {
        return;
    }
    self.toolState = PLVKeyboardToolStateMoreboard;
}

- (void)tapAction:(id)sender {
    self.toolState = PLVKeyboardToolStateNormal;
}

#pragma mark - Public Method

- (instancetype)initWithMode:(PLVKeyboardToolMode)mode {
    self = [super init];
    if (self) {
        _mode = MAX(MIN(PLVKeyboardToolModeSimple, mode), 0);
        _enableSendImage = YES;
        _disableOtherButtonsInTeacherMode = NO;
        
        [self setupUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}

- (void)addAtView:(UIView *)parentView frame:(CGRect)rect {
    self.normalSuperView = parentView;
    [self.normalSuperView addSubview:self];
    
    self.frame = rect;
    self.originY = rect.origin.y;
    self.bottomHeight = rect.size.height - PLVKeyboardToolViewHeight;
    
    [self updateUI];
}

- (void)changeFrameForNewOriginY:(CGFloat)originY {
    if (self.originY == originY) {
        return;
    }
    
    self.originY = originY;
    if (self.superview == self.normalSuperView) {
        CGRect rect = self.frame;
        rect.origin.y = originY;
        self.frame = rect;
    }
}

- (void)clearResource {
    if (@available(iOS 9.0, *)) {
    } else {
        [self.textView resignFirstResponder];
        self.textView.inputView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.textView reloadInputViews];
        [self.textView becomeFirstResponder];
    }
}

#pragma mark - Private Method

- (void)updateUI {
    CGRect rect = self.frame;
    CGFloat textViewWidth = rect.size.width - 16 - (self.mode == PLVKeyboardToolModeSimple ? 48 : 96);
    [self.textView setupWithFrame:CGRectMake(16, 8, textViewWidth, 40)];
    self.lastTextViewHeight = ceilf([self.textView sizeThatFits:self.textView.frame.size].height);
    
    self.emojiButton.frame = CGRectMake(CGRectGetMaxX(self.textView.frame) + 8, 12, 32, 32);
    self.moreButton.frame = CGRectMake(CGRectGetMaxX(self.emojiButton.frame) + 8, 12, 32, 32);
    
    CGFloat emojiboardHeight = 200.0 + self.bottomHeight;
    CGFloat moreboardHeight = 115.0 + self.bottomHeight;
    if ([@"iPad" isEqualToString:[UIDevice currentDevice].model]) {
        emojiboardHeight += 55.0;
        moreboardHeight += 55.0;
    }
    self.emojiboardHeight = emojiboardHeight;
    self.moreboardHeight = moreboardHeight;
    // 提前设置 frame 值，是为了先初始化
    self.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.moreboardHeight);
    self.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.emojiboardHeight);
}

- (void)animateAddToWindow {
    __weak typeof(self) weakSelf = self;
    [weakSelf addViewInWindow];
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat boardHeight = 0;
        if (weakSelf.toolState == PLVKeyboardToolStateEmojiboard) {
            boardHeight = weakSelf.emojiboardHeight;
            weakSelf.emojiboard.frame = CGRectMake(0, kScreenHeight - boardHeight, kScreenWidth, boardHeight);
            weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, weakSelf.moreboardHeight);
        } else if (weakSelf.toolState == PLVKeyboardToolStateMoreboard) {
            boardHeight = weakSelf.moreboardHeight;
            weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight - boardHeight, kScreenWidth, boardHeight);
            weakSelf.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, weakSelf.emojiboardHeight);
        } else if (weakSelf.toolState == PLVKeyboardToolStateKeyboard) {
            boardHeight = weakSelf.keyboardHeight;
            weakSelf.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, weakSelf.emojiboardHeight);
            weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, weakSelf.moreboardHeight);
        }
        CGRect selfRect = weakSelf.frame;
        if (boardHeight == 0) { // 模拟器使用外接键盘时，self.keyboardHeight 为 0
            boardHeight = self.bottomHeight;
        }
        weakSelf.frame = CGRectMake(0, kScreenHeight - selfRect.size.height - boardHeight + weakSelf.bottomHeight, kScreenWidth, selfRect.size.height);
    }];
}

- (void)animateRemoveFromWindow {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (self.superview != window) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect selfRect = weakSelf.frame;
        weakSelf.frame = CGRectMake(0, kScreenHeight - selfRect.size.height, kScreenWidth, selfRect.size.height);
        weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, weakSelf.moreboardHeight);
        weakSelf.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, weakSelf.emojiboardHeight);
    } completion:^(BOOL finished) {
        [weakSelf addViewInOriginView];
    }];
}

- (void)addViewInWindow {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (self.superview == window) {
        return;
    }
    // 将各个视图添加到主窗口
    [window addSubview:self.gestureView];
    [window addSubview:self];
    [window addSubview:self.moreboard];
    [window addSubview:self.emojiboard];
    // 设置视图 frame 值
    CGRect selfRect = self.frame;
    self.frame = CGRectMake(0, kScreenHeight - selfRect.size.height, kScreenWidth, selfRect.size.height);
    self.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.moreboardHeight);
    self.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.emojiboardHeight);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:popBoard:)]) {
        [self.delegate keyboardToolView:self popBoard:YES];
    }
}

- (void)addViewInOriginView {
    if (self.superview == self.normalSuperView) {
        return;
    }
    // 将各个视图从主窗口移除
    [self removeFromSuperview];
    [self.gestureView removeFromSuperview];
    [self.moreboard removeFromSuperview];
    [self.emojiboard removeFromSuperview];
    // 将 self 添加到原先的父视图
    [self.normalSuperView addSubview:self];
    // 设置视图 frame 值
    CGRect selfRect = self.frame;
    CGFloat normalSuperViewHeight = self.originY + PLVKeyboardToolViewHeight + self.bottomHeight;
    self.frame = CGRectMake(0, normalSuperViewHeight - selfRect.size.height, kScreenWidth, selfRect.size.height);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:popBoard:)]) {
        [self.delegate keyboardToolView:self popBoard:NO];
    }
}

- (void)checkSendBtnEnable:(BOOL)enable {
    [self.emojiboard sendButtonEnable:enable]; // emoji 面板发送按钮
    self.textView.enablesReturnKeyAutomatically = enable; //输入 textView 发送按钮
}

/// 触发发送消息回调，隐藏面板
- (void)sendTextAndClearTextView {
    if (self.textView.attributedText.length > 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:sendText:)]) {
            NSString *text = [self.textView plvTextForRange:NSMakeRange(0, self.textView.attributedText.length)];
            [self.delegate keyboardToolView:self sendText:text];
        }
    }
    [self tapAction:nil];
    [self.textView clearText];
    [self textViewDidChange:self.textView];
}

/// 是否允许响应交互
- (BOOL)shouldInteract {
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_shouldInteract:)]) {
        return [self.delegate keyboardToolView_shouldInteract:self];
    } else {
        return YES;
    }
}

#pragma mark - NSNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    self.keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    // 中文键盘或第三方键盘第一次弹出时会收到两至三次弹出事件通知，会导致动画效果不连续流畅，暂无更好解决方案
    if (self.textView.isFirstResponder && self.toolState == PLVKeyboardToolStateKeyboard) {
        [self animateAddToWindow];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
//    [self tapAction:nil]; // 第三方键盘，点击隐藏键盘按钮缩起键盘仍需要使用该方法监听
}

#pragma mark - UITextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (![self shouldInteract]) {
        return NO;
    }
    if (!self.emojiButton.selected && self.toolState != PLVKeyboardToolStateEmojiboard) {
        self.toolState = PLVKeyboardToolStateKeyboard;
    }
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
    return (newLength <= PLVKeyboardMaxTextLength);// 字数超限
}

- (void)textViewDidChange:(UITextView *)textView {
    [self checkSendBtnEnable:self.textView.attributedText.length > 0];
    
    CGFloat height = ceilf([self.textView sizeThatFits:self.textView.frame.size].height);
    if (height <= kMaxTextViewHeight && self.lastTextViewHeight != height) { // 输入框行数发生变化时
        self.lastTextViewHeight = height;
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [weakSelf.textView setContentOffset:CGPointMake(0.0, 1.0) animated:NO];//必须，防止换行时文字的抖动
            // 修改 textView 大小
            CGRect textRect = weakSelf.textView.frame;
            textRect.size.height = height;
            weakSelf.textView.frame = textRect;
            // 根据 textView 新的大小，修改自身位置、大小
            CGRect rect = weakSelf.frame;
            CGFloat maxY = rect.origin.y + rect.size.height;
            rect.size.height = textRect.origin.y * 2.0 + textRect.size.height + weakSelf.bottomHeight;
            rect.origin.y = maxY - rect.size.height;
            weakSelf.frame = rect;
            // 重新布局
            [weakSelf layoutIfNeeded];
        } completion:nil];
    }
}

#pragma mark - PLVKeyboardMoreView Delegate

- (void)keyboardMoreView_openCamera:(PLVKeyboardMoreView *)moreView {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_openCamera:)]) {
        [self.delegate keyboardToolView_openCamera:self];
    }
}

- (void)keyboardMoreView_openAlbum:(PLVKeyboardMoreView *)moreView {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_openAlbum:)]) {
        [self.delegate keyboardToolView_openAlbum:self];
    }
}

- (void)keyboardMoreView_openBulletin:(PLVKeyboardMoreView *)moreView {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_readBulletin:)]) {
        [self.delegate keyboardToolView_readBulletin:self];
    }
}

- (void)keyboardMoreView_onlyTeacher:(PLVKeyboardMoreView *)moreView on:(BOOL)on {
    self.onlySeeTeacher = on;
    [self tapAction:nil];
    
    if (self.disableOtherButtonsInTeacherMode) {
        self.textView.editable = !on;
        self.emojiButton.enabled = self.moreButton.enabled = !on;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:onlyTeacher:)]) {
        [self.delegate keyboardToolView:self onlyTeacher:on];
    }
}

#pragma mark - PLVEmojiSelectView Delegate

- (void)selectEmoji:(PLVEmoticon *)emojiModel {
    if ([self.textView.text length] >= PLVKeyboardMaxTextLength) { // 字数超限
        return;
    }
    NSRange cursorRange = self.textView.selectedRange;
    NSAttributedString *emojiAttrStr = [self.textView convertTextWithEmoji:emojiModel.text];
    [self.textView replaceCharactersInRange:cursorRange withAttributedString:emojiAttrStr];
    self.textView.selectedRange = NSMakeRange(cursorRange.location + emojiAttrStr.length, 0);
    [self textViewDidChange:self.textView];
}

- (void)deleteEmoji {
    NSRange cursorRange = self.textView.selectedRange;
    if (self.textView.attributedText.length > 0 && cursorRange.location > 0) {
        [self.textView replaceCharactersInRange:NSMakeRange(cursorRange.location - 1, 1) withAttributedString:self.textView.emptyContent];
         self.textView.selectedRange = NSMakeRange(cursorRange.location - 1, 0);
        [self textViewDidChange:self.textView];
    }
}

- (void)sendEmoji {
    [self sendTextAndClearTextView];
}

@end
