//
//  PLVCaptureDeviceManager.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/12/15.
//  Copyright © 2022 PLV. All rights reserved.
//
// 摄像头、麦克风管理器

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, PLVCaptureDeviceType) {
    PLVCaptureDeviceTypeCamera,
    PLVCaptureDeviceTypeMicrophone,
    PLVCaptureDeviceTypeCameraAndMicrophone
};

NS_ASSUME_NONNULL_BEGIN

@protocol PLVCaptureDeviceManagerDelegate;

@interface PLVCaptureDeviceManager : NSObject

@property (nonatomic, weak) id<PLVCaptureDeviceManagerDelegate> delegate;

/// 摄像头是否已授权
@property (nonatomic, assign, readonly) BOOL cameraGranted;

/// 麦克风是否已授权
@property (nonatomic, assign, readonly) BOOL microGranted;

/// 麦克风是否已打开
@property (nonatomic, assign, readonly) BOOL microOpen;

/// 摄像头是否已打开
@property (nonatomic, assign, readonly) BOOL cameraOpen;

/// 摄像头是否前置，默认前置
@property (nonatomic, assign, readonly) BOOL cameraFront;

/// 摄像头本地预览图层
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *avPreLayer;

/// 获取管理器单例
+ (instancetype)sharedManager;

/// 请求授权
/// @note 如果授权被拒，不会出现弹层，可用于需要使用自定义弹层的场景
- (void)requestAuthorizationWithoutAlertWithType:(PLVCaptureDeviceType)type completion:(void (^)(BOOL granted))completion;

/// 请求授权
/// @note 如果授权被拒，会出现默认提示语的弹层
- (void)requestAuthorizationWithType:(PLVCaptureDeviceType)type completion:(void (^)(BOOL granted))completion;

/// 请求授权
/// @param refuseTips 授权被拒的弹窗提示文案
/// @note 如果授权被拒，会出现自定义提示语的弹层
- (void)requestAuthorizationWithType:(PLVCaptureDeviceType)type grantedRefuseTips:(NSString * _Nullable)refuseTips completion:(void (^)(BOOL granted))completion;

/// 启动摄像头用于预览
- (BOOL)startVideoCapture;

/// 启动麦克风用于录音
- (BOOL)startAudioRecorder;

/// 关闭摄像头，相关资源销毁
- (void)releaseVideoResource;

/// 关闭麦克风，相关资源销毁
- (void)releaseAudioResource;

/// 开启摄像头
- (void)openCamera:(BOOL)open;

/// 切换前后置摄像头
- (void)switchCamera:(BOOL)front;

/// 开启麦克风
- (void)openMicrophone:(BOOL)open;

@end

/// @note 全部回调方法在主线程执行
@protocol PLVCaptureDeviceManagerDelegate <NSObject>

@optional

/// 本地麦克风录制音量发生变化
/// @note 持有麦克风资源时每隔0.3秒触发一次
- (void)captureDeviceManager:(PLVCaptureDeviceManager *)manager didAudioVolumeChanged:(CGFloat)volume;

/// 麦克风状态开关变化回调
/// @note 调用[-openMicrophone:]修改状态位触发
- (void)captureDeviceManager:(PLVCaptureDeviceManager *)manager didMicrophoneOpen:(BOOL)open;

/// 摄像头状态开关变化回调
/// @note 调用[-openCamera:]修改状态位触发
- (void)captureDeviceManager:(PLVCaptureDeviceManager *)manager didCameraOpen:(BOOL)open;

/// 摄像头前后置状态变化回调
/// @note 调用[-switchCamera:]修改前后置状态触发
- (void)captureDeviceManager:(PLVCaptureDeviceManager *)manager didCameraSwitch:(BOOL)front;

@end

NS_ASSUME_NONNULL_END
