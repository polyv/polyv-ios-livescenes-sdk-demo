//
//  PLVECCustomIntroductionMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/07/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVECCustomIntroductionMessageCell.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVCustomIntroductionMessage.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECCustomIntroductionMessageCell ()

#pragma mark 数据

/// 消息数据模型
@property (nonatomic, strong) PLVCustomIntroductionMessage *customIntroductionMessage;

@end

@implementation PLVECCustomIntroductionMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // 设置bubbleView的属性（覆盖基类的默认样式）
        self.bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#333333" alpha:0.66];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!self.model || self.cellWidth == 0) {
        return;
    }
    
    // 按照PLVECChatCell的布局规则
    CGFloat originX = 8.0;
    CGFloat originY = 4.0;
    CGFloat bubbleWidth = 0;
    
    // 通知消息布局
    CGFloat labelWidth = self.cellWidth - originX * 2;
    CGSize chatLabelSize = [self.chatLabel sizeThatFits:CGSizeMake(labelWidth, MAXFLOAT)];
    CGFloat chatLabelHeight = ceil(chatLabelSize.height);
    CGFloat chatLabelWidth = ceil(chatLabelSize.width);
    self.chatLabel.frame = CGRectMake(originX, originY, chatLabelWidth, chatLabelHeight);
    
    originY += chatLabelHeight + 4;
    bubbleWidth = MIN(chatLabelWidth + originX * 2, self.cellWidth);
    
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, originY);
}

#pragma mark - [ Public Methods ]

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model cellWidth:cellWidth];
    
    if (![PLVECCustomIntroductionMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        self.chatLabel.text = @"";
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    self.customIntroductionMessage = model.message;
    
    // 设置通知内容
    NSMutableAttributedString *contentLabelString;
    if (model.attributeString) {
        contentLabelString = model.attributeString;
    } else {
        contentLabelString = [PLVECCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
        model.attributeString = contentLabelString;
    }
    
    self.chatLabel.attributedText = contentLabelString;
}

#pragma mark - UI - ViewModel

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
    UIFont *contentFont = [UIFont systemFontOfSize:12.0];
    UIColor *contentColor = [UIColor whiteColor];
    NSDictionary *contentAttributeDict = @{
                                           NSFontAttributeName: contentFont,
                                           NSForegroundColorAttributeName: contentColor
    };
    NSAttributedString *contentString = [[NSAttributedString alloc] initWithString:content attributes:contentAttributeDict];
    
    // 组合通知标签和内容
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    // 添加通知标签图片
    UIImage *notificationImage = [PLVECCustomIntroductionMessageCell notificationImage];
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
    if (![PLVECCustomIntroductionMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    // 按照PLVECChatCell的高度计算规则
    CGFloat originX = 8.0;
    CGFloat originY = 4.0;
    
    CGFloat labelWidth = cellWidth - originX * 2;
    NSMutableAttributedString *attributedString = [PLVECCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
    
    UILabel *tmpLabel = [[UILabel alloc] init];
    tmpLabel.numberOfLines = 0;
    tmpLabel.textAlignment = NSTextAlignmentLeft;
    tmpLabel.attributedText = attributedString;
    CGSize textSize = [tmpLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    
    CGFloat chatLabelHeight = ceil(textSize.height);
    originY += chatLabelHeight + 4;
    
    return originY + 4;
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

/// 生成通知标签图片
+ (UIImage *)notificationImage {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont boldSystemFontOfSize:10];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 7;
    label.layer.masksToBounds = YES;
    label.text = PLVLocalizedString(@"通知");
    label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    
    NSString *notificationText = PLVLocalizedString(@"通知");
    CGSize size;
    if (notificationText &&
        [notificationText isKindOfClass:[NSString class]] &&
        notificationText.length > 0) {
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:notificationText attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:10]}];
        size = [attr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 14) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
        size.width += 10;
    }
    label.frame = CGRectMake(0, 0, size.width, 14);
    
    // 使用PLVImageUtil生成图片
    UIImage *image = [PLVImageUtil imageFromUIView:label opaque:NO scale:[UIScreen mainScreen].scale];
    
    return image;
}

@end 
