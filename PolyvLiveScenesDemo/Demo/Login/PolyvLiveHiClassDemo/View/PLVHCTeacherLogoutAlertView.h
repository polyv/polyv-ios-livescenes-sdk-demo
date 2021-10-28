//
//  PLVHCTeacherLogoutAlertView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/9/13.
//  Copyright © 2021 polyv. All rights reserved.
//
//登录模块-弹窗提醒

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCTeacherLogoutAlertView : UIView

+ (void)showLogoutConfirmViewInView:(UIView *)view
                    confirmCallback:(void(^)(void))confirmCallback;

/// 登录模块Alert弹窗 (只有确定按钮)
/// @param title 标题
/// @param message 内容
/// @param confirmTitle 确认按钮文字 为空默认为确定
/// @param confirmCallback 确认点击回调
+ (void)alertViewInView:(UIView *)view
                  title:(NSString *)title
                message:(NSString *)message
           confirmTitle:(NSString * _Nullable)confirmTitle
        confirmCallback:(void(^)(void))confirmCallback;

@end

NS_ASSUME_NONNULL_END
