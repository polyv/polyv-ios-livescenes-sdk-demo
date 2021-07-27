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
@property (nonatomic, strong, readonly) UIView *contentView; // 底部内容区域
@property (nonatomic, copy) void(^didCloseSheet)(void); // 弹层隐藏时的回调

/// 初始化方法
/// @param sheetHeight 弹层弹出高度
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 收起弹层
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
