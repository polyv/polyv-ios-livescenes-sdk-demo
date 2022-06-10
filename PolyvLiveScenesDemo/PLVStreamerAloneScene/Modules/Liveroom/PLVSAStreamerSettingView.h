//
//  PLVSAStreamerSettingView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//
// 开播前设置页视图，覆盖在 PLVSAStreamerViewController 之上

#import <UIKit/UIKit.h>
#import "PLVRoomData.h"


@protocol PLVSAStreamerSettingViewDelegate;

@interface PLVSAStreamerSettingView : UIView

@property (nonatomic, weak) id<PLVSAStreamerSettingViewDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL canAutorotate;

/**
  是否禁用摄像头和镜像按钮
 
 @param prepareSuccess YES启用，NO禁用
 */
- (void)cameraAuthorizationGranted:(BOOL)prepareSuccess;

/// 是否禁用镜像按钮
- (void)enableMirrorButton:(BOOL)enable;

/// 是否禁用横竖屏按钮
- (void)enableOrientationButton:(BOOL)enable;

/// 旋转屏幕
- (void)changeDeviceOrientation:(UIDeviceOrientation)orientation;

/// 当前是否显示 美颜弹层，可在此方法内部设置内部UI的显示与隐藏
/// @param show YES:显示 NO:隐藏
- (void)showBeautySheet:(BOOL)show;

@end

@protocol PLVSAStreamerSettingViewDelegate <NSObject>

/**
  点击事件回调
  */

///返回
- (void)streamerSettingViewBackButtonClick;
/**
  开始直播
 
  @param type 当前清晰度
 */
- (void)streamerSettingViewStartButtonClickWithResolutionType:(PLVResolutionType)type;
/// 摄像头反转
- (void)streamerSettingViewCameraReverseButtonClick;
/// 镜像
- (void)streamerSettingViewMirrorButtonClickWithMirror:(BOOL)mirror;
/// 清晰度切换
- (void)streamerSettingViewBitRateButtonClickWithResolutionType:(PLVResolutionType)type;
/// 显示美颜按钮
- (void)streamerSettingViewDidClickBeautyButton:(PLVSAStreamerSettingView *)streamerSettingView;
/// 设备方向发送改变
- (void)streamerSettingViewDidChangeDeviceOrientation:(PLVSAStreamerSettingView *)streamerSettingView;

@end


