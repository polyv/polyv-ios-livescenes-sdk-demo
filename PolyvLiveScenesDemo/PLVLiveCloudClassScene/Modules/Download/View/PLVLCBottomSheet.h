//
//  PLVLCBottomSheet.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// 底部弹窗sheet 的基类
@interface PLVLCBottomSheet : UIView

@property (nonatomic, strong, readonly) UIView *contentView; // 底部内容区域
@property (nonatomic, assign, readonly) CGFloat sheetHight; // 弹层显示时的高度
@property (nonatomic, assign) BOOL bottomShow;

/// 初始化方法
/// @param sheetHeight 弹层弹出高度
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 收起弹层
- (void)dismiss;


/// 更新弹层布局
/// @param sheetHeight 弹层弹出高度
- (void)refreshWithSheetHeight:(CGFloat)sheetHeight;

@end

NS_ASSUME_NONNULL_END
