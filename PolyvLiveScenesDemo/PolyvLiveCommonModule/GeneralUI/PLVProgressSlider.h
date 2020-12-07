//
//  PLVProgressSlider.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/11/11.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVProgressSliderDelegate;

/// 进度滑杆视图
///
/// @note 适用于 “回放、点播” 等场景下，需要展现观看进度的、可拖动的进度滑杆条；
///       同时，可显示缓冲进度；
@interface PLVProgressSlider : UIView

#pragma mark 可配置项
/// delegate
@property (nonatomic, weak) id delegate;

#pragma mark 状态
/// slider 是否处于拖动中
///
/// @note YES:正在被拖动；NO:未被拖动
@property (nonatomic, assign, readonly) BOOL sliderDragging;

#pragma mark UI
/// 进度条
///
/// @note 用于显示 ‘已缓存进度’；可在 [[PLVProgressSlider alloc]init] 后，对 progressView 作需要的自定义设置，如色值；
@property (nonatomic, strong, readonly) UIProgressView * progressView;

/// 滑杆条
///
/// @note 用于显示 ‘已观看进度’；可在 [[PLVProgressSlider alloc]init] 后，对 slider 作需要的自定义设置，如色值、图标；
@property (nonatomic, strong, readonly) UISlider * slider;

#pragma mark 方法
/// 设置进度
///
/// @note 仅在 [sliderDragging] 为 NO 时调用有效，内部已作相关判断，外部无需关心；
///
/// @param cachedProgress 已缓存进度 (指播放器已下载、缓存的进度；范围:0.0~1.0)
/// @param playedProgress 已观看进度 (指当前正在观看的位置点；范围:0.0~1.0)
- (void)setProgressWithCachedProgress:(CGFloat)cachedProgress playedProgress:(CGFloat)playedProgress;

@end

@protocol PLVProgressSliderDelegate <NSObject>

/// 进度滑杆条 正在被拖动
///
/// @note 当用户拖动时，此回调将被频繁地回调；
///       拖动时，[sliderDragging] 相应地为YES，并且此时调用 [setProgressWithCachedProgress:playedProgress:] 方法将无效
///
/// @param progressSlider 进度滑杆视图对象本身
/// @param currentSliderProgress 当前正在观看的位置点
- (void)plvProgressSlider:(PLVProgressSlider *)progressSlider sliderDragingProgressChange:(CGFloat)currentSliderProgress;

/// 进度滑杆挑 拖动结束
///
/// @note 当用户拖动结束时，此回调将被回调；
///       拖动结束时，[sliderDragging] 相应地为NO
///
/// @param progressSlider 进度滑杆视图对象本身
/// @param currentSliderProgress 拖动结束时，当前正在观看的位置点
- (void)plvProgressSlider:(PLVProgressSlider *)progressSlider sliderDragEnd:(CGFloat)currentSliderProgress;

@end

NS_ASSUME_NONNULL_END
