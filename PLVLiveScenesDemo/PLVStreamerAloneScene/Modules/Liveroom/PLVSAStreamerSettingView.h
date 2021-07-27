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

/**
  是否禁用摄像头和镜像按钮
 
 @param prepareSuccess YES启用，NO禁用
 */
- (void)cameraAuthorizationGranted:(BOOL)prepareSuccess;

/// 是否禁用镜像按钮
- (void)enableMirrorButton:(BOOL)enable;

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


@end


