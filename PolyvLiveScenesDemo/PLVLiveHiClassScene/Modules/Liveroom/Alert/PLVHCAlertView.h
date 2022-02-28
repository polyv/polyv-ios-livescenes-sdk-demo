//
//  PLVHCHiClassAlertView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/26.
//  Copyright © 2021 PLV. All rights reserved.
//
// 互动学堂通用Alert弹窗

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 定义Block回调事件
 */
typedef void(^PLVHCAlertViewBlock)(void);

@interface PLVHCAlertView : UIView

/// 互动学堂通用弹窗，支持标题、内容、确认、取消
/// @param title 标题
/// @param message 内容
/// @param cancelTitle 取消按钮文字 为空默认为取消
/// @param confirmTitle 确认按钮文字 为空默认为确定
/// @param cancelActionBlock 取消点击回调
/// @param confirmActionBlock 确认点击回调
+ (instancetype)alertViewWithTitle:(NSString * _Nullable)title
                           message:(NSString *)message
                       cancelTitle:(NSString * _Nullable)cancelTitle
                      confirmTitle:(NSString * _Nullable)confirmTitle
                 cancelActionBlock:(PLVHCAlertViewBlock _Nullable)cancelActionBlock
                confirmActionBlock:(PLVHCAlertViewBlock _Nullable)confirmActionBlock;

@end

NS_ASSUME_NONNULL_END
