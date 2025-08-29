//
//  PLVStickerEffectLable.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/7/7.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVStickerEffectLable : UILabel

// 描边属性
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, strong) UIColor *strokeColor;

// 内边距
@property (nonatomic, assign) UIEdgeInsets textInsets;

// 自定义阴影属性
@property (nonatomic, assign) CGSize customShadowOffset;
@property (nonatomic, assign) CGFloat customShadowBlurRadius;
@property (nonatomic, strong) UIColor *customShadowColor;

@end

NS_ASSUME_NONNULL_END
