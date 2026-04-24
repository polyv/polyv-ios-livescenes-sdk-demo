#import "PLVECChatBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECProductConversionEffectCell : PLVECChatBaseCell

+ (NSAttributedString *)conversionAttributedStringWithModel:(PLVChatModel *)model;
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model
                     cellWidth:(CGFloat)cellWidth
                     leftInset:(CGFloat)leftInset
                    rightInset:(CGFloat)rightInset;
- (void)updateWithModel:(PLVChatModel *)model
              cellWidth:(CGFloat)cellWidth
              leftInset:(CGFloat)leftInset
             rightInset:(CGFloat)rightInset;

@end

NS_ASSUME_NONNULL_END
