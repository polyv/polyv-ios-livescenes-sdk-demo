//
//  PLVLSBaseMessageCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/4/14.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSBaseMessageCell.h"
#import "PLVChatModel.h"

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
    return canPerform;
}

#pragma mark - Private Method -

/// 设置menuItem
- (void)setMenuItem {
    UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(customCopy:)];
    UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复" action:@selector(reply:)];
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    // 是否含有严禁词
    if (self.model.isProhibitMsg) {
        [menuController setMenuItems:@[copyMenuItem]];
    } else {
        [menuController setMenuItems:@[copyMenuItem, replyMenuItem]];
    }
}

#pragma mark - Action

- (void)reply:(id)sender {
    if (self.replyHandler) {
        self.replyHandler(self.model);
    }
}

- (void)customCopy:(id)sender {
}

- (void)longPressAction:(id)sender {
    [self becomeFirstResponder];

    [self setMenuItem];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    CGRect rect = CGRectMake(0, 0, 105, 42);
    [menuController setTargetRect:rect inView:self];
    [menuController setMenuVisible:YES animated:YES];
}

@end
