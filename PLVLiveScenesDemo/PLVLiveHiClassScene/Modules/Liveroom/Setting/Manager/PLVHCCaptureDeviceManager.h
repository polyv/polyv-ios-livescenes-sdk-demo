//
//  PLVHCCaptureDeviceManager.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/11/19.
//  Copyright © 2021 PLV. All rights reserved.
//
// 摄像头、麦克风【状态管理器】
// 摄像头、麦克风【资源管理器】（用于设备检测页和教师开播前的本地预览）

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVHCCaptureDeviceManagerDelegate;

@interface PLVHCCaptureDeviceManager : NSObject

@property (nonatomic, weak) id<PLVHCCaptureDeviceManagerDelegate> delegate;

/// 摄像头本地预览图层
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *avPreLayer;

/// 应用是否已获得本地摄像头、麦克风权限
@property (nonatomic, assign, readonly) BOOL granted;

/// 麦克风是否已打开，默认关闭
@property (nonatomic, assign, readonly) BOOL micOpen;

/// 摄像头是否已打开，默认关闭
@property (nonatomic, assign, readonly) BOOL cameraOpen;

/// 摄像头是否前置，默认前置
@property (nonatomic, assign, readonly) BOOL cameraFront;

/// 获取管理器单例
+ (instancetype)sharedManager;

/// 请求设备的摄像头、麦克风权限
- (void)requestAuthorizationWithCompletion:(void (^)(BOOL grant))completion;

/// 启动设备摄像头用于预览、启动设备麦克风用于录音
- (void)setupMediaWithCompletion:(void (^)(void))completion;

/// 启动设备麦克风用于录音
- (void)setupVideoWithCompletion:(void (^)(void))completion;

/// 进入教室时调用
/// 1. 回收麦克风资源（只有设备检测页需要）
/// 2. 根据业务需要回收摄像头资源（只有讲师登陆未上课的课节需要）
- (void)enterClassroom;

/// 回收摄像头、麦克风资源
- (void)clearResource;

/// 开启麦克风
/// 1. 修改麦克风开关属性 micOpen
/// 2. 触发回调 [-captureDevice:didMicrophoneOpen:]
/// 3. 若持有本地麦克风资源，则操作本地麦克风
- (void)openMicrophone:(BOOL)open;

/// 开启摄像头
/// 1. 修改摄像头开关属性 cameraOpen
/// 2. 触发回调 [-captureDevice:didCameraOpen:]
/// 3. 若持有本地摄像头资源，则操作本地摄像头
- (void)openCamera:(BOOL)open;

/// 切换前后置摄像头
/// 1. 修改前后置摄像头属性 cameraFront
/// 2. 触发回调 [-captureDevice:didCameraSwitch:]
/// 3. 若持有本地摄像头资源，则操作本地摄像头
- (void)switchCamera:(BOOL)front;

@end

/// @note 全部回调方法在主线程执行
@protocol PLVHCCaptureDeviceManagerDelegate <NSObject>

/// 本地麦克风录制音量发生变化
/// @note 持有麦克风资源时每隔0.3秒触发一次
- (void)captureDevice:(PLVHCCaptureDeviceManager *)manager didAudioVolumeChanged:(CGFloat)volume;

/// 麦克风状态开关变化回调
/// @note 调用[-openMicrophone:]修改状态位触发
- (void)captureDevice:(PLVHCCaptureDeviceManager *)manager didMicrophoneOpen:(BOOL)open;

/// 摄像头状态开关变化回调
/// @note 调用[-openCamera:]修改状态位触发
- (void)captureDevice:(PLVHCCaptureDeviceManager *)manager didCameraOpen:(BOOL)open;

/// 摄像头前后置状态变化回调
/// @note 调用[-switchCamera:]修改前后置状态触发
- (void)captureDevice:(PLVHCCaptureDeviceManager *)manager didCameraSwitch:(BOOL)front;

@end

NS_ASSUME_NONNULL_END
