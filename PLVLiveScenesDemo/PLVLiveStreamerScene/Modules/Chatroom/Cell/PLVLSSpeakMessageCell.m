//
//  PLVLSSpeakMessageCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/18.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSpeakMessageCell.h"
#import "PLVChatModel.h"
#import "PLVChatTextView.h"
#import "PLVEmoticonManager.h"
// 工具类
#import "PLVLSUtils.h"

#import <PLVLiveScenesSDK/PLVSpeakMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLSSpeakMessageCell ()

#pragma mark 数据

@property (nonatomic, assign) CGFloat cellWidth; /// cell宽度
@property (nonatomic, strong) NSString *loginUserId; /// 登录用户的聊天室userId

#pragma mark UI

@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡
@property (nonatomic, strong) UIView *lineView;   /// 严禁词分割线
@property (nonatomic, strong) UILabel *prohibitWordTipLabel;  /// 严禁词提示

@end

@implementation PLVLSSpeakMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = self.allowCopy = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.lineView];
        [self.contentView addSubview:self.prohibitWordTipLabel];
        
    }
    return self;
}

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat yPadding = -4.0; // 气泡与textView的上下内间距
    
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(xPadding, yPadding, textViewSize.width, textViewSize.height);
    
    CGSize bubbleSize = CGSizeMake(textViewSize.width + xPadding * 2, textViewSize.height + yPadding * 2);
    
    if ([self.model isProhibitMsg]) {
        self.lineView.frame = CGRectMake(xPadding, CGRectGetMaxY(self.textView.frame), textViewSize.width, 1);
        CGSize labelViewSize = [self.prohibitWordTipLabel sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
        self.prohibitWordTipLabel.frame = CGRectMake(xPadding, CGRectGetMaxY(self.lineView.frame) + 4,  labelViewSize.width, labelViewSize.height);
        
        bubbleSize = CGSizeMake(MAX(bubbleSize.width, CGRectGetMaxX(self.prohibitWordTipLabel.frame) +4), bubbleSize.height + ceilf(labelViewSize.height) + 1 + 4 + 4 + 4);
    }
    
    if (bubbleSize.height <= 25) {
        self.bubbleView.frame = CGRectMake(0, 0, ceilf(bubbleSize.width), 25);
        self.bubbleView.layer.cornerRadius = 12.5;
    } else {
        self.bubbleView.frame = CGRectMake(0, 0, ceilf(bubbleSize.width), bubbleSize.height);
        self.bubbleView.layer.cornerRadius = 8.0;
    }
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
    }
    return _textView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.hidden = YES;
        _lineView.backgroundColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.2];
    }
    return  _lineView;
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
    NSMutableAttributedString *contentLabelString = [PLVLSSpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:self.loginUserId prohibitWord:model.prohibitWord];
    
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
    
    // 严禁词提示
    if ([model isProhibitMsg]) {
        self.lineView.hidden = NO;
        self.prohibitWordTipLabel.hidden = NO;
        
        self.prohibitWordTipLabel.text = [PLVLSSpeakMessageCell prohibitWordTipWithModel:model];
    }else{
        self.lineView.hidden = YES;
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

/// 获取严禁词提示多属性文本
+ (NSAttributedString *)contentLabelAttributedStringWithProhibitWordTip:(NSString *)prohibitTipString{
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *color = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.6];
    
    NSDictionary *AttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: color};
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
    NSMutableAttributedString *contentLabelString = [PLVLSSpeakMessageCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:loginUserId prohibitWord:model.prohibitWord];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    // 严禁词高度
    if ([model isProhibitMsg]) {
        NSAttributedString *attri = [PLVLSSpeakMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSSpeakMessageCell prohibitWordTipWithModel:model]];
        CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        CGFloat lineViewHeight = 4+1+4;
        contentLabelSize.height += lineViewHeight + tipSize.height + 4;
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
}

#pragma mark - Utils

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

+ (NSString *)prohibitWordTipWithModel:(PLVChatModel *)model {
    return [NSString stringWithFormat:@"你的聊天信息中含有违规词：%@", model.prohibitWord];
}

@end
