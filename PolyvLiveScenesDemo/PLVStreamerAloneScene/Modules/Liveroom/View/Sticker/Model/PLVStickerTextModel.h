//
//  PLVStickerTextModel.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVStickerTextTemplateType) {
    PLVStickerTextTemplateType0 = 0,
    PLVStickerTextTemplateType1 = 1,
    PLVStickerTextTemplateType2 = 2,
    PLVStickerTextTemplateType3 = 3,
    PLVStickerTextTemplateType4 = 4,
    PLVStickerTextTemplateType5 = 5,
    PLVStickerTextTemplateType6 = 6,
    PLVStickerTextTemplateType7 = 7
};

@interface PLVStickerTextTemplate : NSObject

/// 文本颜色
@property (nonatomic, strong) UIColor *textColor;

/// 位置 (相对于画布的坐标)
@property (nonatomic, assign) CGPoint position;

/// 尺寸
@property (nonatomic, assign) CGSize size;

/// 字体名称
@property (nonatomic, copy) NSString *fontName;

/// 字体大小
@property (nonatomic, assign) CGFloat fontSize;

/// 背景颜色 (可选)
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

/// 文本对齐方式
@property (nonatomic, assign) NSTextAlignment textAlignment;

/// 描边宽度
@property (nonatomic, assign) CGFloat strokeWidth;

/// 背景标签组件 描边宽度
@property (nonatomic, assign) CGFloat backStrokeWidth;

/// 描边颜色
@property (nonatomic, strong) UIColor *strokeColor;

/// 背景标签组件 描边颜色
@property (nonatomic, strong) UIColor *backStrokeColor;

/// 文本内边距
@property (nonatomic, assign) UIEdgeInsets textInsets;

/// 自定义阴影偏移量
@property (nonatomic, assign) CGSize customShadowOffset;

/// 自定义阴影模糊半径
@property (nonatomic, assign) CGFloat customShadowBlurRadius;

/// 自定义阴影颜色
@property (nonatomic, strong) UIColor *customShadowColor;

/// 创建默认文本模板
+ (instancetype)defaultTextTemplateWithTemplateType:(PLVStickerTextTemplateType)templateType;

@end


@interface PLVStickerTextModel : NSObject

/// 模版类型
@property (nonatomic, assign) PLVStickerTextTemplateType templateType;

/// 模版类型（编辑状态预览）
@property (nonatomic, assign) PLVStickerTextTemplateType editTemplateType;

/// 文本内容
@property (nonatomic, copy) NSString *text;

/// 文本内容 (编辑状态预览)
@property (nonatomic, copy) NSString *editText;

/// 文本size
@property (nonatomic, assign) CGSize defaultSize;


/// 创建默认文本模板
+ (instancetype)defaultTextModelWithText:(NSString *)text templateType:(PLVStickerTextTemplateType)templateType;

/// 生成默认模版配置
+ (NSArray<PLVStickerTextModel *> *)defaultTextModels;

@end

NS_ASSUME_NONNULL_END 
