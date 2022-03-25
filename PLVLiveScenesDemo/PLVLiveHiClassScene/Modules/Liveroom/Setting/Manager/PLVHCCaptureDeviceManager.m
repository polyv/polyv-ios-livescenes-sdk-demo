//
//  PLVHCCaptureDeviceManager.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/11/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCCaptureDeviceManager.h"

// 模块
#import "PLVRoomDataManager.h"

// 工具类
#import "PLVHCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

// 麦克风、摄像头默认值
static const BOOL kMicDefaultOpen = NO;      // 麦克风按钮 默认开关值
static const BOOL kCameraDefaultOpen = NO;   // 摄像头按钮 默认开关值
static const BOOL kCameraDefaultFront = YES; // 摄像头 默认前置值

@interface PLVHCCaptureDeviceManager ()

#pragma mark 状态

@property (nonatomic, assign) BOOL granted; // 应用是否已获得本地摄像头、麦克风权限
@property (nonatomic, assign) BOOL micOpen; // 麦克风是否已打开，默认关闭
@property (nonatomic, assign) BOOL cameraOpen; // 摄像头是否已打开，默认关闭
@property (nonatomic, assign) BOOL cameraFront; // 摄像头是否前置，默认前置

#pragma mark 功能模块

/// 麦克风
@property (nonatomic, strong) AVAudioRecorder *audioRecorder; // 麦克风检测工具
@property (nonatomic, strong) NSTimer *audioVolumeTimer; // 实时刷新麦克风音量等级

/// 摄像头
@property (nonatomic, strong) AVCaptureSession *avSession;
@property (nonatomic, strong) AVCaptureDeviceInput *avVideoInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *avPreLayer; // 摄像头预览图层
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition; // 摄像头方向

@end

@implementation PLVHCCaptureDeviceManager

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.micOpen = kMicDefaultOpen;
        self.cameraOpen = kCameraDefaultOpen;
        self.cameraFront = kCameraDefaultFront;
    }
    return self;
}

#pragma mark - [ Public Method ]

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static PLVHCCaptureDeviceManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)requestAuthorizationWithCompletion:(void (^)(BOOL grant))completion {
    __weak typeof(self) weakSelf = self;
    [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {
        weakSelf.granted = granted;
        if (!granted) {
            [PLVHCUtils showAlertWithTitle:@"权限不足"
                                   message:@"你没开通访问麦克风或相机的权限，如要开通，请移步到设置进行开通"
                         cancelActionTitle:@"取消"
                         cancelActionBlock:nil
                        confirmActionTitle:@"设置"
                        confirmActionBlock:^{
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }
        if (completion) {
            plv_dispatch_main_async_safe(^{
                completion(granted);
            })
        }
    }];
}

- (void)setupMediaWithCompletion:(void (^)(void))completion {
    __weak typeof(self) weakSelf = self;
    [self requestAuthorizationWithCompletion:^(BOOL grant) {
        if (grant) {
            // 麦克风音量检测
            [weakSelf setupAudioRecorder];
            // 摄像头预览（模拟器运行无法开启摄像头）
            #if !(TARGET_IPHONE_SIMULATOR)
                [weakSelf setupVideoCaptureDevice];
            #endif
            
            if (completion) {
                completion();
            }
        }
    }];
}

- (void)setupVideoWithCompletion:(void (^)(void))completion {
    __weak typeof(self) weakSelf = self;
    [self requestAuthorizationWithCompletion:^(BOOL grant) {
        if (grant) {
            // 摄像头预览（模拟器运行无法开启摄像头）
            #if !(TARGET_IPHONE_SIMULATOR)
                [weakSelf setupVideoCaptureDevice];
            #endif
            
            if (completion) {
                completion();
            }
        }
    }];
}

- (void)enterClassroom {
    // 1. 回收麦克风资源（只有设备检测页需要）
    [self clearAudioResource];
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass ||
        roomData.roomUser.viewerType != PLVRoomUserTypeTeacher) {
        // 2. 根据业务需要回收摄像头资源（只有讲师登陆未上课的课节需要持有摄像头资源）
        [self clearVideoResource];
    }
}

- (void)clearResource {
    [self clearAudioResource];
    [self clearVideoResource];
}

- (void)openMicrophone:(BOOL)open {
    self.micOpen = open;
    [self notifyMicrophoneOpen:open];
    
    if (!_audioRecorder) {
        return;
    }
    if (open) {
        [self.audioRecorder record]; // 启用麦克风
    } else {
        [self.audioRecorder pause]; // 关闭麦克风
    }
}

- (void)openCamera:(BOOL)open {
    self.cameraOpen = open;
    [self notifyCameraOpen:open];
    
    if (!_avPreLayer) {
        return;
    }
    self.avPreLayer.hidden = !open;
    
    if (open) {
        for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (device.position == self.devicePosition) {
                AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
                [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
                if ([self.avPreLayer.session canAddInput:input]) {
                    [self.avPreLayer.session addInput:input];
                }
            }
        }
    } else {
        for (AVCaptureInput *oldInput in self.avPreLayer.session.inputs) {
            [self.avPreLayer.session removeInput:oldInput];
        }
    }
}

- (void)switchCamera:(BOOL)front {
    self.cameraFront = front;
    [self notifyCameraSwitch:front];
    
    if (!_avPreLayer) {
        return;
    }
    
    AVCaptureDevicePosition direction = front ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    self.devicePosition = direction;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == direction) {
            [self.avPreLayer.session beginConfiguration];
            for (AVCaptureInput *oldInput in self.avPreLayer.session.inputs) {
                [self.avPreLayer.session removeInput:oldInput];
            }
            
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            if ([self.avPreLayer.session canAddInput:input]) {
                [self.avPreLayer.session addInput:input];
            }
            [self.avPreLayer.session commitConfiguration];
            break;
        }
    }
}

#pragma mark - [ Private Method ]

#pragma mark Initialize

- (void)setupAudioRecorder {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth error:nil];

    /* 不需要保存录音文件 */
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];

    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                              [NSNumber numberWithInt:kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:AVAudioQualityMax], AVEncoderAudioQualityKey,
                              nil];

    NSError *error;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (_audioRecorder) {
        // 启用音频级别度量
        _audioRecorder.meteringEnabled = YES;
        // 开始录音
        [_audioRecorder record];
    } else {
        NSLog(@"%@", [error description]);
    }
    
    // 音量实时监测定时器
    [self createAudioVolumeTimer];
}

- (void)setupVideoCaptureDevice {
    self.devicePosition = AVCaptureDevicePositionFront;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == self.devicePosition) {
            self.avVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        }
    }
    self.avSession = [[AVCaptureSession alloc] init];
    if ([self.avSession canAddInput:self.avVideoInput]) {
        [self.avSession addInput:self.avVideoInput];
    }
    [self.avSession startRunning];

    self.avPreLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.avSession];
    self.avPreLayer.connection.automaticallyAdjustsVideoMirroring = NO;
    self.avPreLayer.connection.videoMirrored = NO;
    [self.avPreLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? AVCaptureVideoOrientationLandscapeLeft : AVCaptureVideoOrientationLandscapeRight;
    [self.avPreLayer.connection setVideoOrientation:videoOrientation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interfaceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

#pragma mark 资源销毁

- (void)clearAudioResource {
    [self destroyAudioVolumeTimer];
    [self.audioRecorder stop];
    _audioRecorder = nil;
}

- (void)clearVideoResource {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.avSession stopRunning];
    [_avPreLayer removeFromSuperlayer];
    
    _avSession = nil;
    _avPreLayer = nil;
    _avVideoInput = nil;
    _devicePosition = AVCaptureDevicePositionUnspecified;
}

#pragma mark Timer

- (void)createAudioVolumeTimer {
    if (_audioVolumeTimer) {
        [self destroyAudioVolumeTimer];
    }
    _audioVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(autioDetectionTimerAction:) userInfo:nil repeats:YES];
}

- (void)destroyAudioVolumeTimer {
    [_audioVolumeTimer invalidate];
    _audioVolumeTimer = nil;
}

#pragma mark Notify Delegate

- (void)notifyAudioVolumeChanged:(CGFloat)volume {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(captureDevice:didAudioVolumeChanged:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate captureDevice:self didAudioVolumeChanged:volume];
        })
    }
}

- (void)notifyMicrophoneOpen:(BOOL)open {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(captureDevice:didMicrophoneOpen:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate captureDevice:self didMicrophoneOpen:open];
        })
    }
}

- (void)notifyCameraOpen:(BOOL)open {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(captureDevice:didCameraOpen:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate captureDevice:self didCameraOpen:open];
        })
    }
}

- (void)notifyCameraSwitch:(BOOL)front {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(captureDevice:didCameraSwitch:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate captureDevice:self didCameraSwitch:front];
        })
    }
}

#pragma mark - [ Event ]

#pragma mark Timer

- (void)autioDetectionTimerAction:(NSTimer *)timer {
    if (!self.audioRecorder) {
        [self destroyAudioVolumeTimer];
        return;
    }
    
    [self.audioRecorder updateMeters];

    float proportion;                   // The linear 0.0 .. 1.0 value we need.
    float minDecibels = -60.0f;    // use -80db Or use -60dB, which I measured in a silent room.
    float decibels = [self.audioRecorder averagePowerForChannel:0];

    if (decibels < minDecibels) {
        proportion = 0.0f;
    } else if (decibels >= 0.0f) {
        proportion = 1.0f;
    } else {
        float root = 2.0f; // modified level from 2.0 to 5.0 is neast to real test
        float minAmp = powf(10.0f, 0.05f * minDecibels);
        float inverseAmpRange = 1.0f / (1.0f - minAmp);
        float amp = powf(10.0f, 0.05f * decibels);
        float adjAmp = (amp - minAmp) * inverseAmpRange;

        proportion = powf(adjAmp, 1.0f / root);
    }
    
    [self notifyAudioVolumeChanged:proportion];
}

#pragma mark Notification

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    if (!self.avPreLayer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        return;
    }
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureConnection *previewLayerConnection = self.avPreLayer.connection;
    AVCaptureVideoOrientation videoOrientation = interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? AVCaptureVideoOrientationLandscapeLeft : AVCaptureVideoOrientationLandscapeRight;
    [previewLayerConnection setVideoOrientation:videoOrientation];
}

@end
