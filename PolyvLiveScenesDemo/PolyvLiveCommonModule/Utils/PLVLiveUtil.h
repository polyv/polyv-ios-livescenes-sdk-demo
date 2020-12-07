//
//  PLVLiveUtil.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/12.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

CGFloat P_SafeAreaTopEdgeInsets(void);     // 安全区域上边距
CGFloat P_SafeAreaLeftEdgeInsets(void);    // 安全区域左边距
CGFloat P_SafeAreaBottomEdgeInsets(void);  // 安全区域下边距
CGFloat P_SafeAreaRightEdgeInsets(void);   // 安全区域右边距

#define PLVScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define PLVScreenHeight ([UIScreen mainScreen].bounds.size.height)

NS_ASSUME_NONNULL_BEGIN

/// 直播工具类
@interface PLVLiveUtil : NSObject

#pragma mark - view

+ (void)drawViewCornerRadius:(UIView *)view cornerRadii:(CGSize)cornerRadii corners:(UIRectCorner)corners;

+ (void)drawViewCornerRadius:(UIView *)view size:(CGSize)size cornerRadii:(CGSize)cornerRadii corners:(UIRectCorner)corners;

#pragma mark - HUD

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view;

#pragma mark - Common

+ (UIViewController *)getCurrentViewController;

+ (BOOL)isiPhoneXSeries;

+ (void)changeDeviceOrientationToPortrait;
    
@end

NS_ASSUME_NONNULL_END
