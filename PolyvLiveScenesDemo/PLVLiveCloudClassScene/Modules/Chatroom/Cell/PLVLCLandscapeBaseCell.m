//
//  PLVLCLandscapeBaseCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/12/29.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCLandscapeBaseCell.h"

@implementation PLVLCLandscapeBaseCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.bubbleView];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self.contentView addGestureRecognizer:longPress];
    }
    return self;
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

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    return 0;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    return NO;
}

#pragma mark - [ Private Methods ]

#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _bubbleView.layer.cornerRadius = 14.0;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
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
}

#pragma mark Gesture

- (void)longPressAction:(id)sender {
    if (self.allowCopy || self.allowReply) {
        [self becomeFirstResponder];
        
        UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(customCopy:)];
        UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复" action:@selector(reply:)];
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        if (self.model.isProhibitMsg && self.model.prohibitWord) { // 含有严禁词并且发送失败时
            [menuController setMenuItems:@[copyMenuItem]];
        } else {
            [menuController setMenuItems:@[copyMenuItem, replyMenuItem]];
        }
        
        CGRect rect = CGRectMake(0, 0, 105, 42);
        [menuController setTargetRect:rect inView:self];
        [menuController setMenuVisible:YES animated:YES];
    }
}

@end
