//
//  PLVWatermarkModel.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/12/23.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVWatermarkModel : NSObject

/// 水印文字内容
@property (nonatomic, copy, readonly) NSString *content;

///不透明度，取值范围 [0,100]
@property (nonatomic, assign, readonly) NSInteger opacity;

/// 字体大小
@property (nonatomic, assign, readonly) PLVChannelWatermarkFontSize fontSize;

/**
 便利初始化模型

 @param content 跑马灯内容
 @param fontSize 字体大小
 @param opacity 文本不透明度（范围：0~100）
 @return PLVWatermarkModel
 */
+ (instancetype)watermarkModelWithContent:(NSString *)content fontSize:(PLVChannelWatermarkFontSize)fontSize opacity:(NSInteger)opacity;


@end

