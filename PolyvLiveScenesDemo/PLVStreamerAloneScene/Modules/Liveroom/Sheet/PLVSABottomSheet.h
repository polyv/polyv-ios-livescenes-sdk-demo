//
//  PLVASBottomSheet.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播场景（纯视频）底部弹层基类
@interface PLVSABottomSheet : UIView

@property (nonatomic, assign) CGFloat sheetHight; // 弹层显示时的高度
@property (nonatomic, assign) CGFloat sheetLandscapeWidth; // 弹层横屏时弹出宽度

@property (nonatomic, strong, readonly) UIView *contentView; // 底部内容区域
@property (nonatomic, copy) void(^didCloseSheet)(void); // 弹层隐藏时的回调

/// 初始化方法
/// @param sheetHeight 弹层弹出高度
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight;

/// 初始化方法，支持横竖屏
/// @note 竖屏时：弹窗宽充满屏幕宽度，高度为sheetHeight；
///       横屏时：弹窗宽为sheetLandscapeWidth + 右安全距离，高度充满屏幕高度。
/// @param sheetHeight 弹层弹出宽度
/// @param sheetLandscapeWidth  弹层横屏时弹出宽度，需要支持横屏时此值必须大于0
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth;

/// 初始化方法，支持横竖屏
/// @note 竖屏时：弹窗宽充满屏幕宽度，高度为sheetHeight；
///       横屏时：弹窗宽为sheetLandscapeWidth + 右安全距离，高度充满屏幕高度。
/// @param sheetHeight 弹层弹出宽度
/// @param sheetLandscapeWidth  弹层横屏时弹出宽度，需要支持横屏时此值必须大于0
/// @param backgroundColor 背景色，默认为黑色半透明
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth backgroundColor:(UIColor *)backgroundColor;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 收起弹层
- (void)dismiss;

/// 设备横竖屏方向发生变化时调用，子类可以重写此方法来修改UI，重写时请务必添加[super deviceOrientationDidChange]
- (void)deviceOrientationDidChange;

@end

NS_ASSUME_NONNULL_END
