//
//  PLVLSRemindSpeakMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSRemindSpeakMessageCell.h"

// 工具
#import "PLVLSUtils.h"
#import "PLVEmoticonManager.h"

// UI
#import "PLVChatTextView.h"
#import "PLVLSProhibitWordTipView.h"

// 模块
#import "PLVChatModel.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLSRemindSpeakMessageCell()<UITextViewDelegate>

#pragma mark  UI
@property (nonatomic, strong) PLVChatTextView *textView; // 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; // 背景气泡
@property (nonatomic, strong) PLVLSProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图
@property (nonatomic, strong) UIButton *resendButton; // 重发按钮
@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicatorView; // 正在发送提示视图
@property (nonatomic, strong) UIImageView *headerImageView; // 头像视图
@property (nonatomic, strong) UILabel *nickNameLabel;; // 昵称视图

#pragma mark 数据
@property (nonatomic, assign) CGFloat cellWidth; // cell宽度
@property (nonatomic, strong) NSString *loginUserId; // 用户的聊天室userId
@property (nonatomic, assign) PLVChatMsgState msgState; // 消息状态
@property (nonatomic, copy) NSString *previousUserId; // 上一条消息的用户Id

@end

#pragma mark 静态数据

static NSString *KEYPATH_MSGSTATE = @"msgState";
static NSString *otherCellId = @"PLVLSSpeakRemindMessageCell_Other";
static NSString *selfCellId = @"PLVLSSpeakRemindMessageCell_Self";

static CGFloat kCellTopMargin = 10;

@implementation PLVLSRemindSpeakMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        [self.contentView addSubview:self.headerImageView];
        [self.contentView addSubview:self.nickNameLabel];
        
        [self.contentView addSubview:self.bubbleView];
        [self.bubbleView addSubview:self.textView];
        [self.contentView addSubview:self.resendButton];
        [self.contentView addSubview:self.sendingIndicatorView];
        
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
    CGFloat xPadding = 8.0; // 气泡与textView的左右内间距
    CGFloat yPadding = -4.0; // 气泡与textView的上下内间距
    CGFloat resendWidth = 8 + 16;
    CGFloat headerWidth = 30;
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2 - resendWidth - headerWidth - xPadding;
    CGSize nickNameViewSize = CGSizeMake(maxTextViewWidth, 17);
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    // 最小宽度设为35
    CGSize bubbleSize = CGSizeMake(MAX(textViewSize.width + xPadding * 2, 35), textViewSize.height + yPadding * 2);
    NSAttributedString *attri = [PLVLSRemindSpeakMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSRemindSpeakMessageCell prohibitWordTipWithModel:self.model]];
    CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    tipSize = CGSizeMake(tipSize.width + xPadding * 2, tipSize.height + 20);
    
    CGFloat headerImageViewX;
    CGFloat nickNameLabelX;
    CGFloat bubbleViewX;
    CGFloat tipViewX;
    CGFloat nickNameLabelY = kCellTopMargin;
    
    // 自己的发言，右对齐
    if ([PLVLSRemindSpeakMessageCell isLoginUser:self.model.user.userId]) {
        headerImageViewX = self.cellWidth - headerWidth;
        nickNameLabelX = self.cellWidth - headerWidth - nickNameViewSize.width - xPadding;
        bubbleViewX = self.cellWidth - headerWidth - xPadding - bubbleSize.width;
        tipViewX = self.cellWidth - headerWidth - tipSize.width;
        self.nickNameLabel.textAlignment = NSTextAlignmentRight;
    } else { // 他人的发言，左对齐
        headerImageViewX = 0;
        nickNameLabelX = headerImageViewX + headerWidth + xPadding;
        bubbleViewX = nickNameLabelX;
        tipViewX = 0;
        self.nickNameLabel.textAlignment = NSTextAlignmentLeft;
    }
    
    if ([PLVFdUtil checkStringUseable:self.previousUserId] &&
        [self.previousUserId isEqualToString:self.model.user.userId]) {
        nickNameViewSize = CGSizeZero;
        headerWidth = 0;
        nickNameLabelY = 0;
    }
    
    self.headerImageView.frame = CGRectMake(headerImageViewX, kCellTopMargin, headerWidth, headerWidth);
    
    self.nickNameLabel.frame = CGRectMake(nickNameLabelX, nickNameLabelY, nickNameViewSize.width, nickNameViewSize.height);
    
    if (bubbleSize.height <= 32) { // 一行的高度
        self.bubbleView.frame = CGRectMake(bubbleViewX, CGRectGetMaxY(self.nickNameLabel.frame) + 4, ceilf(bubbleSize.width), 32);
    } else {// 大于一行的高度
        self.bubbleView.frame = CGRectMake(bubbleViewX, CGRectGetMaxY(self.nickNameLabel.frame) + 4, ceilf(bubbleSize.width), bubbleSize.height);
    }
    CGSize radiiSize = CGSizeMake(8, 8);
    UIRectCorner corners;
    if ([PLVLSRemindSpeakMessageCell isLoginUser:self.model.user.userId]) {
        corners = UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight;
    } else {
        corners = UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bubbleView.bounds byRoundingCorners:corners cornerRadii:radiiSize];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bubbleView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.bubbleView.layer.mask = maskLayer;
    
    CGFloat textPaddingY = (self.bubbleView.bounds.size.height - textViewSize.height) / 2;
    self.textView.frame = CGRectMake((ceilf(bubbleSize.width) -  textViewSize.width ) / 2, textPaddingY, textViewSize.width, textViewSize.height);
    
    if ([self.model isProhibitMsg] &&
        !self.model.prohibitWordTipIsShowed) {
        _prohibitWordTipView.frame = CGRectMake(tipViewX, CGRectGetMaxY(self.bubbleView.frame), tipSize.width, tipSize.height);
    } else {
        _prohibitWordTipView.frame = CGRectZero;
    }
    
    // 重发按钮
    self.resendButton.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) - 8 - 16,   (self.bubbleView.frame.size.height - 16) / 2 + self.bubbleView.frame.origin.y, 16, 16);
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
    if (!message || ![message isKindOfClass:[PLVSpeakMessage class]]) {
        return NO;
    }
    
    return YES;
}


#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth previousUserId:(NSString *)previousUserId {
    if (![PLVLSRemindSpeakMessageCell isModelValid:model] || cellWidth == 0) {
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
    
    self.previousUserId = previousUserId;
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLSRemindSpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:self.loginUserId prohibitWord:model.prohibitWord];
    
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    // 重发按钮是否隐藏
    self.msgState = model.msgState;
    
    // 严禁词提示
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
        [self.prohibitWordTipView setTipType:PLVLSProhibitWordTipTypeText prohibitWord:model.prohibitWord];
        [self.prohibitWordTipView showWithSuperView:self.contentView];
        
        __weak typeof(self)weakSelf = self;
        self.prohibitWordTipView.dismissBlock = ^{
            weakSelf.model.prohibitWordTipShowed = YES;
            if (weakSelf.prohibitWordTipDismissHandler) {
                weakSelf.prohibitWordTipDismissHandler();
            }
        };
    } else {
        self.prohibitWordTipView.hidden = YES;
    }
    
    // 设置昵称
    self.nickNameLabel.attributedText = [PLVLSRemindSpeakMessageCell nickNameLabelAttributedStringWithUser:model.user];
    
    // 加载头像
    [self loadImageWithModel:model];
    
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth previousUserId:(NSString *)previousUserId {
    if (![PLVLSRemindSpeakMessageCell isModelValid:model] ||
        cellWidth == 0 ||
        ![PLVFdUtil checkStringUseable:model.user.userId]) {
        return 0;
    }
    CGFloat xPadding = 8.0; // 气泡与textView的左右内间距
    CGFloat resendWidth = 8 + 16;
    CGFloat headerWidth = 30;
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2 - resendWidth - headerWidth - xPadding;
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLSRemindSpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:loginUserId prohibitWord:model.prohibitWord];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    // 严禁词高度
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVLSRemindSpeakMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSRemindSpeakMessageCell prohibitWordTipWithModel:model]];
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        contentLabelSize.height += tipSize.height + 20;
    }
    
    if (![PLVFdUtil checkStringUseable:previousUserId] ||
        ![model.user.userId isEqualToString:previousUserId]) {
        NSMutableAttributedString *nickNameLabelString = [PLVLSRemindSpeakMessageCell nickNameLabelAttributedStringWithUser:model.user];
        CGSize  nickNameLabelSize = [nickNameLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        contentLabelSize.height +=  nickNameLabelSize.height + 4;
        contentLabelSize.height += kCellTopMargin;
    }

    CGFloat bubbleHeight = 8 + contentLabelSize.height + 4;
    bubbleHeight = ceilf(bubbleHeight);
    
    bubbleHeight = MAX(32, bubbleHeight);
    return  bubbleHeight + 8;
}

#pragma mark - [ Private Method ]
#pragma mark Getter
- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#313540"];
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.delegate = self;
        _textView.font = [UIFont systemFontOfSize:12];
    }
    return _textView;
}

- (PLVLSProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVLSProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
}

- (UIButton *)resendButton {
    if (!_resendButton) {
        _resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_resendButton setImage:[PLVLSUtils imageForChatroomResource:@"plvls_chatroom_cell_icon_error"] forState:UIControlStateNormal];
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
        _nickNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
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

#pragma mark AttributedString

/// 获取昵称多属性文本
+ (NSMutableAttributedString *)nickNameLabelAttributedStringWithUser:(PLVChatUser *)user {
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: [PLVColorUtil colorFromHexString:@"#F0F1F5"]};
    NSMutableAttributedString *nickNameAttributedString = [[NSMutableAttributedString alloc] initWithString: user.userName attributes:nickNameAttDict];
    
    // 特殊身份头衔
    if (user.actor &&
        [user.actor isKindOfClass:[NSString class]] &&
        user.actor.length > 0 &&
        [PLVLSRemindBaseMessageCell showActorLabelWithUser:user]) {
        
        UIImage *image = [PLVLSRemindBaseMessageCell actorImageWithUser:user];
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

/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVSpeakMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId prohibitWord:(NSString *)prohibitWord{
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *contentColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:contentColor};
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:message.content attributes:contentAttDict];
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    
    // 含有严禁内容,添加提示图片
    if (prohibitWord && prohibitWord.length >0) {
        CGFloat paddingTop = font.lineHeight - font.pointSize;
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.bounds = CGRectMake(0, -ceilf(paddingTop), font.lineHeight, font.lineHeight);
        attachment.image = [PLVLSUtils imageForChatroomResource:@"plvls_chatroom_cell_icon_error"];
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

#pragma mark 加载头像
- (void)loadImageWithModel:(PLVChatModel *)model {
    PLVChatUser *user = model.user;
    
    UIImage *placeHolderImage = [PLVLSUtils imageForChatroomResource:@"PLVLS_chatroom_cell_image_placeholder"];
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
#pragma mark - [ Event ]
#pragma mark Action
- (void)resendButtonAction {
    // 只有在发送失败方可触发重发点击事件，避免重复发送
    if (self.msgState == PLVChatMsgStateFail) {
        __weak typeof(self) weakSelf = self;
        [PLVLSUtils showAlertWithMessage:@"重发该消息？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
            weakSelf.model.msgState = PLVChatMsgStateSending;
            if (weakSelf.resendHandler) {
                weakSelf.resendHandler(weakSelf.model);
            }
        }];
    } else {
        self.resendButton.hidden = YES;
    }
}

#pragma mark - [ KVO ]

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
