#import "PLVECProductConversionEffectCell.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>


static NSString * const kPLVECConversionPayloadKey = @"plv_ec_conversion_payload";
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
    if (![model.message isKindOfClass:[PLVSpeakMessage class]]) {
        return NO;
    }
    if (![model.replyMessage isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSDictionary *payload = (NSDictionary *)model.replyMessage;
    return PLV_SafeBoolForDictKey(payload, kPLVECConversionPayloadKey);
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
    NSDictionary *payload = (NSDictionary *)model.replyMessage;
    NSString *type = [PLV_SafeStringForDictKey(payload, @"type") lowercaseString];
    BOOL positionType = [type isEqualToString:@"position"];
    BOOL financeType = [type isEqualToString:@"finance"];
    BOOL purchaseType = !positionType;

    NSString *nickName = [model.user getDisplayNickname:[PLVRoomDataManager sharedManager].roomData.menuInfo.hideViewerNicknameEnabled loginUserId:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    if (![PLVFdUtil checkStringUseable:nickName]) {
        nickName = PLV_SafeStringForDictKey(payload, @"nickName");
    }

    NSString *content = @"";
    if ([model.message isKindOfClass:[PLVSpeakMessage class]]) {
        content = ((PLVSpeakMessage *)model.message).content;
    }
    if (![PLVFdUtil checkStringUseable:content]) {
        if (positionType) {
            content = PLVLocalizedString(@"正在投递职位");
        } else if (financeType) {
            content = PLVLocalizedString(@"正在选购商品");
        } else {
            content = PLVLocalizedString(@"正在购买商品");
        }
    }

    return @{
        @"nickName": nickName ?: @"",
        @"content": content ?: @"",
        @"showArrow": @(purchaseType)
    };
}

+ (NSAttributedString *)conversionAttributedStringWithNickName:(NSString *)nickName
                                                       content:(NSString *)content
                                                     showArrow:(BOOL)showArrow {
    NSDictionary *nameAttributes = @{
        NSFontAttributeName:[UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#8E97AA"]
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
    if ([PLVFdUtil checkStringUseable:nickName]) {
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:nickName attributes:nameAttributes]];
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"  " attributes:contentAttributes]];
    }
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:content ?: @"" attributes:contentAttributes]];
    if (showArrow) {
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"  ›" attributes:arrowAttributes]];
    }
    return [string copy];
}

+ (NSString *)nicknamePrefix:(NSString *)nickName maxLength:(NSUInteger)maxLength {
    if (![PLVFdUtil checkStringUseable:nickName] || maxLength == 0) {
        return @"";
    }
    NSRange range = [nickName rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, MIN(maxLength, nickName.length))];
    return [nickName substringWithRange:range];
}

+ (CGFloat)textWidthForAttributedString:(NSAttributedString *)string {
    CGSize size = [string boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                       context:nil].size;
    return ceil(size.width);
}

+ (NSAttributedString *)conversionAttributedStringWithModel:(PLVChatModel *)model maxLabelWidth:(CGFloat)maxLabelWidth {
    NSDictionary *parts = [self conversionMessagePartsWithModel:model];
    NSString *nickName = parts[@"nickName"];
    NSString *content = parts[@"content"];
    BOOL showArrow = [parts[@"showArrow"] boolValue];

    NSAttributedString *full = [self conversionAttributedStringWithNickName:nickName content:content showArrow:showArrow];
    if (maxLabelWidth <= 0 || [self textWidthForAttributedString:full] <= maxLabelWidth) {
        return full;
    }

    NSAttributedString *withoutName = [self conversionAttributedStringWithNickName:nil content:content showArrow:showArrow];
    if (![PLVFdUtil checkStringUseable:nickName]) {
        return withoutName;
    }

    NSUInteger maxPreviewLength = MIN((NSUInteger)4, nickName.length);
    for (NSUInteger length = maxPreviewLength; length >= 1; length--) {
        NSString *prefix = [self nicknamePrefix:nickName maxLength:length];
        NSString *displayName = (prefix.length < nickName.length) ? [prefix stringByAppendingString:@"…"] : prefix;
        NSAttributedString *candidate = [self conversionAttributedStringWithNickName:displayName content:content showArrow:showArrow];
        if ([self textWidthForAttributedString:candidate] <= maxLabelWidth) {
            return candidate;
        }
        if (length == 1) {
            break;
        }
    }

    return withoutName;
}

+ (NSAttributedString *)conversionAttributedStringWithModel:(PLVChatModel *)model {
    return [self conversionAttributedStringWithModel:model maxLabelWidth:CGFLOAT_MAX];
}

@end
