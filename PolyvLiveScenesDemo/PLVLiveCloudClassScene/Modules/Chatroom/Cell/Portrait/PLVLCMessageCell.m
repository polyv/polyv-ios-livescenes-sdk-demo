//
//  PLVLCMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCMessageCell.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@implementation PLVLCMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.avatarImageView];
        [self.contentView addSubview:self.nickLabel];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self.contentView addGestureRecognizer:longPress];
    }
    return self;
}

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 头像左间距，昵称右间距
    CGFloat originX = xPadding;
    CGFloat originY = 8.0;
    
    self.avatarImageView.frame = CGRectMake(originX, originY, 40, 40);
    
    originX += self.avatarImageView.frame.size.width + 8; // 头像于昵称间距为8
    self.nickLabel.frame = CGRectMake(originX, originY, self.cellWidth - originX - xPadding, 15);
}

#pragma mark - Getter

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 8, 40, 40)];
        _avatarImageView.layer.masksToBounds = YES;
        _avatarImageView.layer.cornerRadius = 20.0;
    }
    return _avatarImageView;
}

- (UILabel *)nickLabel {
    if (!_nickLabel) {
        _nickLabel = [[UILabel alloc] init];
    }
    return _nickLabel;
}

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    // 设置用户头像
    NSURL *avatarURL = [PLVLCMessageCell avatarImageURLWithUser:model.user];
    UIImage *placeholderImage = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_default_avatar"];
    if (avatarURL) {
        [PLVLCUtils setImageView:self.avatarImageView url:avatarURL  placeholderImage:placeholderImage
                         options:SDWebImageRetryFailed];
    } else {
        self.avatarImageView.image = placeholderImage;
    }
    
    // 设置昵称文本
    NSAttributedString *nickLabelString = [PLVLCMessageCell nickLabelAttributedStringWithUser:model.user
                                                                                  loginUserId:self.loginUserId];
    self.nickLabel.attributedText = nickLabelString;
}

#pragma mark UI - ViewModel

/// 获取用户头像URL
+ (NSURL *)avatarImageURLWithUser:(PLVChatUser *)user {
    if (!user || ![user isKindOfClass:[PLVChatUser class]]) {
        return nil;
    }
    NSString *avatarUrl = user.avatarUrl;
    if (!avatarUrl || ![avatarUrl isKindOfClass:[NSString class]] || avatarUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:avatarUrl];
}

/// 获取"头衔+昵称“多属性文本
+ (NSAttributedString *)nickLabelAttributedStringWithUser:(PLVChatUser *)user loginUserId:(NSString *)loginUserId {
    if (!user.userName || ![user.userName isKindOfClass:[NSString class]] || user.userName.length == 0) {
        return nil;
    }
    
    NSString *content = user.userName;
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, user.userName];
    }
    
    if (user.userId && [user.userId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isEqualToString:user.userId]) {
        content = [content stringByAppendingString:PLVLocalizedString(@"（我）")];
    }

    NSString *colorHexString = [user isUserSpecial] ? @"#78A7ED" : @"#ADADC0";
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:colorHexString]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

#pragma mark - 高度计算

/// 计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVLCMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    return 8 + 40 + 16;
}

#pragma mark - Utils

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message ||
        (![message isKindOfClass:[PLVSpeakMessage class]] &&
         ![message isKindOfClass:[PLVQuoteMessage class]] &&
         ![message isKindOfClass:[PLVImageMessage class]] &&
         ![message isKindOfClass:[PLVImageEmotionMessage class]] &&
         ![message isKindOfClass:[PLVFileMessage class]] &&
         ![message isKindOfClass:[PLVRedpackMessage class]] &&
         ![message isKindOfClass:[PLVCustomIntroductionMessage class]] &&
         ![message isKindOfClass:[NSString class]])) {
        return NO;
    }
    
    return YES;
}

+ (CAShapeLayer *)bubbleLayerWithSize:(CGSize)size {
    UIRectCorner corners = UIRectCornerTopRight|UIRectCornerBottomLeft|UIRectCornerBottomRight;
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    return maskLayer;
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
        
        UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:PLVLocalizedString(@"复制") action:@selector(customCopy:)];
        UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:PLVLocalizedString(@"回复") action:@selector(reply:)];
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        if (self.model.isProhibitMsg && self.model.prohibitWord) { // 含有严禁词并且发送失败时
            [menuController setMenuItems:@[copyMenuItem]];
        } else {
            [menuController setMenuItems:@[copyMenuItem, replyMenuItem]];
        }
        
        CGRect rect = CGRectMake(24, 30, 105, 42);
        [menuController setTargetRect:rect inView:self];
        [menuController setMenuVisible:YES animated:YES];
    }
}

@end
