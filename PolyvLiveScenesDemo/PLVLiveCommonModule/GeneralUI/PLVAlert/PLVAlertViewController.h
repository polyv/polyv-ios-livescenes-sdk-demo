//
//  PLVAlertViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/3/2.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播通用 alert
@interface PLVAlertViewController : UIViewController

/// 初始化方法 1
/// @param message 弹窗提示文本
/// @param cancelActionTitle cancel 按钮文本，为空时默认“取消”
/// @param cancelHandler cancel 按钮事件，可为空
+ (instancetype)alertControllerWithMessage:(NSString *)message
                         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
                             cancelHandler:(void(^ _Nullable)(void))cancelHandler;

/// 初始化方法 2
/// @param message 弹窗提示文本
/// @param cancelActionTitle cancel 按钮文本，为空时默认“取消”
/// @param cancelHandler cancel 按钮事件，可为空
/// @param confirmActionTitle confirm 按钮文本，可为空
/// @param confirmHandler confirm 按钮事件，可为空
+ (instancetype)alertControllerWithMessage:(NSString *)message
                         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
                             cancelHandler:(void(^ _Nullable)(void))cancelHandler
                        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
                            confirmHandler:(void(^ _Nullable)(void))confirmHandler;

@end

NS_ASSUME_NONNULL_END
