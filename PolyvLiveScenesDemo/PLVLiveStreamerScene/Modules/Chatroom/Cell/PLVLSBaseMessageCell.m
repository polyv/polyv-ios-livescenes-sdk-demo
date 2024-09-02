//
//  PLVLSBaseMessageCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/4/14.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSBaseMessageCell.h"
#import "PLVChatModel.h"
#import "PLVMultiLanguageManager.h"

@implementation PLVLSBaseMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self.contentView addGestureRecognizer:longPress];
    }
    return self;
}

#pragma mark - Override

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
    return (self.allowCopy || self.allowReply);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL canPerform = NO;
    if (self.allowCopy && (action == @selector(customCopy:))) {
        canPerform = YES;
    }
    if (self.allowReply && (action == @selector(reply:))) {
        canPerform = YES;
    }
    if (self.allowPinMessage && (action == @selector(pinMessage:))) {
        canPerform = YES;
    }
    return canPerform;
}

#pragma mark - Private Method -

/// 设置menuItem
- (void)setMenuItem {
    UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:PLVLocalizedString(@"复制") action:@selector(customCopy:)];
    UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:PLVLocalizedString(@"回复") action:@selector(reply:)];
    UIMenuItem *pinMsgMenuItem = [[UIMenuItem alloc] initWithTitle:PLVLocalizedString(@"上墙") action:@selector(pinMessage:)];    
    NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity:3];
    // 是否含有严禁词并且发送失败时 || 提醒消息时
    if ((self.model.isProhibitMsg && self.model.prohibitWord) ||
        self.model.isRemindMsg) {
        [menuItems addObject:copyMenuItem];
    } else {
        [menuItems addObjectsFromArray:@[copyMenuItem, replyMenuItem]];
    }
    if (self.allowPinMessage) {
        [menuItems addObject:pinMsgMenuItem];
    }
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuItems:[menuItems copy]];
}

#pragma mark - Action

- (void)reply:(id)sender {
    if (self.replyHandler) {
        self.replyHandler(self.model);
    }
}

- (void)customCopy:(id)sender {
}

- (void)pinMessage:(id)sender {
    if (self.pinMessageHandler) {
        self.pinMessageHandler(self.model);
    }
}

- (void)longPressAction:(id)sender {
    UIGestureRecognizer *gesture = sender;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        [self setMenuItem];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        CGRect rect = CGRectMake(0, 0, 105, 42);
        [menuController setTargetRect:rect inView:self];
        [menuController setMenuVisible:YES animated:YES];
    }
}

@end
