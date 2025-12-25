//
//  PLVLCQuoteMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCQuoteMessageCell.h"
#import "PLVChatTextView.h"
#import "PLVPhotoBrowser.h"
#import "PLVEmoticonManager.h"
#import "PLVLCUtils.h"
#import "PLVLiveToast.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVQuoteMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <PLVFoundationSDK/PLVImageUtil.h>

@interface PLVLCQuoteMessageCell ()

@property (nonatomic, strong) UIView *blueVerticalLine; /// 被引用消息为自己消息时的蓝色竖线
@property (nonatomic, strong) UILabel *quoteContentLabel; /// 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; /// 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) UIView *line; /// 引用消息与回复消息分割线
@property (nonatomic, strong) PLVChatTextView *textView; /// 回复消息文本
@property (nonatomic, strong) UIView *bubbleView; /// 聊天气泡

@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 聊天消息图片Browser

@end

@implementation PLVLCQuoteMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowCopy = YES;
        self.allowReply = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.blueVerticalLine];
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
    
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 头像左间距，气泡右间距
    CGFloat bubbleXPadding = 12;//textView等气泡内控件与bubble的内部左右间距均为12
    CGFloat maxContentWidth = self.cellWidth - originX - xPadding - bubbleXPadding * 2;
    
    originX += bubbleXPadding;
    originY += 8; // 被引用消息与bubble的内部上间距为8
    
    CGSize quoteContentLabelSize = [self.quoteContentLabel sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
    self.quoteContentLabel.frame = CGRectMake(originX, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
    
    [self layoutBlueVerticalLineWithOriginX:originX];
    
    originY += ceil(quoteContentLabelSize.height) + 4;
    
    if (!self.quoteImageView.hidden) { //  被引用消息图片
        CGSize quoteImageViewSize = [PLVLCQuoteMessageCell calculateImageViewSizeWithMessage:self.model.message];
        self.quoteImageView.frame = CGRectMake(originX, originY, quoteImageViewSize.width, quoteImageViewSize.height);
        originY += quoteImageViewSize.height + 4;
    }
    
    originY += bubbleXPadding - 4;
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

- (CGFloat)actualMaxContentWidth {
    CGFloat quoteContentWidth = 0;
    if (!self.quoteContentLabel.hidden) {
        quoteContentWidth = self.quoteContentLabel.frame.size.width;
    }
    CGFloat quoteImageWidth = 0;
    if (!self.quoteImageView.hidden) {
        quoteImageWidth = self.quoteImageView.frame.size.width;
    }
    CGFloat textViewContentWidth = self.textView.frame.size.width;
    return MAX(quoteContentWidth, MAX(quoteImageWidth, textViewContentWidth));
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35"];
    }
    return _bubbleView;
}

- (UIView *)blueVerticalLine {
    if (!_blueVerticalLine) {
        _blueVerticalLine = [[UIView alloc] init];
        _blueVerticalLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#3F76FC"];
        _blueVerticalLine.layer.cornerRadius = 1.0;
        _blueVerticalLine.layer.masksToBounds = YES;
        _blueVerticalLine.hidden = YES;
    }
    return _blueVerticalLine;
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

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
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
    
    // 判断被引用消息是否为自己的消息
    NSString *quoteUserId = message.quoteUserId;
    BOOL isMyQuoteMessage = quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
                            self.loginUserId && [self.loginUserId isKindOfClass:[NSString class]] &&
                            [self.loginUserId isEqualToString:quoteUserId];
    
    NSAttributedString *quoteContentLabelString = [PLVLCQuoteMessageCell quoteContentAttributedStringWithMessage:message loginUserId:self.loginUserId isMyMessage:isMyQuoteMessage];
    self.quoteContentLabel.hidden = !quoteContentLabelString;
    if (quoteContentLabelString) {
        self.quoteContentLabel.attributedText = quoteContentLabelString;
    }
    
    NSURL *quoteImageURL = [PLVLCQuoteMessageCell quoteImageURLWithMessage:message];
    self.quoteImageView.hidden = !quoteImageURL;
    if (quoteImageURL) {
        UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
        
        [PLVLCUtils setImageView:self.quoteImageView url:quoteImageURL placeholderImage:placeHolderImage options:SDWebImageRetryFailed];
    }
    
    NSMutableAttributedString *contentLabelString;
    if (model.attributeString) { // 如果在 model 中已经存在计算好的 消息多属性文本 ，那么 就直接使用；
        contentLabelString = model.attributeString;
    } else {
        contentLabelString = [PLVLCQuoteMessageCell contentAttributedStringWithMessage:message];
        model.attributeString = contentLabelString;
    }
    
    if (contentLabelString) {
        [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    }
}

#pragma mark UI - Blue Line Layout

- (void)layoutBlueVerticalLineWithOriginX:(CGFloat)originX {
    PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)self.model.message;
    NSString *quoteUserId = quoteMessage.quoteUserId;
    NSString *loginUserId = self.loginUserId;
    BOOL isMyQuoteMessage = quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
                            loginUserId && [loginUserId isKindOfClass:[NSString class]] &&
                            [loginUserId isEqualToString:quoteUserId];
    
    if (!isMyQuoteMessage || self.quoteContentLabel.hidden) {
        self.blueVerticalLine.hidden = YES;
        return;
    }
    
    UIFont *font = [UIFont systemFontOfSize:12.0];
    CGFloat firstLineCenterY = CGRectGetMinY(self.quoteContentLabel.frame) + font.lineHeight / 2.0;
    CGFloat blueLineHeight = 10.0;
    CGFloat blueLineWidth = 2.0;
    CGFloat blueY = firstLineCenterY - blueLineHeight / 2.0;
    
    self.blueVerticalLine.frame = CGRectMake(originX, blueY, blueLineWidth, blueLineHeight);
    self.blueVerticalLine.hidden = NO;
}

#pragma mark UI - ViewModel

/// 获取被引用的消息的多属性文本，格式为 "昵称：文本"
+ (NSAttributedString *)quoteContentAttributedStringWithMessage:(PLVQuoteMessage *)message loginUserId:(NSString *)loginUserId isMyMessage:(BOOL)isMyMessage {
    NSString *quoteUserName = message.quoteUserName ?: @"";
    NSString *quoteUserId = message.quoteUserId;
    if (quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isEqualToString:quoteUserId]) {
        quoteUserName = [quoteUserName stringByAppendingString:PLVLocalizedString(@"（我）")];
    } else if ([PLVRoomDataManager sharedManager].roomData.menuInfo.hideViewerNicknameEnabled && [PLVFdUtil checkStringUseable:quoteUserName] && quoteUserName.length > 1) {
        
        NSString *firstChar = [quoteUserName substringToIndex:1];
        NSString *stars = [@"" stringByPaddingToLength:quoteUserName.length - 1 withString:@"*" startingAtIndex:0];
        quoteUserName = [firstChar stringByAppendingString:stars];
    }
    
    UIColor *nickNameColor;
    if (isMyMessage) {
        nickNameColor = [PLVColorUtil colorFromHexString:@"#3F76FC" alpha:0.6];
    } else {
        nickNameColor = [PLVColorUtil colorFromHexString:@"#777786"];
    }
    
    if (!isMyMessage && [PLVRoomDataManager sharedManager].roomData.menuInfo.hideViewerNicknameEnabled && [PLVFdUtil checkStringUseable:quoteUserName] && quoteUserName.length > 1) {
        NSString *firstChar = [quoteUserName substringToIndex:1];
        NSString *stars = [@"" stringByPaddingToLength:quoteUserName.length - 1 withString:@"*" startingAtIndex:0];
        quoteUserName = [firstChar stringByAppendingString:stars];
    }
    
    NSString *quoteContent = message.quoteContent ?: @"";
    NSString *content = [NSString stringWithFormat:@"%@：%@", quoteUserName, quoteContent];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:content];
    
    UIFont *font = [UIFont systemFontOfSize:12.0];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, content.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[PLVColorUtil colorFromHexString:@"#777786"] range:NSMakeRange(0, content.length)];
    
    NSString *nickNamePart = [NSString stringWithFormat:@"%@：", quoteUserName];
    if (content.length >= nickNamePart.length) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:nickNameColor range:NSMakeRange(0, nickNamePart.length)];
    }
    
    NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:[attributedString copy] font:[UIFont systemFontOfSize:12.0]];
    
    if (isMyMessage) {
        CGFloat blueLineWidth = 2.0;
        CGFloat spacing = 4.0;
        CGFloat indent = blueLineWidth + spacing;
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.firstLineHeadIndent = indent;
        paragraphStyle.headIndent = indent;
        [emojiAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, emojiAttributedString.length)];
    }
    
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

/// 生成回复消息的多属性文本
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
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:string font:[UIFont systemFontOfSize:22.0]];
    return emojiAttributedString;
}

#pragma mark - 高度、宽度、尺寸计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    CGFloat cellHeight = [super cellHeightWithModel:model cellWidth:cellWidth];
    if (cellHeight == 0 || ![PLVLCQuoteMessageCell isModelValid:model]) {
        return 0;
    }
    
    CGFloat originX = 64.0; // 64 为气泡初始x值
    CGFloat originY = 28.0; // 28 为气泡初始y值（bubbleOriginY）
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 头像左间距，气泡右间距
    CGFloat bubbleXPadding = 12;//textView与bubble的内部左右间距均为12
    CGFloat maxContentWidth = cellWidth - originX - xPadding - bubbleXPadding * 2;
    
    PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)model.message;
    NSString *quoteUserId = quoteMessage.quoteUserId;
    NSString *loginUserId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
    BOOL isMyQuoteMessage = quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
                            loginUserId && [loginUserId isKindOfClass:[NSString class]] &&
                            [loginUserId isEqualToString:quoteUserId];
    originY += 8;
    
    NSAttributedString *quoteContentLabelString = [PLVLCQuoteMessageCell quoteContentAttributedStringWithMessage:model.message loginUserId:loginUserId isMyMessage:isMyQuoteMessage];
    if (quoteContentLabelString) {
        UILabel *tempQuoteContentLabel = [[UILabel alloc] init];
        tempQuoteContentLabel.attributedText = quoteContentLabelString;
        tempQuoteContentLabel.numberOfLines = 0;
        CGSize quoteContentLabelSize = [tempQuoteContentLabel sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
        
        CGFloat quoteTextHeight = quoteContentLabelSize.height + 4; // 文本高度 + 间距
        originY += quoteTextHeight;
    }
    
    CGFloat quoteImageHeight = 0;
    NSURL *quoteImageURL = [PLVLCQuoteMessageCell quoteImageURLWithMessage:model.message];
    if (quoteImageURL) {
        CGSize quoteImageViewSize = [PLVLCQuoteMessageCell calculateImageViewSizeWithMessage:model.message];
        quoteImageHeight = quoteImageViewSize.height + 4; // 图片高度 + 间距
        originY += quoteImageHeight;
    }
    
    originY += bubbleXPadding - 4;
    
    originY += 1;
    

    NSMutableAttributedString *contentLabelString;
    if (model.attributeString) {
        contentLabelString = model.attributeString;
    } else {
        contentLabelString = [PLVLCQuoteMessageCell contentAttributedStringWithMessage:model.message];
        model.attributeString = contentLabelString;
    }

    PLVChatTextView *tempTextView = [[PLVChatTextView alloc] init];
    [tempTextView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    CGSize textViewSize = [tempTextView sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
    originY += textViewSize.height;
    
    CGFloat bubbleHeight = originY - 28.0;
    
    // 16为气泡底部外间距
    return 28.0 + bubbleHeight + 16;
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
    if (message &&
        [message isKindOfClass:[PLVQuoteMessage class]]) {
        return model.contentLength == PLVChatMsgContentLength_0To500;
    } else {
        return NO;
    }
}

#pragma mark - [ Override ]

- (void)customCopy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    PLVQuoteMessage *message = self.model.message;
    pasteboard.string = message.content;
    [PLVLiveToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.superview.superview afterDelay:3.0];
}

@end
