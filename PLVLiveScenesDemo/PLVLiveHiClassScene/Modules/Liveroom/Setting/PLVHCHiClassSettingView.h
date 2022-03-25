//
//  PLVHCHiClassSettingView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//
// 设备设置视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVHCHiClassSettingViewDelegate;

@interface PLVHCHiClassSettingView : UIView

@property (nonatomic, weak) id<PLVHCHiClassSettingViewDelegate> delegate;

- (void)audioVolumeChanged:(CGFloat)volume;

@end

@protocol PLVHCHiClassSettingViewDelegate <NSObject>

/// 【进入教室】按钮被点按时触发
/// @param settingView 设备设置视图
- (void)didTapEnterClassButtonInSettingView:(PLVHCHiClassSettingView *)settingView;

/// 【返回】按钮被点按时触发
/// @param settingView 设备设置视图
- (void)didTapBackButtonInSettingView:(PLVHCHiClassSettingView *)settingView;

@end

NS_ASSUME_NONNULL_END
