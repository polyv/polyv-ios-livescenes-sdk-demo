//
//  PLVHCLinkMicTeacherPreView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/9/2.
//  Copyright © 2021 PLV. All rights reserved.
//
//未上课时讲师连麦窗口的预览视图【讲师端】【学生端】

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVHCLinkMicTeacherPreViewDelegate;

@interface PLVHCLinkMicTeacherPreView : UIView

@property (nonatomic, weak) id<PLVHCLinkMicTeacherPreViewDelegate> delegate;

- (void)clear;

- (void)startRunning;

/// 麦克风开启或者关闭
/// @param enable (YES 开启 NO关闭)
- (void)teacherPreViewEnableMicrophone:(BOOL)enable;

/// 摄像头开启或者关闭
/// @param enable (YES 开启 NO关闭)
- (void)teacherPreViewEnableCamera:(BOOL)enable;

/// 摄像头方向
/// @param switchFront (YES朝前  NO朝后)
- (void)teacherPreViewSwitchCameraFront:(BOOL)switchFront;

@end

/// 连麦区域设置弹窗代理
@protocol PLVHCLinkMicTeacherPreViewDelegate <NSObject>

@optional

/// 点击讲师预览窗口回调，【讲师端】会弹出设备设置弹窗
/// @param configDict 本地预览窗口的参数包括设备和本地用户信息
- (void)teacherPreView:(PLVHCLinkMicTeacherPreView *)preView
   didSelectAtUserConfig:(NSDictionary *)configDict;

@end

///学生端讲师的预览图
@interface PLVHCLinkMicStudentRoleTeacherPreView : UIView

@end

NS_ASSUME_NONNULL_END
