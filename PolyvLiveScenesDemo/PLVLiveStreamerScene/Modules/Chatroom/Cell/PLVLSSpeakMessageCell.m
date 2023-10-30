//
//  PLVLSSpeakMessageCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/18.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSpeakMessageCell.h"

// 工具类
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVToast.h"

// UI
#import "PLVChatTextView.h"
#import "PLVLSProhibitWordTipView.h"

// 模块
#import "PLVChatModel.h"
#import "PLVEmoticonManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSSpeakMessageCell ()

#pragma mark UI
@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡
@property (nonatomic, strong) PLVLSProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图
@property (nonatomic, strong) UIButton *prohibitWordTipButton; // 严禁词提示按钮

#pragma mark 数据
@property (nonatomic, assign) CGFloat cellWidth; /// cell宽度
@property (nonatomic, strong) NSString *loginUserId; /// 登录用户的聊天室userId

@end

@implementation PLVLSSpeakMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = self.allowCopy = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.prohibitWordTipButton];
    }
    return self;
}

// cell 复用前清除数据
- (void)prepareForReuse {
    [super prepareForReuse];
    if (_prohibitWordTipView) {
        [self.prohibitWordTipView dismiss];
    }
}

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat yPadding = -4.0; // 气泡与textView的上下内间距
    
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2;
    if (self.model.isProhibitMsg) {
        maxTextViewWidth = maxTextViewWidth - 6 - 16;
    }
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(xPadding, yPadding, textViewSize.width, textViewSize.height);
    
    CGSize bubbleSize = CGSizeMake(ceilf(textViewSize.width + xPadding * 2), textViewSize.height + yPadding * 2);
    if (self.model.isProhibitMsg) {
        bubbleSize = CGSizeMake(bubbleSize.width + 6 + 16, bubbleSize.height);
    }
    bubbleSize.width = ceilf(bubbleSize.width);
    if ([self.model isProhibitMsg] &&
        !self.model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVLSSpeakMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSSpeakMessageCell prohibitWordTipWithModel:self.model]];
        CGSize maxSize = CGSizeMake(bubbleSize.width, CGFLOAT_MAX);
        CGSize tipSize = [attri boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        tipSize.width = MIN(tipSize.width + 16, bubbleSize.width); // 适配换行时
        self.prohibitWordTipView.frame = CGRectMake(bubbleSize.width - tipSize.width, CGRectGetMaxY(self.textView.frame), tipSize.width, tipSize.height + 20 + 8);
    } else {
        self.prohibitWordTipView.frame = CGRectZero;
    }
    
    if (bubbleSize.height <= 25) {
        self.bubbleView.frame = CGRectMake(0, 0, bubbleSize.width, 25);
        self.bubbleView.layer.cornerRadius = 12.5;
    } else {
        self.bubbleView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
        self.bubbleView.layer.cornerRadius = 8.0;
    }
    self.prohibitWordTipButton.frame = CGRectMake(CGRectGetMaxX(self.textView.frame) + 6, (self.bubbleView.frame.size.height - 16 ) / 2, 16, 16);
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.4];
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [_textView addGestureRecognizer:tapGesture];
    }
    return _textView;
}

- (PLVLSProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVLSProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
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

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLSSpeakMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLSSpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:self.loginUserId prohibitWord:model.prohibitWord isRemindMsg:model.isRemindMsg];
    
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    
    // 严禁词提示
    if ([model isProhibitMsg] &&
        !model.prohibitWordTipIsShowed) {
    
        self.prohibitWordTipView.hidden = NO;
        [self.prohibitWordTipView setTipType:PLVLSProhibitWordTipTypeText prohibitWord:model.prohibitWord];
        [self.prohibitWordTipView showWithSuperView:self.contentView];
        
        __weak typeof(self)weakSelf = self;
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

#pragma mark UI - ViewModel

/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVSpeakMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId prohibitWord:(NSString *)prohibitWord isRemindMsg:(BOOL)isRemindMsg {
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

/// 获取严禁词提示多属性文本
+ (NSAttributedString *)contentLabelAttributedStringWithProhibitWordTip:(NSString *)prohibitTipString{
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *color = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.6];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByCharWrapping; //适配特殊字符，默认的NSLineBreakByWordWrapping遇到特殊字符会提前换行
    
    NSDictionary *AttDict = @{NSFontAttributeName: font,
                              NSForegroundColorAttributeName: color, NSParagraphStyleAttributeName : style};
    
    
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:prohibitTipString attributes:AttDict];
    
    return attributed;
}

#pragma mark - 高度计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLSSpeakMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2;
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLSSpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:loginUserId prohibitWord:model.prohibitWord isRemindMsg:model.isRemindMsg];
    if (model.isProhibitMsg) {
        maxTextViewWidth = maxTextViewWidth - 6 - 16;
    }
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;

    // 严禁词高度
    if (model.isProhibitMsg &&
        !model.prohibitWordTipIsShowed) {
        
        NSAttributedString *attri = [PLVLSSpeakMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSSpeakMessageCell prohibitWordTipWithModel:model]];
        CGFloat maxWidth = xPadding * 2 + contentLabelSize.width + 6 + 16;
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        contentLabelSize.height += tipSize.height + 20 + 8 + 2;
    }
    CGFloat bubbleHeight = 4 + contentLabelSize.height + 4; // content文本与气泡的内部有上下间距4
    bubbleHeight = ceilf(bubbleHeight);
    
    bubbleHeight = MAX(25, bubbleHeight);
    return bubbleHeight + 4; // 气泡底部外间距为4
}

#pragma mark - Action

- (void)customCopy:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    PLVSpeakMessage *message = self.model.message;
    pasteboard.string = message.content;
    [PLVToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:[PLVLSUtils sharedUtils].homeVC.view afterDelay:3.0];
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

#pragma mark - Utils

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (message &&
        [message isKindOfClass:[PLVSpeakMessage class]]) {
        return model.contentLength == PLVChatMsgContentLength_0To500;
    } else {
        return NO;
    }
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

@end
