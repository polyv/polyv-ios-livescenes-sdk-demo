//
//  PLVHCSettingSheet.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 polyv. All rights reserved.
//
// 设置弹层

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCSettingSheet;

@protocol PLVHCSettingSheetDelegate <NSObject>

/// 点击【麦克风】开关触发回调
/// @param settingSheet 设置弹层
- (void)didChangeMicrophoneSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet enable:(BOOL)enable;

/// 点击【摄像头】开关触发回调
/// @param settingSheet 设置弹层
- (void)didChangeCameraSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet enable:(BOOL)enable;

/// 点击【方向】开关触发回调
/// @param settingSheet 设置弹层
- (void)didChangeCameraDirectionSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet front:(BOOL)isFront;

/// 点击【全屏】开关触发回调
/// @param settingSheet 设置弹层
- (void)didChangeFullScreenSwitchInSettingSheet:(PLVHCSettingSheet *)settingSheet fullScreen:(BOOL)fullScreen;

/// 点击【退出教室】按钮触发回调
/// @param settingSheet 设置弹层
- (void)didTapLogoutButtonInSettingSheet:(PLVHCSettingSheet *)settingSheet;

/**
【学生端 在教室中】判断学生是否已经连麦
 */
/// 获取当前学生用户的上台状态，未上台则禁止麦克风、摄像头操作
/// @return 返回当前学生用户是否上台
- (BOOL)alreadyLinkMicLocalStudentInSettingSheet;

@end

@interface PLVHCSettingSheet : UIView

@property (nonatomic, weak) id<PLVHCSettingSheetDelegate> delegate;

/// 弹出弹层
/// @param superView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)superView;

/// 收起弹层
- (void)dismiss;

/// 同步设备设置页控件的开关状态
- (void)synchronizeConfig:(NSDictionary *)dict;

/// 同步麦克风开关
/// @param open YES-开启;NO-关闭
- (void)microphoneSwitchChange:(BOOL)open;

/// 同步摄像头开关
/// @param open YES-开启;NO-关闭
- (void)cameraSwitchChange:(BOOL)open;

/// 同步摄像头前后置切换
/// @param front YES-前置;NO-后置
- (void)cameraDirectionChange:(BOOL)front;

@end

NS_ASSUME_NONNULL_END
