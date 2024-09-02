//
//  PLVCaptureDeviceManager.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/12/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVCaptureDeviceManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static const BOOL kCameraDefaultFront = YES; // 摄像头 默认前置值

@interface PLVCaptureDeviceManager ()

#pragma mark 状态

/// 麦克风
@property (nonatomic, assign) BOOL microOpen; // 麦克风是否已打开，默认关闭

/// 摄像头
@property (nonatomic, assign) BOOL cameraOpen; // 摄像头是否已打开，默认关闭
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition; // 摄像头方向
@property (nonatomic, assign, readonly) AVCaptureVideoOrientation videoOrientation; // 摄像头采集的方向

#pragma mark 功能模块

/// 麦克风
@property (nonatomic, strong) AVAudioRecorder *audioRecorder; // 麦克风检测工具
@property (nonatomic, strong) NSTimer *audioVolumeTimer; // 实时刷新麦克风音量等级

/// 摄像头
@property (nonatomic, strong) AVCaptureSession *avSession;
@property (nonatomic, strong) AVCaptureDeviceInput *avVideoInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *avPreLayer; // 摄像头预览图层

@end

@implementation PLVCaptureDeviceManager

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _devicePosition = kCameraDefaultFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    }
    return self;
}

#pragma mark - [ Public Method ]

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static PLVCaptureDeviceManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)requestAuthorizationWithoutAlertWithType:(PLVCaptureDeviceType)type completion:(void (^)(BOOL granted))completion {
    PLVAuthorizationType authorType = (PLVAuthorizationType)type;
    [PLVAuthorizationManager requestAuthorizationWithType:authorType completion:^(BOOL granted) {
        if (completion) {
            completion(granted);
        }
    }];
}

- (void)requestAuthorizationWithType:(PLVCaptureDeviceType)type completion:(void (^)(BOOL granted))completion {
    [self requestAuthorizationWithType:type grantedRefuseTips:nil completion:completion];
}

- (void)requestAuthorizationWithType:(PLVCaptureDeviceType)type grantedRefuseTips:(NSString *)refuseTips completion:(void (^)(BOOL granted))completion {
    NSString *device = PLVLocalizedString(@"麦克风或摄像头");
    if (type == PLVCaptureDeviceTypeCamera) {
        device = PLVLocalizedString(@"摄像头");
    } else if (type == PLVCaptureDeviceTypeMicrophone) {
        device = PLVLocalizedString(@"麦克风");
    }
    NSString *tips = refuseTips ?: [NSString stringWithFormat:PLVLocalizedString(@"你没开通访问%@的权限，如要开通，请移步到设置进行开通"), device];
    PLVAuthorizationType authorType = (PLVAuthorizationType)type;
    [PLVAuthorizationManager requestAuthorizationWithType:authorType completion:^(BOOL granted) {
        if (!granted) {
            [PLVFdUtil showAlertWithTitle:PLVLocalizedString(@"提示")
                                  message:tips
                           viewController:[PLVFdUtil getCurrentViewController]
                        cancelActionTitle:PLVLocalizedString(@"取消")
                        cancelActionStyle:UIAlertActionStyleDefault
                        cancelActionBlock:nil
                       confirmActionTitle:PLVLocalizedString(@"前往设置")
                       confirmActionStyle:UIAlertActionStyleDestructive
                       confirmActionBlock:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }
        if (completion) {
            completion(granted);
        }
    }];
}

- (BOOL)startVideoCapture {
    if (!self.cameraGranted) {
        return NO;
    }
#if !(TARGET_IPHONE_SIMULATOR)
    [self setupVideoCapture];
#endif
    return YES;
}

- (BOOL)startAudioRecorder {
    if (!self.microGranted) {
        return NO;
    }
    
    [self setupAudioRecorder];
    return YES;
}

- (void)releaseVideoResource {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.avSession stopRunning];
    [_avPreLayer removeFromSuperlayer];
    
    _avSession = nil;
    _avPreLayer = nil;
    _avVideoInput = nil;
}

- (void)releaseAudioResource {
    [self destroyAudioVolumeTimer];
    
    [self.audioRecorder stop];
    _audioRecorder = nil;
}

- (void)openCamera:(BOOL)open {
    if (!_avPreLayer) {
        return;
    }
    
    self.cameraOpen = open;
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
    
    [self notifyCameraOpen:open];
}

- (void)switchCamera:(BOOL)front {
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
    
    [self notifyCameraSwitch:front];
}

- (void)openMicrophone:(BOOL)open {
    if (!_audioRecorder) {
        return;
    }
    
    self.microOpen = open;
    
    if (open) {
        [self.audioRecorder record]; // 启用麦克风
    } else {
        [self.audioRecorder pause]; // 关闭麦克风
    }
    
    [self notifyMicrophoneOpen:open];
}

#pragma mark Getter & Setter

- (BOOL)cameraGranted {
    PLVAuthorizationStatus status = [PLVAuthorizationManager authorizationStatusWithType:PLVAuthorizationTypeMediaVideo];
    return status == PLVAuthorizationStatusAuthorized;
}

- (BOOL)microGranted {
    PLVAuthorizationStatus status = [PLVAuthorizationManager authorizationStatusWithType:PLVAuthorizationTypeMediaAudio];
    return status == PLVAuthorizationStatusAuthorized;
}

- (BOOL)cameraFront {
    return self.devicePosition == AVCaptureDevicePositionFront;
}

#pragma mark - [ Private Method ]

- (void)setupVideoCapture {
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
    [self.avPreLayer.connection setVideoOrientation:self.videoOrientation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interfaceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

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
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeVerbose, @"%@", [error description]);
    }
    
    // 音量实时监测定时器
    [self createAudioVolumeTimer];
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
        [self.delegate respondsToSelector:@selector(captureDeviceManager:didAudioVolumeChanged:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate captureDeviceManager:self didAudioVolumeChanged:volume];
        })
    }
}

- (void)notifyMicrophoneOpen:(BOOL)open {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(captureDeviceManager:didMicrophoneOpen:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate captureDeviceManager:self didMicrophoneOpen:open];
        })
    }
}

- (void)notifyCameraOpen:(BOOL)open {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(captureDeviceManager:didCameraOpen:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate captureDeviceManager:self didCameraOpen:open];
        })
    }
}

- (void)notifyCameraSwitch:(BOOL)front {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(captureDeviceManager:didCameraSwitch:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate captureDeviceManager:self didCameraSwitch:front];
        })
    }
}

#pragma mark Getter & Setter

- (AVCaptureVideoOrientation)videoOrientation {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    return videoOrientation;
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
    if (self.avPreLayer) {
        if (self.avPreLayer.connection != nil) {
            [self.avPreLayer.connection setVideoOrientation:self.videoOrientation];
        }
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

@end
