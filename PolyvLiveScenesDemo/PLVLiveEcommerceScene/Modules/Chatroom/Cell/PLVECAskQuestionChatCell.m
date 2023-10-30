//
//  PLVECAskQuestionChatCell.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/8/8.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECAskQuestionChatCell.h"
#import "PLVToast.h"
// 模块
#import "PLVChatUser.h"
#import "PLVEmoticonManager.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

@implementation PLVECAskQuestionChatCell

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    if (!self.model || self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 8.0;
    CGFloat originY = 4.0;
    CGFloat bubbleWidth = 0;
    
    CGFloat labelWidth = self.cellWidth - originX * 2;
    CGSize chatLabelSize = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)
                                                                       options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                       context:nil].size;
    CGFloat chatLabelHeight = ceil(chatLabelSize.height) + 8; // 修复可能出现文字显示不全的情况
    CGFloat chatLabelWidth = ceil(chatLabelSize.width) + 2; // 修复可能出现文字显示不全的情况
    self.chatLabel.frame = CGRectMake(originX, originY, chatLabelWidth, chatLabelHeight);
    
    originY += chatLabelHeight + 4;
    bubbleWidth = MIN(chatLabelWidth + originX * 2, self.cellWidth);
    
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, originY);
}

#pragma mark - [ Override ]
- (void)customCopy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    id message = self.model.message;
    if ([message isKindOfClass:[NSString class]]) {
        pasteboard.string = (NSString *)message;
    }
    [PLVToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:[PLVFdUtil getCurrentViewController].view afterDelay:3.0];
}

#pragma mark - [ Public Methods ]
- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model cellWidth:cellWidth];

    if (![PLVECAskQuestionChatCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        self.chatLabel.text = @"";
        return;
    }
    
    self.allowCopy = YES;
    self.cellWidth = cellWidth;
    self.model = model;
    
    // 设置 "昵称：文本（如果有的话）"
    NSAttributedString *chatLabelString = [PLVECAskQuestionChatCell chatLabelAttributedStringWithModel:model];
    self.chatLabel.attributedText = chatLabelString;
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVECAskQuestionChatCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat originX = 8.0;
    CGFloat bubbleHeight = 4.0;
    
    // 内容文本高度
    NSAttributedString *chatLabelString = [PLVECAskQuestionChatCell chatLabelAttributedStringWithModel:model];
    CGRect chatLabelRect = CGRectZero;
    if (chatLabelString) {
        CGFloat labelWidth = cellWidth - originX * 2;
        chatLabelRect = [chatLabelString boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        bubbleHeight += ceil(chatLabelRect.size.height) + 12;
    }
    
    return bubbleHeight + 4;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (message && [message isKindOfClass:[NSString class]]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - [ Private Methods ]

+ (NSAttributedString *)chatLabelAttributedStringWithModel:(PLVChatModel *)model {
    NSAttributedString *actorAttributedString = [PLVECAskQuestionChatCell actorAttributedStringWithUser:model.user];
    NSAttributedString *nickNameAttributedString = [PLVECAskQuestionChatCell nickNameAttributedStringWithUser:model.user];
    NSAttributedString *contentAttributedString = [PLVECAskQuestionChatCell contentAttributedStringWithChatModel:model];
    
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    if (actorAttributedString) {
        [mutableAttributedString appendAttributedString:actorAttributedString];
    }
    if (nickNameAttributedString) {
        [mutableAttributedString appendAttributedString:nickNameAttributedString];
    }
    if (contentAttributedString) {
        [mutableAttributedString appendAttributedString:contentAttributedString];
    }
    return [mutableAttributedString copy];
}

/// 获取头衔
+ (NSAttributedString *)actorAttributedStringWithUser:(PLVChatUser *)user {
    if (!user.specialIdentity ||
        !user.actor || ![user.actor isKindOfClass:[NSString class]] || user.actor.length == 0) {
        return nil;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat actorFontSize = 10.0;
    
    // 设置昵称label
    UILabel *actorLabel = [[UILabel alloc] init];
    actorLabel.text = user.actor;
    actorLabel.font = [UIFont systemFontOfSize:actorFontSize * scale];
    actorLabel.backgroundColor = [PLVECAskQuestionChatCell actorLabelBackground:user];
    actorLabel.textColor = [UIColor whiteColor];
    actorLabel.textAlignment = NSTextAlignmentCenter;
    
    CGRect actorContentRect = [user.actor boundingRectWithSize:CGSizeMake(MAXFLOAT, 12) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:actorFontSize]} context:nil];
    CGSize actorLabelSize = CGSizeMake(actorContentRect.size.width + 12.0, 12);
    actorLabel.frame = CGRectMake(0, 0, actorLabelSize.width * scale, actorLabelSize.height * scale);
    actorLabel.layer.cornerRadius = 6.0 * scale;
    actorLabel.layer.masksToBounds = YES;
    
    // 将昵称label再转换为NSAttributedString对象
    UIImage *actorImage = [PLVImageUtil imageFromUIView:actorLabel];
    NSTextAttachment *labelAttach = [[NSTextAttachment alloc] init];
    labelAttach.bounds = CGRectMake(0, -1.5, actorLabelSize.width, actorLabelSize.height);
    labelAttach.image = actorImage;
    NSAttributedString *actorAttributedString = [NSAttributedString attributedStringWithAttachment:labelAttach];
    
    NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] init];
    [mutableString appendAttributedString:actorAttributedString];
    
    NSAttributedString *emptyAttributedString = [[NSAttributedString alloc] initWithString:@" "
                                                                                attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:actorFontSize]}];
    [mutableString appendAttributedString:emptyAttributedString];
    
    return [mutableString copy];
}

/// 获取头衔label文本背景色
+ (UIColor *)actorLabelBackground:(PLVChatUser *)user {
    UIColor *backgroundColor = [UIColor clearColor];
    if (user.userType == PLVRoomUserTypeGuest) {
        backgroundColor = [PLVColorUtil colorFromHexString:@"#EB6165"];
    } else if (user.userType == PLVRoomUserTypeTeacher) {
        backgroundColor = [PLVColorUtil colorFromHexString:@"#289343"];
    } else if (user.userType == PLVRoomUserTypeAssistant) {
        backgroundColor = [PLVColorUtil colorFromHexString:@"#598FE5"];
    } else if (user.userType == PLVRoomUserTypeManager) {
        backgroundColor = [PLVColorUtil colorFromHexString:@"#33BBC5"];
    }
    return backgroundColor;
}

/// 获取昵称
+ (NSAttributedString *)nickNameAttributedStringWithUser:(PLVChatUser *)user {
    if (!user.userName || ![user.userName isKindOfClass:[NSString class]] || user.userName.length == 0 ||
        (user.userType == PLVRoomUserTypeTeacher && ![PLVFdUtil checkStringUseable:user.userId])) {
        return nil;
    }
    
    NSString *content = [NSString stringWithFormat:@"%@：",user.userName];
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#FFD16B"]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取聊天文本
+ (NSAttributedString *)contentAttributedStringWithChatModel:(PLVChatModel *)chatModel {
    id message = chatModel.message;
    NSString *content = @"";
    if ([message isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
        content = speakMessage.content;
    } else {
        content = (NSString *)message;
    }
    
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    
    UIColor *contentColor = [UIColor whiteColor];
    if (chatModel.user.userType == PLVRoomUserTypeTeacher && ![PLVFdUtil checkStringUseable:chatModel.user.userId]) {
        // 讲师 问候语
        contentColor = [PLVColorUtil colorFromHexString:@"#FFD16B"];
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:contentColor
    };
    NSMutableAttributedString *emotionAttrStr = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:content attributes:attributeDict];
    return [emotionAttrStr copy];
}

// 将UIView转换为UIImage对象
+ (UIImage *)imageFromUIView:(UIView *)view {
    UIImage *image = [PLVImageUtil imageFromUIView:view];
    return image;
}

@end
