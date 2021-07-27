//
//  PLVLSBottomSheet.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/2/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播场景底部弹层基类
@interface PLVLSBottomSheet : UIView

@property (nonatomic, strong, readonly) UIView *contentView; // 底部内容区域
@property (nonatomic, assign, readonly) CGFloat sheetHight; // 弹层显示时的高度

/// 初始化方法
/// @param sheetHeight 弹层弹出高度
/// @param showSlider 是否显示顶部滑动条
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight showSlider:(BOOL)showSlider;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 收起弹层
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
