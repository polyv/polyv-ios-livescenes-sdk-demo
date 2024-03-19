//
//  PLVSAMoreInfoSheet.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSAMoreInfoSheet;
@protocol PLVSAMoreInfoSheetDelegate <NSObject>

/// 点击 清晰度 按钮 触发回调
- (void)moreInfoSheetDidTapCameraBitRateButton:(PLVSAMoreInfoSheet *)moreInfoSheet;

/// 点击 翻转 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCameraFront:(BOOL)cameraFront;

/// 点击 镜像 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeMirrorOpen:(BOOL)mirrorOpen;

/// 点击 屏幕共享 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeScreenShareOpen:(BOOL)screenShareOpen;

/// 点击 闪光灯 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeFlashOpen:(BOOL)flashOpen;

/// 点击 全体禁言 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCloseRoom:(BOOL)closeRoom;

/// 点击 美颜 按钮 触发回调
- (void)moreInfoSheetDidTapBeautyButton:(PLVSAMoreInfoSheet *)moreInfoSheet;

/// 点击 分享 按钮 触发回调
- (void)moreInfoSheetDidTapShareButton:(PLVSAMoreInfoSheet *)moreInfoSheet;

/// 点击 弱网处理 按钮 触发回调
- (void)moreInfoSheetDidTapBadNetworkButton:(PLVSAMoreInfoSheet *)moreInfoSheet;

/// 点击 混流布局 按钮 触发回调
- (void)moreInfoSheetDidTapMixLayoutButton:(PLVSAMoreInfoSheet *)moreInfoSheet;

/// 点击 转播布局 按钮 触发回调
- (void)moreInfoSheetDidTapBroadcastLayoutButton:(PLVSAMoreInfoSheet *)moreInfoSheet;

@end

/// 更多信息弹层
@interface PLVSAMoreInfoSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAMoreInfoSheetDelegate> delegate;

/// 本地用户的 摄像头 当前是否开启
@property (nonatomic, assign) BOOL currentCameraOpen;

/// 本地用户的 摄像头 当前是否前置
@property (nonatomic, assign) BOOL currentCameraFront;

/// 本地用户的 镜像 当前是否开启
@property (nonatomic, assign) BOOL currentCameraMirror;

/// 本地用户的 闪光灯 当前是否开启
@property (nonatomic, assign) BOOL currentCameraFlash;

/// 当前 流分辨率 (清晰度)
@property (nonatomic, assign) PLVResolutionType streamQuality;

/// 当前 推流质量等级 (清晰度)
@property (nonatomic, copy) NSString *streamQualityLevel;

/// 当前 全体禁言 当前是否开启
@property (nonatomic, assign) BOOL closeRoom;


/// 开始上课/结束上课
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

/// 改变闪光灯按钮选中状态
- (void)changeFlashButtonSelectedState:(BOOL)selectedState;

/// 改变屏幕共享按钮选中状态
- (void)changeScreenShareButtonSelectedState:(BOOL)selectedState;

@end

NS_ASSUME_NONNULL_END
