//
//  PLVToast.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播通用 toast
@interface PLVToast : UIView

@property (nonatomic, strong, readonly) UILabel *label;

/// 显示 toast
/// @param message toast 文本
/// @param view toast 在视图
+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view;

/// 显示 toast
/// @param message toast 文本
/// @param view toast 在视图
/// @param delay toast 显示时间
+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view afterDelay:(CGFloat)delay;

/// 主动隐藏
- (void)hide;

/// 显示 倒计时toast
/// @param message toast 文本
/// @param view toast 在视图
/// @param countdown toast 显示倒计时时间，内部会向下取整
/// @param finishHandler 倒计时结束执行响应
+ (void)showToastWithCountMessage:(NSString *)message inView:(UIView *)view afterCountdown:(CGFloat)countdown finishHandler:(void(^)(void))finishHandler;

@end

NS_ASSUME_NONNULL_END
