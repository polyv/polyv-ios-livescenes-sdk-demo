//
//  PLVWatermarkModel.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/12/23.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVWatermarkModel.h"

@interface PLVWatermarkModel()

/// 水印文字内容
@property (nonatomic, copy) NSString *content;

/// 不透明度，取值范围 [0,100]
@property (nonatomic, assign) NSInteger opacity;

/// 字体大小
@property (nonatomic, assign) PLVChannelWatermarkFontSize fontSize;

@end

@implementation PLVWatermarkModel


#pragma mark - [ Public Method ]

+ (instancetype)watermarkModelWithContent:(NSString *)content fontSize:(PLVChannelWatermarkFontSize)fontSize opacity:(NSInteger)opacity {
    PLVWatermarkModel *model = [PLVWatermarkModel new];
    model.content = content;
    model.opacity = opacity;
    model.fontSize = fontSize;
    
    return model;
}

@end
