//
//  PLVLCLandscapeRepliedMsgView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/12/30.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCLandscapeRepliedMsgView.h"
#import "PLVChatModel.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCLandscapeRepliedMsgView ()

@property (nonatomic, strong) PLVChatModel *chatModel; // 被引用的消息模型
@property (nonatomic, assign) CGFloat viewHeight; // 根据 chatModel 得到的本视图高度
@property (nonatomic, strong) UIButton *closeButton; // 右方关闭按钮
@property (nonatomic, strong) UILabel *label; // 昵称+消息内容文本

@end

@implementation PLVLCLandscapeRepliedMsgView

#pragma mark - [ Public Method ]

- (instancetype)initWithChatModel:(PLVChatModel *)chatModel {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        
        [self setupUI];
        [self configureChatModel:chatModel];
    }
    return self;
}

#pragma mark - [ Private Method ]

#pragma mark Initialization

- (void)setupUI {
    [self addSubview:self.closeButton];
    [self addSubview:self.label];
}

- (void)configureChatModel:(PLVChatModel *)chatModel {
    _chatModel = chatModel;
    
    NSMutableString *muString = [[NSMutableString alloc] init];
    [muString appendFormat:@"%@：", chatModel.user.userName];
    
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
        [muString appendString:PLVLocalizedString(@"[图片]")];
    } else if ([message isKindOfClass:[PLVImageEmotionMessage class]]) {
        [muString appendString:PLVLocalizedString(@"[图片表情]")];
    }
    
    _label.text = [muString copy];
    [self layoutUI];
}

- (void)layoutUI {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat labelOriginX = (isPad ? 36 : 16) + P_SafeAreaLeftEdgeInsets();
    CGFloat buttonWidth = 40.0;
    CGFloat closeButtonOriginX = PLVScreenWidth - buttonWidth - ((isPad ? 36 : 16) + P_SafeAreaRightEdgeInsets());
    CGFloat labelWidth = closeButtonOriginX - labelOriginX;
    
    self.closeButton.frame = CGRectMake(closeButtonOriginX, 0, buttonWidth, buttonWidth);
    self.label.frame = CGRectMake(labelOriginX, 12, labelWidth, 16);
    
    _viewHeight = 40.0;
}

#pragma mark Getter & Setter

- (UIButton *)closeButton {
    if (!_closeButton) {
        UIImage *image = [PLVLCUtils imageForLiveRoomResource:@"plvlc_liveroom_reply_close_btn"];
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    }
    return _label;
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
