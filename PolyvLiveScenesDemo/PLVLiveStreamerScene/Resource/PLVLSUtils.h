//
//  PLVLSUtils.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageDownloader.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSUtils : NSObject

/// 子视图距离设备左右两侧的边距，主页赋值，全局使用
@property (class, nonatomic, assign) float safeSidePad;

/// 子视图距离设备底部的边距，主页赋值，全局使用
@property (class, nonatomic, assign) float safeBottomPad;

/// 子视图距离设备顶部的边距，主页赋值，全局使用
@property (class, nonatomic, assign) float safeTopPad;

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

/// 显示自定义 toast
/// @param message toast 文本
/// @param view toast 在视图
/// @param delay toast 显示时间
+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view afterDelay:(CGFloat)delay;

/// 显示自定义倒计时 toast
/// @param message toast 文本
/// @param view toast 在视图
/// @param countdown toast 倒计时显示时间
/// @param finishHandler 倒计时结束执行响应
+ (void)showToastWithCountMessage:(NSString *)message inView:(UIView *)view afterCountdown:(CGFloat)countdown finishHandler:(void(^ _Nullable)(void))finishHandler;

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

/// 显示自定义 alert 弹窗便捷方法3
/// @param title 弹窗标题
/// @param message 弹窗文本
/// @param cancelActionTitle 取消按钮的文本（若传nil，则默认为‘取消’）
/// @param cancelActionBlock 取消按钮的点击事件
/// @param confirmActionTitle 确认按钮的文本（若传nil，则无此按钮）
/// @param confirmActionBlock 确认按钮的点击事件
+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
         cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
        confirmActionBlock:(void(^ _Nullable)(void))confirmActionBlock;

/// 显示自定义 alert 弹窗便捷方法（同纯视频开播样式）
/// @param title 弹窗标题
/// @param message 弹窗文本
/// @param cancelActionTitle 取消按钮的文本（若传nil，则默认为‘取消’）
/// @param cancelActionBlock 取消按钮的点击事件
/// @param confirmActionTitle 确认按钮的文本（若传nil，则无此按钮）
/// @param confirmActionBlock 确认按钮的点击事件
+ (void)showAlertWithTitle2:(NSString *)title
                   message:(NSString *)message
         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
         cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
        confirmActionBlock:(void(^ _Nullable)(void))confirmActionBlock;

+ (UIImage *)imageForStatusResource:(NSString *)imageName;

+ (UIImage *)imageForDocumentResource:(NSString *)imageName;

+ (UIImage *)imageForChatroomResource:(NSString *)imageName;

+ (UIImage *)imageForMemberResource:(NSString *)imageName;

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName;

+ (UIImage *)imageForBeautyResource:(NSString *)imageName;

+ (UIImage *)imageForLiveroomResource:(NSString *)imageName;

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url;

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder;

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options;

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock;

+ (void)setImageView:(UIImageView *)imageView
                 url:(nullable NSURL *)url
    placeholderImage:(nullable UIImage *)placeholder
             options:(SDWebImageOptions)options
            progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
           completed:(nullable SDExternalCompletionBlock)completedBlock;

@end

NS_ASSUME_NONNULL_END
