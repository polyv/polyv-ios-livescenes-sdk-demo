//
//  PLVSAStreamAlertController.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// 手机开播（纯视频）通用 alert
@interface PLVSAStreamAlertController : UIViewController

/// 初始化方法 1
/// @param title 标题，可为空
/// @param message 弹窗提示文本，可为空
/// @param cancelActionTitle cancel 按钮文本，为空时则无此按钮
/// @param cancelHandler cancel 按钮事件，可为空
/// @param confirmActionTitle confirm 按钮文本，为空时默认为确定按钮
/// @param confirmHandler confirm 按钮事件，可为空
+ (instancetype)alertControllerWithTitle:(NSString * _Nullable)title
                                 Message:(NSString * _Nullable)message
                       cancelActionTitle:(NSString * _Nullable)cancelActionTitle
                           cancelHandler:(void(^ _Nullable)(void))cancelHandler
                      confirmActionTitle:(NSString * _Nullable)confirmActionTitle
                          confirmHandler:(void(^ _Nullable)(void))confirmHandler;

@end

NS_ASSUME_NONNULL_END
