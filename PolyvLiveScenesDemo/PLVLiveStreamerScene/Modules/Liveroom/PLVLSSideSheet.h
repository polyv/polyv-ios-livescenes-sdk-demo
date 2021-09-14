//
//  PLVLSSideSheet.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/2/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播场景右侧弹层基类
@interface PLVLSSideSheet : UIView

@property (nonatomic, strong, readonly) UIView *contentView; // 弹层右侧内容区域
@property (nonatomic, assign, readonly) CGFloat sheetWidth; // 弹层显示时的宽度

/// 初始化方法
/// @param sheetWidth 弹层弹出宽度
- (instancetype)initWithSheetWidth:(CGFloat)sheetWidth;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 收起弹层
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
