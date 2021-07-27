//
//  PLVSASpeakMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSASpeakMessageCell.h"

// Utils
#import "PLVSAUtils.h"
#import "PLVEmoticonManager.h"

// UI
#import "PLVChatTextView.h"
#import "PLVSAProhibitWordTipView.h"

// Model
#import "PLVChatModel.h"

// SDK
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSASpeakMessageCell ()

// Data
@property (nonatomic, assign) CGFloat cellWidth; // cell宽度
@property (nonatomic, strong) NSString *loginUserId; // 用户的聊天室userId
@property (nonatomic, assign) PLVChatMsgState msgState; // 消息状态

// UI
@property (nonatomic, strong) PLVChatTextView *textView; // 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; // 背景气泡
@property (nonatomic, strong) PLVSAProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图
@property (nonatomic, strong) UIButton *resendButton; // 重发按钮
@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicatorView; // 正在发送提示视图

@end

static NSString *KEYPATH_MSGSTATE = @"msgState";

@implementation PLVSASpeakMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = self.allowCopy = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.prohibitWordTipView];
        [self.contentView addSubview:self.resendButton];
        [self.contentView addSubview:self.sendingIndicatorView];
        
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
    CGFloat xPadding = 8.0; // 气泡与textView的左右内间距
    CGFloat yPadding = -4.0; // 气泡与textView的上下内间距
    CGFloat resendWidth = 8 + 16;
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2 - resendWidth;
    
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(xPadding, 4, textViewSize.width, textViewSize.height);
    
    CGSize bubbleSize = CGSizeMake(textViewSize.width + xPadding * 2, textViewSize.height + yPadding * 2);
    
    if ([self.model isProhibitMsg] &&
        !self.model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVSASpeakMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVSASpeakMessageCell prohibitWordTipWithModel:self.model]];
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        self.prohibitWordTipView.frame = CGRectMake(xPadding, CGRectGetMaxY(self.textView.frame), tipSize.width + xPadding * 2, tipSize.height + 20);
    } else {
        self.prohibitWordTipView.frame = CGRectZero;
    }
    
    if (bubbleSize.height <= 25) {
        self.bubbleView.frame = CGRectMake(0, 8, ceilf(bubbleSize.width), 25);
        self.bubbleView.layer.cornerRadius = 12.5;
    } else {
        self.bubbleView.frame = CGRectMake(0, 8, ceilf(bubbleSize.width), bubbleSize.height);
        self.bubbleView.layer.cornerRadius = 8.0;
    }
    // 重发按钮
    self.resendButton.frame = CGRectMake(CGRectGetMaxX(self.bubbleView.frame) + 8,   (self.bubbleView.frame.size.height - 16) / 2 + self.bubbleView.frame.origin.y, 16, 16);
    // 发送中小菊花
    self.sendingIndicatorView.frame = self.resendButton.frame;
    
}

- (void)customCopy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    PLVSpeakMessage *message = self.model.message;
    pasteboard.string = message.content;
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVSASpeakMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
   
    self.cellWidth = cellWidth;
    self.model = model;
    // KVO
    [self removeObserveMsgState];
    [self addObserveMsgState];
    
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }

    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVSASpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:self.loginUserId prohibitWord:model.prohibitWord];
    
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
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
    if (![PLVSASpeakMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    CGFloat xPadding = 8.0; // 气泡与textView的左右内间距
    CGFloat resendWidth = 8 + 16;
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2 - resendWidth;
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVSASpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:loginUserId prohibitWord:model.prohibitWord];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    // 严禁词高度
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVSASpeakMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVSASpeakMessageCell prohibitWordTipWithModel:model]];
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        contentLabelSize.height += tipSize.height + 20;
    }
    CGFloat bubbleHeight = 8 + contentLabelSize.height + 4;
    bubbleHeight = ceilf(bubbleHeight);
    
    bubbleHeight = MAX(25, bubbleHeight);
    return bubbleHeight + 8;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVSpeakMessage class]]) { // 文本消息
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

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
    }
    return _textView;
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

#pragma mark AttributedString
/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVSpeakMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId prohibitWord:(NSString *)prohibitWord{
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

/// 获取严禁词提示多属性文本
+ (NSAttributedString *)contentLabelAttributedStringWithProhibitWordTip:(NSString *)prohibitTipString{
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *color = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.6];
    
    NSDictionary *AttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: color};
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:prohibitTipString attributes:AttDict];
    
    return attributed;
}

#pragma mark Data Mode
+ (NSString *)prohibitWordTipWithModel:(PLVChatModel *)model {
    return [NSString stringWithFormat:@"你的聊天信息中含有违规词：%@", model.prohibitWord];
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
    if (self.resendHandler &&
        self.msgState == PLVChatMsgStateFail) {
        if ([self.model content]) {
            __weak typeof(self) weakSelf = self;
            [PLVSAUtils showAlertWithMessage:@"重发该消息？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
                weakSelf.model.msgState = PLVChatMsgStateSending;
                weakSelf.resendHandler([self.model content]);
            }];
        }
        
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

@end
