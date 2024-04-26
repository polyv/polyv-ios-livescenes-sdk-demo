//
//  PLVLCKeyboardToolView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/6.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCKeyboardToolView.h"
#import "PLVLCKeyboardTextView.h"
#import "PLVLCEmojiSelectView.h"
#import "PLVLCKeyboardMoreView.h"
#import "PLVEmoticonManager.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVChatModel.h"
#import "PLVLCRepliedMsgView.h"
#import "PLVLCIarEntranceView.h"

#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

NSString *PLVLCInteractUpdateIarEntranceCallbackNotification = @"PLVInteractUpdateIarEntranceCallbackNotification";

NSString *PLVLCKeyBoardToolViewChatroomOpenInteractAppNotification = @"PLVLCChatroomOpenInteractAppNotification";

static CGFloat kMaxTextViewHeight = 120.0;

@interface PLVLCKeyboardToolView ()<
UITextViewDelegate,
PLVLCEmojiSelectViewDelegate,
PLVLCIarEntranceViewDelegate,
PLVLCKeyboardMoreViewDelegate
>
/// 不同的 mode，决定不同的 UI
@property (nonatomic, assign) PLVLCKeyboardToolMode mode;

@property (nonatomic, assign) PLVLCKeyboardToolState toolState;
/// 使用局部变量代替属性会在 iOS 9.3.1 上产生内存问题
@property (nonatomic, strong) UIView *tempInputView;
/// 文本输入框
@property (nonatomic, strong) PLVLCKeyboardTextView *textView;
/// 互动功能入口
@property (nonatomic, strong) PLVLCIarEntranceView *iarEntranceView;
/// emoji 按钮
@property (nonatomic, strong) UIButton *emojiButton;
/// 打赏按钮
@property (nonatomic, strong) UIButton *rewardButton;
/// 打开更多面板按钮
@property (nonatomic, strong) UIButton *moreButton;
/// emoji 选择面板
@property (nonatomic, strong) PLVLCEmojiSelectView *emojiboard;
/// 查看更多面板
@property (nonatomic, strong) PLVLCKeyboardMoreView *moreboard;
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
//textView 的点击手势 当处于表情面板时点击切换输入法面板
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
/// 引用回复消息
@property (nonatomic, strong) PLVChatModel * _Nullable replyModel;
/// 显示被引用回复消息UI
@property (nonatomic, strong) PLVLCRepliedMsgView * _Nullable replyModelView;

@end

@implementation PLVLCKeyboardToolView

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithMode:PLVLCKeyboardToolModeDefault];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.toolState == PLVLCKeyboardToolStateMoreboard) {
        CGFloat boardHeight = self.moreboardHeight;
        self.moreboard.frame = CGRectMake(0, CGRectGetMaxY(self.moreboard.frame) - boardHeight, self.bounds.size.width, boardHeight);
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Initialize

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRed:0x1a/255.0 green:0x1b/255.0 blue:0x1f/255.0 alpha:1.0];
    
    [self addSubview:self.textView];
    [self addSubview:self.emojiButton];
    [self.textView addGestureRecognizer:self.tapGesture];
    if (self.mode == PLVLCKeyboardToolModeDefault) {
        [self addSubview:self.moreButton];
        [self addSubview:self.rewardButton];
        [self addSubview:self.iarEntranceView];
    }
}

#pragma mark - Getterr & Setter

- (PLVLCKeyboardTextView *)textView {
    if (!_textView) {
        _textView = [[PLVLCKeyboardTextView alloc] init];
        _textView.delegate = self;
    }
    return _textView;
}

- (PLVLCIarEntranceView *)iarEntranceView {
    if (!_iarEntranceView) {
        _iarEntranceView = [[PLVLCIarEntranceView alloc] init];
        _iarEntranceView.hidden = YES;
        _iarEntranceView.delegate = self;
    }
    return _iarEntranceView;
}

- (UIButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_btn_emoji"];
        [_emojiButton setImage:image forState:UIControlStateNormal];
        [_emojiButton setImage:image forState:UIControlStateSelected];
        [_emojiButton addTarget:self action:@selector(emojiAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _emojiButton;
}

- (UIButton *)rewardButton {
    if (!_rewardButton) {
        _rewardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVLCUtils imageForChatroomResource:@"plv_keyboard_btn_reward"];
        [_rewardButton setImage:image forState:UIControlStateNormal];
        [_rewardButton setImage:image forState:UIControlStateSelected];
        [_rewardButton addTarget:self action:@selector(rewardAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rewardButton;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *moreBtnImage = [PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_btn_more"];
        [_moreButton setImage:moreBtnImage forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (PLVLCEmojiSelectView *)emojiboard {
    if (!_emojiboard) {
        PLVLCEmojiSelectToolMode emojiMode = _mode == PLVLCKeyboardToolModeDefault ? PLVLCEmojiSelectToolModeDefault : PLVLCEmojiSelectToolModeSimple;
        _emojiboard = [[PLVLCEmojiSelectView alloc] initWithMode:emojiMode];
        _emojiboard.delegate = self;
    }
    return _emojiboard;
}

- (PLVLCKeyboardMoreView *)moreboard {
    if (!_moreboard) {
        _moreboard = [[PLVLCKeyboardMoreView alloc] init];
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

- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapGestureRecognizer)];
        _tapGesture.enabled = NO;
    }
    return _tapGesture;
}

- (void)setEnableSendImage:(BOOL)enableSendImage {
    if (_enableSendImage == enableSendImage) {
        return;
    }
    _enableSendImage = enableSendImage;
    self.moreboard.sendImageEnable = enableSendImage;
}

- (void)setEnableReward:(BOOL)enableReward {
    _enableReward = enableReward;
    self.moreboard.hideRewardDisplaySwitch = !enableReward;
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

- (void)setToolState:(PLVLCKeyboardToolState)toolState {
    if (toolState == _toolState) {
        return;
    }
    
    if (self.changingToolState) {
        return;
    }
    self.changingToolState = YES;
    
    PLVLCKeyboardToolState originState = _toolState;
    
    self.emojiButton.selected = (toolState == PLVLCKeyboardToolStateEmojiboard);
    
    if (originState == PLVLCKeyboardToolStateEmojiboard) { // 从emoji键盘切换到其他模式时
       self.textView.inputView = nil;
       [self.textView reloadInputViews];
       [self.textView becomeFirstResponder];
       if (toolState != PLVLCKeyboardToolStateKeyboard) {
           [self.textView resignFirstResponder];
       }
    }
    
    if (toolState == PLVLCKeyboardToolStateEmojiboard) { // 从其他模式切换到emoji键盘时
        // 在 iOS 9.3.1 上使用局部变量代替 tempInputView 在打开表情键盘退出时会出现内存问题
        self.tempInputView = [[UIView alloc] initWithFrame:CGRectZero];
        self.textView.inputView = self.tempInputView;
        [self.textView reloadInputViews];
        [self.textView becomeFirstResponder];
        [self.textView resignFirstResponder];
    }
    
    if (toolState != PLVLCKeyboardToolStateEmojiboard &&
        toolState != PLVLCKeyboardToolStateKeyboard) {
        self.textView.inputView = nil;
        [self.textView reloadInputViews];
        [self.textView becomeFirstResponder];
        [self.textView resignFirstResponder];
    }
    
    if (toolState != PLVLCKeyboardToolStateEmojiboard && toolState != PLVLCKeyboardToolStateKeyboard) {
        [self updateReplyModel:nil];
    }
    
    _toolState = toolState;
    
    if (_toolState == PLVLCKeyboardToolStateNormal) {
        [self animateRemoveFromWindow];
    } else if (_toolState == PLVLCKeyboardToolStateKeyboard) {
        if (originState == PLVLCKeyboardToolStateEmojiboard) {
            [self animateAddToWindow];
        }
    } else if (_toolState == PLVLCKeyboardToolStateEmojiboard || _toolState == PLVLCKeyboardToolStateMoreboard) {
        [self animateAddToWindow];
    }
    self.changingToolState = NO;
}

- (void)setImageEmotions:(NSArray *)imageEmotions {
    self.emojiboard.imageEmotions = imageEmotions;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)rewardAction:(UIButton *)sender {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_openReward:)]) {
        [self.delegate keyboardToolView_openReward:self];
    }
}

- (void)emojiAction:(UIButton *)sender {
    if (![self shouldInteract]) {
        return;
    }
    self.tapGesture.enabled = !self.emojiButton.selected;
    self.emojiButton.selected = !self.emojiButton.selected;
    self.toolState = self.emojiButton.selected ? PLVLCKeyboardToolStateEmojiboard : PLVLCKeyboardToolStateKeyboard;
}

- (void)moreAction:(UIButton *)sender {
    self.toolState = PLVLCKeyboardToolStateMoreboard;
    if (![self shouldInteract]) {
        [self.moreboard disableRoomInteraction:YES];
    }
}

- (void)tapAction:(id)sender {
    self.toolState = PLVLCKeyboardToolStateNormal;
}

- (void)textViewTapGestureRecognizer {
    if (self.emojiButton.selected) {
        [self emojiAction:nil];
    }
}

#pragma mark - Public Method

- (instancetype)initWithMode:(PLVLCKeyboardToolMode)mode {
    self = [super init];
    if (self) {
        _mode = MAX(MIN(PLVLCKeyboardToolModeSimple, mode), 0);
        _enableSendImage = YES;
        _disableOtherButtonsInTeacherMode = NO;
        _enablePointReward = NO;
        _enableReward = NO;
        [self setupUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
        if (self.mode == PLVLCKeyboardToolModeDefault) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(interactUpdateIarEntranceCallback:) name:PLVLCInteractUpdateIarEntranceCallbackNotification
                                                       object:nil];
        }
    }
    return self;
}

- (void)changePlaceholderText:(NSString *)text {
    [self.textView changePlaceholderText:text];
}

- (void)addAtView:(UIView *)parentView frame:(CGRect)rect {
    self.normalSuperView = parentView;
    [self.normalSuperView addSubview:self];
    
    self.frame = rect;
    self.originY = rect.origin.y;
    self.bottomHeight = rect.size.height - [self getKeyboardToolViewHeight];
    
    [self updateUI];
}

- (void)updateTextViewAndButton {
    CGRect rect = self.frame;
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 左右边距
    CGFloat textViewWidth = rect.size.width - xPadding - (self.mode == PLVLCKeyboardToolModeSimple ? 40 + xPadding : 80 + xPadding);
    CGFloat iarEntranceViewHeight = self.iarEntranceView.hidden ? 0.0 : PLVLCIarEntranceViewHeight + 8.0;
    [self.textView setupWithFrame:CGRectMake(xPadding, iarEntranceViewHeight + 8, textViewWidth, 40)];

    if (self.mode == PLVLCKeyboardToolModeDefault && self.enableReward) {
        self.rewardButton.frame = CGRectMake(xPadding, iarEntranceViewHeight + 8, 32, 32);
        [self.textView setupWithFrame:CGRectMake(CGRectGetMaxX(self.rewardButton.frame) + 8, iarEntranceViewHeight + 8, textViewWidth - 40, 40)];
    }
    
    self.emojiButton.frame = CGRectMake(CGRectGetMaxX(self.textView.frame) + 8, iarEntranceViewHeight + 12, 32, 32);
    self.moreButton.frame = CGRectMake(CGRectGetMaxX(self.emojiButton.frame) + 8, iarEntranceViewHeight + 12, 32, 32);
}

- (void)updateChatButtonDataArray:(NSArray *)dataArray {
    [self.moreboard updateChatButtonDataArray:dataArray];
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

- (void)replyChatModel:(PLVChatModel *)model {
    [self updateReplyModel:model];
    
    self.toolState = PLVLCKeyboardToolStateKeyboard;
    [self.textView becomeFirstResponder];
}

- (CGFloat)getKeyboardToolViewHeight {
    if (self.iarEntranceView.hidden) {
        return 56.0;
    }
    return 56.0 + PLVLCIarEntranceViewHeight + 8.0;
}

#pragma mark - Private Method
- (void)updateUI {
    self.iarEntranceView.frame = CGRectMake(0, 8, kScreenWidth, PLVLCIarEntranceViewHeight);
    [self updateTextViewAndButton];
    self.lastTextViewHeight = ceilf([self.textView sizeThatFits:self.textView.frame.size].height);
    self.emojiButton.frame = CGRectMake(CGRectGetMaxX(self.textView.frame) + 8, PLVLCIarEntranceViewHeight + 20, 32, 32);
    self.moreButton.frame = CGRectMake(CGRectGetMaxX(self.emojiButton.frame) + 8, PLVLCIarEntranceViewHeight + 20, 32, 32);
    if (self.iarEntranceView.hidden) {
        self.emojiButton.frame = CGRectMake(CGRectGetMaxX(self.textView.frame) + 8, 12, 32, 32);
        self.moreButton.frame = CGRectMake(CGRectGetMaxX(self.emojiButton.frame) + 8, 12, 32, 32);
    }
    
    CGFloat emojiboardHeight = 190.0 + self.bottomHeight;
    if (self.mode == PLVLCKeyboardToolModeDefault) {
        emojiboardHeight += 40;
    }
    
    CGFloat moreboardHeight = 115.0 + self.bottomHeight;
    self.emojiboardHeight = emojiboardHeight;
    self.moreboardHeight = moreboardHeight;
    // 提前设置 frame 值，是为了先初始化
    self.moreboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.moreboardHeight);
    self.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, self.emojiboardHeight);
}

- (void)animateAddToWindow {
    __weak typeof(self) weakSelf = self;
    [weakSelf addViewInWindow];
    [UIView animateWithDuration:0 animations:^{ // 动画效果有点问题，暂时移除动画
        CGFloat boardHeight = 0;
        CGFloat boardWidth = weakSelf.bounds.size.width;
        if (weakSelf.toolState == PLVLCKeyboardToolStateEmojiboard) {
            boardHeight = weakSelf.emojiboardHeight;
            weakSelf.emojiboard.frame = CGRectMake(0, kScreenHeight - boardHeight, kScreenWidth, boardHeight);
            weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight, boardWidth, weakSelf.moreboardHeight);
        } else if (weakSelf.toolState == PLVLCKeyboardToolStateMoreboard) {
            boardHeight = weakSelf.moreboardHeight;
            weakSelf.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, weakSelf.emojiboardHeight);
            weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight - boardHeight, boardWidth, boardHeight);
        } else if (weakSelf.toolState == PLVLCKeyboardToolStateKeyboard) {
            boardHeight = weakSelf.keyboardHeight;
            weakSelf.emojiboard.frame = CGRectMake(0, kScreenHeight, kScreenWidth, weakSelf.emojiboardHeight);
            weakSelf.moreboard.frame = CGRectMake(0, kScreenHeight, boardWidth, weakSelf.moreboardHeight);
        }
        CGRect selfRect = weakSelf.frame;
        if (boardHeight == 0) { // 模拟器使用外接键盘时，self.keyboardHeight 为 0
            boardHeight = weakSelf.bottomHeight;
        }
        weakSelf.frame = CGRectMake(0, kScreenHeight - selfRect.size.height - boardHeight + weakSelf.bottomHeight, boardWidth, selfRect.size.height);
        if (weakSelf.replyModelView) {
            CGFloat replyModelViewHeight = weakSelf.replyModelView.viewHeight;
            weakSelf.replyModelView.frame = CGRectMake(0, weakSelf.frame.origin.y - replyModelViewHeight, boardWidth, replyModelViewHeight);
        }
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
    [window addSubview:self.replyModelView];
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
    self.tapGesture.enabled = NO;
    // 将 self 添加到原先的父视图
    [self.normalSuperView addSubview:self];
    // 设置视图 frame 值
    CGRect selfRect = self.frame;
    CGFloat normalSuperViewHeight = self.originY + [self getKeyboardToolViewHeight] + self.bottomHeight;
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
        NSString *text = [self.textView plvTextForRange:NSMakeRange(0, self.textView.attributedText.length)];
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:sendText:replyModel:)]) {
            [self.delegate keyboardToolView:self sendText:text replyModel:self.replyModel];
        }
        
        [self updateReplyModel:nil];
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

/// 切换聊天室关闭状态，开启/禁用输入框、emoji 选择、查看更多中的部分功能
- (void)changeCloseRoomStatus:(BOOL)closeRoom {
    NSString *placeholderText = closeRoom ? PLVLocalizedString(@"聊天室已关闭"):PLVLocalizedString(@"我也来聊几句");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setEditable:!closeRoom];
        [self changePlaceholderText:placeholderText];
        self.emojiButton.enabled = !closeRoom;
        if (self.mode == PLVLCKeyboardToolModeDefault) {
            [self.moreboard changeCloseRoomStatus:closeRoom];
        }
        [self setToolState:PLVLCKeyboardToolStateNormal];
    });
}

/// 切换聊天室专注模式状态，开启/禁用输入框、emoji 选择、查看更多中的部分功能，启用只看讲师功能
- (void)changeFocusMode:(BOOL)focusMode {
    NSString *placeholderText = focusMode ? PLVLocalizedString(@"当前为专注模式，无法发言"):PLVLocalizedString(@"我也来聊几句");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setEditable:!focusMode];
        [self changePlaceholderText:placeholderText];
        self.emojiButton.enabled = !focusMode;
        if (self.mode == PLVLCKeyboardToolModeDefault) {
            [self.moreboard changeFocusModeStatus:focusMode];
        }
        [self setToolState:PLVLCKeyboardToolStateNormal];
    });
}

- (void)updateReplyModel:(PLVChatModel *)model {
    self.replyModel = model;
    
    if (self.replyModel) {
        self.replyModelView = [[PLVLCRepliedMsgView alloc] initWithChatModel:model];
        __weak typeof(self) weakSelf = self;
        [self.replyModelView setCloseButtonHandler:^{
            [weakSelf updateReplyModel:nil];
        }];
        self.replyModelView.frame = CGRectMake(0, CGRectGetMinY(self.frame), CGRectGetWidth(self.frame), self.replyModelView.viewHeight);
    } else {
        [self.replyModelView removeFromSuperview];
        self.replyModelView = nil;
    }
}

#pragma mark - NSNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    self.keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    // 中文键盘或第三方键盘第一次弹出时会收到两至三次弹出事件通知，会导致动画效果不连续流畅，暂无更好解决方案
    if (self.textView.isFirstResponder && self.toolState == PLVLCKeyboardToolStateKeyboard) {
        [self animateAddToWindow];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
//    [self tapAction:nil]; // 第三方键盘，点击隐藏键盘按钮缩起键盘仍需要使用该方法监听
}

- (void)onDeviceOrientationDidChange {
    UIDevice *device = [UIDevice currentDevice] ;
    if (device.orientation == UIDeviceOrientationLandscapeLeft && self.toolState == PLVLCKeyboardToolStateKeyboard) {
        self.toolState = PLVLCKeyboardToolStateNormal;
    }
}

- (void)interactUpdateIarEntranceCallback:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;;
    NSArray *buttonDataArray = PLV_SafeArraryForDictKey(dict, @"dataArray");
    [self.iarEntranceView updateIarEntranceButtonDataArray:buttonDataArray];
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_showIarEntranceView:show:)]) {
        [self.delegate keyboardToolView_showIarEntranceView:self show:!self.iarEntranceView.hidden];
    }
}

#pragma mark - UITextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (![self shouldInteract]) {
        return NO;
    }
    self.toolState = PLVLCKeyboardToolStateKeyboard;
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
    return (newLength <= PLVLCKeyboardMaxTextLength);// 字数超限
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
            if (!weakSelf.iarEntranceView.hidden) {
                rect.size.height -= PLVLCIarEntranceViewHeight + 8.0;
            }
            
            rect.origin.y = maxY - rect.size.height;
            weakSelf.frame = rect;
            // 重新布局
            [weakSelf layoutIfNeeded];
        } completion:nil];
    }
}

#pragma mark - PLVKeyboardMoreView Delegate

- (void)keyboardMoreView_openCamera:(PLVLCKeyboardMoreView *)moreView {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_openCamera:)]) {
        [self.delegate keyboardToolView_openCamera:self];
    }
}

- (void)keyboardMoreView_openAlbum:(PLVLCKeyboardMoreView *)moreView {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_openAlbum:)]) {
        [self.delegate keyboardToolView_openAlbum:self];
    }
}

- (void)keyboardMoreView_openBulletin:(PLVLCKeyboardMoreView *)moreView {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_readBulletin:)]) {
        [self.delegate keyboardToolView_readBulletin:self];
    }
}

- (void)keyboardMoreView_openInteractApp:(PLVLCKeyboardMoreView *)moreView eventName:(NSString *)eventName {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_openInteractApp:eventName:)]) {
        [self.delegate keyboardToolView_openInteractApp:self eventName:eventName];
    }
}

- (void)keyboardMoreView_onlyTeacher:(PLVLCKeyboardMoreView *)moreView on:(BOOL)on {
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

- (void)keyboardMoreView_switchRewardDisplay:(PLVLCKeyboardMoreView *)moreView on:(BOOL)on {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView_switchRewardDisplay:on:)]) {
        [self.delegate keyboardToolView_switchRewardDisplay:self on:on];
    }
}

- (void)keyboardMoreView:(PLVLCKeyboardMoreView *)moreView switchLanguageMode:(NSInteger)languageMode {
    [self tapAction:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:switchLanguageMode:)]) {
        [self.delegate keyboardToolView:self switchLanguageMode:languageMode];
    }
}

#pragma mark - PLVEmojiSelectView Delegate

- (void)selectEmoji:(PLVEmoticon *)emojiModel {
    if ([self.textView.text length] >= PLVLCKeyboardMaxTextLength) { // 字数超限
        return;
    }
    if (self.textView.isInPlaceholder) {
        [self.textView startEdit];
    }
    NSRange cursorRange = self.textView.selectedRange;
    NSAttributedString *emojiAttrStr = [self.textView convertTextWithEmoji:emojiModel.text];
    [self.textView replaceCharactersInRange:cursorRange withAttributedString:emojiAttrStr];
    self.textView.selectedRange = NSMakeRange(cursorRange.location + emojiAttrStr.length, 0);
    [self textViewDidChange:self.textView];
    if (self.textView.selectedRange.location == self.textView.text.length) {
        CGFloat offsetY = MAX(self.textView.contentSize.height - self.textView.bounds.size.height, 0);
        [self.textView setContentOffset:CGPointMake(0.0, offsetY) animated:YES];
    }
}

- (void)selectImageEmotions:(PLVImageEmotion *)emojiModel {
    if (!emojiModel.imageId ||
        ![emojiModel.imageId isKindOfClass:[NSString class]]) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardToolView:sendImageEmotionId:imageUrl:)]) {
        [self.delegate keyboardToolView:self
                     sendImageEmotionId:emojiModel.imageId
                               imageUrl:emojiModel.url];
    }
    //隐藏面板
    [self tapAction:nil];
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

#pragma mark - PLVLCIarEntranceView Delegate

- (void)iarEntranceView_openInteractApp:(PLVLCIarEntranceView *)iarEntranceView eventName:(NSString *)eventName {
    if ([PLVFdUtil checkStringUseable:eventName]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCKeyBoardToolViewChatroomOpenInteractAppNotification object:eventName];
    }
}

@end
