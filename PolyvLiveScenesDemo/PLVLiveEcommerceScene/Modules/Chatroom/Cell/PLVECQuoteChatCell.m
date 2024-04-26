//
//  PLVECQuoteChatCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/2/7.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECQuoteChatCell.h"

// 工具
#import "PLVECUtils.h"

// UI
#import "PLVPhotoBrowser.h"

// 模块
#import "PLVChatUser.h"
#import "PLVEmoticonManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECQuoteChatCell ()

@property (nonatomic, strong) UIView *line; /// 引用消息与回复消息分割线
@property (nonatomic, strong) UILabel *quoteContentLabel; /// 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; /// 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser

@end

@implementation PLVECQuoteChatCell


#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.line];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.quoteImageView];
    }
    return self;
}

- (void)layoutSubviews {
    if (!self.model || self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 8.0;
    CGFloat originY = 4.0;
    
    // 设置内容文本frame
    CGFloat labelWidth = self.cellWidth - originX * 2;
    CGRect chatLabelRect = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
    CGFloat chatLabelHeight = ceil(chatLabelRect.size.height) + 8; // 避免可能出现文字显示不全的情况
    self.chatLabel.frame = CGRectMake(originX, originY, ceil(chatLabelRect.size.width), chatLabelHeight);
    originY += chatLabelHeight + 4;
    
    self.line.frame = CGRectMake(originX, originY, 0, 1); // 最后再设置分割线宽度
    originY += 1 + 4;
    
    // 被引用消息文本最多显示2行，故最大高度为44
    NSAttributedString *quoteContentLabelString = self.quoteContentLabel.attributedText;
    CGSize quoteContentLabelSize = [quoteContentLabelString boundingRectWithSize:CGSizeMake(labelWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    self.quoteContentLabel.frame = CGRectMake(originX, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
    originY += ceil(quoteContentLabelSize.height) + 4;
    
    if (!self.quoteImageView.hidden) { //  被引用消息图片
        CGSize quoteImageViewSize = [PLVECQuoteChatCell calculateImageViewSizeWithMessage:self.model.message];
        self.quoteImageView.frame = CGRectMake(originX, originY, quoteImageViewSize.width, quoteImageViewSize.height);
        originY += quoteImageViewSize.height + 4;
    }
    
    self.bubbleView.frame = CGRectMake(0, 0, 0, originY); // 最后再设置气泡宽度
    
    CGFloat contentWidth = [self actualMaxContentWidth];
    CGRect lineRect = self.line.frame;
    self.line.frame = CGRectMake(lineRect.origin.x, lineRect.origin.y, contentWidth, lineRect.size.height);
    
    CGRect bubbleRect = self.bubbleView.frame;
    self.bubbleView.frame = CGRectMake(bubbleRect.origin.x, bubbleRect.origin.y, contentWidth + originX * 2, bubbleRect.size.height);
}

#pragma mark - [ Public Methods ]

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model cellWidth:cellWidth];
    
    if (![PLVECQuoteChatCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    
    // 设置 "昵称：文本（如果有的话）"
    NSMutableAttributedString *chatLabelString;
    if (model.attributeString) {
        chatLabelString = model.attributeString;
    } else {
        model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECQuoteChatCell chatLabelAttributedStringWithModel:model]];
    }
    
    self.chatLabel.attributedText = chatLabelString;
    
    NSAttributedString *quoteLabelString = [PLVECQuoteChatCell quoteContentAttributedStringWithMessage:self.model.message];
    self.quoteContentLabel.attributedText = quoteLabelString;
    
    NSURL *quoteImageURL = [PLVECQuoteChatCell quoteImageURLWithMessage:self.model.message];
    self.quoteImageView.hidden = !quoteImageURL;
    if (quoteImageURL) {
        UIImage *placeholderImage = [PLVECUtils imageForWatchResource:@"plv_chatroom_thumbnail_imag"];
        [PLVECUtils setImageView:self.quoteImageView url:quoteImageURL placeholderImage:placeholderImage options:SDWebImageRetryFailed];
    }
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVECQuoteChatCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat originX = 8.0;
    CGFloat bubbleHeight = 4.0;
    CGFloat labelWidth = cellWidth - originX * 2;
    CGFloat chatLabelHeight = 0;
    
    // 内容文本高度
    NSMutableAttributedString *chatLabelString;
    if (model.attributeString) {
        chatLabelString = model.attributeString;
    } else {
        model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECQuoteChatCell chatLabelAttributedStringWithModel:model]];
    }
    
    if (chatLabelString) {
        CGRect chatLabelRect = [chatLabelString boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        chatLabelHeight = ceil(chatLabelRect.size.height) + 8;
        bubbleHeight += chatLabelHeight;
    }
    
    NSAttributedString *quoteLabelString = [PLVECQuoteChatCell quoteContentAttributedStringWithMessage:model.message];
    CGSize quoteContentSize = [quoteLabelString boundingRectWithSize:CGSizeMake(labelWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat quoteContentHeight = ceil(quoteContentSize.height);
    
    CGFloat quoteImageHeight = 0;
    NSURL *quoteImageURL = [PLVECQuoteChatCell quoteImageURLWithMessage:model.message];
    if (quoteImageURL) {
        CGSize quoteImageViewSize = [PLVECQuoteChatCell calculateImageViewSizeWithMessage:model.message];
        quoteImageHeight = quoteImageViewSize.height;
    }
    
    return 4 + chatLabelHeight + 4 + 1 + 4 + quoteContentHeight + (quoteImageURL ? 4 + quoteImageHeight : 0) + 4 + 4; // 气泡底部外间距为4
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    PLVChatUser *user = model.user;
    id message = model.message;
    if (!user ||
        ![user isKindOfClass:[PLVChatUser class]] ||
        !message ||
        ![message isKindOfClass:[PLVQuoteMessage class]]) {
        return NO;
    }
    
    if (model.contentLength != PLVChatMsgContentLength_0To500) {
        return NO;
    }
    
    return YES;
}

#pragma mark - [ Private Methods ]

/// 消息内容多属性文本：头衔+昵称：文本
+ (NSAttributedString *)chatLabelAttributedStringWithModel:(PLVChatModel *)model {
    NSAttributedString *actorAttributedString = [PLVECQuoteChatCell actorAttributedStringWithUser:model.user];
    NSAttributedString *nickNameAttributedString = [PLVECQuoteChatCell nickNameAttributedStringWithUser:model.user];
    NSAttributedString *contentAttributedString = [PLVECQuoteChatCell contentAttributedStringWithChatModel:model];
    
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

/// 获取特殊身份的头衔，无返回空
+ (NSAttributedString * _Nullable)actorAttributedStringWithUser:(PLVChatUser *)user {
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
    actorLabel.backgroundColor = [PLVECQuoteChatCell actorColor:user];
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
+ (UIColor *)actorColor:(PLVChatUser *)user {
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
+ (NSAttributedString * _Nullable)nickNameAttributedStringWithUser:(PLVChatUser *)user {
    if (!user.userName || ![user.userName isKindOfClass:[NSString class]] || user.userName.length == 0) {
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
+ (NSAttributedString * _Nullable)contentAttributedStringWithChatModel:(PLVChatModel *)chatModel {
    id message = chatModel.message;
    if (!message ||
        ![message isKindOfClass:[PLVQuoteMessage class]]) {
        return nil;
    }
    
    PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)message;
    NSString *content = quoteMessage.content;
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[UIColor whiteColor]
    };
    NSMutableAttributedString *emotionAttrStr = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:content attributes:attributeDict];
    return [emotionAttrStr copy];
}

/// 获取被引用的消息的多属性文本，格式为 “昵称：文本”
+ (NSAttributedString *)quoteContentAttributedStringWithMessage:(PLVQuoteMessage *)message {
    NSString *quoteUserName = message.quoteUserName ?: @"";
    NSString *content = [NSString stringWithFormat:@"%@：%@", quoteUserName, (message.quoteContent ?: @"")];
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[UIColor colorWithWhite:1 alpha:0.8]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取被引用图片URL
+ (NSURL *)quoteImageURLWithMessage:(PLVQuoteMessage *)message {
    NSString *imageUrl = message.quoteImageUrl;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}

/// 计算被引用消息图片尺寸
+ (CGSize)calculateImageViewSizeWithMessage:(PLVQuoteMessage *)message {
    CGSize quoteImageSize = message.quoteImageSize;
    CGFloat maxLength = 60.0;
    if (quoteImageSize.width == 0 || quoteImageSize.height == 0) {
        return CGSizeMake(maxLength, maxLength);
    }
    
    if (quoteImageSize.width < quoteImageSize.height) { // 竖图
        CGFloat height = maxLength;
        CGFloat width = maxLength * quoteImageSize.width / quoteImageSize.height;
        return CGSizeMake(width, height);
    } else if (quoteImageSize.width > quoteImageSize.height) { // 横图
        CGFloat width = maxLength;
        CGFloat height = maxLength * quoteImageSize.height / quoteImageSize.width;
        return CGSizeMake(width, height);
    } else {
        return CGSizeMake(maxLength, maxLength);
    }
}

/// 设置完数据模型之后，找到textView、quoteContentLabel、quoteImageView的最大宽度
- (CGFloat)actualMaxContentWidth {
    CGFloat chatLabelWidth = self.chatLabel.frame.size.width;
    CGFloat quoteContentWidth = 0;
    if (!self.quoteContentLabel.hidden) {
        quoteContentWidth = self.quoteContentLabel.frame.size.width;
    }
    CGFloat quoteImageWidth = 0;
    if (!self.quoteImageView.hidden) {
        quoteImageWidth = self.quoteImageView.frame.size.width;
    }
    
    return MAX(chatLabelWidth, MAX(quoteContentWidth, quoteImageWidth));
}

#pragma mark Getter

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    }
    return _line;
}

- (UILabel *)quoteContentLabel {
    if (!_quoteContentLabel) {
        _quoteContentLabel = [[UILabel alloc] init];
        _quoteContentLabel.numberOfLines = 2;
    }
    return _quoteContentLabel;
}

- (UIImageView *)quoteImageView {
    if (!_quoteImageView) {
        _quoteImageView = [[UIImageView alloc] init];
        _quoteImageView.userInteractionEnabled = YES;
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(quoteImageViewTapAction)];
        [_quoteImageView addGestureRecognizer:tapGesture];
    }
    return _quoteImageView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)quoteImageViewTapAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.quoteImageView];
}

@end
