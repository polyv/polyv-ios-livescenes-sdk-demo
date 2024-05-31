//
//  PLVLCLandscapeQuoteCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLandscapeQuoteCell.h"
#import "PLVChatTextView.h"
#import "PLVPhotoBrowser.h"
#import "PLVEmoticonManager.h"
#import "PLVLCUtils.h"
#import "PLVLiveToast.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCLandscapeQuoteCell ()

#pragma mark UI

@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *line; /// 引用消息与回复消息分割线
@property (nonatomic, strong) UILabel *quoteContentLabel; /// 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; /// 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser

@end

@implementation PLVLCLandscapeQuoteCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowCopy = YES;
        self.allowReply = YES;
        
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.line];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.quoteImageView];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 12.0;
    CGFloat originY = -4.0;
    CGFloat bubbleXPadding = 12.0; // 气泡与textView的左右内间距
    
    CGFloat maxContentWidth = self.cellWidth - bubbleXPadding * 2;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(originX, originY, textViewSize.width, textViewSize.height);
    originY += textViewSize.height - 4;
    
    self.line.frame = CGRectMake(originX, originY, 0, 1); // 最后再设置分割线宽度
    originY += 1 + 4;
    
    // 被引用消息文本最多显示2行，故最大高度为44
    NSAttributedString *quoteContentLabelString = self.quoteContentLabel.attributedText;
    CGSize quoteContentLabelSize = [quoteContentLabelString boundingRectWithSize:CGSizeMake(maxContentWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    self.quoteContentLabel.frame = CGRectMake(originX, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
    originY += quoteContentLabelSize.height + 4;
    
    if (!self.quoteImageView.hidden) {
        CGSize quoteImageViewSize = [PLVLCLandscapeQuoteCell calculateImageViewSizeWithMessage:self.model.message];
        self.quoteImageView.frame = CGRectMake(originX, originY, quoteImageViewSize.width, quoteImageViewSize.height);
        originY += quoteImageViewSize.height + 4;
    }
    
    self.bubbleView.frame = CGRectMake(0, 0, 0, originY); // 最后再设置气泡宽度
    
    CGFloat contentWidth = [self actualMaxContentWidth];
    CGRect lineRect = self.line.frame;
    self.line.frame = CGRectMake(lineRect.origin.x, lineRect.origin.y, contentWidth, lineRect.size.height);
    
    CGRect bubbleRect = self.bubbleView.frame;
    self.bubbleView.frame = CGRectMake(bubbleRect.origin.x, bubbleRect.origin.y, contentWidth + bubbleXPadding * 2, bubbleRect.size.height);
}

/// 设置完数据模型之后，找到textView、quoteContentLabel、quoteImageView的最大宽度
- (CGFloat)actualMaxContentWidth {
    CGFloat textViewContentWidth = self.textView.frame.size.width;
    CGFloat quoteContentWidth = 0;
    if (!self.quoteContentLabel.hidden) {
        quoteContentWidth = self.quoteContentLabel.frame.size.width;
    }
    CGFloat quoteImageWidth = 0;
    if (!self.quoteImageView.hidden) {
        quoteImageWidth = self.quoteImageView.frame.size.width;
    }
    
    return MAX(textViewContentWidth, MAX(quoteContentWidth, quoteImageWidth));
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeQuoteCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    
    PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
    NSMutableAttributedString *contentLabelString;
    if (model.landscapeAttributeString) {
        // 如果在 model 中已经存在计算好的 横屏 消息多属性文本 ，那么 就直接使用；
        contentLabelString = model.landscapeAttributeString;
    } else {
        contentLabelString = [PLVLCLandscapeQuoteCell contentLabelAttributedStringWithMessage:message user:model.user];
        model.landscapeAttributeString = contentLabelString;
    }
    
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    
    NSAttributedString *quoteLabelString = [PLVLCLandscapeQuoteCell quoteContentAttributedStringWithMessage:message
                                                                                                loginUserId:loginUserId];
    self.quoteContentLabel.attributedText = quoteLabelString;
    
    NSURL *quoteImageURL = [PLVLCLandscapeQuoteCell quoteImageURLWithMessage:message];
    self.quoteImageView.hidden = !quoteImageURL;
    if (quoteImageURL) {
        UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
        [PLVLCUtils setImageView:self.quoteImageView url:quoteImageURL placeholderImage:placeHolderImage options:SDWebImageRetryFailed];
    }
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeQuoteCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2;
    
    PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
    NSMutableAttributedString *contentLabelString;
    if (model.landscapeAttributeString) {
        // 如果在 model 中已经存在计算好的 横屏 消息多属性文本 ，那么 就直接使用；
        contentLabelString = model.landscapeAttributeString;
    } else {
        contentLabelString = [PLVLCLandscapeQuoteCell contentLabelAttributedStringWithMessage:message user:model.user];
        model.landscapeAttributeString = contentLabelString;
    }
    
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    NSAttributedString *quoteLabelString = [PLVLCLandscapeQuoteCell quoteContentAttributedStringWithMessage:message loginUserId:loginUserId];
    CGSize quoteContentSize = [quoteLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat quoteContentHeight = quoteContentSize.height;
    
    CGFloat quoteImageHeight = 0;
    NSURL *quoteImageURL = [PLVLCLandscapeQuoteCell quoteImageURLWithMessage:model.message];
    if (quoteImageURL) {
        CGSize quoteImageViewSize = [PLVLCLandscapeQuoteCell calculateImageViewSizeWithMessage:model.message];
        quoteImageHeight = quoteImageViewSize.height;
    }
    
    return 4 + contentLabelSize.height + 4 + 1 + 4 + quoteContentHeight + (quoteImageURL ? 4 + quoteImageHeight : 0) + 4 + 5; // 气泡底部外间距为5
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (message &&
        [message isKindOfClass:[PLVQuoteMessage class]]) {
        return model.contentLength == PLVChatMsgContentLength_0To500;
    } else {
        return NO;
    }
}

#pragma mark - [ Private Methods ]

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVQuoteMessage *)message
                                                                  user:(PLVChatUser *)user {
    UIFont *font = [UIFont systemFontOfSize:14.0];
    NSString *nickNameColorHexString = [user isUserSpecial] ? @"#FFD36D" : @"#6DA7FF";
    UIColor *nickNameColor = [PLVColorUtil colorFromHexString:nickNameColorHexString];
    UIColor *contentColor = [UIColor whiteColor];
    
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: nickNameColor};
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:contentColor};
    
    NSString *content = [NSString stringWithFormat:@"%@：", user.userName];
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, content];
    }
    
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:message.content attributes:contentAttDict];
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:[UIFont systemFontOfSize:22.0]];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    return contentLabelString;
}

/// 获取被引用的消息的多属性文本，格式为 “昵称：文本”
+ (NSAttributedString *)quoteContentAttributedStringWithMessage:(PLVQuoteMessage *)message
                                                    loginUserId:(NSString *)loginUserId {
    NSString *quoteUserName = message.quoteUserName ?: @"";
    NSString *quoteUserId = message.quoteUserId;
    if (quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:quoteUserId]) {
        quoteUserName = [quoteUserName stringByAppendingString:PLVLocalizedString(@"（我）")];
    }
    
    NSString *content = [NSString stringWithFormat:@"%@：%@", quoteUserName, (message.quoteContent ?: @"")];
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#999999"]
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

#pragma mark Getter

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
    }
    return _textView;
}

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [UIColor colorWithWhite:0 alpha:0.12];
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
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageViewAction)];
        [_quoteImageView addGestureRecognizer:tapGesture];
    }
    return _quoteImageView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)customCopy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    PLVQuoteMessage *message = self.model.message;
    pasteboard.string = message.content;
    [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.superview.superview.superview afterDelay:3.0];
}

- (void)tapImageViewAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.quoteImageView];
}

@end
