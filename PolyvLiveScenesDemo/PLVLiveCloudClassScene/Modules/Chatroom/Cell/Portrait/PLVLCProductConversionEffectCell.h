#import <UIKit/UIKit.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCProductConversionEffectCell : UITableViewCell

+ (BOOL)isModelValid:(PLVChatModel *)model;
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model
                     cellWidth:(CGFloat)cellWidth
                     leftInset:(CGFloat)leftInset
                    rightInset:(CGFloat)rightInset;
+ (NSAttributedString *)conversionAttributedStringWithModel:(PLVChatModel *)model;

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;
- (void)updateWithModel:(PLVChatModel *)model
              cellWidth:(CGFloat)cellWidth
              leftInset:(CGFloat)leftInset
             rightInset:(CGFloat)rightInset;

@end

NS_ASSUME_NONNULL_END
