//
//  PLVHCUtils.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//
// 互动学堂场景工具类

#import <Foundation/Foundation.h>
#import "PLVHCHiClassToast.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCUtils : NSObject

/// 页面安全区域是否已赋值给 safeAreaInsets，默认为 NO
@property (nonatomic, assign) BOOL hadSetAreaInsets;

/// 页面布局区域（范围小于或等于系统的安全区域）
@property (nonatomic, assign, readonly) UIEdgeInsets areaInsets;

/// 主页控制器
@property (nonatomic, weak) UIViewController *homeVC;

/// 当前屏幕方向，根据setupInterfaceOrientation:方法配置，缺省值为UIInterfaceOrientationLandscapeRight
@property (nonatomic, assign, readonly) UIInterfaceOrientation interfaceOrientation;

/// 单例
+ (instancetype)sharedUtils;

/// 设置页面布局安全区域
- (void)setupAreaInsets:(UIEdgeInsets)areaInsets;

/// 设置当前iPhone、iPad设备的屏幕的旋转方向
/// @note 只支持UIInterfaceOrientationLandscapeRight、UIInterfaceOrientationLandscapeLeft，在启动图片选择器后，保证当前方向为用户设置的方向。(开播后允许用户左右转屏)
/// @param interfaceOrientation 屏幕方向(即Home键方向)
- (void)setupInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

/// 在KeyWindow显示文本 toast
/// @param message toast 文本
+ (void)showToastInWindowWithMessage:(NSString *)message;

/// 包含不同图案和文字的Toast
/// @param type 提示toast 类型
/// @param message 提示文字
+ (void)showToastWithType:(PLVHCToastType)type message:(NSString *)message;

/// 显示自定义 alert 弹窗便捷方法
/// @param title 弹窗标题
/// @param message 弹窗文本
/// @param cancelActionTitle 取消按钮的文本（若传nil，则默认为‘取消’）
/// @param cancelActionBlock 取消按钮的点击事件
/// @param confirmActionTitle 确认按钮的文本（若传nil，则默认为‘确定’）
/// @param confirmActionBlock 确认按钮的点击事件
+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
         cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
        confirmActionBlock:(void(^)(void))confirmActionBlock;

/// 显示自定义 alert 弹窗便捷方法2，无标题
/// @param message 弹窗文本
/// @param cancelActionTitle 取消按钮的文本
/// @param cancelActionBlock 取消按钮的点击事件
/// @param confirmActionTitle 确认按钮的文本（若传nil，则默认为‘确定’）
/// @param confirmActionBlock 确认按钮的点击事件
+ (void)showAlertWithMessage:(NSString *)message
         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
         cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
        confirmActionBlock:(void(^ _Nullable)(void))confirmActionBlock;

/// 获取PLVHCLiveroom.bundle的图片资源
/// @param imageName 图片资源名称
+ (UIImage *)imageForLiveroomResource:(NSString *)imageName;

/// 获取PLVHCStatusbar.bundle的图片资源
/// @param imageName 图片资源名称
+ (UIImage *)imageForStatusbarResource:(NSString *)imageName;

/// 获取PLVHCToolbar.bundle的图片资源
/// @param imageName 图片资源名称
+ (UIImage *)imageForToolbarResource:(NSString *)imageName;

/// 获取PLVHCDocument.bundle的图片资源
/// @param imageName 图片资源名称
+ (UIImage *)imageForDocumentResource:(NSString *)imageName;

/// 获取PLVHCMember.bundle的图片资源
/// @param imageName 图片资源名称
+ (UIImage *)imageForMemberResource:(NSString *)imageName;

/// 获取PLVHCChatroom.bundle的图片资源
/// @param imageName 图片资源名称
+ (UIImage *)imageForChatroomResource:(NSString *)imageName;

/// 获取PLVHCLinkMic.bundle的图片资源
/// @param imageName 图片资源名称
+ (UIImage *)imageForLinkMicResource:(NSString *)imageName;

/// 获取PLVHCLiveroom.bundle路径
+ (NSBundle *)bundlerForLiveroom;

@end

NS_ASSUME_NONNULL_END
