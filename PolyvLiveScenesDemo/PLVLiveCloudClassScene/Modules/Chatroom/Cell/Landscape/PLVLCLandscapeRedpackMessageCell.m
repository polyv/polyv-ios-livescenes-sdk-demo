//
//  PLVLCLandscapeRedpackMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/11.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCLandscapeRedpackMessageCell.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *kPLVLCRedpackMessageTapKey = @"redpackTap";

@interface PLVLCLandscapeRedpackMessageCell ()

@property (nonatomic, strong) UILabel *chatLabel;

@end

@implementation PLVLCLandscapeRedpackMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.chatLabel];
    }
    return self;
}

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat xPadding = 8.0; // 文本与气泡的内部左右间距
    CGFloat yPadding = 4.0; // 文本与气泡的内部上下间距
    
    CGFloat labelWidth = self.cellWidth - xPadding * 2;
    CGSize chatLabelSize = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)
                                                                       options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading|NSStringDrawingUsesDeviceMetrics
                                                                       context:nil].size;
    CGFloat chatLabelHeight = 0;
    if (chatLabelSize.height <= 24) {
        chatLabelHeight = 20;
    } else if (chatLabelSize.height <= 37) {
        chatLabelHeight = ceil(chatLabelSize.height) + 4;
    } else {
        chatLabelHeight = ceil(chatLabelSize.height) + 8;
    }
    self.chatLabel.frame = CGRectMake(xPadding, yPadding, chatLabelSize.width, chatLabelHeight);
    
    CGSize bubbleSize = CGSizeMake(chatLabelSize.width + xPadding * 2, chatLabelHeight + yPadding * 2);
    self.bubbleView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeRedpackMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    
    NSAttributedString *attributedString = [PLVLCLandscapeRedpackMessageCell contentAttributedStringWithChatModel:model];
    self.chatLabel.attributedText = attributedString;
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeRedpackMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 8.0; // 文本与气泡的内部左右间距
    CGFloat yPadding = 4.0; // 文本与气泡的内部上下间距
    CGFloat bubbleHeight = 0;
    
    // 内容文本高度
    NSAttributedString *chatLabelString = [PLVLCLandscapeRedpackMessageCell contentAttributedStringWithChatModel:model];
    CGRect chatLabelRect = CGRectZero;
    if (chatLabelString) {
        CGFloat labelWidth = cellWidth - xPadding * 2;
        chatLabelRect = [chatLabelString boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading|NSStringDrawingUsesDeviceMetrics context:nil];
        CGFloat chatLabelHeight = 0;
        if (chatLabelRect.size.height <= 24) { //一行
            chatLabelHeight = 20;
        } else if (chatLabelRect.size.height <= 37) { //二行
            chatLabelHeight = ceil(chatLabelRect.size.height) + 4;
        } else { //三行及以上
            chatLabelHeight = ceil(chatLabelRect.size.height) + 8;
        }
        bubbleHeight = yPadding + chatLabelHeight + yPadding;
    }
    
    return bubbleHeight + 5; // 气泡外部间隔5pt
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (message &&
        [message isKindOfClass:[PLVRedpackMessage class]]) { // 目前移动端只支持支付宝口令红包
        PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)message;
        return redpackMessage.type == PLVRedpackMessageTypeAliPassword;
    }
    return NO;
}

#pragma mark - [ Private Methods ]

/// 获取红包消息文本
+ (NSAttributedString *)contentAttributedStringWithChatModel:(PLVChatModel *)chatModel {
    id message = chatModel.message;
    if (![message isKindOfClass:[PLVRedpackMessage class]]) {
        return nil;
    }
    
    PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)message;
    
    // 红包icon
    UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_landscape_redpack_icon"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, -2, 20, 20);
    
    // 白色文本
    NSString *redpackTypeString = @"";
    if (redpackMessage.type == PLVRedpackMessageTypeAliPassword) {
        redpackTypeString = PLVLocalizedString(@"支付宝口令");
    }
    NSString *contentString = [NSString stringWithFormat:PLVLocalizedString(@" %@ 发了一个%@红包，"), chatModel.user.userName, redpackTypeString];
    NSDictionary *attributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                    NSForegroundColorAttributeName:[UIColor whiteColor],
                                    NSBaselineOffsetAttributeName:@(4.0)};
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:contentString attributes:attributeDict];
    
    // 红色文本
    NSDictionary *redAttributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                       kPLVLCRedpackMessageTapKey:@(1),
                                       NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#FF5959"],
                                       NSBaselineOffsetAttributeName:@(4.0)};
    NSAttributedString *redString = [[NSAttributedString alloc] initWithString:PLVLocalizedString(@"点击领取") attributes:redAttributeDict];
    
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
    [muString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [muString appendAttributedString:string];
    [muString appendAttributedString:redString];
    return [muString copy];
}

#pragma mark Getter

- (UILabel *)chatLabel {
    if (!_chatLabel) {
        _chatLabel = [[UILabel alloc] init];
        _chatLabel.numberOfLines = 0;
        _chatLabel.userInteractionEnabled = YES;
        _chatLabel.textAlignment = NSTextAlignmentLeft;
        
        UITapGestureRecognizer *labTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatLabelTapAction:)];
        [_chatLabel addGestureRecognizer:labTapGesture];
    }
    return _chatLabel;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)chatLabelTapAction:(UITapGestureRecognizer *)gesture {
    if (![self.model.message isKindOfClass:[PLVRedpackMessage class]]) {
        return;
    }
    
    PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)self.model.message;
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        CGPoint point = [gesture locationInView:self.chatLabel];
        NSDictionary *dict = [PLVFdUtil textAttributesAtPoint:point withLabel:self.chatLabel];
        for (NSString *attributeName in dict.allKeys) {
            if ([attributeName isEqualToString:kPLVLCRedpackMessageTapKey]) {
                if (self.redpackTapHandler) {
                    self.redpackTapHandler(self.model);
                }
            }
        }
    }
}

@end
