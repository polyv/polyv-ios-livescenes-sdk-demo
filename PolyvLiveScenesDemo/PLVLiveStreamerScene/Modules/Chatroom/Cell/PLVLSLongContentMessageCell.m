//
//  PLVLSLongContentMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/21.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSLongContentMessageCell.h"
#import "PLVChatTextView.h"
#import "PLVLSProhibitWordTipView.h"
#import "PLVEmoticonManager.h"
#import "PLVPhotoBrowser.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kMaxFoldedContentHeight = 91.0;
static CGFloat kButtonoHeight = 34.0;

@interface PLVLSLongContentMessageCell ()

#pragma mark 数据
@property (nonatomic, assign) CGFloat cellWidth; /// cell宽度
@property (nonatomic, strong) NSString *loginUserId; /// 登录用户的聊天室userId

#pragma mark UI
@property (nonatomic, strong) UIView *quoteLine; /// 引用消息与回复消息分割线
@property (nonatomic, strong) UILabel *quoteContentLabel; /// 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; /// 被引用的消息图片（如果为文本消息，imageView不可见
@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡
@property (nonatomic, strong) UIView *contentSepLine; /// 文本和按钮之间的分隔线
@property (nonatomic, strong) UIView *buttonSepLine; /// 两个按钮中间的分隔线
@property (nonatomic, strong) UIButton *copButton;
@property (nonatomic, strong) UIButton *foldButton;
@property (nonatomic, strong) UIButton *prohibitWordTipButton; // 严禁词提示按钮
@property (nonatomic, strong) PLVLSProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser

@end

@implementation PLVLSLongContentMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.contentSepLine];
        [self.contentView addSubview:self.buttonSepLine];
        [self.contentView addSubview:self.copButton];
        [self.contentView addSubview:self.foldButton];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.quoteImageView];
        [self.contentView addSubview:self.quoteLine];
        [self.contentView addSubview:self.prohibitWordTipButton];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originY = 4.0;
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat yPadding = -4.0; // 气泡与textView的上下内间距
    
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2;
    
    CGFloat quoteHeight = 0;
    if ([self.model.message isKindOfClass:[PLVQuoteMessage class]]) {
        CGSize quoteContentLabelSize = [self.quoteContentLabel.attributedText boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        self.quoteContentLabel.frame = CGRectMake(xPadding, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
        originY += quoteContentLabelSize.height + 4;
        
        if (!self.quoteImageView.hidden) {
            CGSize quoteImageViewSize = [PLVLSLongContentMessageCell calculateImageViewSizeWithMessage:self.model.message];
            self.quoteImageView.frame = CGRectMake(xPadding, originY, quoteImageViewSize.width, quoteImageViewSize.height);
            originY += quoteImageViewSize.height + 4;
        }
        
        self.quoteLine.frame = CGRectMake(8, originY, 0, 1); // 最后再设置分割线宽度
        
        quoteHeight = CGRectGetMinY(self.quoteLine.frame) - CGRectGetMinY(self.quoteContentLabel.frame) + 4;
        originY += 1;
    }
    
    originY += yPadding;
    if (self.model.isProhibitMsg) {
        maxTextViewWidth = maxTextViewWidth - 6 - 16;
    }
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    CGSize contentLabelSize = [self.textView.attributedText boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat contentHeight = MIN(contentLabelSize.height, kMaxFoldedContentHeight);
    CGFloat textViewHeight = 8 + contentHeight + 8; // textView文本与textView的内部有上下间距8
    self.textView.frame = CGRectMake(xPadding, originY, textViewSize.width, textViewHeight);
    
    CGFloat bubbleWidth = ceilf(textViewSize.width + xPadding * 2);
    CGFloat bubbleHeight = ceil(textViewHeight) + yPadding * 2 + kButtonoHeight + quoteHeight;
    if (self.model.isProhibitMsg) {
        bubbleWidth += 6 + 16;
    }
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, bubbleHeight);
    self.bubbleView.layer.cornerRadius = 8.0;
    
    // 横的分割线跟气泡左右间隔8pt
    self.contentSepLine.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) + 8, CGRectGetMaxY(self.bubbleView.frame) - kButtonoHeight - 1, bubbleWidth - 8 * 2, 1);
    self.buttonSepLine.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) + bubbleWidth / 2.0 - 0.5, CGRectGetMaxY(self.contentSepLine.frame) + 10.5, 1, 15);
    
    CGSize buttonSize = CGSizeMake(CGRectGetWidth(self.bubbleView.frame)/ 2.0, kButtonoHeight);
    self.copButton.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame), CGRectGetMaxY(self.bubbleView.frame) - buttonSize.height, buttonSize.width, buttonSize.height);
    self.foldButton.frame = CGRectMake(CGRectGetMaxX(self.copButton.frame), CGRectGetMinY(self.copButton.frame), buttonSize.width, buttonSize.height);
    
    if (!self.quoteLine.hidden) {
        CGRect lineRect = self.quoteLine.frame;
        lineRect.origin.x = self.contentSepLine.frame.origin.x;
        lineRect.size.width = self.contentSepLine.frame.size.width;
        self.quoteLine.frame = lineRect;
    }
    
    self.prohibitWordTipButton.frame = CGRectMake(CGRectGetMaxX(self.textView.frame) + 6, (self.bubbleView.frame.size.height - 16 ) / 2, 16, 16);
    
    if ([self.model isProhibitMsg] &&
        !self.model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVLSLongContentMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSLongContentMessageCell prohibitWordTipWithModel:self.model]];
        CGSize maxSize = CGSizeMake(bubbleWidth, CGFLOAT_MAX);
        CGSize tipSize = [attri boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        tipSize.width = MIN(tipSize.width + 16, bubbleWidth); // 适配换行时
        self.prohibitWordTipView.frame = CGRectMake(bubbleWidth - tipSize.width, CGRectGetMaxY(self.bubbleView.frame), tipSize.width, tipSize.height + 20 + 8);
    } else {
        self.prohibitWordTipView.frame = CGRectZero;
    }
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLSLongContentMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLSLongContentMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:self.loginUserId isRemindMsg:model.isRemindMsg];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    
    if ([model.message isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)model.message;
        self.quoteLine.hidden = NO;
        
        NSAttributedString *quoteLabelString = [PLVLSLongContentMessageCell quoteContentAttributedStringWithMessage:quoteMessage loginUserId:self.loginUserId];
        self.quoteContentLabel.attributedText = quoteLabelString;
        self.quoteContentLabel.hidden = !quoteLabelString;
        
        NSURL *quoteImageURL = [PLVLSLongContentMessageCell quoteImageURLWithMessage:quoteMessage];
        self.quoteImageView.hidden = !quoteImageURL;
        if (quoteImageURL) {
            UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
            [PLVLSUtils setImageView:self.quoteImageView url:quoteImageURL placeholderImage:placeHolderImage options:SDWebImageRetryFailed];
        }
    } else {
        self.quoteContentLabel.hidden = YES;
        self.quoteImageView.hidden = YES;
        self.quoteLine.hidden = YES;
    }
    
    // 严禁词提示
    __weak typeof(self)weakSelf = self;
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
    
        self.prohibitWordTipView.hidden = NO;
        [self.prohibitWordTipView setTipType:PLVLSProhibitWordTipTypeText prohibitWord:model.prohibitWord];
        [self.prohibitWordTipView showWithSuperView:self.contentView];
        
        self.prohibitWordTipView.dismissBlock = ^{
            weakSelf.model.prohibitWordTipShowed = YES;
            if (weakSelf.prohibitWordDismissHandler) {
                weakSelf.prohibitWordDismissHandler();
            }
        };
    }else{
        self.prohibitWordTipView.hidden = YES;
    }
    self.prohibitWordTipButton.hidden = ![model isProhibitMsg];
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLSLongContentMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2;
    if (model.isProhibitMsg) {
        maxTextViewWidth = maxTextViewWidth - 6 - 16;
    }
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLSLongContentMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:loginUserId isRemindMsg:model.isRemindMsg];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat contentHeight = MIN(contentLabelSize.height, kMaxFoldedContentHeight);
    
    // 严禁词高度
    if (model.isProhibitMsg &&
        !model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVLSLongContentMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSLongContentMessageCell prohibitWordTipWithModel:model]];
        CGFloat maxWidth = xPadding * 2 + contentLabelSize.width + 6 + 16;
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        contentHeight += tipSize.height + 20 + 8 + 2;
    }
    
    CGFloat bubbleHeight = MAX(25, 4 + ceilf(contentHeight) + 4); // content文本与气泡的内部有上下间距4，气泡最小高度为25pt
    CGFloat cellHeight = bubbleHeight + kButtonoHeight + 4; // 气泡底部外间距为4
    
    if ([model.message isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)model.message;
        NSAttributedString *quoteLabelString = [PLVLSLongContentMessageCell quoteContentAttributedStringWithMessage:quoteMessage loginUserId:loginUserId];
        CGSize quoteContentSize = [quoteLabelString boundingRectWithSize:CGSizeMake(cellWidth - xPadding * 2, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        CGFloat quoteContentHeight = quoteContentSize.height;
        
        CGFloat quoteImageHeight = 0;
        NSURL *quoteImageURL = [PLVLSLongContentMessageCell quoteImageURLWithMessage:quoteMessage];
        if (quoteImageURL) {
            CGSize quoteImageViewSize = [PLVLSLongContentMessageCell calculateImageViewSizeWithMessage:quoteMessage];
            quoteImageHeight = quoteImageViewSize.height;
        }
        
        cellHeight += 4 + quoteContentHeight + (quoteImageURL ? 4 + quoteImageHeight : 0) + 4 + 1;
    }
    
    return cellHeight;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (message &&
        ([message isKindOfClass:[PLVSpeakMessage class]] || [message isKindOfClass:[PLVQuoteMessage class]])) {
        return model.contentLength > PLVChatMsgContentLength_0To500;
    }
    return NO;
}

#pragma mark - [ Private Method ]

/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVSpeakMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId
                                                           isRemindMsg:(BOOL)isRemindMsg {
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSString *nickNameColorHexString = [user isUserSpecial] ? @"#FFCA43" : @"#4399FF";
    UIColor *nickNameColor = [PLVColorUtil colorFromHexString:nickNameColorHexString];
    UIColor *contentColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: nickNameColor};
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:contentColor};
    
    NSString *content = user.userName;
    if (user.userId && [user.userId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:user.userId]) {
        content = [content stringByAppendingString:PLVLocalizedString(@"（我）")];
    }
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, content];
    }
    content = [content stringByAppendingString:@"："];
    
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:message.content attributes:contentAttDict];
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    
    // 提醒消息
    if (isRemindMsg) {
        UIImage *image = [PLVLSUtils imageForChatroomResource:PLVLocalizedString(@"plvls_chatroom_remind_tag")];
        //创建Image的富文本格式
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = font.lineHeight - font.pointSize;
        attach.bounds = CGRectMake(0, -ceilf(paddingTop), image.size.width, image.size.height);
        attach.image = image;
        //添加到富文本对象里
        NSAttributedString * imageStr = [NSAttributedString attributedStringWithAttachment:attach];
        [contentLabelString insertAttributedString:[[NSAttributedString alloc] initWithString:@" "] atIndex:0];
        [contentLabelString insertAttributedString:imageStr atIndex:0];
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
        quoteUserName = [quoteUserName stringByAppendingString:PLVLocalizedString(@"（我）")];
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

/// 获取严禁词提示多属性文本
+ (NSAttributedString *)contentLabelAttributedStringWithProhibitWordTip:(NSString *)prohibitTipString {
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *color = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.6];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByCharWrapping; //适配特殊字符，默认的NSLineBreakByWordWrapping遇到特殊字符会提前换行
    
    NSDictionary *AttDict = @{NSFontAttributeName: font,
                              NSForegroundColorAttributeName: color, NSParagraphStyleAttributeName : style};
    
    
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:prohibitTipString attributes:AttDict];
    
    return attributed;
}

+ (NSString *)prohibitWordTipWithModel:(PLVChatModel *)model {
    NSString *text = nil;
    if (model.prohibitWord) {
        text = [NSString stringWithFormat:PLVLocalizedString(@"你的聊天信息中含有违规词：%@"), model.prohibitWord];
    } else {
        text = PLVLocalizedString(@"您的聊天消息中含有违规词语，已全部作***代替处理");
    }
    return text;
}

#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.4];
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
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

- (UIView *)quoteLine {
    if (!_quoteLine) {
        _quoteLine = [[UIView alloc] init];
        _quoteLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.12];
    }
    return _quoteLine;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [_textView addGestureRecognizer:tapGesture];
    }
    return _textView;
}

- (UIView *)contentSepLine {
    if (!_contentSepLine) {
        _contentSepLine = [[UIView alloc] init];
        _contentSepLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.12];
    }
    return _contentSepLine;
}

- (UIView *)buttonSepLine {
    if (!_buttonSepLine) {
        _buttonSepLine = [[UIView alloc] init];
        _buttonSepLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.12];
    }
    return _buttonSepLine;
}

- (UIButton *)copButton {
    if (!_copButton) {
        _copButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_copButton setTitle:PLVLocalizedString(@"复制") forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC" alpha:0.8] forState:UIControlStateNormal];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC"] forState:UIControlStateHighlighted];
        [_copButton addTarget:self action:@selector(copButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _copButton;
}

- (UIButton *)foldButton {
    if (!_foldButton) {
        _foldButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_foldButton setTitle:PLVLocalizedString(@"更多") forState:UIControlStateNormal];
        _foldButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC" alpha:0.8] forState:UIControlStateNormal];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC"] forState:UIControlStateHighlighted];
        [_foldButton addTarget:self action:@selector(foldButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _foldButton;
}

- (UIButton *)prohibitWordTipButton {
    if (!_prohibitWordTipButton) {
        _prohibitWordTipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_prohibitWordTipButton setImage:[PLVLSUtils imageForStatusResource:@"plvls_status_signal_error_icon"] forState:UIControlStateNormal];
        [_prohibitWordTipButton addTarget:self action:@selector(prohibitWordTipButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _prohibitWordTipButton.hidden = YES;
    }
    return _prohibitWordTipButton;
}

- (PLVLSProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVLSProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapImageViewAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.quoteImageView];
}

- (void)copButtonAction {
    if (self.copButtonHandler) {
        self.copButtonHandler();
    }
}

- (void)foldButtonAction {
    if (self.foldButtonHandler) {
        self.foldButtonHandler();
    }
}

- (void)tapGestureAction {
    if (self.model.isProhibitMsg &&
        self.model.prohibitWordTipShowed) { // 已显示过的提示，点击可以重复提示
            self.model.prohibitWordTipShowed = NO;
            self.prohibitWordShowHandler ? self.prohibitWordShowHandler() : nil;
    }
}

- (void)prohibitWordTipButtonAction {
    if (self.model.isProhibitMsg &&
        self.model.prohibitWordTipShowed) { // 已显示过的提示，点击可以重复提示
            self.model.prohibitWordTipShowed = NO;
            self.prohibitWordShowHandler ? self.prohibitWordShowHandler() : nil;
    }
}

@end
