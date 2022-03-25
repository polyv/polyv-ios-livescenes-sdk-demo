//
//  PLVHCChatroomToolView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCChatroomToolView.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import "PLVHCSendMessageTextView.h"

// 模块
#import "PLVEmoticonManager.h"
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCChatroomToolView()

#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  └── (PLVHCChatroomToolView) self (lowest)
///    ├── (UIView) leftView
///    |     ├── (UIButton) emojiButton
///    |     ├── (UIButton) imageButton
///    |     ├── (UIView) lineView
///    |     ├── (PLVHCSendMessageTextView) textView
///    |     ├── (UIButton) chatButton
///    └── (UIButton) closeRoomButton

@property (nonatomic, strong) UIView *leftView; // 左侧视图
@property (nonatomic, strong) UIButton *emojiButton; // emoji表情按钮
@property (nonatomic, strong) UIButton *imageButton; // 图片按钮
@property (nonatomic, strong) UIButton *chatButton; // 聊天按钮（点击显示sendMessageView）
@property (nonatomic, strong) UIView *lineView; // 分隔视图
@property (nonatomic, strong) UIButton *closeRoomButton; // 关闭聊天室按钮

#pragma mark 数据
@property (nonatomic, assign, getter=isStartClass) BOOL startClass;
@property (nonatomic, assign) PLVRoomUserType userType; // 身份类型
@property (nonatomic, assign) BOOL closeRoom;

@end

@implementation PLVHCChatroomToolView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        self.backgroundColor = [UIColor clearColor];
        
        [self.leftView addSubview:self.emojiButton];
        [self.leftView addSubview:self.imageButton];
        [self.leftView addSubview:self.lineView];
        [self.leftView addSubview:self.textView];
        [self.leftView addSubview:self.chatButton];
        [self addSubview:self.leftView];
        [self addSubview:self.closeRoomButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isTeacher = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVSocketUserTypeTeacher;
    CGFloat margin = 8;
    CGFloat closeRoomBtnWH = isTeacher ? 34 : 0;
    CGSize leftSize = CGSizeMake(self.bounds.size.width - closeRoomBtnWH - (isTeacher ? margin : 0), 34);
    
    self.leftView.frame = CGRectMake(0, 0, leftSize.width , leftSize.height);
    self.emojiButton.frame = CGRectMake(0, 0, 32, leftSize.height);
    self.imageButton.frame = CGRectMake(CGRectGetMaxX(self.emojiButton.frame), 0, 32, leftSize.height);
    self.lineView.frame = CGRectMake(CGRectGetMaxX(self.imageButton.frame) + 6, 7, 1, 20);
    self.chatButton.frame = CGRectMake(CGRectGetMaxX(self.lineView.frame) + 12, 0, leftSize.width - CGRectGetMaxX(self.lineView.frame) - margin * 2, leftSize.height);
    self.textView.frame = self.chatButton.frame;
    
    self.closeRoomButton.frame = CGRectMake(CGRectGetMaxX(self.leftView.frame) + margin, 0, closeRoomBtnWH, closeRoomBtnWH);
    [self.chatButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
}

#pragma mark - [ Public Method ]

- (void)startClass {
    self.startClass = YES;
    [self.textView startClass];
}

- (void)finishClass {
    self.startClass = NO;
    [self.textView finishClass];
}

- (void)emojiDidSelectEmoticon:(PLVEmoticon *)emoticon {
    if ([self.textView.text length] > PLVHCSendMessageMaxTextLength) {
        return;
    }
    [self.textView startEdit];
    NSRange cursorRange = self.textView.selectedRange;
    NSAttributedString *emojiAttrStr = [self.textView convertTextWithEmoji:emoticon.text];
    [self.textView replaceCharactersInRange:cursorRange withAttributedString:emojiAttrStr];
    self.textView.selectedRange = NSMakeRange(cursorRange.location + emojiAttrStr.length, 0);
}

- (void)emojiDidDelete {
    if (self.textView.isInPlaceholder) {
        return;
    }
    NSRange cursorRange = self.textView.selectedRange;
    if (self.textView.attributedText.length > 0 &&
        cursorRange.location > 0) {
        [self.textView replaceCharactersInRange:NSMakeRange(cursorRange.location - 1, 1) withAttributedString:self.textView.emptyContent];
         self.textView.selectedRange = NSMakeRange(cursorRange.location - 1, 0);
        
        // 删除最后一个显示占位符
        NSRange cursorRange = self.textView.selectedRange;
        if (self.textView.attributedText.length == 0 ||
            cursorRange.location == 0) {
            [self.textView endEdit];
        }
    }
}

- (void)setCloseRoomButtonState:(BOOL)selected {
    plv_dispatch_main_async_safe(^{
        self.closeRoomButton.selected = selected;
        self.closeRoom = selected;
    })
}

- (void)setEmojiButtonState:(BOOL)selected {
    self.emojiButton.selected = selected;
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)leftView {
    if (!_leftView) {
        _leftView = [[UIView alloc] init];
        _leftView.layer.cornerRadius = 17;
        _leftView.layer.masksToBounds = YES;
        _leftView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
    }
    return _leftView;
}

- (UIButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_emojiButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_emoji"] forState:UIControlStateNormal];
        [_emojiButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_emoji_focused"] forState:UIControlStateSelected];
        [_emojiButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_emoji_focused"] forState:UIControlStateHighlighted];
        [_emojiButton addTarget:self action:@selector(emojiButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _emojiButton;
}

- (UIButton *)imageButton {
    if (!_imageButton) {
        _imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_imageButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_image"] forState:UIControlStateNormal];
        [_imageButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_image_focused"] forState:UIControlStateHighlighted];
        [_imageButton addTarget:self action:@selector(imageButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _imageButton;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [PLVColorUtil colorFromHexString:@"#3D425F"];
    }
    return _lineView;
}

- (UIButton *)chatButton {
    if (!_chatButton) {
        _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chatButton.backgroundColor = [UIColor clearColor];
        [_chatButton addTarget:self action:@selector(chatButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chatButton;
}

- (UIButton *)closeRoomButton {
    if (!_closeRoomButton) {
        _closeRoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeRoomButton.layer.cornerRadius = 17;
        _closeRoomButton.layer.masksToBounds = YES;
        [_closeRoomButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_closeRoom"] forState:UIControlStateNormal];
        [_closeRoomButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_closeRoom_selected"] forState:UIControlStateSelected];
        [_closeRoomButton addTarget:self action:@selector(closeRoomButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _closeRoomButton.hidden = (self.userType != PLVRoomUserTypeTeacher);
    }
    return _closeRoomButton;
}

- (PLVHCSendMessageTextView *)textView {
    if (!_textView) {
        _textView = [[PLVHCSendMessageTextView alloc] init];
        _textView.textContainer.maximumNumberOfLines = 1;
    }
    return _textView;
}

- (void)showUnStartClassToast {
    [PLVHCUtils showToastInWindowWithMessage:@"上课前不能聊天"];
}

- (void)showCloseRoomToast {
    [PLVHCUtils showToastInWindowWithMessage:@"老师已开启全体禁言"];
}

#pragma mark - Event

#pragma mark Action
- (void)chatButtonAction {
    if (!self.isStartClass) {
        [self showUnStartClassToast];
        return;
    }
    
    if (self.closeRoom &&
        self.userType != PLVRoomUserTypeTeacher) {
        [self showCloseRoomToast];
        return;
    }
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] init];
    if (!self.textView.isInPlaceholder) {
        attributedText = self.textView.attributedText;
    }
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomToolViewDidTapChatButton:emojiAttrStr:)]) {
        [self.delegate chatroomToolViewDidTapChatButton:self emojiAttrStr:attributedText];
    }
    // 移除emoji弹窗
    if (self.emojiButton.selected) {
        [self emojiButtonAction];
    }
    // 清除textView输入内容
    [self.textView clearText];
}

- (void)emojiButtonAction {
    if (!self.isStartClass) {
        [self showUnStartClassToast];
        return;
    }
    
    if (self.closeRoom &&
        self.userType != PLVRoomUserTypeTeacher) {
        [self showCloseRoomToast];
        return;
    }
    
    self.emojiButton.selected = !self.emojiButton.selected;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomToolViewDidTapEmojiButton:emojiButtonSelected:)]) {
        [self.delegate chatroomToolViewDidTapEmojiButton:self emojiButtonSelected:self.emojiButton.selected];
    }
}

- (void)imageButtonAction {
    if (!self.isStartClass) {
        [self showUnStartClassToast];
        return;
    }
    
    if (self.closeRoom &&
        self.userType != PLVRoomUserTypeTeacher) {
        [self showCloseRoomToast];
        return;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomToolViewDidTapImageButton:)]) {
        [self.delegate chatroomToolViewDidTapImageButton:self];
    }
}

- (void)closeRoomButtonAction {
    if (!self.isStartClass) {
        [self showUnStartClassToast];
        return;
    }
    
    if (self.userType != PLVRoomUserTypeTeacher) {
        return;
    }
    
    self.closeRoomButton.selected = !self.closeRoomButton.selected;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomToolViewDidTapCloseRoomButton:closeRoomButtonSelected:)]) {
        [self.delegate chatroomToolViewDidTapCloseRoomButton:self closeRoomButtonSelected:self.closeRoomButton.selected];
    }
}

@end
