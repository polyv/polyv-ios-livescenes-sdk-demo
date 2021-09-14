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

/// 点击 摄像头 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCameraOpen:(BOOL)cameraOpen;

/// 点击 麦克风 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeMicOpen:(BOOL)micOpen;

/// 点击 翻转 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCameraFront:(BOOL)cameraFront;

/// 点击 镜像 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeMirrorOpen:(BOOL)mirrorOpen;

/// 点击 闪光灯 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeFlashOpen:(BOOL)flashOpen;

/// 点击 全体禁言 按钮 触发回调
- (void)moreInfoSheet:(PLVSAMoreInfoSheet *)moreInfoSheet didChangeCloseRoom:(BOOL)closeRoom;

@end

/// 更多信息弹层
@interface PLVSAMoreInfoSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAMoreInfoSheetDelegate> delegate;

/// 本地用户的 麦克风 当前是否开启
@property (nonatomic, assign) BOOL currentMicOpen;

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

/// 当前 全体禁言 当前是否开启
@property (nonatomic, assign) BOOL closeRoom;


/// 初始化方法
/// @param sheetHeight 弹层弹出高度
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight;

/// 改变闪光灯按钮选中状态
- (void)changeFlashButtonSelectedState:(BOOL)selectedState;

@end

NS_ASSUME_NONNULL_END
