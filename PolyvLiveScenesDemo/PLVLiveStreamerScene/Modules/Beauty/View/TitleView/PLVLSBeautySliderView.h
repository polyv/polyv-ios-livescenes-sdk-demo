//
//  PLVLSBeautySliderView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/13.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSBeautySliderView;
@protocol PLVLSBeautySliderViewDelegate <NSObject>

/// 进度改变回调
- (void)beautySliderView:(PLVLSBeautySliderView *)beautySliderView didChangedValue:(CGFloat)value;

@end

@interface PLVLSBeautySliderView : UIView

@property (nonatomic, weak) id<PLVLSBeautySliderViewDelegate> delegate;

/// 更新美颜强度
/// @param value 当前强度
/// @param defaultValue 默认强度
- (void)updateSliderValue:(CGFloat)value defaultValue:(CGFloat)defaultValue;

@end

NS_ASSUME_NONNULL_END
