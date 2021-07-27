//
//  PLVSAUtils.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSAUtils : NSObject

/// 页面安全区域是否已赋值给 safeAreaInsets，默认为 NO
@property (nonatomic, assign) BOOL hadSetAreaInsets;

/// 当前页面是否为横屏布局，默认为 NO
@property (nonatomic, assign, getter=isLandscape) BOOL landscape;

/// 页面布局区域（范围小于或等于系统的安全区域）
@property (nonatomic, assign, readonly) UIEdgeInsets areaInsets;

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
/// @param cancelActionTitle 取消按钮的文本（若传nil，则无此按钮）
/// @param cancelActionBlock 取消按钮的点击事件
/// @param confirmActionTitle 确认按钮的文本（若传nil，则默认为'确定'）
/// @param confirmActionBlock 确认按钮的点击事件
+ (void)showAlertWithMessage:(NSString * _Nonnull)message
           cancelActionTitle:(NSString * _Nullable)cancelActionTitle
           cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
          confirmActionTitle:(NSString * _Nullable)confirmActionTitle
          confirmActionBlock:(void(^ _Nullable)(void))confirmActionBlock;

/// 显示自定义 alert 弹窗便捷方法2
/// @param title 弹窗标题
/// @param cancelActionTitle 取消按钮的文本（若传nil，则无此按钮）
/// @param cancelActionBlock 取消按钮的点击事件
/// @param confirmActionTitle 确认按钮的文本（若传nil，则默认为'确定'）
/// @param confirmActionBlock 确认按钮的点击事件
+ (void)showAlertWithTitle:(NSString * _Nonnull)title
         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
         cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
        confirmActionBlock:(void(^ _Nullable)(void))confirmActionBlock;

/// 显示自定义 alert 弹窗便捷方法3
/// @param title 弹窗标题
/// @param message 弹窗文本
/// @param cancelActionTitle 取消按钮的文本（若传nil，则无此按钮）
/// @param cancelActionBlock 取消按钮的点击事件
/// @param confirmActionTitle 确认按钮的文本（若传nil，则默认为'确定'）
/// @param confirmActionBlock 确认按钮的点击事件
+ (void)showAlertWithTitle:(NSString * _Nonnull)title
                   Message:(NSString * _Nonnull)message
         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
         cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
        confirmActionBlock:(void(^ _Nullable)(void))confirmActionBlock;


- (void)setupAreaInsets:(UIEdgeInsets)areaInsets;

+ (UIImage *)imageForLiveroomResource:(NSString *)imageName;

+ (UIImage *)imageForStatusbarResource:(NSString *)imageName;

+ (UIImage *)imageForToolbarResource:(NSString *)imageName;

+ (UIImage *)imageForChatroomResource:(NSString *)imageName;

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName;

+ (UIImage *)imageForMemberResource:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
