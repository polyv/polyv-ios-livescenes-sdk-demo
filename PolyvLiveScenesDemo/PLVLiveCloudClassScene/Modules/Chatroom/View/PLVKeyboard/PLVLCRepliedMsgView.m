//
//  PLVLCRepliedMsgView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/12/30.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCRepliedMsgView.h"
#import "PLVChatModel.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCRepliedMsgView ()

@property (nonatomic, strong) PLVChatModel *chatModel; // 被引用的消息模型
@property (nonatomic, assign) CGFloat viewHeight; // 根据 chatModel 得到的本视图高度
@property (nonatomic, strong) UIButton *closeButton; // 右上方关闭按钮
@property (nonatomic, strong) UILabel *nickNameLabel; // 昵称文本
@property (nonatomic, strong) UILabel *contentLabel; // 文字消息的内容文本

@end

@implementation PLVLCRepliedMsgView

#pragma mark - [ Public Method ]

- (instancetype)initWithChatModel:(PLVChatModel *)chatModel {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0x1a/255.0 green:0x1b/255.0 blue:0x1f/255.0 alpha:1.0];
        
        [self setupUI];
        [self configureChatModel:chatModel];
    }
    return self;
}

#pragma mark - [ Private Method ]

#pragma mark Initialization

- (void)setupUI {
    [self addSubview:self.closeButton];
    [self addSubview:self.nickNameLabel];
    [self addSubview:self.contentLabel];
}

- (void)configureChatModel:(PLVChatModel *)chatModel {
    _chatModel = chatModel;
    
    _nickNameLabel.text = [NSString stringWithFormat:@"%@：", [chatModel.user getDisplayNickname:[PLVRoomDataManager sharedManager].roomData.menuInfo.hideViewerNicknameEnabled loginUserId:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId]];
    
    id message = chatModel.message;
    if ([message isKindOfClass:[PLVSpeakMessage class]] ||
        [message isKindOfClass:[PLVQuoteMessage class]]) {
        if ([message isKindOfClass:[PLVSpeakMessage class]]) {
            PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
            _contentLabel.text = speakMessage.content;
        } else if ([message isKindOfClass:[PLVQuoteMessage class]]) {
            PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)message;
            _contentLabel.text = quoteMessage.content;
        }
    } else if ([message isKindOfClass:[PLVImageMessage class]]) {
        _contentLabel.text = PLVLocalizedString(@"[图片]");
    } else if ([message isKindOfClass:[PLVImageEmotionMessage class]]) {
        _contentLabel.text = PLVLocalizedString(@"[图片表情]");
    }
    
    [self layoutUI];
}

- (void)layoutUI {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat originX = isPad ? 20.0 : 16.0; // 左右边距
    CGFloat closeButtonOriginX = PLVScreenWidth - 44 - (isPad ? 7 : 3);
    CGFloat labelWidth = closeButtonOriginX - originX;
    
    self.closeButton.frame = CGRectMake(closeButtonOriginX, 0, 44, 44);
    self.nickNameLabel.frame = CGRectMake(originX, 6, labelWidth, 15);
    self.contentLabel.frame = CGRectMake(originX, CGRectGetMaxY(self.nickNameLabel.frame) + 4, labelWidth, 15);
    
    _viewHeight = 44.0;
}

#pragma mark Getter & Setter

- (UIButton *)closeButton {
    if (!_closeButton) {
        UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_reply_close_btn"];
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:12];
        _nickNameLabel.textColor = [PLVColorUtil colorFromHexString:@"#ADADC0"];
    }
    return _nickNameLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:12];
        _contentLabel.textColor = [PLVColorUtil colorFromHexString:@"#ADADC0"];
    }
    return _contentLabel;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeButtonAction:(id)sender {
    [self removeFromSuperview];
    if (self.closeButtonHandler) {
        self.closeButtonHandler();
    }
}


@end
