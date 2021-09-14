//
//  PLVLSUtils.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSUtils : NSObject

/// 子视图距离设备左右两侧的边距，主页赋值，全局使用
@property (class, nonatomic, assign) float safeSidePad;

/// 子视图距离设备底部的边距，主页赋值，全局使用
@property (class, nonatomic, assign) float safeBottomPad;

/// 主页控制器
@property (nonatomic, weak) UIViewController *homeVC;

/// 单例
+ (instancetype)sharedUtils;

/// 在主页显示自定义 toast
/// @param message toast 文本
+ (void)showToastInHomeVCWithMessage:(NSString *)message;

/// 显示自定义 toast
/// @param message toast 文本
/// @param view toast 在视图
+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view;

/// 显示自定义 alert 弹窗便捷方法1
/// @param message 弹窗文本
/// @param cancelActionTitle 取消按钮的文本（若传nil，则默认为‘取消’）
/// @param cancelActionBlock 取消按钮的点击事件
+ (void)showAlertWithMessage:(NSString *)message
           cancelActionTitle:(NSString * _Nullable)cancelActionTitle
           cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock;

/// 显示自定义 alert 弹窗便捷方法2
/// @param message 弹窗文本
/// @param cancelActionTitle 取消按钮的文本（若传nil，则默认为‘取消’）
/// @param cancelActionBlock 取消按钮的点击事件
/// @param confirmActionTitle 确认按钮的文本（若传nil，则无此按钮）
/// @param confirmActionBlock 确认按钮的点击事件
+ (void)showAlertWithMessage:(NSString *)message
           cancelActionTitle:(NSString * _Nullable)cancelActionTitle
           cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
          confirmActionTitle:(NSString * _Nullable)confirmActionTitle
          confirmActionBlock:(void(^ _Nullable)(void))confirmActionBlock;

+ (UIImage *)imageForStatusResource:(NSString *)imageName;

+ (UIImage *)imageForDocumentResource:(NSString *)imageName;

+ (UIImage *)imageForChatroomResource:(NSString *)imageName;

+ (UIImage *)imageForMemberResource:(NSString *)imageName;

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
