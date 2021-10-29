//
//  PLVHCHiClassSettingView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCHiClassSettingView.h"

// UI
#import "PLVHCSettingConfigView.h"

// 工具类
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <AVFoundation/AVFoundation.h>
#import "PLVHCUtils.h"

// 麦克风音量最大等级
static int volumeMaxLevel = 17;
// 麦克风开关
static NSString *const kSCMicrophoneEnableConfigKey = @"kSCMicrophoneEnableConfigKey";
// 摄像头开关
static NSString *const kSCCameraEnableConfigKey = @"kSCCameraEnableConfigKey";
// 摄像头方向是否为前置
static NSString *const kSCCameraIsFrontConfigKey = @"kSCCameraIsFrontConfigKey";


@interface PLVHCHiClassSettingView ()<PLVHCSettingConfigViewDelegate>

#pragma mark UI
/// view hierarchy
///
/// (PLVHCHiClassSettingView) self
///   └── (UIView) preView
///          ├─ (UIImageView) cameraDisableImageView
///          ├─ (AVCaptureVideoPreviewLayer) avPreLayer
///   ├──  (UIButton) backButton
///   └── (UIView) configView

@property (nonatomic, strong) UIView *preView;  // 摄像头预览区域
@property (nonatomic, strong) UIImageView *cameraDisableImageView; // 摄像头关闭提示icon
@property (nonatomic, strong) UIButton *backButton; // 返回按钮

@property (nonatomic, strong) PLVHCSettingConfigView *configView; // 设置区域

#pragma mark 工具

/// 麦克风
@property (nonatomic, strong) AVAudioRecorder *audioRecorder; // 麦克风检测工具
@property (nonatomic, strong) NSTimer *audioVolumeTimer; // 实时刷新麦克风音量等级

/// 摄像头
@property (nonatomic, strong) AVCaptureSession *avSession;
@property (nonatomic, strong) AVCaptureDeviceInput *avVideoInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *avPreLayer;
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition; // 摄像头方向

#pragma mark 数据

@property (nonatomic, assign, getter=isShowToast) BOOL showToast;

@property (nonatomic, strong) NSMutableDictionary *configDict; // 该数据对应PLVHCSettingSheet的configView开关状态

@end

@implementation PLVHCHiClassSettingView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = PLV_UIColorFromRGB(@"#1B1C2D");
        [self setupUI];
        [self setupMedia];
        [self setupNotification];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;

    self.preView.frame = CGRectMake(edgeInsets.left + 10, 40, CGRectGetWidth(self.bounds) - (edgeInsets.left + 10) - (edgeInsets.right + 26) - 203, CGRectGetHeight(self.bounds) - 80);
    self.avPreLayer.frame = self.preView.bounds;
    self.cameraDisableImageView.frame = CGRectMake((CGRectGetWidth(self.preView.bounds) - 44) / 2, (CGRectGetHeight(self.preView.bounds) - 44) / 2, 44, 44);
    self.backButton.frame = CGRectMake(edgeInsets.left + 3, CGRectGetMinY(self.preView.frame) - 36, 36, 36);
    
    self.configView.frame = CGRectMake(CGRectGetWidth(self.bounds) - 203 - 10 - edgeInsets.right, 40, 203, CGRectGetHeight(self.bounds) - 80);
}

- (void)dealloc {
    [self clear];
}

#pragma mark - [ Private Method ]

#pragma mark Initialize

- (void)setupUI {
    [self addSubview:self.backButton];
    [self addSubview:self.preView];
    [self.preView addSubview:self.cameraDisableImageView];
    
    [self addSubview:self.configView];
}

- (void)setupMedia {
    /// 麦克风、摄像头权限检测
    [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {
        if (granted) {
            // 麦克风音量检测
            [self setupAudioRecorder];
            // 定时器
            [self createAudioVolumeTimer];
            // 摄像头预览（模拟器运行无法开启摄像头）
            #if !(TARGET_IPHONE_SIMULATOR)
                [self setupVideoCaptureDevice];
            #endif
            [self.configView openMediaSwitch];
            self.showToast = YES;
        } else {
            [PLVHCUtils showAlertWithTitle:@"权限不足" message:@"你没开通访问麦克风或相机的权限，如要开通，请移步到设置进行开通" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"设置" confirmActionBlock:^{
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }
    }];
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
        NSLog(@"%@", [error description]);
    }
}

- (void)setupVideoCaptureDevice {
    self.devicePosition = AVCaptureDevicePositionFront;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == self.devicePosition) {
            self.avVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        }
    }
    if ([self.avSession canAddInput:self.avVideoInput]) {
        [self.avSession addInput:self.avVideoInput];
    }
    [self.avSession startRunning];
    [self.preView.layer addSublayer:self.avPreLayer];

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureConnection *previewLayerConnection = self.avPreLayer.connection;
    AVCaptureVideoOrientation videoOrientation = interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? AVCaptureVideoOrientationLandscapeLeft : AVCaptureVideoOrientationLandscapeRight;
    [previewLayerConnection setVideoOrientation:videoOrientation];
}

- (void)setupNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
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

#pragma mark Getter & Setter

- (UIView *)preView {
    if (!_preView) {
        _preView = [[UIView alloc] init];
        _preView.backgroundColor = PLV_UIColorFromRGB(@"#383F64");
        _preView.layer.masksToBounds = YES;
        _preView.layer.cornerRadius = 16;
    }
    return _preView;
}

- (UIImageView *)cameraDisableImageView {
    if (!_cameraDisableImageView) {
        _cameraDisableImageView = [[UIImageView alloc] initWithImage:[PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_setting_camera_disable"]];
        _cameraDisableImageView.hidden = NO;
    }
    return _cameraDisableImageView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton setImage:[PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_setting_back_btn"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (PLVHCSettingConfigView *)configView {
    if (!_configView) {
        _configView = [[PLVHCSettingConfigView alloc] initWithType:PLVHCSettingConfigViewEnterClass];
        _configView.backgroundColor = PLV_UIColorFromRGB(@"#242940");
        _configView.layer.masksToBounds = YES;
        _configView.layer.cornerRadius = 16;
        _configView.delegate = self;
    }
    return _configView;
}

- (AVCaptureSession *)avSession {
    if (!_avSession) {
        _avSession = [[AVCaptureSession alloc] init];
    }
    return _avSession;
}

- (AVCaptureVideoPreviewLayer *)avPreLayer {
    if (!_avPreLayer) {
        _avPreLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.avSession];
        _avPreLayer.connection.automaticallyAdjustsVideoMirroring = NO;
        _avPreLayer.connection.videoMirrored = NO;
        [_avPreLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
    return _avPreLayer;
}

- (NSMutableDictionary *)configDict {
    if (!_configDict) {
        _configDict = [NSMutableDictionary dictionary];
        // 默认值
        plv_dict_set(_configDict, kSCMicrophoneEnableConfigKey, @(NO));
        plv_dict_set(_configDict, kSCCameraEnableConfigKey, @(NO));
        plv_dict_set(_configDict, kSCCameraIsFrontConfigKey, @(YES));
    }
    return _configDict;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)backButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapBackButtonInSettingView:)]) {
        [self.delegate didTapBackButtonInSettingView:self];
    }
}

#pragma mark Timer

- (void)autioDetectionTimerAction:(NSTimer *)timer {
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
    
    /* level 范围[0 ~ 1], 转为[0 ~17] 之间 */
    int level = proportion * volumeMaxLevel;
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i = 0; i < level; i++) {
            CALayer *layer = weakSelf.configView.volumeView.layer.sublayers[i];
            layer.backgroundColor = PLV_UIColorFromRGB(@"#00B16C").CGColor;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            for (int i = 0; i < volumeMaxLevel; i++) {
                CALayer *layer = weakSelf.configView.volumeView.layer.sublayers[i];
                layer.backgroundColor = PLV_UIColorFromRGB(@"#767676").CGColor;
            }
        });
    });
    
}

#pragma mark Notification

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureConnection *previewLayerConnection = self.avPreLayer.connection;
    AVCaptureVideoOrientation videoOrientation = interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? AVCaptureVideoOrientationLandscapeLeft : AVCaptureVideoOrientationLandscapeRight;
    [previewLayerConnection setVideoOrientation:videoOrientation];
}


#pragma mark - [ Delegate ]

#pragma mark PLVHCSettingConfigViewDelegate

/// 进入教室
- (void)didTapEnterButtonInSettingConfigView:(PLVHCSettingConfigView *)configView {
    /// 麦克风、摄像头权限检测
    [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {
        if (granted) {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(didTapEnterClassButtonInSettingView:)]) {
                [self.delegate didTapEnterClassButtonInSettingView:self];
            }
        } else {
            [PLVHCUtils showAlertWithTitle:@"权限不足" message:@"你没开通访问麦克风或相机的权限，如要开通，请移步到设置进行开通" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"设置" confirmActionBlock:^{
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }
    }];
}

/// 麦克风开关
- (void)didChangeMicrophoneSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView enable:(BOOL)enable {
    if (enable) {
        [self.audioRecorder record]; // 启用麦克风
        if (self.isShowToast) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenMic message:@"已开启麦克风"];
        }
    } else {
        [self.audioRecorder pause]; // 关闭麦克风
        if (self.isShowToast) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CloseMic message:@"已关闭麦克风"];
        }
    }
    
    plv_dict_set(self.configDict, kSCMicrophoneEnableConfigKey, @(enable));
}

/// 摄像头开关
- (void)didChangeCameraSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView enable:(BOOL)enable {
    self.cameraDisableImageView.hidden = enable;
    self.avPreLayer.hidden = !enable;
    if (enable) {
        for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (device.position == self.devicePosition) {
                AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
                [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
                if ([self.avPreLayer.session canAddInput:input]) {
                    [self.avPreLayer.session addInput:input];
                }
            }
        }
        if (self.isShowToast) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenCamera message:@"已开启摄像头"];
        }
    } else {
        for (AVCaptureInput *oldInput in self.avPreLayer.session.inputs) {
            [self.avPreLayer.session removeInput:oldInput];
        }
        if (self.isShowToast) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CloseCamera message:@"已关闭摄像头"];
        }
    }
    
    plv_dict_set(self.configDict, kSCCameraEnableConfigKey, @(enable));
}

/// 切换摄像头方向
- (void)didChangeCameraDirectionSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView front:(BOOL)isFront {
    AVCaptureDevicePosition direction = isFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
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
    
    plv_dict_set(self.configDict, kSCCameraIsFrontConfigKey, @(isFront));
}

#pragma mark - [ Public Method ]
- (void)clear {
    [self destroyAudioVolumeTimer];
    [self.avSession stopRunning];
    [self.audioRecorder stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
