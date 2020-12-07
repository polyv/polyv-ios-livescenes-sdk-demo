//
//  PLVLCQuoteMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCQuoteMessageCell.h"
#import "PLVLCChatTextView.h"
#import "PLVPhotoBrowser.h"
#import "PLVEmoticonManager.h"
#import <PLVLiveScenesSDK/PLVQuoteMessage.h>
#import <PolyvFoundationSDK/PLVColorUtil.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLCQuoteMessageCell ()

@property (nonatomic, strong) UILabel *quoteNickLabel; /// 被引用的用户昵称
@property (nonatomic, strong) UILabel *quoteContentLabel; /// 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; /// 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) UIView *line; /// 引用消息与回复消息分割线
@property (nonatomic, strong) PLVLCChatTextView *textView; /// 回复消息文本
@property (nonatomic, strong) UIView *bubbleView; /// 聊天气泡

@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 聊天消息图片Browser

@end

@implementation PLVLCQuoteMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.quoteNickLabel];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.quoteImageView];
        [self.contentView addSubview:self.line];
        [self.contentView addSubview:self.textView];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = self.nickLabel.frame.origin.x;
    CGFloat originY =  self.nickLabel.frame.origin.y + 20;
    
    CGFloat xPadding = 16.0; // 头像左间距，气泡右间距
    CGFloat bubbleXPadding = 12;//textView等气泡内控件与bubble的内部左右间距均为12
    CGFloat maxContentWidth = self.cellWidth - originX - xPadding - bubbleXPadding * 2;
    
    originX += bubbleXPadding;
    originY += 8; //被引用消息的用户昵称文本与bubble的内部上间距为8
    NSAttributedString *quoteNickAttributeString = self.quoteNickLabel.attributedText;
    CGSize quoteNickSize = [quoteNickAttributeString boundingRectWithSize:CGSizeMake(maxContentWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    self.quoteNickLabel.frame = CGRectMake(originX, originY, quoteNickSize.width, 18);
    originY += 18 + 5; //被引用消息的用户昵称文本与被引用消息文本/图片的间距为5
    
    if (!self.quoteContentLabel.hidden) { // 被引用消息文本最多显示2行，故最大高度为44
        NSAttributedString *quoteContentLabelString = self.quoteContentLabel.attributedText;
        CGSize quoteContentLabelSize = [quoteContentLabelString boundingRectWithSize:CGSizeMake(maxContentWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        self.quoteContentLabel.frame = CGRectMake(originX, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
        originY += quoteContentLabelSize.height;
    }
    
    if (!self.quoteImageView.hidden) {
        CGSize quoteImageViewSize = [PLVLCQuoteMessageCell calculateImageViewSizeWithMessage:self.model.message];
        self.quoteImageView.frame = CGRectMake(originX, originY, quoteImageViewSize.width, quoteImageViewSize.height);
        originY += quoteImageViewSize.height;
    }
    
    originY += bubbleXPadding;
    self.line.frame = CGRectMake(originX, originY, 0, 1); // 最后再设置分割线宽度
    
    originY += 1; // textView文本与textView的内部已有上下间距8，所以此处无需再增加间隔
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(originX, originY, textViewSize.width, textViewSize.height);
    
    originY += textViewSize.height;
    CGFloat bubbleOriginX = self.nickLabel.frame.origin.x;
    CGFloat bubbleOriginY =  self.nickLabel.frame.origin.y + 20;
    self.bubbleView.frame = CGRectMake(bubbleOriginX, bubbleOriginY, 0, originY - bubbleOriginY); // 最后再设置气泡宽度
    
    CGFloat contentWidth = [self actualMaxContentWidth];
    CGRect lineRect = self.line.frame;
    self.line.frame = CGRectMake(lineRect.origin.x, lineRect.origin.y, contentWidth, lineRect.size.height);
    
    CGRect bubbleRect = self.bubbleView.frame;
    self.bubbleView.frame = CGRectMake(bubbleRect.origin.x, bubbleRect.origin.y, contentWidth + bubbleXPadding * 2, bubbleRect.size.height);
    CAShapeLayer *maskLayer = [PLVLCMessageCell bubbleLayerWithSize:self.bubbleView.frame.size];
    self.bubbleView.layer.mask = maskLayer;
}

/// 设置完数据模型之后，找到quoteNickLabel、quoteContentLabel、quoteImageView与textView的最大宽度
- (CGFloat)actualMaxContentWidth {
    CGFloat quoteNickWidth = self.quoteNickLabel.frame.size.width;
    CGFloat quoteContentWidth = 0;
    if (!self.quoteContentLabel.hidden) {
        quoteContentWidth = self.quoteContentLabel.frame.size.width;
    }
    CGFloat quoteImageWidth = 0;
    if (!self.quoteImageView.hidden) {
        quoteImageWidth = self.quoteImageView.frame.size.width;
    }
    CGFloat textViewContentWidth = self.textView.frame.size.width;
    return MAX(quoteNickWidth, MAX(quoteContentWidth, MAX(quoteImageWidth, textViewContentWidth)));
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35"];
    }
    return _bubbleView;
}

- (UILabel *)quoteNickLabel {
    if (!_quoteNickLabel) {
        _quoteNickLabel = [[UILabel alloc] init];
    }
    return _quoteNickLabel;
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
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageViewAction)];
        [_quoteImageView addGestureRecognizer:tapGesture];
    }
    return _quoteImageView;
}

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [UIColor colorWithWhite:0 alpha:0.18];
    }
    return _line;
}

- (PLVLCChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVLCChatTextView alloc] init];
    }
    return _textView;
}

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model loginUserId:loginUserId cellWidth:cellWidth];
    
    if (self.cellWidth == 0 || ![PLVLCQuoteMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    
    PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
    
    NSAttributedString *quoteNickLabelString = [PLVLCQuoteMessageCell quoteNickAttributedStringWithMessage:message
                                                                                               loginUserId:self.loginUserId];
    if (quoteNickLabelString) {
        self.quoteNickLabel.attributedText = quoteNickLabelString;
    }
    
    NSAttributedString *quoteContentLabelString = [PLVLCQuoteMessageCell quoteContentAttributedStringWithMessage:message];
    self.quoteContentLabel.hidden = !quoteContentLabelString;
    if (quoteContentLabelString) {
        self.quoteContentLabel.attributedText = quoteContentLabelString;
    }
    
    NSURL *quoteImageURL = [PLVLCQuoteMessageCell quoteImageURLWithMessage:message];
    self.quoteImageView.hidden = !quoteImageURL;
    if (quoteImageURL) {
        UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
        [self.quoteImageView sd_setImageWithURL:quoteImageURL
                               placeholderImage:placeHolderImage
                                        options:SDWebImageRetryFailed];
    }
    
    NSMutableAttributedString *contentLabelString = [PLVLCQuoteMessageCell contentAttributedStringWithMessage:message];
    if (contentLabelString) {
        [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    }
}

#pragma mark UI - ViewModel

/// 获取被引用的消息用户昵称的多属性文本
+ (NSAttributedString *)quoteNickAttributedStringWithMessage:(PLVQuoteMessage *)message loginUserId:(NSString *)loginUserId {
    NSString *quoteUserName = message.quoteUserName;
    if (!quoteUserName || ![quoteUserName isKindOfClass:[NSString class]] || quoteUserName.length == 0) {
        return nil;
    }
    
    NSString *content = quoteUserName;
    NSString *quoteUserId = message.quoteUserId;
    if (quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isEqualToString:quoteUserId]) {
        content = [content stringByAppendingString:@"（我）"];
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#777786"]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取被引用的消息的多属性文本
+ (NSAttributedString *)quoteContentAttributedStringWithMessage:(PLVQuoteMessage *)message {
    NSString *content = message.quoteContent;
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#777786"]
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:attributedString font:[UIFont systemFontOfSize:16.0]];
    return [emojiAttributedString copy];
}

/// 获取图片URL
+ (NSURL *)quoteImageURLWithMessage:(PLVQuoteMessage *)message {
    NSString *imageUrl = message.quoteImageUrl;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}

/// 获取回复消息的多属性文本
+ (NSMutableAttributedString *)contentAttributedStringWithMessage:(PLVQuoteMessage *)message {
    NSString *content = message.content;
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#78A7ED"]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:string font:[UIFont systemFontOfSize:16.0]];
    return emojiAttributedString;
}

#pragma mark - 高度、宽度、尺寸计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    CGFloat cellHeight = [super cellHeightWithModel:model cellWidth:cellWidth];
    if (cellHeight == 0 || ![PLVLCQuoteMessageCell isModelValid:model]) {
        return 0;
    }
    
    CGFloat originX = 64.0; // 64 为气泡初始x值
    CGFloat originY = 28.0; // 64 为气泡初始y值
    CGFloat xPadding = 16.0; // 头像左间距，气泡右间距
    CGFloat bubbleXPadding = 12;//textView与bubble的内部左右间距均为12
    CGFloat maxTextViewWidth = cellWidth - originX - xPadding - bubbleXPadding * 2;
    
    CGFloat quoteNickHeight = 18; // quoteNickHeight为被引用消息用户昵称文本高度
    
    CGFloat quoteContentHeight = 0; // quoteContentHeight为被引用消息文本或图片高度
    NSAttributedString *quoteContentLabelString = [PLVLCQuoteMessageCell quoteContentAttributedStringWithMessage:model.message];
    NSURL *quoteImageURL = [PLVLCQuoteMessageCell quoteImageURLWithMessage:model.message];
    if (quoteContentLabelString) {
        CGSize quoteContentSize = [quoteContentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        quoteContentHeight = quoteContentSize.height;
    } else if (quoteImageURL) {
        CGSize quoteImageViewSize = [PLVLCQuoteMessageCell calculateImageViewSizeWithMessage:model.message];
        quoteContentHeight = quoteImageViewSize.height;
    }
    
    NSMutableAttributedString *contentLabelString = [PLVLCQuoteMessageCell contentAttributedStringWithMessage:model.message];
    CGSize contentLabelSize = [[contentLabelString copy] boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat textViewHeight = 8 + contentLabelSize.height + 8; // textView文本与textView的内部有上下间距8
    
    // 16为气泡底部外间距
    return originY + bubbleXPadding + quoteNickHeight + 5 + quoteContentHeight + bubbleXPadding + textViewHeight + 16;
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

#pragma mark - Action

- (void)tapImageViewAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.quoteImageView];
}

#pragma mark - Utils

/// 判断model是否为有效类型
+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVQuoteMessage class]]) {
        return NO;
    }
    
    return YES;
}

@end
