//
//  PLVLCUtils.h
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

@interface PLVLCUtils : NSObject

/// 当前页面是否为横屏布局，默认为 NO
@property (nonatomic, assign, getter=isLandscape) BOOL landscape;

/// 页面布局区域（范围小于或等于系统的安全区域）
@property (nonatomic, assign, readonly) UIEdgeInsets areaInsets;

/// 当前屏幕方向，根据setupDeviceOrientation:方法配置的值返回对应屏幕方向
@property (nonatomic, assign, readonly) UIInterfaceOrientation interfaceOrientation;

/// 当前屏幕方向，根据setupDeviceOrientation:方法配置的值返回对应屏幕方向
@property (nonatomic, assign, readonly) UIInterfaceOrientationMask interfaceOrientationMask;

/// 设备方向
@property (nonatomic, assign, readonly) UIDeviceOrientation deviceOrientation;

/// 单例
+ (instancetype)sharedUtils;

/// 设置屏幕安全距离
/// @param areaInsets 安全距离
- (void)setupAreaInsets:(UIEdgeInsets)areaInsets;

/// 设置当前iPhone、iPad设备的屏幕的旋转方向
/// @param deviceOrientation 设备方向
- (void)setupDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view;

+ (void)showHUDWithTitle:(NSString * _Nullable)title detail:(NSString *)detail view:(UIView *)view afterDelay:(CGFloat)delay;

+ (UIImage *)imageForLiveRoomResource:(NSString *)imageName;

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName;

+ (NSURL *)URLForLinkMicResource:(NSString *)resourceName;

+ (UIImage *)imageForMediaResource:(NSString *)imageName;

+ (UIImage *)imageForMenuResource:(NSString *)imageName;

+ (UIImage *)imageForChatroomResource:(NSString *)imageName;

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
