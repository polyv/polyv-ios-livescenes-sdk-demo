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

/// 【讲师端】开始显示本地摄像头预览
- (void)startPreview;

/// 【讲师端】麦克风开启或者关闭
/// @param enable (YES 开启 NO关闭)
- (void)enableLocalMic:(BOOL)enable;

/// 【讲师端】摄像头开启或者关闭
/// @param enable (YES 开启 NO关闭)
- (void)enableLocalCamera:(BOOL)enable;

@end

/// 连麦区域设置弹窗代理
@protocol PLVHCLinkMicTeacherPreViewDelegate <NSObject>

@optional

/// 点击讲师预览窗口回调，【讲师端】会弹出设备设置弹窗
- (void)didTeacherPreViewSelected:(PLVHCLinkMicTeacherPreView *)preView;

@end

///学生端讲师的预览图
@interface PLVHCLinkMicStudentRoleTeacherPreView : UIView

@end

NS_ASSUME_NONNULL_END
