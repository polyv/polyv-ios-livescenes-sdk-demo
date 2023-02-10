//
//  PLVLCLongContentMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCLongContentMessageCell.h"
#import "PLVChatTextView.h"
#import "PLVEmoticonManager.h"
#import "PLVPhotoBrowser.h"
#import "PLVLCUtils.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kMaxFoldedContentHeight = 336.0;
static CGFloat kButtonoHeight = 40.0;

@interface PLVLCLongContentMessageCell ()

@property (nonatomic, strong) UILabel *quoteNickLabel; /// 被引用的用户昵称
@property (nonatomic, strong) UILabel *quoteContentLabel; /// 被引用的消息文本（如果为图片消息，label不可见）
@property (nonatomic, strong) UIImageView *quoteImageView; /// 被引用的消息图片（如果为文本消息，imageView不可见）
@property (nonatomic, strong) UIView *quoteLine; /// 引用消息与回复消息分割线
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡
@property (nonatomic, strong) UIView *buttonSepLine; /// 两个按钮中间的分隔线
@property (nonatomic, strong) UIButton *copButton;
@property (nonatomic, strong) UIButton *foldButton;

@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 聊天消息图片Browser

@end

@implementation PLVLCLongContentMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.quoteNickLabel];
        [self.contentView addSubview:self.quoteContentLabel];
        [self.contentView addSubview:self.quoteImageView];
        [self.contentView addSubview:self.quoteLine];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.buttonSepLine];
        [self.contentView addSubview:self.copButton];
        [self.contentView addSubview:self.foldButton];
        
        [self.textView.layer addSublayer:self.gradientLayer];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = self.nickLabel.frame.origin.x;
    CGFloat originY =  self.nickLabel.frame.origin.y + 20;
    
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 头像左间距，气泡右间距
    CGFloat bubbleXPadding = 12;//textView与bubble的内部左右间距均为12
    CGFloat maxTextViewWidth = self.cellWidth - originX - xPadding - bubbleXPadding * 2;
    
    CGFloat quoteHeight = 0;
    if ([self.model.message isKindOfClass:[PLVQuoteMessage class]]) {
        originY += 8; //被引用消息的用户昵称文本与bubble的内部上间距为8
        CGSize quoteNickSize = [self.quoteNickLabel.attributedText boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        self.quoteNickLabel.frame = CGRectMake(originX + bubbleXPadding, originY, quoteNickSize.width, 18);
        originY += 18 + 5; //被引用消息的用户昵称文本与被引用消息文本/图片的间距为5
        
        if (!self.quoteContentLabel.hidden) { // 被引用消息文本最多显示2行，故最大高度为44
            CGSize quoteContentLabelSize = [self.quoteContentLabel.attributedText boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
            self.quoteContentLabel.frame = CGRectMake(originX + bubbleXPadding, originY, quoteContentLabelSize.width, quoteContentLabelSize.height);
            originY += quoteContentLabelSize.height;
        }
        
        if (!self.quoteImageView.hidden) {
            CGSize quoteImageViewSize = [PLVLCLongContentMessageCell calculateImageViewSizeWithMessage:self.model.message];
            self.quoteImageView.frame = CGRectMake(originX + bubbleXPadding, originY, quoteImageViewSize.width, quoteImageViewSize.height);
            originY += quoteImageViewSize.height;
        }
        
        originY += bubbleXPadding;
        self.quoteLine.frame = CGRectMake(originX+ bubbleXPadding, originY, 0, 1); // 最后再设置分割线宽度
        
        quoteHeight = CGRectGetMinY(self.quoteLine.frame) - CGRectGetMinY(self.quoteNickLabel.frame);
    }
    
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    
    NSMutableAttributedString *contentLabelString = [PLVLCLongContentMessageCell contentLabelAttributedStringWithModel:self.model];
    CGSize contentLabelSize = [[contentLabelString copy] boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat contentHeight = MIN(contentLabelSize.height, kMaxFoldedContentHeight);
    
    CGFloat textViewHeight = 8 + contentHeight + 8; // textView文本与textView的内部有上下间距8
    
    self.textView.frame = CGRectMake(originX + bubbleXPadding, originY, textViewSize.width, textViewHeight);
    
    // textView文本与textView的内部不存在左右间距，所以气泡与textView不等宽
    // textView文本与textView的内部已有上下间距8，按钮上部与textView下部会有14pt的重叠
    CGSize bubbleSize = CGSizeMake(self.textView.frame.size.width + bubbleXPadding * 2, self.textView.frame.size.height + kButtonoHeight - 14 + quoteHeight);
    self.bubbleView.frame = CGRectMake(originX, self.nickLabel.frame.origin.y + 20, bubbleSize.width, bubbleSize.height);
    
    // 绘制气泡外部曲线
    CAShapeLayer *maskLayer = [PLVLCMessageCell bubbleLayerWithSize:bubbleSize];
    self.bubbleView.layer.mask = maskLayer;
    
    CGSize lineSize = CGSizeMake(1.0, 14.0);
    self.buttonSepLine.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) + CGRectGetWidth(self.bubbleView.frame)/ 2.0 - lineSize.width/2.0, CGRectGetMaxY(self.bubbleView.frame) - 27.0, lineSize.width, lineSize.height);
    
    CGSize buttonSize = CGSizeMake(CGRectGetWidth(self.bubbleView.frame)/ 2.0, kButtonoHeight);
    self.copButton.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame), CGRectGetMaxY(self.bubbleView.frame) - buttonSize.height, buttonSize.width, buttonSize.height);
    self.foldButton.frame = CGRectMake(CGRectGetMaxX(self.copButton.frame), CGRectGetMinY(self.copButton.frame), buttonSize.width, buttonSize.height);
    
    self.gradientLayer.frame = self.textView.bounds;
    
    if (!self.quoteLine.hidden) {
        CGRect lineRect = self.quoteLine.frame;
        self.quoteLine.frame = CGRectMake(lineRect.origin.x, lineRect.origin.y, CGRectGetWidth(self.bubbleView.frame) - bubbleXPadding * 2, lineRect.size.height);
    }
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model loginUserId:loginUserId cellWidth:cellWidth];
    
    if (self.cellWidth == 0 || ![PLVLCLongContentMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    
    if ([model.message isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)model.message;
        self.quoteNickLabel.hidden = NO;
        self.quoteLine.hidden = NO;
        
        NSAttributedString *quoteNickLabelString = [PLVLCLongContentMessageCell quoteNickAttributedStringWithMessage:quoteMessage loginUserId:loginUserId];
        self.quoteNickLabel.attributedText = quoteNickLabelString;
        
        NSAttributedString *quoteContentLabelString = [PLVLCLongContentMessageCell quoteContentAttributedStringWithMessage:quoteMessage];
        self.quoteContentLabel.attributedText = quoteContentLabelString;
        self.quoteContentLabel.hidden = !quoteContentLabelString;
        
        NSURL *quoteImageURL = [PLVLCLongContentMessageCell quoteImageURLWithMessage:quoteMessage];
        self.quoteImageView.hidden = !quoteImageURL;
        if (quoteImageURL) {
            UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
            [PLVLCUtils setImageView:self.quoteImageView url:quoteImageURL placeholderImage:placeHolderImage options:SDWebImageRetryFailed];
        }
    } else {
        self.quoteNickLabel.hidden = YES;
        self.quoteContentLabel.hidden = YES;
        self.quoteImageView.hidden = YES;
        self.quoteLine.hidden = YES;
    }
    
    NSMutableAttributedString *contentLabelString = [PLVLCLongContentMessageCell contentLabelAttributedStringWithModel:model];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    CGFloat cellHeight = [super cellHeightWithModel:model cellWidth:cellWidth];
    if (cellHeight == 0 || ![PLVLCLongContentMessageCell isModelValid:model]) {
        return 0;
    }
    
    CGFloat originX = 64.0; // 64 为气泡初始x值
    CGFloat originY = 28.0; // 64 为气泡初始y值
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 头像左间距，气泡右间距
    CGFloat bubbleXPadding = 12;//textView与bubble的内部左右间距均为12
    CGFloat maxTextViewWidth = cellWidth - originX - xPadding - bubbleXPadding * 2;
    
    NSMutableAttributedString *contentLabelString = [PLVLCLongContentMessageCell contentLabelAttributedStringWithModel:model];
    CGSize contentLabelSize = [[contentLabelString copy] boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat contentHeight = MIN(contentLabelSize.height, kMaxFoldedContentHeight);
    CGFloat textViewHeight = 8 + contentHeight + 8; // textView文本与textView的内部有上下间距8
    cellHeight = originY + textViewHeight + kButtonoHeight - 14 + 16; // 按钮上部与textView下部会有14pt的重叠, 16为气泡底部外间距
    
    if ([model.message isKindOfClass:[PLVQuoteMessage class]]) {
        PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)model.message;
        CGFloat quoteNickHeight = 18; // quoteNickHeight为被引用消息用户昵称文本高度
        CGFloat quoteContentHeight = 0; // quoteContentHeight为被引用消息文本或图片高度
        NSAttributedString *quoteContentLabelString = [PLVLCLongContentMessageCell quoteContentAttributedStringWithMessage:quoteMessage];
        NSURL *quoteImageURL = [PLVLCLongContentMessageCell quoteImageURLWithMessage:quoteMessage];
        if (quoteContentLabelString) {
            CGSize quoteContentSize = [quoteContentLabelString boundingRectWithSize:CGSizeMake(maxTextViewWidth, 44) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
            quoteContentHeight = quoteContentSize.height;
        } else if (quoteImageURL) {
            CGSize quoteImageViewSize = [PLVLCLongContentMessageCell calculateImageViewSizeWithMessage:quoteMessage];
            quoteContentHeight = quoteImageViewSize.height;
        }
        cellHeight += 8 + quoteNickHeight + 5 + quoteContentHeight + bubbleXPadding;
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
+ (NSMutableAttributedString *)contentLabelAttributedStringWithModel:(PLVChatModel *)model {
    NSString *content = model.content;
    NSString *colorHexString = [model.user isUserSpecial] ? @"#78A7ED" : @"#ADADC0";
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:colorHexString]
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:attributedString font:[UIFont systemFontOfSize:22.0]];
    return emojiAttributedString;
}

/// 获取被引用的消息用户昵称的多属性文本
+ (NSAttributedString *)quoteNickAttributedStringWithMessage:(PLVQuoteMessage *)message loginUserId:(NSString *)loginUserId {
    NSString *quoteUserName = message.quoteUserName;
    if (!quoteUserName || ![quoteUserName isKindOfClass:[NSString class]] || quoteUserName.length == 0) {
        return nil;
    }
    
    NSString *content = quoteUserName;
    NSString *quoteUserId = message.quoteUserId;
    if (quoteUserId && [quoteUserId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isEqualToString:quoteUserId]) {
        content = [content stringByAppendingString:@"（我）"];
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#777786"]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取被引用的消息的多属性文本
+ (NSAttributedString *)quoteContentAttributedStringWithMessage:(PLVQuoteMessage *)message {
    NSString *content = message.quoteContent;
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#777786"]
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:attributedString font:[UIFont systemFontOfSize:22.0]];
    return [emojiAttributedString copy];
}

/// 获取图片URL
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
    CGFloat maxLength = 60.0;
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

#pragma mark Getter

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#2B2C35" alpha:0].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#2B2C35" alpha:1].CGColor];
        _gradientLayer.locations = @[@0.85, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(0, 1);
    }
    return _gradientLayer;
}

- (UILabel *)quoteNickLabel {
    if (!_quoteNickLabel) {
        _quoteNickLabel = [[UILabel alloc] init];
    }
    return _quoteNickLabel;
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
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageViewAction)];
        [_quoteImageView addGestureRecognizer:tapGesture];
    }
    return _quoteImageView;
}

- (UIView *)quoteLine {
    if (!_quoteLine) {
        _quoteLine = [[UIView alloc] init];
        _quoteLine.backgroundColor = [UIColor colorWithWhite:0 alpha:0.18];
    }
    return _quoteLine;
}

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35"];
    }
    return _bubbleView;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _textView;
}

- (UIView *)buttonSepLine {
    if (!_buttonSepLine) {
        _buttonSepLine = [[UIView alloc] init];
        _buttonSepLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.3];
    }
    return _buttonSepLine;
}

- (UIButton *)copButton {
    if (!_copButton) {
        _copButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_copButton setTitle:@"复制" forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#ADADC0" alpha:0.8] forState:UIControlStateNormal];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#78A7ED"] forState:UIControlStateHighlighted];
        [_copButton addTarget:self action:@selector(copButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _copButton;
}

- (UIButton *)foldButton {
    if (!_foldButton) {
        _foldButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_foldButton setTitle:@"更多" forState:UIControlStateNormal];
        _foldButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#ADADC0" alpha:0.8] forState:UIControlStateNormal];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#78A7ED"] forState:UIControlStateHighlighted];
        [_foldButton addTarget:self action:@selector(foldButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _foldButton;
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

@end
