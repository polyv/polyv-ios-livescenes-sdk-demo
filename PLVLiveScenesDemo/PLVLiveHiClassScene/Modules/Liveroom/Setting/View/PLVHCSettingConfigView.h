//
//  PLVHCSettingConfigView.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/8/4.
//  Copyright © 2021 PLV. All rights reserved.
//  设置控件（提供于PLVHCHiClassSettingView、PLVHCSettingSheet）

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCSettingConfigView;

@protocol PLVHCSettingConfigViewDelegate <NSObject>

@optional
/**
 [进入教室类型]
 */
/// 点击【进入教室】按钮触发回调
/// @param configView 设置控件
- (void)didTapEnterButtonInSettingConfigView:(PLVHCSettingConfigView *)configView;

/**
 [退出教室类型]
 */
/// 点击【退出教室】按钮触发回调
/// @param configView 设置控件
- (void)didTapLogoutButtonInSettingConfigView:(PLVHCSettingConfigView *)configView;

/// 点击【全屏】开关触发回调
/// @param configView 设置控件
- (void)didChangeFullScreenSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView fullScreen:(BOOL)fullScreen;

/**
【学生端 在教室中】判断学生是否已经连麦
 */
/// 获取当前学生用户的上台状态，未上台则禁止麦克风、摄像头操作
/// @return 返回当前学生用户是否上台
- (BOOL)alreadyLinkMicLocalStudentInSettingConfigView;

@required
/**
 公共
 */
/// 点击【麦克风】开关触发回调
/// @param configView 设置控件
- (void)didChangeMicrophoneSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView enable:(BOOL)enable;

/// 点击【摄像头】开关触发回调
/// @param configView 设置控件
- (void)didChangeCameraSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView enable:(BOOL)enable;

/// 点击【方向】按钮触发回调
/// @param configView 设置控件
- (void)didChangeCameraDirectionSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView front:(BOOL)isFront;


@end

///  控件类型
typedef NS_ENUM(NSUInteger, PLVHCSettingConfigViewType) {
    PLVHCSettingConfigViewEnterClass   = 0, // 进入教室
    PLVHCSettingConfigViewLogoutClass  = 1, // 退出教室
};

@interface PLVHCSettingConfigView : UIView

@property (nonatomic, weak) id<PLVHCSettingConfigViewDelegate> delegate;

- (instancetype)initWithType:(PLVHCSettingConfigViewType)type;

// 打开麦克风和摄像头（该方法只能用于进入教室类型UI）
- (void)openMediaSwitch;

// 同步设备设置页控件的开关状态（该方法只能用于退出教室类型UI）
- (void)synchronizeConfig;

/// 同步麦克风开关
/// @param open YES-开启;NO-关闭
- (void)microphoneSwitchChange:(BOOL)open;

/// 同步摄像头开关
/// @param open YES-开启;NO-关闭
- (void)cameraSwitchChange:(BOOL)open;

/// 同步摄像头前后置切换
/// @param front YES-前置;NO-后置
- (void)cameraDirectionChange:(BOOL)front;

/// 修改麦克风音量
- (void)audioVolumeChanged:(CGFloat)volume;

@end

NS_ASSUME_NONNULL_END
