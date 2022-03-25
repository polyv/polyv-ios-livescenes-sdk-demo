//
//  PLVLCLandscapeSpeakCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLandscapeSpeakCell.h"
#import "PLVChatTextView.h"
#import "PLVEmoticonManager.h"
#import <PLVLiveScenesSDK/PLVSpeakMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLCLandscapeSpeakCell ()

#pragma mark 数据

@property (nonatomic, strong) PLVChatModel *model; /// 消息数据模型
@property (nonatomic, assign) CGFloat cellWidth; /// cell宽度
@property (nonatomic, strong) NSString *loginUserId; /// 登录用户的聊天室userId

#pragma mark UI

@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡

@end

@implementation PLVLCLandscapeSpeakCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
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
    self.bubbleView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _bubbleView.layer.cornerRadius = 14.0;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.showMenu = YES;
    }
    return _textView;
}

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeSpeakCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLCLandscapeSpeakCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:self.loginUserId];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
}

#pragma mark UI - ViewModel

/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVSpeakMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId {
    UIFont *font = [UIFont systemFontOfSize:14.0];
    NSString *nickNameColorHexString = [user isUserSpecial] ? @"#FFD36D" : @"#6DA7FF";
    UIColor *nickNameColor = [PLVColorUtil colorFromHexString:nickNameColorHexString];
    UIColor *contentColor = [UIColor whiteColor];
    
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
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:[UIFont systemFontOfSize:22.0]];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    return contentLabelString;
}

#pragma mark - 高度计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeSpeakCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2;
    
    PLVSpeakMessage *message = (PLVSpeakMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLCLandscapeSpeakCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:loginUserId];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat bubbleHeight = 4 + contentLabelSize.height + 4; // content文本与气泡的内部有上下间距4
    
    return bubbleHeight + 5; // 气泡底部外间距为5
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

@end
