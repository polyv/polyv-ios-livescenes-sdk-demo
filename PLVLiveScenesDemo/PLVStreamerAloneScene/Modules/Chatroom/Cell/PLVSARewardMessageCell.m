//
//  PLVSARewardMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/17.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSARewardMessageCell.h"

// Utils
#import "PLVSAUtils.h"
#import "PLVEmoticonManager.h"

// Model
#import "PLVChatModel.h"

// SDK
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVSARewardMessageCell()

// Data
@property (nonatomic, assign) CGFloat cellWidth; // cell宽度
@property (nonatomic, strong) NSString *loginUserId; // 用户的聊天室userId

// UI
@property (nonatomic, strong) UIView *bubbleView; // 背景气泡
@property (nonatomic, strong) UILabel *contentLabel; // 消息文本内容视图
@property (nonatomic, strong) UIImageView *rewardImageView; // 打赏图片
@end

// cell高度
static int cellHeight = 32 + 8;

@implementation PLVSARewardMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply =NO;
        self.allowCopy = NO;
        
        [self.contentView addSubview:self.bubbleView];
        [self.bubbleView addSubview:self.contentLabel];
        [self.bubbleView addSubview:self.rewardImageView];
        
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    CGFloat xPadding = 8.0;
    CGFloat yPadding = 4.0;
    CGFloat bubbleHeight = cellHeight - yPadding * 2;
    CGFloat rewardWidth = 20;
    CGFloat rewardHeight = bubbleHeight;
    CGFloat rewardPadding = 4;
    
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2 - rewardWidth - rewardPadding;
    
    CGSize textViewSize = [self.contentLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 12)];
    
    if (textViewSize.width + xPadding + rewardWidth + rewardPadding > maxTextViewWidth ) {
        textViewSize.width = maxTextViewWidth - xPadding - rewardWidth - rewardPadding;
    }
    
    self.contentLabel.frame = CGRectMake(xPadding, (bubbleHeight - textViewSize.height ) / 2, textViewSize.width, textViewSize.height);
    
    
    CGSize bubbleSize = CGSizeMake(textViewSize.width + xPadding + 32, cellHeight - yPadding *2);
    
    self.bubbleView.frame = CGRectMake(0, yPadding, ceilf(bubbleSize.width), ceilf(bubbleSize.height));
    self.bubbleView.layer.cornerRadius = 12.5;
 
    self.rewardImageView.frame = CGRectMake(CGRectGetMaxX(self.contentLabel.frame) + rewardPadding, (bubbleHeight - rewardHeight ) / 2 , rewardWidth, rewardHeight);
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVSARewardMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
   
    self.cellWidth = cellWidth;
    self.model = model;
    
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }

    
    PLVRewardMessage *message = (PLVRewardMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVSARewardMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:self.loginUserId];
    
    self.contentLabel.attributedText = contentLabelString;
    self.contentLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    // 礼物打赏为礼物图片，现金打赏为空
    if ([PLVFdUtil checkStringUseable:message.gimg]) {
        [self.rewardImageView sd_setImageWithURL:[NSURL URLWithString:message.gimg]];
    } else {
        self.rewardImageView.image = [PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_gift_icon_cash"];
    }
    
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVSARewardMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    return cellHeight;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVRewardMessage class]]) { // 打赏消息
        return NO;
    }
    
    return YES;
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:12];
        _contentLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _contentLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _contentLabel;
}

- (UIImageView *)rewardImageView {
    if (!_rewardImageView) {
        _rewardImageView = [[UIImageView alloc] init];
        _rewardImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _rewardImageView;
}

#pragma mark AttributedString

/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVRewardMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId {
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *nickNameColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    UIColor *contentColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: nickNameColor};
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:contentColor};
    
    NSString *content = user.userName;
    if (!content ||
        ![content isKindOfClass:[NSString class]]) {
        content = @"";
    }
    if (user.userId && [user.userId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:user.userId]) {
        content = [content stringByAppendingString:@"（我）"];
    }
    content = [content stringByAppendingString:@"："];
    
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    
    NSString *gimg = message.gimg;
    NSString *rewardContent = message.rewardContent;
    // 礼物打赏为礼物图片，现金打赏为空
    if ([PLVFdUtil checkStringUseable:gimg]) {
        rewardContent = [NSString stringWithFormat:@"赠送了 %@", rewardContent];
    } else {
        rewardContent = [NSString stringWithFormat:@"打赏 %@元", rewardContent];
    }
    
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:rewardContent attributes:contentAttDict];
    
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    
    return contentLabelString;
}

@end
