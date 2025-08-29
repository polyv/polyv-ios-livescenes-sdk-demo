//
//  PLVLCCustomIntroductionMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/07/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLCCustomIntroductionMessageCell.h"
#import "PLVChatTextView.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVCustomIntroductionMessage.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCCustomIntroductionMessageCell ()

#pragma mark 数据

/// 消息数据模型
@property (nonatomic, strong) PLVCustomIntroductionMessage *customIntroductionMessage;

#pragma mark UI

/// 通知内容视图
@property (nonatomic, strong) PLVChatTextView *textView;
/// 背景气泡
@property (nonatomic, strong) UIView *bubbleView;

@end


@implementation PLVLCCustomIntroductionMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    // 使用与高度计算相同的布局逻辑
    CGFloat originY = 8.0; // 通知消息的起始y位置
    CGFloat bubblePadding = 8;
    
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0;
    CGFloat originX = xPadding; // 通知消息从左边开始，不依赖头像位置
    CGFloat maxTextViewWidth = self.cellWidth - originX - xPadding - bubblePadding * 2;
    
    CGSize textSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, CGFLOAT_MAX)];
    
    self.textView.frame = CGRectMake(originX + bubblePadding, originY, textSize.width, textSize.height);
    
    CGSize bubbleSize = CGSizeMake(textSize.width + bubblePadding * 2, textSize.height);
    
    self.bubbleView.frame = CGRectMake(originX, originY, bubbleSize.width, bubbleSize.height);
    
    // 绘制气泡外部曲线 - 通知消息需要四个角都是圆角
    CAShapeLayer *maskLayer = [PLVLCCustomIntroductionMessageCell notificationBubbleLayerWithSize:bubbleSize];
    self.bubbleView.layer.mask = maskLayer;
}

#pragma mark - Getter

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
        _textView.textContainer.maximumNumberOfLines = 0;
        _textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return _textView;
}



#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model loginUserId:loginUserId cellWidth:cellWidth];
    
    if (self.cellWidth == 0 || ![PLVLCCustomIntroductionMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    
    // 隐藏头像和昵称，因为这是通知消息
    self.avatarImageView.hidden = YES;
    self.nickLabel.hidden = YES;
    
    self.customIntroductionMessage = model.message;
    
    NSMutableAttributedString *contentLabelString;
    if (model.attributeString) { // 如果在 model 中已经存在计算好的 消息多属性文本 ，那么 就直接使用；
        contentLabelString = model.attributeString;
    } else {
        contentLabelString = [PLVLCCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
        model.attributeString = contentLabelString;
    }
    
    [self.textView setContent:contentLabelString showUrl:NO];
}

#pragma mark UI - ViewModel

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(id)message {
    NSString *content = @"";
    if ([message isKindOfClass:[PLVCustomIntroductionMessage class]]) {
        PLVCustomIntroductionMessage *customIntroductionMessage = (PLVCustomIntroductionMessage *)message;
        content = customIntroductionMessage.content ?: @"";
    } else {
        content = (NSString *)message;
    }
    
    // 创建内容的富文本
    UIFont *contentFont = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0];
    UIColor *contentColor = [UIColor whiteColor];
    NSDictionary *contentAttributeDict = @{
                                           NSFontAttributeName: contentFont,
                                           NSForegroundColorAttributeName: contentColor
    };
    NSAttributedString *contentString = [[NSAttributedString alloc] initWithString:content attributes:contentAttributeDict];
    
    // 组合通知标签和内容
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    // 添加通知标签图片
    UIImage *notificationImage = [PLVLCCustomIntroductionMessageCell notificationImage];
    if (notificationImage) {
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = round(contentFont.capHeight - notificationImage.size.height)/2.0;
        attach.bounds = CGRectMake(0, paddingTop, notificationImage.size.width, notificationImage.size.height);
        attach.image = notificationImage;
        NSAttributedString *imageStr = [NSAttributedString attributedStringWithAttachment:attach];
        [attributedString appendAttributedString:imageStr];
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    
    [attributedString appendAttributedString:contentString];
    
    return attributedString;
}

#pragma mark - 高度计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    CGFloat cellHeight = [super cellHeightWithModel:model cellWidth:cellWidth];
    if (![PLVLCCustomIntroductionMessageCell isModelValid:model] || cellHeight == 0) {
        return 0;
    }
    
    CGFloat originY = 8.0; // 通知消息的起始y位置
    CGFloat bubblePadding = 8.0;
    
    // 计算文本高度
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0;
    CGFloat originX = xPadding; // 通知消息从左边开始，不依赖头像位置
    CGFloat maxTextViewWidth = cellWidth - originX - xPadding - bubblePadding * 2;
    
    // 生成富文本内容
    NSMutableAttributedString *attributedString = [PLVLCCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
    
    PLVChatTextView *tmpTextView = [[PLVChatTextView alloc] init];
    tmpTextView.textContainer.maximumNumberOfLines = 0;
    tmpTextView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    [tmpTextView setContent:attributedString showUrl:NO];
    CGSize textSize = [tmpTextView sizeThatFits:CGSizeMake(maxTextViewWidth, CGFLOAT_MAX)];
    
    CGFloat bubbleHeight = textSize.height;
    
    return originY + bubbleHeight + 16;
}

#pragma mark - Utils

/// 生成通知消息的气泡层 - 四个角都是圆角
+ (CAShapeLayer *)notificationBubbleLayerWithSize:(CGSize)size {
    UIRectCorner corners = UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight;
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    return maskLayer;
}

/// 生成通知标签图片
+ (UIImage *)notificationImage {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont boldSystemFontOfSize:10];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 8;
    label.layer.masksToBounds = YES;
    label.text = PLVLocalizedString(@"通知");
    label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    
    NSString *notificationText = PLVLocalizedString(@"通知");
    CGSize size;
    if (notificationText &&
        [notificationText isKindOfClass:[NSString class]] &&
        notificationText.length > 0) {
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:notificationText attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Medium" size:10]}];
        size = [attr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 14) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
        size.width += 12;
    }
    label.frame = CGRectMake(0, 0, size.width, 16);
    
    // 使用PLVImageUtil生成图片
    UIImage *image = [PLVImageUtil imageFromUIView:label opaque:NO scale:[UIScreen mainScreen].scale];
    
    return image;
}

#pragma mark - Utils

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVCustomIntroductionMessage class]]) {
        return NO;
    }
    return YES;
}

@end 
