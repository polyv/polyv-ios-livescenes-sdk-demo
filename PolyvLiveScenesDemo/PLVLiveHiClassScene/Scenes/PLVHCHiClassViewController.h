//
//  PLVHCHiClassViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/22.
//  Copyright © 2021 PLV. All rights reserved.
//
// 互动学堂场景主页面

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCHiClassViewController : UIViewController

/// 互动学堂场景的初始化方法 可用 [init]初始化方法，hidden默认为NO
/// @param hidden 是否隐藏设备检测页，在上课中时关闭应用重新打开时时不需要显示
- (instancetype)initWithHideDevicePreview:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
