//
//  PLVSABeautySliderView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/13.
//  Copyright © 2022 PLV. All rights reserved.
// 美颜强度进度条控件 

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSABeautySliderView;
@protocol PLVSABeautySliderViewDelegate <NSObject>

/// 进度改变回调
- (void)beautySliderView:(PLVSABeautySliderView *)beautySliderView didChangedValue:(CGFloat)value;

@end

@interface PLVSABeautySliderView : UIView

@property (nonatomic, weak) id<PLVSABeautySliderViewDelegate> delegate;

/// 更新美颜强度
/// @param value 当前强度
/// @param defaultValue 默认强度
- (void)updateSliderValue:(CGFloat)value defaultValue:(CGFloat)defaultValue;

@end

NS_ASSUME_NONNULL_END
