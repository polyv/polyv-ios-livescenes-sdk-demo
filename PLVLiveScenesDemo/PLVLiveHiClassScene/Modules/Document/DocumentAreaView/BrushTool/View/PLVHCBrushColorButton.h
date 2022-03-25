//
//  PLVHCBrushColorButton.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
// 自定义画笔颜色按钮
// PLVHCBrushToolSelectSheet 弹层中使用

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCBrushColorButton : UIButton

@property (nonatomic, strong) UIColor *color;

@property (nonatomic, strong) UIColor *bgColor;

@end

NS_ASSUME_NONNULL_END
