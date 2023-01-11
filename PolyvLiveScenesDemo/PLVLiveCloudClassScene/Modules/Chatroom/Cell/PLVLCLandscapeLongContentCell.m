//
//  PLVLCLandscapeLongContentCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/17.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCLandscapeLongContentCell.h"
#import "PLVChatTextView.h"
#import "PLVEmoticonManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kMaxFoldedContentHeight = 127.0;
static CGFloat kButtonoHeight = 34.0;

@interface PLVLCLandscapeLongContentCell ()

#pragma mark 数据

@property (nonatomic, strong) PLVChatModel *model; /// 消息数据模型
@property (nonatomic, assign) CGFloat cellWidth; /// cell宽度

#pragma mark UI

@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡
@property (nonatomic, strong) UIView *contentSepLine; /// 文本和按钮之间的分隔线
@property (nonatomic, strong) UIView *buttonSepLine; /// 两个按钮中间的分隔线
@property (nonatomic, strong) UIButton *copButton;
@property (nonatomic, strong) UIButton *foldButton;

@end

@implementation PLVLCLandscapeLongContentCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.contentSepLine];
        [self.contentView addSubview:self.buttonSepLine];
        [self.contentView addSubview:self.copButton];
        [self.contentView addSubview:self.foldButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat yPadding = -4.0; // 气泡与textView的上下内间距
    
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    
    CGSize contentLabelSize = [self.textView.attributedText boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat contentHeight = MIN(contentLabelSize.height, kMaxFoldedContentHeight);
    CGFloat textViewHeight = 8 + contentHeight + 8; // textView文本与textView的内部有上下间距8
    self.textView.frame = CGRectMake(xPadding, yPadding, textViewSize.width, textViewHeight);
    
    // textView文本与textView的内部不存在左右间距，所以气泡与textView不等宽
    // textView文本与textView的内部已有上下间距8，按钮上部与textView下部会有4pt的重叠
    CGSize bubbleSize = CGSizeMake(textViewSize.width + xPadding * 2, textViewHeight + yPadding * 2 + kButtonoHeight);
    self.bubbleView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
    
    // 横的分割线跟气泡左右间隔8pt
    self.contentSepLine.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) + 8, CGRectGetMaxY(self.textView.frame) + yPadding, bubbleSize.width - 8 * 2, 1);
    self.buttonSepLine.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) + bubbleSize.width / 2.0 - 0.5, CGRectGetMaxY(self.contentSepLine.frame) + 10.5, 1, 15);
    
    CGSize buttonSize = CGSizeMake(CGRectGetWidth(self.bubbleView.frame)/ 2.0, kButtonoHeight);
    self.copButton.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame), CGRectGetMaxY(self.bubbleView.frame) - buttonSize.height, buttonSize.width, buttonSize.height);
    self.foldButton.frame = CGRectMake(CGRectGetMaxX(self.copButton.frame), CGRectGetMinY(self.copButton.frame), buttonSize.width, buttonSize.height);
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeLongContentCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    
    NSMutableAttributedString *contentLabelString = [PLVLCLandscapeLongContentCell contentLabelAttributedStringWithModel:model loginUserId:loginUserId];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeLongContentCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2;
    
    NSMutableAttributedString *contentLabelString = [PLVLCLandscapeLongContentCell contentLabelAttributedStringWithModel:model loginUserId:loginUserId];
    CGSize contentLabelSize = [contentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat contentHeight = MIN(contentLabelSize.height, kMaxFoldedContentHeight);
    CGFloat bubbleHeight = 4 + contentHeight + 4 + kButtonoHeight; // content文本与气泡的内部有上下间距4
    
    return bubbleHeight + 5; // 气泡底部外间距为5
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
+ (NSMutableAttributedString *)contentLabelAttributedStringWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId {
    PLVChatUser *user = model.user;
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
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:model.content attributes:contentAttDict];
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:[UIFont systemFontOfSize:22.0]];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    return contentLabelString;
}

#pragma mark Getter

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
        _textView.showMenu = NO;
        _textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
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
        [_copButton setTitle:@"复制" forState:UIControlStateNormal];
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
        [_foldButton setTitle:@"更多" forState:UIControlStateNormal];
        _foldButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC" alpha:0.8] forState:UIControlStateNormal];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC"] forState:UIControlStateHighlighted];
        [_foldButton addTarget:self action:@selector(foldButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _foldButton;
}

#pragma mark - [ Event ]

#pragma mark Action

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

@end
