//
//  PLVSALongContentMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/22.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSALongContentMessageCell.h"

#import "PLVSAUtils.h"
#import "PLVEmoticonManager.h"
#import "PLVPhotoBrowser.h"

// UI
#import "PLVChatTextView.h"
#import "PLVSAProhibitWordTipView.h"

// Model
#import "PLVChatModel.h"

// SDK
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kMaxFoldedContentHeight = 97.0;
static CGFloat kButtonoHeight = 34.0;
static NSString *KEYPATH_MSGSTATE = @"msgState";

@interface PLVSALongContentMessageCell ()

#pragma mark 数据
@property (nonatomic, assign) CGFloat cellWidth; // cell宽度
@property (nonatomic, strong) NSString *loginUserId; // 登录用户的聊天室userId
@property (nonatomic, assign) PLVChatMsgState msgState; // 消息状态

#pragma mark UI
@property (nonatomic, strong) UIView *quoteLine; // 引用消息与回复消息分割线
@property (nonatomic, strong) UILabel *quoteContentLabel; // 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; // 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) PLVChatTextView *textView; // 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; // 背景气泡
@property (nonatomic, strong) UIView *contentSepLine; // 文本和按钮之间的分隔线
@property (nonatomic, strong) UIView *buttonSepLine; // 两个按钮中间的分隔线
@property (nonatomic, strong) UIButton *copButton; // 复制按钮
@property (nonatomic, strong) UIButton *foldButton; // 展开/收起按钮
@property (nonatomic, strong) PLVSAProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图
@property (nonatomic, strong) UIButton *resendButton; // 重发按钮
@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicatorView; // 正在发送提示视图
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; // 消息图片Browser

@end

@implementation PLVSALongContentMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.quoteImageView];
        [self.contentView addSubview:self.quoteLine];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.contentSepLine];
        [self.contentView addSubview:self.buttonSepLine];
        [self.contentView addSubview:self.copButton];
        [self.contentView addSubview:self.foldButton];
        [self.contentView addSubview:self.prohibitWordTipView];
        [self.contentView addSubview:self.resendButton];
        [self.contentView addSubview:self.sendingIndicatorView];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

// cell 复用前清除数据
- (void)prepareForReuse {
    [super prepareForReuse];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkSendState) object:nil];
    [self removeObserveMsgState];
}

- (void)dealloc {
    [self removeObserveMsgState];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat xPadding = 8.0; // 气泡与textView的左右内间距
    CGFloat resendWidth = 8 + 16;
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2 - resendWidth;
    CGFloat originY = 4.0;
    CGFloat bubbleViewTop = isPad ? 2 : 8;
    
    CGFloat quoteHeight = 0;
    if ([self.model.message isKindOfClass:[PLVQuoteMessage class]]) {
        quoteHeight = 4.0;
        originY += bubbleViewTop;
        CGSize quoteContentLabelSize = [self.quoteContentLabel.attributedText boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        self.quoteContentLabel.frame = CGRectMake(xPadding, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
        originY += quoteContentLabelSize.height + 4;
        
        CGSize quoteImageViewSize = CGSizeZero;
        if (!self.quoteImageView.hidden) {
            quoteImageViewSize = [PLVSALongContentMessageCell calculateImageViewSizeWithMessage:self.model.message];
            self.quoteImageView.frame = CGRectMake(xPadding, originY, quoteImageViewSize.width, quoteImageViewSize.height);
            originY += quoteImageViewSize.height + 4;
        }
        
        self.quoteLine.frame = CGRectMake(xPadding, originY, 0, 1); // 最后再设置分割线宽度
        
        quoteHeight = 4 + quoteContentLabelSize.height + (self.quoteImageView.hidden ? 0 : 4 + quoteImageViewSize.height) + 4 + 1;
        originY += 1;
    }

    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    CGSize contentLabelSize = [self.textView.attributedText boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat contentHeight = MIN(contentLabelSize.height, kMaxFoldedContentHeight);
    self.textView.frame = CGRectMake(xPadding, originY - 4, textViewSize.width, contentHeight - 4 * 2);
    
    CGFloat bubbleWidth = self.cellWidth - resendWidth;
    
    // 横的分割线跟气泡左右间隔8pt
    self.contentSepLine.frame = CGRectMake(0 + 8, CGRectGetMaxY(self.textView.frame) - 4, bubbleWidth - 8 * 2, 1);
    self.buttonSepLine.frame = CGRectMake(0 + bubbleWidth / 2.0 - 0.5, CGRectGetMaxY(self.contentSepLine.frame) + 10.5, 1, 15);
    
    CGFloat bubbleHeight = CGRectGetMaxY(self.contentSepLine.frame) - bubbleViewTop + kButtonoHeight;
    self.bubbleView.frame = CGRectMake(0, bubbleViewTop, bubbleWidth, bubbleHeight);
    self.bubbleView.layer.cornerRadius = 8.0;
    
    CGSize buttonSize = CGSizeMake(CGRectGetWidth(self.bubbleView.frame)/ 2.0, kButtonoHeight);
    self.copButton.frame = CGRectMake(0, CGRectGetMaxY(self.bubbleView.frame) - buttonSize.height, buttonSize.width, buttonSize.height);
    self.foldButton.frame = CGRectMake(CGRectGetMaxX(self.copButton.frame), CGRectGetMinY(self.copButton.frame), buttonSize.width, buttonSize.height);
    
    self.resendButton.frame = CGRectMake(CGRectGetMaxX(self.bubbleView.frame) + 8, (self.bubbleView.frame.size.height - 16) / 2 + self.bubbleView.frame.origin.y, 16, 16);
    self.sendingIndicatorView.frame = self.resendButton.frame;
    
    if ([self.model isProhibitMsg] &&
        !self.model.prohibitWordTipIsShowed) {
        NSAttributedString *attri = [PLVSALongContentMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVSALongContentMessageCell prohibitWordTipWithModel:self.model]];
        CGFloat maxWidth = contentLabelSize.width + 6 + 16;
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        self.prohibitWordTipView.frame = CGRectMake(0, CGRectGetMaxY(self.bubbleView.frame), tipSize.width + 2 * xPadding, tipSize.height + 20);
    } else {
        self.prohibitWordTipView.frame = CGRectZero;
    }
    
    if (!self.quoteLine.hidden) {
        CGRect lineRect = self.quoteLine.frame;
        lineRect.origin.x = self.contentSepLine.frame.origin.x;
        lineRect.size.width = self.contentSepLine.frame.size.width;
        self.quoteLine.frame = lineRect;
    }
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVSALongContentMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
   
    self.cellWidth = cellWidth;
    self.model = model;
    
    // KVO
    [self removeObserveMsgState];
    [self addObserveMsgState];
    
    // 检查发送状态
    self.msgState = model.msgState;
    if (self.msgState == PLVChatMsgStateSending) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkSendState) object:nil];
        [self performSelector:@selector(checkSendState) withObject:nil afterDelay:10.0];
    }
    
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }

    if ([model.message isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)model.message;
        self.quoteLine.hidden = NO;
        
        NSAttributedString *quoteLabelString = [PLVSALongContentMessageCell quoteContentAttributedStringWithMessage:quoteMessage loginUserId:self.loginUserId];
        self.quoteContentLabel.attributedText = quoteLabelString;
        self.quoteContentLabel.hidden = !quoteLabelString;
        
        NSURL *quoteImageURL = [PLVSALongContentMessageCell quoteImageURLWithMessage:quoteMessage];
        self.quoteImageView.hidden = !quoteImageURL;
        if (quoteImageURL) {
            UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
            [PLVSAUtils setImageView:self.quoteImageView url:quoteImageURL
                                   placeholderImage:placeHolderImage
                                            options:SDWebImageRetryFailed];
        }
    } else {
        self.quoteContentLabel.hidden = YES;
        self.quoteImageView.hidden = YES;
        self.quoteLine.hidden = YES;
    }
    
    // 严禁词提示
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
    
        self.prohibitWordTipView.hidden = NO;
        [self.prohibitWordTipView setTipType:PLVSAProhibitWordTipTypeText prohibitWord:model.prohibitWord];
        [self.prohibitWordTipView show];
        
        __weak typeof(self)weakSelf = self;
        self.prohibitWordTipView.dismissBlock = ^{
            weakSelf.model.prohibitWordTipShowed = YES;
            if (weakSelf.dismissHandler) {
                weakSelf.dismissHandler();
            }
        };
    }else{
        self.prohibitWordTipView.hidden = YES;
    }
    
    NSMutableAttributedString *contentLabelString = [PLVSALongContentMessageCell contentLabelAttributedStringWithModel:model loginUserId:self.loginUserId];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    
    self.resendButton.hidden = (self.msgState != PLVChatMsgStateFail) && (!model.prohibitWord || model.prohibitWord.length == 0);
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVSALongContentMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 8.0; // 气泡与textView的左右内间距
    CGFloat resendWidth = 8 + 16;
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2 - resendWidth;
    
    NSMutableAttributedString *contentLabelString = [PLVSALongContentMessageCell contentLabelAttributedStringWithModel:model loginUserId:loginUserId];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat contentHeight = MIN(contentLabelSize.height, kMaxFoldedContentHeight);
    
    // 严禁词高度
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
        NSAttributedString *attri = [PLVSALongContentMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVSALongContentMessageCell prohibitWordTipWithModel:model]];
        CGFloat maxWidth = contentLabelSize.width + 6 + 16;
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        contentHeight += tipSize.height + 20;
    }
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat cellHeight = (isPad ? 2 : 8) + ceilf(contentHeight) - 4 * 2 + kButtonoHeight;
    
    if ([model.message isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)model.message;
        NSAttributedString *quoteLabelString = [PLVSALongContentMessageCell quoteContentAttributedStringWithMessage:quoteMessage loginUserId:loginUserId];
        CGSize quoteContentSize = [quoteLabelString boundingRectWithSize:CGSizeMake(cellWidth - xPadding * 2 - resendWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        CGFloat quoteContentHeight = quoteContentSize.height;
        
        CGFloat quoteImageHeight = 0;
        NSURL *quoteImageURL = [PLVSALongContentMessageCell quoteImageURLWithMessage:quoteMessage];
        if (quoteImageURL) {
            CGSize quoteImageViewSize = [PLVSALongContentMessageCell calculateImageViewSizeWithMessage:quoteMessage];
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
+ (NSMutableAttributedString *)contentLabelAttributedStringWithModel:(PLVChatModel *)model
                                                           loginUserId:(NSString *)loginUserId {
    PLVChatUser *user = model.user;
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
        content = [content stringByAppendingString:@"（我）"];
    }
    content = [content stringByAppendingString:@"："];
    
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:model.content attributes:contentAttDict];
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    
    // 特殊身份头衔
    if (user.actor &&
        [user.actor isKindOfClass:[NSString class]] &&
        user.actor.length > 0 &&
        [PLVSABaseMessageCell showActorLabelWithUser:user]) {
        
        UIImage *image = [PLVSABaseMessageCell actorImageWithUser:user];
        //创建Image的富文本格式
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = font.lineHeight - font.pointSize + 1;
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

+ (NSString *)prohibitWordTipWithModel:(PLVChatModel *)model {
    NSString *text = nil;
    if (model.prohibitWord) {
        text = [NSString stringWithFormat:@"你的聊天信息中含有违规词：%@", model.prohibitWord];
    } else {
        text = @"您的聊天消息中含有违规词语，已全部作***代替处理";
    }
    return text;
}

/// 检查发送状态
- (void)checkSendState {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkSendState) object:nil];
    if (self.msgState == PLVChatMsgStateSending) {
        self.model.msgState = PLVChatMsgStateFail;
    }
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

#pragma mark Getter && Setter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (UIView *)quoteLine {
    if (!_quoteLine) {
        _quoteLine = [[UIView alloc] init];
        _quoteLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.12];
    }
    return _quoteLine;
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

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.selectable = NO;
        _textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _textView;
}

- (PLVSAProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVSAProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
}

- (UIView *)contentSepLine {
    if (!_contentSepLine) {
        _contentSepLine = [[UIView alloc] init];
        _contentSepLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.2];
    }
    return _contentSepLine;
}

- (UIView *)buttonSepLine {
    if (!_buttonSepLine) {
        _buttonSepLine = [[UIView alloc] init];
        _buttonSepLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.2];
    }
    return _buttonSepLine;
}

- (UIButton *)copButton {
    if (!_copButton) {
        _copButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_copButton setTitle:@"复制" forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC"] forState:UIControlStateNormal];
        [_copButton addTarget:self action:@selector(copButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _copButton;
}

- (UIButton *)foldButton {
    if (!_foldButton) {
        _foldButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_foldButton setTitle:@"更多" forState:UIControlStateNormal];
        _foldButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC"] forState:UIControlStateNormal];
        [_foldButton addTarget:self action:@selector(foldButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _foldButton;
}

- (UIButton *)resendButton {
    if (!_resendButton) {
        _resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_resendButton setImage:[PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_cell_icon_error"] forState:UIControlStateNormal];
        _resendButton.hidden = YES;
        [_resendButton addTarget:self action:@selector(resendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resendButton;
}

- (UIActivityIndicatorView *)sendingIndicatorView {
    if (!_sendingIndicatorView) {
        _sendingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _sendingIndicatorView.hidden = YES;
    }
    return _sendingIndicatorView;
}

- (void)setMsgState:(PLVChatMsgState)msgState {
    _msgState = msgState;
    plv_dispatch_main_async_safe(^{
        if (msgState == PLVChatMsgStateSending) {
            self.sendingIndicatorView.hidden = NO;
            [self.sendingIndicatorView startAnimating];
        } else {
            self.sendingIndicatorView.hidden = YES;
            if (self.sendingIndicatorView.isAnimating) {
                [self.sendingIndicatorView stopAnimating];
            }
        }
    })
}

#pragma mark KVO

- (void)addObserveMsgState {
    if (!self.observingMsgState &&
        self.model) {
        self.observingMsgState = YES;
        [self.model addObserver:self forKeyPath:KEYPATH_MSGSTATE options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveMsgState {
    if (self.observingMsgState &&
        self.model) {
        self.observingMsgState = NO;
        [self.model removeObserver:self forKeyPath:KEYPATH_MSGSTATE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.model &&
        [keyPath isEqual:KEYPATH_MSGSTATE]) {
        
        self.msgState = (PLVChatMsgState)[[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        
    }
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

- (void)resendButtonAction {
    if (self.resendHandler &&
        self.msgState == PLVChatMsgStateFail) {  // 只有在发送失败方可触发重发点击事件，避免重复发送
        if ([self.model content]) {
            __weak typeof(self) weakSelf = self;
            [PLVSAUtils showAlertWithMessage:@"重发该消息？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
                weakSelf.model.msgState = PLVChatMsgStateSending;
                weakSelf.resendHandler(weakSelf.model);
            }];
        }
    }
}

@end
