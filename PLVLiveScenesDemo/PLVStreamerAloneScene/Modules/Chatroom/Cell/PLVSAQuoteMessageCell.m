//
//  PLVSAQuoteMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAQuoteMessageCell.h"

// Utils
#import "PLVPhotoBrowser.h"
#import "PLVSAUtils.h"
#import "PLVChatTextView.h"
#import "PLVEmoticonManager.h"

// UI
#import "PLVSAProhibitWordTipView.h"

// Model
#import "PLVChatModel.h"

// SDK
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>


@interface PLVSAQuoteMessageCell ()

// Data
@property (nonatomic, assign) CGFloat cellWidth; // cell宽度
@property (nonatomic, strong) NSString *loginUserId; // 用户的聊天室userId
@property (nonatomic, assign) PLVChatMsgState msgState; // 消息状态

// UI
@property (nonatomic, strong) PLVChatTextView *textView; // 消息文本内容视图
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; // 消息图片Browser
@property (nonatomic, strong) UIView *line; // 引用消息与回复消息分割线
@property (nonatomic, strong) UILabel *quoteContentLabel; // 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; // 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) UIView *bubbleView; // 背景气泡
@property (nonatomic, strong) PLVSAProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图
@property (nonatomic, strong) UIButton *resendButton; // 重发按钮
@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicatorView; // 正在发送提示视图

@end

static NSString *KEYPATH_MSGSTATE = @"msgState";

@implementation PLVSAQuoteMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = self.allowCopy = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.line];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.quoteImageView];
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

#pragma mark - [ Override ]

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    CGFloat originX = 8.0;
    CGFloat originY = 8.0;
    CGFloat bubbleXPadding = 8.0; // 气泡与textView的左右内间距
    CGFloat resendWidth = 8 + 16;
    
    CGFloat maxContentWidth = self.cellWidth - bubbleXPadding * 2 - resendWidth;
    
    NSAttributedString *quoteContentLabelString = self.quoteContentLabel.attributedText;
    CGSize quoteContentLabelSize = [quoteContentLabelString boundingRectWithSize:CGSizeMake(maxContentWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    originY += originY;
    
    self.quoteContentLabel.frame = CGRectMake(originX, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
    originY += quoteContentLabelSize.height + 4;
    
    if (!self.quoteImageView.hidden) {
        CGSize quoteImageViewSize = [PLVSAQuoteMessageCell calculateImageViewSizeWithMessage:self.model.message];
        self.quoteImageView.frame = CGRectMake(originX, originY, quoteImageViewSize.width, quoteImageViewSize.height);
        originY += quoteImageViewSize.height + 4;
    }
    
    self.line.frame = CGRectMake(originX, originY, 0, 1); // 最后再设置分割线宽度
    originY += 1 + 4 - 8;
    
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxContentWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(originX, originY, textViewSize.width, textViewSize.height);
    originY += textViewSize.height - 4;
    
    self.bubbleView.frame = CGRectMake(0, 8, 0, originY); // 最后再设置气泡宽度
    // 严禁词
    if ([self.model isProhibitMsg] &&
        !self.model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVSAQuoteMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVSAQuoteMessageCell prohibitWordTipWithModel:self.model]];
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxContentWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        self.prohibitWordTipView.frame = CGRectMake(originX, CGRectGetMaxY(self.textView.frame), maxContentWidth - originX, tipSize.height + 20);
    } else {
        self.prohibitWordTipView.frame = CGRectZero;
    }
    
    CGFloat contentWidth = [self actualMaxContentWidth];
    CGRect lineRect = self.line.frame;
    self.line.frame = CGRectMake(lineRect.origin.x, lineRect.origin.y, contentWidth, lineRect.size.height);
    
    CGRect bubbleRect = self.bubbleView.frame;
    self.bubbleView.frame = CGRectMake(bubbleRect.origin.x, bubbleRect.origin.y, contentWidth + bubbleXPadding * 2, bubbleRect.size.height);
    
    // 重发按钮
    self.resendButton.frame = CGRectMake(CGRectGetMaxX(self.bubbleView.frame) + 8,   (self.bubbleView.frame.size.height - 16) / 2 + self.bubbleView.frame.origin.y, 16, 16);
    // 发送中小菊花
    self.sendingIndicatorView.frame = self.resendButton.frame;
}


/// 覆盖实现父类customCopy方法
/// @param sender sender
- (void)customCopy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    PLVQuoteMessage *message = self.model.message;
    pasteboard.string = message.content;
}

#pragma mark - [ Public Method ]
#pragma mark Set UI
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVSAQuoteMessageCell isModelValid:model] || cellWidth == 0) {
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
    NSMutableAttributedString *contentLabelString = [PLVSAQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    
    NSAttributedString *quoteLabelString = [PLVSAQuoteMessageCell quoteContentAttributedStringWithMessage:message
                                                                                                loginUserId:self.loginUserId];
    self.quoteContentLabel.attributedText = quoteLabelString;
    
    NSURL *quoteImageURL = [PLVSAQuoteMessageCell quoteImageURLWithMessage:message];
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
    
    __weak typeof(self) weakSelf = self;
    [self.textView setReplyHandler:^{
        if (weakSelf.replyHandler) {
            weakSelf.replyHandler(model);
        }
    }];
    
    // 检查发送状态
    if (self.model.msgState == PLVChatMsgStateSending) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkSendState) object:nil];
        [self performSelector:@selector(checkSendState) withObject:nil afterDelay:10.0];
    }
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVSAQuoteMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat bubbleXPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat resendWidth = 8 + 16;
    
    CGFloat maxTextViewWidth = cellWidth - bubbleXPadding * 2 - resendWidth;
    PLVQuoteMessage *message = (PLVQuoteMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVSAQuoteMessageCell contentLabelAttributedStringWithMessage:message user:model.user prohibitWord:model.prohibitWord];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    NSAttributedString *quoteLabelString = [PLVSAQuoteMessageCell quoteContentAttributedStringWithMessage:message loginUserId:loginUserId];
    CGSize quoteContentSize = [quoteLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat quoteContentHeight = quoteContentSize.height;
    
    CGFloat quoteImageHeight = 0;
    NSURL *quoteImageURL = [PLVSAQuoteMessageCell quoteImageURLWithMessage:model.message];
    if (quoteImageURL) {
        CGSize quoteImageViewSize = [PLVSAQuoteMessageCell calculateImageViewSizeWithMessage:model.message];
        quoteImageHeight = quoteImageViewSize.height;
    }
    
    // 严禁词高度
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVSAQuoteMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVSAQuoteMessageCell prohibitWordTipWithModel:model]];
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        contentLabelSize.height += tipSize.height + 20;
    }
    
    return 8 + quoteContentHeight + 8 + (quoteImageURL ? 4 + quoteImageHeight : 0) + 4 + 1 + 4 + contentLabelSize.height + 4 + 8; // 气泡底部外间距为8
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

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
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

- (PLVSAProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVSAProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
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
    if (!self.prohibitWordTipView.hidden) {
        prohibitTipWidth = self.prohibitWordTipView.frame.size.width;
    }
    
    return MAX(MAX(textViewContentWidth, prohibitTipWidth) , MAX(quoteContentWidth, quoteImageWidth));
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

+ (NSString *)prohibitWordTipWithModel:(PLVChatModel *)model {
    return [NSString stringWithFormat:@"你的聊天信息中含有违规词：%@", model.prohibitWord];
}

#pragma mark AttributedString
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
  
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:message.content attributes:contentAttDict];
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
    
    // 含有严禁内容,添加提示图片
    if (prohibitWord && prohibitWord.length >0) {
        CGFloat paddingTop = font.lineHeight - font.pointSize;
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.bounds = CGRectMake(0, -ceilf(paddingTop), font.lineHeight, font.lineHeight);
        attachment.image = [PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_cell_icon_error"];
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

#pragma mark 检查发送状态
- (void)checkSendState {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkSendState) object:nil];
    if (self.msgState == PLVChatMsgStateSending) {
        self.model.msgState = PLVChatMsgStateFail;
    }
}

#pragma mark - Event

#pragma mark Action

- (void)resendButtonAction {
    // 只有在发送失败方可触发重发点击事件，避免重复发送
    if (self.resendReplyHandler &&
        self.msgState == PLVChatMsgStateFail) {
        
        PLVQuoteMessage *message = (PLVQuoteMessage *)self.model.message;
        if (message) {
            __weak typeof(self) weakSelf = self;
            [PLVSAUtils showAlertWithMessage:@"重发该消息？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
                weakSelf.model.msgState = PLVChatMsgStateSending;
                weakSelf.resendReplyHandler(message.content, weakSelf.model.replyMessage);
            }];
        }
    }
}

#pragma mark Gesture

- (void)tapImageViewAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.quoteImageView];
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
@end
