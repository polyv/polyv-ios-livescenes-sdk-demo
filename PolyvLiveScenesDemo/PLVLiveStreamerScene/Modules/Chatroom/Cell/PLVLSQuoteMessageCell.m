//
//  PLVLSQuoteMessageCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/18.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSQuoteMessageCell.h"
#import "PLVChatModel.h"
#import "PLVChatTextView.h"
#import "PLVPhotoBrowser.h"
#import "PLVEmoticonManager.h"
#import "PLVLSUtils.h"
#import <PLVLiveScenesSDK/PLVQuoteMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLSQuoteMessageCell ()

#pragma mark 数据

@property (nonatomic, assign) CGFloat cellWidth; /// cell宽度
@property (nonatomic, strong) NSString *loginUserId; /// 登录用户的聊天室userId

#pragma mark UI

@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *line; /// 引用消息与回复消息分割线
@property (nonatomic, strong) UILabel *quoteContentLabel; /// 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; /// 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser
@property (nonatomic, strong) UIView *prohibitLineView;      /// 严禁词分割线
@property (nonatomic, strong) UILabel *prohibitWordTipLabel; /// 严禁词提示

@end

@implementation PLVLSQuoteMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = self.allowCopy = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.line];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.quoteImageView];
        [self.contentView addSubview:self.prohibitWordTipLabel];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 12.0;
    CGFloat originY = 4.0;
    CGFloat bubbleXPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat maxContentWidth = self.cellWidth - bubbleXPadding * 2;
    
    NSAttributedString *quoteContentLabelString = self.quoteContentLabel.attributedText;
    CGSize quoteContentLabelSize = [quoteContentLabelString boundingRectWithSize:CGSizeMake(maxContentWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    self.quoteContentLabel.frame = CGRectMake(originX, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
    originY += quoteContentLabelSize.height + 4;
    
    if (!self.quoteImageView.hidden) {
        CGSize quoteImageViewSize = [PLVLSQuoteMessageCell calculateImageViewSizeWithMessage:self.model.message];
        self.quoteImageView.frame = CGRectMake(originX, originY, quoteImageViewSize.width, quoteImageViewSize.height);
        originY += quoteImageViewSize.height + 4;
    }
    
    self.line.frame = CGRectMake(originX, originY, 0, 1); // 最后再设置分割线宽度
    originY += 1 + 4 - 8;
    
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(originX, originY, textViewSize.width, textViewSize.height);
    originY += textViewSize.height - 4;
    
    self.bubbleView.frame = CGRectMake(0, 0, 0, originY); // 最后再设置气泡宽度
    // 严禁词
    if ([self.model isProhibitMsg]) {
        self.prohibitLineView.frame = CGRectMake(originX, CGRectGetMaxY(self.textView.frame), textViewSize.width, 1);
        CGSize labelViewSize = [self.prohibitWordTipLabel sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
        self.prohibitWordTipLabel.frame = CGRectMake(originX, CGRectGetMaxY(self.prohibitLineView.frame) + 4,  labelViewSize.width, labelViewSize.height);
        self.bubbleView.frame = CGRectMake(0, 0, 0, self.bubbleView.frame.size.height + ceilf(labelViewSize.height) + 1 + 4 +4 +4);
    }
    
    CGFloat contentWidth = [self actualMaxContentWidth];
    CGRect lineRect = self.line.frame;
    self.line.frame = CGRectMake(lineRect.origin.x, lineRect.origin.y, contentWidth, lineRect.size.height);
    
    CGRect bubbleRect = self.bubbleView.frame;
    self.bubbleView.frame = CGRectMake(bubbleRect.origin.x, bubbleRect.origin.y, contentWidth + bubbleXPadding * 2, bubbleRect.size.height);
}

/// 设置完数据模型之后，找到textView、quoteContentLabel、quoteImageView、prohibitWordTipLabel的最大宽度
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
    CGFloat prohibitTipWidth = 0;
    if (!self.prohibitWordTipLabel.hidden) {
        prohibitTipWidth = self.prohibitWordTipLabel.frame.size.width;
    }
    
    return MAX(MAX(textViewContentWidth, prohibitTipWidth) , MAX(quoteContentWidth, quoteImageWidth));
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.4];
        _bubbleView.layer.cornerRadius = 8.0;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
    }
    return _textView;
}

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.12];
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
        _quoteImageView.layer.cornerRadius = 4.0;
        _quoteImageView.layer.masksToBounds = YES;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageViewAction)];
        [_quoteImageView addGestureRecognizer:tapGesture];
    }
    return _quoteImageView;
}

- (UIView *)prohibitLineView {
    if (!_prohibitLineView) {
        _prohibitLineView = [[UIView alloc] init];
        _prohibitLineView.hidden = YES;
        _prohibitLineView.backgroundColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.2];
    }
    return  _prohibitLineView;
}

- (UILabel *)prohibitWordTipLabel {
    if(!_prohibitWordTipLabel) {
        _prohibitWordTipLabel = [[UILabel alloc] init];
        _prohibitWordTipLabel.font = [UIFont systemFontOfSize:12];
        _prohibitWordTipLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.6];
        _prohibitWordTipLabel.hidden = YES;
    }
    return _prohibitWordTipLabel;
}
#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLSQuoteMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLSQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    
    NSAttributedString *quoteLabelString = [PLVLSQuoteMessageCell quoteContentAttributedStringWithMessage:message
                                                                                                loginUserId:self.loginUserId];
    self.quoteContentLabel.attributedText = quoteLabelString;
    
    NSURL *quoteImageURL = [PLVLSQuoteMessageCell quoteImageURLWithMessage:message];
    self.quoteImageView.hidden = !quoteImageURL;
    if (quoteImageURL) {
        UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
        [self.quoteImageView sd_setImageWithURL:quoteImageURL
                               placeholderImage:placeHolderImage
                                        options:SDWebImageRetryFailed];
    }
    
    // 严禁词提示
    if ([model isProhibitMsg]) {
        self.prohibitLineView.hidden = NO;
        self.prohibitWordTipLabel.hidden = NO;
        
        self.prohibitWordTipLabel.text = [PLVLSQuoteMessageCell prohibitWordTipWithModel:model];
    }else{
        self.prohibitLineView.hidden = YES;
        self.prohibitWordTipLabel.hidden = YES;
        
        self.prohibitWordTipLabel.text = @"";
    }
    
    __weak typeof(self) weakSelf = self;
    [self.textView setReplyHandler:^{
        if (weakSelf.replyHandler) {
            weakSelf.replyHandler(model);
        }
    }];
}

#pragma mark UI - ViewModel

/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVQuoteMessage *)message
                                                                  user:(PLVChatUser *)user
                                                          prohibitWord:(NSString *)prohibitWord{
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSString *nickNameColorHexString = [user isUserSpecial] ? @"#FFCA43" : @"#4399FF";
    UIColor *nickNameColor = [PLVColorUtil colorFromHexString:nickNameColorHexString];
    UIColor *contentColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 17;
    
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: nickNameColor,
                                      NSParagraphStyleAttributeName:paragraph
    };
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:contentColor,
                                     NSParagraphStyleAttributeName:paragraph
    };
    
    NSString *content = [NSString stringWithFormat:@"%@：", user.userName];
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, content];
    }
    
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:message.content attributes:contentAttDict];
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    
    // 含有严禁内容,添加提示图片
    if (prohibitWord && prohibitWord.length >0) {
        CGFloat paddingTop = font.lineHeight - font.pointSize;
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.bounds = CGRectMake(0, -ceilf(paddingTop), font.lineHeight, font.lineHeight);
        attachment.image = [PLVLSUtils imageForStatusResource:@"plvls_status_signal_error_icon"];
        // 设置文字与图片间隔
        [contentLabelString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        NSAttributedString *attachAttri = [NSAttributedString attributedStringWithAttachment:attachment];
        [contentLabelString appendAttributedString:attachAttri];
    }
    return contentLabelString;
}

/// 获取被引用的消息的多属性文本，格式为 “昵称：文本”
+ (NSAttributedString *)quoteContentAttributedStringWithMessage:(PLVQuoteMessage *)message
                                                    loginUserId:(NSString *)loginUserId {
    NSString *quoteUserName = message.quoteUserName ?: @"";
    NSString *quoteUserId = message.quoteUserId;
    if (quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:quoteUserId]) {
        quoteUserName = [quoteUserName stringByAppendingString:@"（我）"];
    }
    
    NSString *content = [NSString stringWithFormat:@"%@：%@", quoteUserName, (message.quoteContent ?: @"")];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 17;
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#CFD1D6"],
                                    NSParagraphStyleAttributeName:paragraph
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取严禁词提示多属性文本
+ (NSAttributedString *)contentLabelAttributedStringWithProhibitWordTip:(NSString *)prohibitTipString{
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *color = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.6];
    
    NSDictionary *AttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: color};
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:prohibitTipString attributes:AttDict];
    
    return attributed;
}

/// 获取被引用图片URL
+ (NSURL *)quoteImageURLWithMessage:(PLVQuoteMessage *)message {
    NSString *imageUrl = message.quoteImageUrl;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}

#pragma mark - 高度、尺寸计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLSQuoteMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2;
    
    PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLSQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    NSAttributedString *quoteLabelString = [PLVLSQuoteMessageCell quoteContentAttributedStringWithMessage:message loginUserId:loginUserId];
    CGSize quoteContentSize = [quoteLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat quoteContentHeight = quoteContentSize.height;
    
    CGFloat quoteImageHeight = 0;
    NSURL *quoteImageURL = [PLVLSQuoteMessageCell quoteImageURLWithMessage:model.message];
    if (quoteImageURL) {
        CGSize quoteImageViewSize = [PLVLSQuoteMessageCell calculateImageViewSizeWithMessage:model.message];
        quoteImageHeight = quoteImageViewSize.height;
    }
    
    // 严禁词高度
    if ([model isProhibitMsg]) {
        NSAttributedString *attri = [PLVLSQuoteMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSQuoteMessageCell prohibitWordTipWithModel:model]];
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        CGFloat lineViewHeight = 4 + 1 + 4;
        contentLabelSize.height += lineViewHeight + tipSize.height + 4;
    }
    
    return 4 + quoteContentHeight + (quoteImageURL ? 4 + quoteImageHeight : 0) + 4 + 1 + 4 + contentLabelSize.height + 4 + 4; // 气泡底部外间距为4
}

/// 计算被引用消息图片尺寸
+ (CGSize)calculateImageViewSizeWithMessage:(PLVQuoteMessage *)message {
    CGSize quoteImageSize = message.quoteImageSize;
    CGFloat maxLength = 40.0;
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

- (void)customCopy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    PLVQuoteMessage *message = self.model.message;
    pasteboard.string = message.content;
}

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

+ (NSString *)prohibitWordTipWithModel:(PLVChatModel *)model {
    return [NSString stringWithFormat:@"你的聊天信息中含有违规词：%@", model.prohibitWord];
}
@end
