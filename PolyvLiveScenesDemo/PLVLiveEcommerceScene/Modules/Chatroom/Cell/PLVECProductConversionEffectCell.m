#import "PLVECProductConversionEffectCell.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>


static CGFloat const kPLVECConversionInnerHorizontalPadding = 8.0; // 与普通电商消息文本起点对齐
static CGFloat const kPLVECConversionInnerVerticalPadding = 4.0;
static CGFloat const kPLVECConversionLabelMinHeight = 19.0;
static CGFloat const kPLVECConversionBottomPadding = 4.0;

@interface PLVECProductConversionEffectCell ()

@property (nonatomic, assign) CGFloat leftInset;
@property (nonatomic, assign) CGFloat rightInset;

@end

@interface PLVECProductConversionEffectCell (ConversionLayout)

+ (NSAttributedString *)conversionAttributedStringWithModel:(PLVChatModel *)model maxLabelWidth:(CGFloat)maxLabelWidth;

@end

@implementation PLVECProductConversionEffectCell

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (![PLVECChatBaseCell isModelValid:model]) {
        return NO;
    }
    if (![model.message isKindOfClass:[PLVMessageEffectMessage class]]) {
        return NO;
    }
    PLVMessageEffectMessage *message = (PLVMessageEffectMessage *)model.message;
    return [message isProductClickEffectMessage];
}

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    [self updateWithModel:model cellWidth:cellWidth leftInset:0 rightInset:0];
}

- (void)updateWithModel:(PLVChatModel *)model
              cellWidth:(CGFloat)cellWidth
              leftInset:(CGFloat)leftInset
             rightInset:(CGFloat)rightInset {
    [super updateWithModel:model cellWidth:cellWidth];
    if (![PLVECProductConversionEffectCell isModelValid:model] || cellWidth == 0) {
        self.leftInset = 0;
        self.rightInset = 0;
        return;
    }
    
    self.model = model;
    self.cellWidth = cellWidth;
    self.allowCopy = NO;
    self.allowReply = NO;
    self.chatLabel.numberOfLines = 1;
    self.chatLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#10131E" alpha:0.9];
    self.bubbleView.layer.cornerRadius = 14.0;
    self.leftInset = MAX(leftInset, 0);
    self.rightInset = MAX(rightInset, 0);
    CGFloat maxBubbleWidth = MAX(cellWidth - self.leftInset - self.rightInset, 0);
    CGFloat labelWidth = MAX(maxBubbleWidth - kPLVECConversionInnerHorizontalPadding * 2, 0);
    self.chatLabel.attributedText = [PLVECProductConversionEffectCell conversionAttributedStringWithModel:model maxLabelWidth:labelWidth];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (![PLVECProductConversionEffectCell isModelValid:self.model] || self.cellWidth == 0) {
        return;
    }
    
    CGFloat safeLeftInset = MAX(self.leftInset, 0);
    CGFloat safeRightInset = MAX(self.rightInset, 0);
    CGFloat maxBubbleWidth = MAX(self.cellWidth - safeLeftInset - safeRightInset, 0);
    CGFloat labelWidth = MAX(maxBubbleWidth - kPLVECConversionInnerHorizontalPadding * 2, 0);
    self.chatLabel.attributedText = [PLVECProductConversionEffectCell conversionAttributedStringWithModel:self.model maxLabelWidth:labelWidth];
    CGSize size = [self.chatLabel sizeThatFits:CGSizeMake(labelWidth, MAXFLOAT)];
    CGFloat chatLabelWidth = MIN(ceil(size.width), labelWidth);
    CGFloat chatLabelHeight = MAX(ceil(size.height), kPLVECConversionLabelMinHeight);
    self.chatLabel.frame = CGRectMake(kPLVECConversionInnerHorizontalPadding, kPLVECConversionInnerVerticalPadding, chatLabelWidth, chatLabelHeight);
    CGFloat bubbleWidth = MIN(chatLabelWidth + kPLVECConversionInnerHorizontalPadding * 2, maxBubbleWidth);
    self.bubbleView.frame = CGRectMake(safeLeftInset, 0, bubbleWidth, chatLabelHeight + kPLVECConversionInnerVerticalPadding * 2);
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    return [self cellHeightWithModel:model cellWidth:cellWidth leftInset:0 rightInset:0];
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model
                     cellWidth:(CGFloat)cellWidth
                     leftInset:(CGFloat)leftInset
                    rightInset:(CGFloat)rightInset {
    if (![PLVECProductConversionEffectCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat safeLeftInset = MAX(leftInset, 0);
    CGFloat safeRightInset = MAX(rightInset, 0);
    CGFloat maxBubbleWidth = MAX(cellWidth - safeLeftInset - safeRightInset, 0);
    CGFloat labelWidth = MAX(maxBubbleWidth - kPLVECConversionInnerHorizontalPadding * 2, 0);
    NSAttributedString *string = [PLVECProductConversionEffectCell conversionAttributedStringWithModel:model maxLabelWidth:labelWidth];
    if (!string) {
        return 0;
    }
    CGSize size = [string boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)
                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                       context:nil].size;
    CGFloat chatLabelHeight = MAX(ceil(size.height), kPLVECConversionLabelMinHeight);
    return chatLabelHeight + kPLVECConversionInnerVerticalPadding * 2 + kPLVECConversionBottomPadding;
}

+ (NSDictionary *)conversionMessagePartsWithModel:(PLVChatModel *)model {
    PLVMessageEffectMessage *message = (PLVMessageEffectMessage *)model.message;
    NSString *content = message.content;

    return @{
        @"nickName": message.displayNickName ?: @"",
        @"content": content ?: @"",
        @"showArrow": @YES
    };
}

+ (NSAttributedString *)conversionAttributedStringWithNickName:(NSString *)nickName
                                                       content:(NSString *)content
                                                     showArrow:(BOOL)showArrow {
    NSDictionary *nameAttributes = @{
        NSFontAttributeName:[UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.55]
    };
    NSDictionary *contentAttributes = @{
        NSFontAttributeName:[UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName:[UIColor whiteColor]
    };
    NSDictionary *arrowAttributes = @{
        NSFontAttributeName:[UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#D2D8E6"]
    };

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:content ?: @"" attributes:contentAttributes]];
    if ([PLVFdUtil checkStringUseable:nickName] && [content hasPrefix:nickName]) {
        [string addAttributes:nameAttributes range:NSMakeRange(0, nickName.length)];
    }
    if (showArrow) {
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"  ›" attributes:arrowAttributes]];
    }
    return [string copy];
}

+ (NSAttributedString *)conversionAttributedStringWithModel:(PLVChatModel *)model maxLabelWidth:(CGFloat)maxLabelWidth {
    (void)maxLabelWidth;
    NSDictionary *parts = [self conversionMessagePartsWithModel:model];
    NSString *nickName = parts[@"nickName"];
    NSString *content = parts[@"content"];
    BOOL showArrow = [parts[@"showArrow"] boolValue];

    return [self conversionAttributedStringWithNickName:nickName content:content showArrow:showArrow];
}

+ (NSAttributedString *)conversionAttributedStringWithModel:(PLVChatModel *)model {
    return [self conversionAttributedStringWithModel:model maxLabelWidth:CGFLOAT_MAX];
}

@end
