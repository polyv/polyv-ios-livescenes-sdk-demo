//
//  PLVStickerEffectText.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/7/9.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVStickerTextModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVStickerEffectText : UIView

- (instancetype)initWithText:(NSString *)text templateType:(PLVStickerTextTemplateType)templateType;
- (void)updateText:(NSString *)text templateType:(PLVStickerTextTemplateType)templateType;
- (void)updateText:(NSString *)text;
- (CGFloat)getBoundWidthForText;

@end

NS_ASSUME_NONNULL_END
