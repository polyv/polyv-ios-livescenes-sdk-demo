//
//  PLVSABaseMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABaseMessageCell.h"
// 工具
#import "PLVSAUtils.h"

// model
#import "PLVChatModel.h"

@implementation PLVSABaseMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
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

#pragma mark - [ Private Method ]

#pragma mark Setter
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

#pragma mark - Event

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
    if (!self.allowCopy &&
        !self.allowReply) {
        return;
    }
    [self becomeFirstResponder];
    [self setMenuItem];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    CGRect rect = CGRectMake(0, 0, 105, 42);
    [menuController setTargetRect:rect inView:self];
    [menuController setMenuVisible:YES animated:YES];
}

#pragma mark 设置身份标签

+ (NSString *)actorBgColorHexStringWithUserType:(PLVRoomUserType)userType {
    NSString *colorHexString = nil;
    switch (userType) {
        case PLVRoomUserTypeGuest:
            colorHexString = @"#EB6165";
            break;
        case PLVRoomUserTypeTeacher:
            colorHexString = @"#F09343";
            break;
        case PLVRoomUserTypeAssistant:
            colorHexString = @"#598FE5";
            break;
        case PLVRoomUserTypeManager:
            colorHexString = @"#33BBC5";
            break;
        default:
            break;
    }
    return colorHexString;
}

+ (BOOL)showActorLabelWithUser:(PLVChatUser *)user {
    return (user.userType == PLVRoomUserTypeGuest ||
            user.userType == PLVRoomUserTypeTeacher ||
            user.userType == PLVRoomUserTypeAssistant ||
            user.userType == PLVRoomUserTypeManager);
}

+ (UIImage*) actorImageWithUser:(PLVChatUser *)user; {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:10];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 7;
    label.layer.masksToBounds = YES;
    label.text = user.actor;
    
    NSString *backgroundColor = [self actorBgColorHexStringWithUserType:user.userType];
    if (backgroundColor) {
        label.backgroundColor = [PLVColorUtil colorFromHexString:backgroundColor];
    }
    NSString *actor = user.actor;
    CGSize size;
    if (actor &&
        [actor isKindOfClass:[NSString class]] &&
        actor.length >0) {
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:actor attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10]}];
        size = [attr boundingRectWithSize:CGSizeMake(100, 14) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
        size.width += 10;
    }
    label.frame = CGRectMake(0, 0, size.width, 14);
    UIGraphicsBeginImageContextWithOptions(label.frame.size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [label.layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    return image;
}
@end
