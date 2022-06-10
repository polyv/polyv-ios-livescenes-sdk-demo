//
//  PLVLSSliderView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/5/6.
//  Copyright © 2022 PLV. All rights reserved.
// 自定义SliderView

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static const CGFloat DEFAULT_LINE_HEIGHT = 2;
static const CGFloat DEFAULT_CIRCLE_RADIUS = 16;
static const CGFloat DEFAULT_DEFAULT_CIRCLE_RADIUS = 4;
static const CGFloat DEFAULT_PADDING_LEFT = 0;
static const CGFloat DEFAULT_PADDING_RIGHT = 0;
static const CGFloat DEFAULT_PADDING_BOTTOM = 2;

@class PLVLSSliderView;
@protocol PLVLSSliderViewDelegate <NSObject>

@optional
/// 进度改变回调
- (void)sliderView:(PLVLSSliderView *)sliderView didChangedValue:(CGFloat)value;

/// 中间触摸块frame改变回调
- (void)sliderView:(PLVLSSliderView *)sliderView didChangedCircleRect:(CGRect)rect;

@end

/// 自定义SliderView
@interface PLVLSSliderView : UIView
/// 代理
@property (nonatomic, weak) id<PLVLSSliderViewDelegate> delegate;
 
/// 激活状态的颜色
@property (nonatomic, strong) UIColor *activeLineColor;
/// 非激活状态的颜色
@property (nonatomic, strong) UIColor *inactiveLineColor;
/// 圆形颜色
@property (nonatomic, strong) UIColor *circleColor;

/// 线的高度
@property (nonatomic, assign) CGFloat lineHeight;
/// 圆形的默认半径
@property (nonatomic, assign) CGFloat circleRadius;
/// 默认进度圆形的默认半径
@property (nonatomic, assign) CGFloat defaultCircleRadius;

/// 左边距
@property (nonatomic, assign) CGFloat paddingLeft;
/// 右边距
@property (nonatomic, assign) CGFloat paddingRight;
/// 底边距
@property (nonatomic, assign) CGFloat paddingBottom;

/// 进度，0～1
@property (nonatomic, assign) CGFloat progress;

/// 默认进度，0~1
@property (nonatomic, assign) CGFloat defaultProgress;

@end

NS_ASSUME_NONNULL_END
