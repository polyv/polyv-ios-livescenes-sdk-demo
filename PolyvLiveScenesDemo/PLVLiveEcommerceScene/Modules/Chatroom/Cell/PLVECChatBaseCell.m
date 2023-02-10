//
//  PLVECChatBaseCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/3.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECChatBaseCell.h"

@implementation PLVECChatBaseCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.chatLabel];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self.contentView addGestureRecognizer:longPress];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVECChatBaseCell isModelValid:model] || cellWidth == 0) {
        return;
    }
    
    id message = model.message;
    if ([message isKindOfClass:[PLVSpeakMessage class]]) {
        self.allowCopy = YES;
        self.allowReply = YES;
    } else if ([message isKindOfClass:[PLVQuoteMessage class]]) {
        self.allowCopy = YES;
        self.allowReply = YES;
    } else if ([message isKindOfClass:[PLVImageMessage class]]) {
        self.allowCopy = NO;
        self.allowReply = YES;
    } else if ([message isKindOfClass:[PLVImageEmotionMessage class]]) {
        self.allowCopy = NO;
        self.allowReply = YES;
    } else {
        self.allowCopy = NO;
        self.allowReply = NO;
    }
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    return 0;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    PLVChatUser *user = model.user;
    if (!user || ![user isKindOfClass:[PLVChatUser class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message) {
        return NO;
    }
    
    if ([message isKindOfClass:[PLVSpeakMessage class]] ||
        [message isKindOfClass:[PLVQuoteMessage class]] ||
        [message isKindOfClass:[PLVImageMessage class]] ||
        [message isKindOfClass:[PLVImageEmotionMessage class]] ||
        [message isKindOfClass:[PLVCustomMessage class]] ||
        [message isKindOfClass:[PLVFileMessage class]]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.39];
        _bubbleView.layer.cornerRadius = 10;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (UILabel *)chatLabel {
    if (!_chatLabel) {
        _chatLabel = [[UILabel alloc] init];
        _chatLabel.numberOfLines = 0;
        _chatLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _chatLabel;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    if (menuController.isMenuVisible) {
        [self resignFirstResponder];
        [menuController setMenuVisible:NO animated:YES];
    }
    return touchView;
}

- (BOOL)canBecomeFirstResponder {
    return (self.allowCopy || (self.allowReply && self.quoteReplyEnabled));
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL canPerform = NO;
    if (self.allowCopy && (action == @selector(customCopy:))) {
        canPerform = YES;
    }
    if ((self.allowReply && self.quoteReplyEnabled) && (action == @selector(reply:))) {
        canPerform = YES;
    }
    return canPerform;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)reply:(id)sender {
    if (self.replyHandler) {
        self.replyHandler(self.model);
    }
}

/// UIMenuItem复制方法，由子类覆盖实现，处理业务
/// @param sender sender
- (void)customCopy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    id message = self.model.message;
    if ([message isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
        pasteboard.string = speakMessage.content;
    } else if ([message isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)message;
        pasteboard.string = quoteMessage.content;
    }
}

#pragma mark Gesture

- (void)longPressAction:(UIGestureRecognizer *)gesture {
    if (self.allowCopy || (self.allowReply && self.quoteReplyEnabled)) {
        [self becomeFirstResponder];
        
        UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(customCopy:)];
        UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复" action:@selector(reply:)];
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        if (self.model.isProhibitMsg && self.model.prohibitWord) { // 含有严禁词并且发送失败时
            [menuController setMenuItems:@[copyMenuItem]];
        } else {
            [menuController setMenuItems:@[copyMenuItem, replyMenuItem]];
        }
        
        CGRect rect = CGRectMake(0, 2, 105, 42);
        [menuController setTargetRect:rect inView:self];
        [menuController setMenuVisible:YES animated:YES];
    }
}

@end
