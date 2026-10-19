//
//  PLVScreenshotHelper.h
//  PLVLiveScenesDemo
//
//  Created by PLV on 2026/10/9.
//  Copyright © 2026 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 观看端截屏。更多面板点击后抓取当前画面并保存到相册。
/// 与防系统截屏互斥：systemScreenShotProtect 开启时不显示入口，也不抓屏。
@interface PLVScreenshotHelper : NSObject

/// 是否在更多面板显示截屏入口。手动开关默认 YES，防系统截屏开启时固定为 NO。
+ (BOOL)isShowScreenshotView;
+ (void)setShowScreenshotView:(BOOL)showScreenshotView;

/// 抓取当前界面并保存到系统相册。防系统截屏开启时直接返回。
+ (void)startScreenCaptureFromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
