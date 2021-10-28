//
//  PLVHCQuoteMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/25.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCQuoteMessageCell.h"

// 工具
#import "PLVPhotoBrowser.h"
#import "PLVHCUtils.h"
#import "PLVChatTextView.h"
#import "PLVEmoticonManager.h"

// UI
#import "PLVHCProhibitWordTipView.h"

// 模块
#import "PLVChatModel.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVHCQuoteMessageCell ()<
UITextViewDelegate>

#pragma mark UI

@property (nonatomic, strong) PLVChatTextView *textView; // 消息文本内容视图
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; // 消息图片Browser
@property (nonatomic, strong) UIView *line; // 引用消息与回复消息分割线
@property (nonatomic, strong) UILabel *quoteContentLabel; // 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; // 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) UIView *bubbleView; // 背景气泡
@property (nonatomic, strong) PLVHCProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图
@property (nonatomic, strong) UIButton *resendButton; // 重发按钮
@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicatorView; // 正在发送提示视图
@property (nonatomic, strong) UIImageView *headerImageView; // 头像视图
@property (nonatomic, strong) UILabel *nickNameLabel;; // 昵称视图

#pragma mark 数据

@property (nonatomic, assign) CGFloat cellWidth; // cell宽度
@property (nonatomic, strong) NSString *loginUserId; // 用户的聊天室userId
@property (nonatomic, assign) PLVChatMsgState msgState; // 消息状态


@end

#pragma mark 静态数据
static NSString *KEYPATH_MSGSTATE = @"msgState";
static NSString *otherCellId = @"PLVHCQuoteMessageCell_Other";
static NSString *selfCellId = @"PLVHCQuoteMessageCell_Self";

static CGFloat kCellTopMargin = 10;

@implementation PLVHCQuoteMessageCell


#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = self.allowCopy = YES;
        self.menuSuperView = self.textView;
        
        [self.contentView addSubview:self.headerImageView];
        [self.contentView addSubview:self.nickNameLabel];
        
        [self.contentView addSubview:self.bubbleView];
        [self.bubbleView addSubview:self.textView];
        [self.bubbleView addSubview:self.line];
        [self.bubbleView addSubview:self.quoteContentLabel];
        [self.bubbleView addSubview:self.quoteImageView];
        
        [self.contentView addSubview:self.resendButton];
        [self.contentView addSubview:self.sendingIndicatorView];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

// cell 复用前清除数据
- (void)prepareForReuse {
    [super prepareForReuse];
    [self removeObserveMsgState];
}

- (void)dealloc {
    [self removeObserveMsgState];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    CGFloat originX = 8.0;
    CGFloat bubbleXPadding = originX; // 气泡与textView的左右内间距
    CGFloat padding = 4;
    CGFloat resendWidth = 8 + 16;
    CGFloat headerWidth = 30;
    CGFloat lineHeight = 1;
    
    CGFloat maxContentWidth = self.cellWidth - bubbleXPadding * 2 - resendWidth - headerWidth - bubbleXPadding;
    
    NSAttributedString *quoteContentLabelString = self.quoteContentLabel.attributedText;
    CGSize quoteContentLabelSize = [quoteContentLabelString boundingRectWithSize:CGSizeMake(maxContentWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
    CGSize nickNameViewSize = CGSizeMake(maxContentWidth, 17);
    CGSize quoteImageViewSize = CGSizeZero;
    if (!self.quoteImageView.hidden) {
        quoteImageViewSize = [PLVHCQuoteMessageCell calculateImageViewSizeWithMessage:self.model.message];
    }
    
    CGSize bubbleSize = CGSizeMake(MAX(textViewSize.width + bubbleXPadding * 2, quoteContentLabelSize.width + bubbleXPadding * 2), textViewSize.height -  padding + quoteContentLabelSize.height  + quoteImageViewSize.height + padding + lineHeight + padding);
    NSAttributedString *attri = [PLVHCQuoteMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVHCQuoteMessageCell prohibitWordTipWithModel:self.model]];
    CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxContentWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    tipSize = CGSizeMake(tipSize.width + bubbleXPadding * 2, tipSize.height + 20);
   
    CGFloat headerImageViewX;
    CGFloat nickNameLabelX;
    CGFloat bubbleViewX;
    CGFloat tipViewX;
    
    // 自己的发言，右对齐、隐藏昵称；
    if ([PLVHCQuoteMessageCell isLoginUser:self.model.user.userId]) {
        headerImageViewX = self.cellWidth - headerWidth;
        nickNameLabelX = 0; // 昵称会被隐藏
        nickNameViewSize = CGSizeZero;
        bubbleViewX = self.cellWidth - headerWidth - bubbleXPadding - bubbleSize.width;
        tipViewX = self.cellWidth - headerWidth - tipSize.width;
        
    } else { // 他人的发言，左对齐，显示昵称
        headerImageViewX = 0;
        nickNameLabelX = headerImageViewX + headerWidth + bubbleXPadding;
        bubbleViewX = nickNameLabelX;
        tipViewX = 0;
    }
    
    self.headerImageView.frame = CGRectMake(headerImageViewX, kCellTopMargin, headerWidth, headerWidth);
    
    self.nickNameLabel.frame = CGRectMake(nickNameLabelX, kCellTopMargin, nickNameViewSize.width, nickNameViewSize.height);
    
    self.bubbleView.frame = CGRectMake(bubbleViewX, CGRectGetMaxY(self.nickNameLabel.frame) + padding, ceilf(bubbleSize.width), bubbleSize.height);
    self.bubbleView.layer.cornerRadius = 8.0;
    
    self.quoteContentLabel.frame = CGRectMake(bubbleXPadding, padding, quoteContentLabelSize.width, quoteContentLabelSize.height);

    
    if (!self.quoteImageView.hidden) {
        self.quoteImageView.frame = CGRectMake(originX, CGRectGetMaxY(self.quoteContentLabel.frame) + 4, quoteImageViewSize.width, quoteImageViewSize.height);
        
        self.line.frame = CGRectMake(bubbleXPadding, CGRectGetMaxY(self.quoteImageView.frame) + padding, MAX(quoteContentLabelSize.width, textViewSize.width), lineHeight);
    } else {
        self.line.frame = CGRectMake(bubbleXPadding, CGRectGetMaxY(self.quoteContentLabel.frame) + padding, MAX(quoteContentLabelSize.width, textViewSize.width), lineHeight);
    }
    
    self.textView.frame = CGRectMake(bubbleXPadding, CGRectGetMaxY(self.line.frame) - padding, textViewSize.width, textViewSize.height);
    
    if ([self.model isProhibitMsg] &&
        !self.model.prohibitWordTipIsShowed) {
        _prohibitWordTipView.frame = CGRectMake(tipViewX, CGRectGetMaxY(self.bubbleView.frame), tipSize.width, tipSize.height);
    } else {
        _prohibitWordTipView.frame = CGRectZero;
    }
    
    // 重发按钮
    self.resendButton.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) - bubbleXPadding - 16, 0, 16, 16);
    self.resendButton.center = CGPointMake(self.resendButton.center.x, self.textView.center.y);
    // 发送中小菊花
    self.sendingIndicatorView.frame = self.resendButton.frame;
}

#pragma mark 覆盖重写BaseMessageCell方法

+ (NSString *)reuseIdentifierWithUser:(PLVChatUser *)user {
    if (!user ||
        ![user isKindOfClass:[PLVChatUser class]] ||
        ![PLVFdUtil checkStringUseable:user.userId]) {
        return nil;
    }
    
    NSString *cellId = nil;
    if ([self isLoginUser:user.userId]) {
        cellId = selfCellId;
    } else {
        cellId = otherCellId;
    }
    
    return cellId;
}

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

/// 覆盖实现父类copyAction方法
- (void)copyAction {
    [super copyAction];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    PLVQuoteMessage *message = self.model.message;
    pasteboard.string = message.content;
    [PLVHCUtils showToastInWindowWithMessage:@"已复制"];
}

#pragma mark - [ Public Method ]
#pragma mark Set UI
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVHCQuoteMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    // KVO
    [self removeObserveMsgState];
    [self addObserveMsgState];
    
    PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVHCQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    
    NSAttributedString *quoteLabelString = [PLVHCQuoteMessageCell quoteContentAttributedStringWithMessage:message
                                                                                                loginUserId:self.loginUserId];
    self.quoteContentLabel.attributedText = quoteLabelString;
    
    NSURL *quoteImageURL = [PLVHCQuoteMessageCell quoteImageURLWithMessage:message];
    self.quoteImageView.hidden = !quoteImageURL;
    if (quoteImageURL) {
        UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
        [self.quoteImageView sd_setImageWithURL:quoteImageURL
                               placeholderImage:placeHolderImage
                                        options:SDWebImageRetryFailed];
    }
    // 重发按钮是否隐藏
    self.msgState = model.msgState;
    
    // 严禁词提示
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
        [self.prohibitWordTipView setTipType:PLVHCProhibitWordTipTypeText prohibitWord:model.prohibitWord];
        [self.prohibitWordTipView showInView:self.contentView];
        
        __weak typeof(self)weakSelf = self;
        self.prohibitWordTipView.dismissBlock = ^{
            weakSelf.model.prohibitWordTipShowed = YES;
            if (weakSelf.prohibitWordTipdismissHandler) {
                weakSelf.prohibitWordTipdismissHandler();
            }
        };
    } else { 
        if (_prohibitWordTipView) {
            [self.prohibitWordTipView dismissNoCallblck];
        }
    }
    
    // 设置昵称
    self.nickNameLabel.attributedText = [PLVHCQuoteMessageCell nickNameLabelAttributedStringWithUser:model.user];
    
    // 加载头像
    [self loadImageWithModel:model];

    
    __weak typeof(self) weakSelf = self;
    [self.textView setReplyHandler:^{
        if (weakSelf.replyHandler) {
            weakSelf.replyHandler(model);
        }
    }];
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVHCQuoteMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat bubbleXPadding = 8.0; // 气泡与textView的左右内间距
    CGFloat resendWidth = 8 + 16;
    CGFloat headerWidth = 30;
    CGFloat maxTextViewWidth = cellWidth - bubbleXPadding * 2 - resendWidth - headerWidth - bubbleXPadding;
    
    PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVHCQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    NSAttributedString *quoteLabelString = [PLVHCQuoteMessageCell quoteContentAttributedStringWithMessage:message loginUserId:loginUserId];
    CGSize quoteContentSize = [quoteLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat quoteContentHeight = quoteContentSize.height;
    
    CGFloat quoteImageHeight = 0;
    NSURL *quoteImageURL = [PLVHCQuoteMessageCell quoteImageURLWithMessage:model.message];
    if (quoteImageURL) {
        CGSize quoteImageViewSize = [PLVHCQuoteMessageCell calculateImageViewSizeWithMessage:model.message];
        quoteImageHeight = quoteImageViewSize.height;
    }
    
    // 严禁词高度
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVHCQuoteMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVHCQuoteMessageCell prohibitWordTipWithModel:model]];
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        contentLabelSize.height += tipSize.height + 20;
    }
    
    // 昵称，当前消息为他人发送的才显示，自己的发言隐藏昵称
    if (![self isLoginUser:model.user.userId]) {
        NSMutableAttributedString *nickNameLabelString = [PLVHCQuoteMessageCell nickNameLabelAttributedStringWithUser:model.user];
        CGSize  nickNameLabelSize = [nickNameLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        contentLabelSize.height +=  nickNameLabelSize.height + 4;
    }
    
    return kCellTopMargin + 8 + quoteContentHeight + 8 + (quoteImageURL ? 4 + quoteImageHeight : 0) + 4 + 1 + 4 + contentLabelSize.height + 4 + 8; // 气泡底部外间距为8
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
        _bubbleView.layer.cornerRadius = 8.0;
        _bubbleView.layer.masksToBounds = YES;
        _bubbleView.userInteractionEnabled = YES;
        UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTapQuoteContentLabelAction:)];
        [_bubbleView addGestureRecognizer:longGesture];
    }
    return _bubbleView;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.delegate = self;
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
        _quoteContentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
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

- (PLVHCProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVHCProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
}

- (UIButton *)resendButton {
    if (!_resendButton) {
        _resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_resendButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_icon_error"] forState:UIControlStateNormal];
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

- (UIImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc] init];
        _headerImageView.layer.cornerRadius = 15;
        _headerImageView.layer.masksToBounds = YES;
    }
    return _headerImageView;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.numberOfLines = 1;
        _nickNameLabel.font = [UIFont systemFontOfSize:12];
    }
    return _nickNameLabel;
}

#pragma mark Setter

- (void)setMsgState:(PLVChatMsgState)msgState {
    _msgState = msgState;
    
    plv_dispatch_main_async_safe(^{
        self.resendButton.hidden = !(msgState == PLVChatMsgStateFail);
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

#pragma mark Data Mode

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

+ (NSString *)prohibitWordTipWithModel:(PLVChatModel *)model {
    return [NSString stringWithFormat:@"你的聊天信息中含有违规词：%@", model.prohibitWord];
}

#pragma mark AttributedString
/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVQuoteMessage *)message
                                                                  user:(PLVChatUser *)user
                                                          prohibitWord:(NSString *)prohibitWord{
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *contentColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 17;
    
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:contentColor,
                                     NSParagraphStyleAttributeName:paragraph
    };
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:message.content attributes:contentAttDict];
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    
    // 含有严禁内容,添加提示图片
    if (prohibitWord && prohibitWord.length >0) {
        CGFloat paddingTop = font.lineHeight - font.pointSize;
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.bounds = CGRectMake(0, -ceilf(paddingTop), font.lineHeight, font.lineHeight);
        attachment.image = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_icon_error"];
        // 设置文字与图片间隔
        [contentLabelString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        NSAttributedString *attachAttri = [NSAttributedString attributedStringWithAttachment:attachment];
        [contentLabelString appendAttributedString:attachAttri];
    }
    return contentLabelString;
}

/// 获取被引用的消息的多属性文本，格式为 “文本”
+ (NSAttributedString *)quoteContentAttributedStringWithMessage:(PLVQuoteMessage *)message
                                                    loginUserId:(NSString *)loginUserId {
    NSString *quoteUserName = message.quoteUserName ?: @"";
    NSString *quoteUserId = message.quoteUserId;
    if (quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:quoteUserId]) {
        quoteUserName = [quoteUserName stringByAppendingString:@"（我）"];
    }
    
    NSString *content;
    if (message.quoteContent) {
        content  = [NSString stringWithFormat:@"%@:\n%@", quoteUserName, message.quoteContent];
    } else {
        content  = [NSString stringWithFormat:@"%@:", quoteUserName];
    }
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 17;
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#787C90"],
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

/// 获取昵称多属性文本
+ (NSMutableAttributedString *)nickNameLabelAttributedStringWithUser:(PLVChatUser *)user {
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 17;
    
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: [PLVColorUtil colorFromHexString:@"#8D909A"],
                                      NSParagraphStyleAttributeName:paragraph};
    
    NSMutableAttributedString *nickNameAttributedString = [[NSMutableAttributedString alloc] initWithString:user.userName attributes:nickNameAttDict];
    
    // 特殊身份头衔
    if (user.actor &&
        [user.actor isKindOfClass:[NSString class]] &&
        user.actor.length > 0 &&
        [PLVHCBaseMessageCell showActorLabelWithUser:user]) {
        
        UIImage *image = [PLVHCBaseMessageCell actorImageWithUser:user];
        //创建Image的富文本格式
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = font.lineHeight - font.pointSize + 1;
        attach.bounds = CGRectMake(0, -ceilf(paddingTop), image.size.width, image.size.height);
        attach.image = image;
        //添加到富文本对象里
        NSAttributedString * imageStr = [NSAttributedString attributedStringWithAttachment:attach];
        [nickNameAttributedString insertAttributedString:[[NSAttributedString alloc] initWithString:@" "] atIndex:0];
        [nickNameAttributedString insertAttributedString:imageStr atIndex:0];
    }
    
    
    return nickNameAttributedString;
}

#pragma mark 检查发送状态
- (void)checkSendState {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkSendState) object:nil];
    if (self.msgState == PLVChatMsgStateSending) {
        self.model.msgState = PLVChatMsgStateFail;
    }
}

#pragma mark 加载头像
- (void)loadImageWithModel:(PLVChatModel *)model {
    PLVChatUser *user = model.user;
    
    UIImage *placeHolderImage = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_image_placeholder"];
    if (!user ||
        ![user isKindOfClass:[PLVChatUser class]] ||
        ![PLVFdUtil checkStringUseable:user.avatarUrl]) {
        [self.headerImageView setImage:placeHolderImage];
        return;
    }
    
    NSURL *imageURL = [NSURL URLWithString:user.avatarUrl];
    if (imageURL) {
        [self.headerImageView sd_setImageWithURL:imageURL placeholderImage:placeHolderImage];
    } else {
        [self.headerImageView setImage:placeHolderImage];
    }
}

#pragma mark - Event

#pragma mark Action

- (void)resendButtonAction {
    // 只有在发送失败时方可触发重发点击事件，避免重复发送
    if (self.msgState == PLVChatMsgStateFail) {
        __weak typeof(self) weakSelf = self;
        [PLVHCUtils showAlertWithMessage:@"重发该消息？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
            weakSelf.model.msgState = PLVChatMsgStateSending;
            if (weakSelf.resendReplyHandler) {
                weakSelf.resendReplyHandler(weakSelf.model);
            }
        }];
    } else {
        self.resendButton.hidden = YES;
    }
}

#pragma mark Gesture

- (void)tapImageViewAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.quoteImageView];
}

- (void)longTapQuoteContentLabelAction:(UILongPressGestureRecognizer *)longGesture {
    if (longGesture.state == UIGestureRecognizerStateBegan) {
        [super showMenuPopup];
    }
}

#pragma mark - KVO

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

#pragma mark - [ Delegate ]
#pragma mark UITextViewDelegate
// 过滤长按emoji表情事件
- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction  API_AVAILABLE(ios(10.0)){
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {
    return NO;
}

@end
