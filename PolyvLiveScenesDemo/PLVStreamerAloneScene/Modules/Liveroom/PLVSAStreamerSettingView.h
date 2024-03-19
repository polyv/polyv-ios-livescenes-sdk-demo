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
#import "PLVSAMixLayoutSheet.h"
#import "PLVSACameraSettingSheet.h"


@protocol PLVSAStreamerSettingViewDelegate;

@interface PLVSAStreamerSettingView : UIView

@property (nonatomic, weak) id<PLVSAStreamerSettingViewDelegate> delegate;

// 混流布局选择面板，用于更新当前混流布局类型
@property (nonatomic, strong, readonly) PLVSAMixLayoutSheet *mixLayoutSheet;

@property (nonatomic, assign, readonly) BOOL canAutorotate;

/// 本地用户的 摄像头 当前是否开启
@property (nonatomic, assign) BOOL currentCameraOpen;

/// 本地用户的 麦克风 当前是否开启
@property (nonatomic, assign) BOOL currentMicOpen;

// 推流视频模版默认清晰度（已区分讲师和嘉宾）
@property (nonatomic, copy, readonly) NSString *defaultQualityLevel;

/**
  是否禁用摄像头和镜像按钮
 
 @param prepareSuccess YES启用，NO禁用
 */
- (void)cameraAuthorizationGranted:(BOOL)prepareSuccess;

/// 是否启用镜像按钮
- (void)enableMirrorButton:(BOOL)enable;

/// 是否启用横竖屏按钮
- (void)enableOrientationButton:(BOOL)enable;

/// 旋转屏幕
- (void)changeDeviceOrientation:(UIDeviceOrientation)orientation;

/// 当前是否显示 美颜弹层，可在此方法内部设置内部UI的显示与隐藏
/// @param show YES:显示 NO:隐藏
- (void)showBeautySheet:(BOOL)show;

/// 同步当前开播流比例
- (void)synchPushStreamScale:(PLVBLinkMicStreamScale)streamScale;

/// 右移显示
- (void)landscapeShouldShiftRight:(BOOL)shiftRight;

/// 更新摄像头来源，摄像头图片地址
- (void)updateVideoSourceType:(PLVVideoSourceType)videoSourceType image:(UIImage * _Nullable)image imageSourceUrl:(NSString * _Nullable)imageSourceUrl;

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
/// 点击 摄像头设置 按钮 触发回调
- (void)streamerSettingViewDidTapCameraSettingButton:(PLVSAStreamerSettingView *)streamerSettingView didTapCameraOpen:(BOOL)cameraOpen cameraSetting:(BOOL)isPicture placeholderImage:(UIImage * _Nullable)image placeholderImageUrl:(NSString * _Nullable)url;
/// 点击 摄像头 按钮 触发回调
- (void)streamerSettingViewDidChangeCameraOpen:(BOOL)cameraOpen;
// 点击 麦克风 按钮 触发回调
- (void)streamerSettingViewDidChangeMicOpen:(BOOL)micOpen;
/// 摄像头反转
- (void)streamerSettingViewCameraReverseButtonClick;
/// 镜像
- (void)streamerSettingViewMirrorButtonClickWithMirror:(BOOL)mirror;
/// 清晰度切换
- (void)streamerSettingViewBitRateButtonClickWithResolutionType:(PLVResolutionType)type;
/// 流清晰度质量等级切换
- (void)streamerSettingViewBitRateSheetDidSelectStreamQualityLevel:(NSString *)streamQualityLevel;
/// 显示美颜按钮
- (void)streamerSettingViewDidClickBeautyButton:(PLVSAStreamerSettingView *)streamerSettingView;
/// 设备方向发送改变
- (void)streamerSettingViewDidChangeDeviceOrientation:(PLVSAStreamerSettingView *)streamerSettingView;
/// 开播流比例改变
- (void)streamerSettingViewStreamScaleButtonClickWithStreamScale:(PLVBLinkMicStreamScale)streamScale;;
/// 混流布局切换
- (void)streamerSettingViewMixLayoutButtonClickWithMixLayoutType:(PLVMixLayoutType)type;

@end


