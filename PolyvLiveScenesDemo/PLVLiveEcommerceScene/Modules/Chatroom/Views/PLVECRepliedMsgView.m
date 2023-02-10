//
//  PLVECRepliedMsgView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/12/30.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVECRepliedMsgView.h"
#import "PLVChatModel.h"
#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECRepliedMsgView ()

@property (nonatomic, strong) PLVChatModel *chatModel; // 被引用的消息模型
@property (nonatomic, assign) CGFloat viewHeight; // 根据 chatModel 得到的本视图高度
@property (nonatomic, strong) UIButton *closeButton; // 右上方关闭按钮
@property (nonatomic, strong) UILabel *contentLabel; // 文字消息的内容文本

@end

@implementation PLVECRepliedMsgView

#pragma mark - [ Public Method ]

- (instancetype)initWithChatModel:(PLVChatModel *)chatModel {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        
        [self setupUI];
        [self configureChatModel:chatModel];
    }
    return self;
}

#pragma mark - [ Private Method ]

#pragma mark Initialization

- (void)setupUI {
    [self addSubview:self.closeButton];
    [self addSubview:self.contentLabel];
}

- (void)configureChatModel:(PLVChatModel *)chatModel {
    _chatModel = chatModel;
    
    NSMutableString *muString = [[NSMutableString alloc] init];
    if (chatModel.user.userName &&
        [chatModel.user.userName isKindOfClass:[NSString class]] &&
        chatModel.user.userName.length > 0) {
        [muString appendFormat:@"%@：", chatModel.user.userName];
    }
    
    id message = chatModel.message;
    if ([message isKindOfClass:[PLVSpeakMessage class]] ||
        [message isKindOfClass:[PLVQuoteMessage class]]) {
        if ([message isKindOfClass:[PLVSpeakMessage class]]) {
            PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
            [muString appendString:speakMessage.content];
        } else if ([message isKindOfClass:[PLVQuoteMessage class]]) {
            PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)message;
            [muString appendString:quoteMessage.content];
        }
    } else if ([message isKindOfClass:[PLVImageMessage class]]) {
        [muString appendString:@"[图片]"];
    } else if ([message isKindOfClass:[PLVImageEmotionMessage class]]) {
        [muString appendString:@"[图片表情]"];
    }
    
    _contentLabel.text = [muString copy];
    
    [self layoutUI];
}

- (void)layoutUI {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat originX = isPad ? 20.0 : 16.0; // 左右边距
    CGFloat closeButtonOriginX = PLVScreenWidth - 40 - (isPad ? 10 : 6);
    CGFloat labelWidth = closeButtonOriginX - originX;
    
    self.closeButton.frame = CGRectMake(closeButtonOriginX, 0, 40, 40);
    self.contentLabel.frame = CGRectMake(originX, 13, labelWidth, 14);
    
    _viewHeight = 40.0;
}

#pragma mark Getter & Setter

- (UIButton *)closeButton {
    if (!_closeButton) {
        UIImage *image = [PLVECUtils imageForWatchResource:@"plvec_chatroom_reply_close_btn"];
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:12];
        _contentLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
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
