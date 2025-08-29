//
//  PLVStickerTextModel.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVStickerTextModel.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@implementation PLVStickerTextTemplate

+ (instancetype)defaultTextTemplateWithTemplateType:(PLVStickerTextTemplateType)templateType {
    PLVStickerTextTemplate *template = [[PLVStickerTextTemplate alloc] init];
    template.fontSize = 18;
    template.fontName = @"PingFangSC-Regular";
    template.backgroundColor = [UIColor clearColor];
    template.textAlignment = NSTextAlignmentCenter;
    
    [template configModel:template type:templateType];
    return template;
}

- (void)configModel:(PLVStickerTextTemplate *)model type:(PLVStickerTextTemplateType)type {
   switch (type) {
       case PLVStickerTextTemplateType0: // 关注主播
           model.textColor = [PLVColorUtil colorFromHexString:@"#3F76FC"];
           model.strokeColor = [UIColor whiteColor];
           model.strokeWidth = 4.0;
           
           model.backStrokeColor = [PLVColorUtil colorFromHexString:@"#B9CDFF"];
           model.backStrokeWidth = 6;

           break;
       case PLVStickerTextTemplateType1: // 限时抢购
           model.textColor = [UIColor whiteColor];
           model.strokeColor = [PLVColorUtil colorFromHexString:@"#F2344F"];
           model.strokeWidth = 4;
           
           model.backStrokeColor = [UIColor whiteColor];
           model.backStrokeWidth = 6;
           
           break;
       case PLVStickerTextTemplateType2: // 新品推荐
           model.textColor = [UIColor blackColor];
           model.strokeWidth = 0;
           model.customShadowBlurRadius = 0;
           break;
       case PLVStickerTextTemplateType3: // 精品课程
           model.textColor = [UIColor blackColor];
           model.strokeWidth = 0;
           model.customShadowBlurRadius = 0;
           break;
       case PLVStickerTextTemplateType4: // 分享有礼
           model.textColor = [UIColor whiteColor];
           model.strokeColor = [PLVColorUtil colorFromHexString:@"#E84787"];
           model.strokeWidth = 2;
           model.customShadowBlurRadius = 0;
           model.customShadowOffset = CGSizeMake(1.0, 1.0);
           model.customShadowColor = [PLVColorUtil colorFromHexString:@"#E480B1"];
           break;
       case PLVStickerTextTemplateType5: // 精品课程
           model.textColor = [UIColor blackColor];
           model.strokeWidth = 0;
           model.customShadowBlurRadius = 0;
           break;
       case PLVStickerTextTemplateType6: // 扫码关注
           model.textColor = [UIColor whiteColor];
           model.strokeWidth = 2;
           model.strokeColor = [PLVColorUtil colorFromHexString:@"#3F76FC"];
           break;
       case PLVStickerTextTemplateType7: // 看这里
           model.textColor = [PLVColorUtil colorFromHexString:@"#E94343"];
           model.strokeColor = [UIColor whiteColor];
           model.strokeWidth = 2.0;
           break;
       default:
           break;
   }
}

@end


@implementation PLVStickerTextModel

+ (NSArray<PLVStickerTextModel *> *)defaultTextModels {
    // 创建文本模板, 默认配置
    NSMutableArray *templates = [NSMutableArray array];

    NSArray *templateTexts = @[@"关注主播", @"限时抢购", @"新品推荐", @"精品课程", @"分享有礼", @"精品课程", @"扫码关注", @"看这里"];
    for (NSInteger index = 0; index < templateTexts.count; index++) {
        NSString *text = templateTexts[index];
        PLVStickerTextModel *model = [PLVStickerTextModel defaultTextModelWithText:text templateType:(PLVStickerTextTemplateType)index];
        [templates addObject:model];
    }
    return [templates copy];
}

+ (instancetype)defaultTextModelWithText:(NSString *)text templateType:(PLVStickerTextTemplateType)templateType {
    CGSize defaultSize = CGSizeMake(150, 60);
    PLVStickerTextModel *model = [[PLVStickerTextModel alloc] init];
    model.text = text;
    model.editText = text;
    model.templateType = templateType;
    model.editTemplateType = templateType;
    model.defaultSize = defaultSize;
   
    return model;
}

@end 
