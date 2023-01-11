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

// 模块
#import "PLVCaptureDeviceManager.h"

// 工具类
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <AVFoundation/AVFoundation.h>
#import "PLVHCUtils.h"

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
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *avPreLayer;

@end

@implementation PLVHCHiClassSettingView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = PLV_UIColorFromRGB(@"#1B1C2D");
        [self setupUI];
        [self setupMedia];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
    CGFloat top = [PLVHCUtils sharedUtils].isPad ? 166 : 40;

    self.preView.frame = CGRectMake(edgeInsets.left + 10, top, CGRectGetWidth(self.bounds) - (edgeInsets.left + 10) - (edgeInsets.right + 26) - 203, CGRectGetHeight(self.bounds) - top * 2);
    self.avPreLayer.frame = self.preView.bounds;
    self.cameraDisableImageView.frame = CGRectMake((CGRectGetWidth(self.preView.bounds) - 44) / 2, (CGRectGetHeight(self.preView.bounds) - 44) / 2, 44, 44);
    self.backButton.frame = CGRectMake(edgeInsets.left + 3, CGRectGetMinY(self.preView.frame) - 36, 36, 36);
    
    self.configView.frame = CGRectMake(CGRectGetWidth(self.bounds) - 203 - 10 - edgeInsets.right, top, 203, CGRectGetHeight(self.bounds) - top * 2);
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
    __weak typeof(self) weakSelf = self;
    PLVCaptureDeviceManager *deviceManager = [PLVCaptureDeviceManager sharedManager];
    [deviceManager requestAuthorizationWithoutAlertWithType:PLVCaptureDeviceTypeCameraAndMicrophone completion:^(BOOL granted) {
        if (granted) {
            [deviceManager startVideoCapture];
            [deviceManager startAudioRecorder];
            
            [weakSelf.configView openMediaSwitch];
            weakSelf.avPreLayer = deviceManager.avPreLayer;
            [weakSelf.preView.layer addSublayer:weakSelf.avPreLayer];
            [weakSelf setNeedsLayout];
            [weakSelf layoutIfNeeded];
        } else {
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
    }];
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

#pragma mark - [ Event ]

#pragma mark Action

- (void)backButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapBackButtonInSettingView:)]) {
        [self.delegate didTapBackButtonInSettingView:self];
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVHCSettingConfigViewDelegate

/// 进入教室
- (void)didTapEnterButtonInSettingConfigView:(PLVHCSettingConfigView *)configView {
    [[PLVCaptureDeviceManager sharedManager] requestAuthorizationWithoutAlertWithType:PLVCaptureDeviceTypeCameraAndMicrophone completion:^(BOOL granted) {
        if (granted) {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(didTapEnterClassButtonInSettingView:)]) {
                [self.delegate didTapEnterClassButtonInSettingView:self];
            }
        } else {
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
    }];
}

/// 麦克风开关
- (void)didChangeMicrophoneSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView enable:(BOOL)enable {
    PLVCaptureDeviceManager *deviceManager = [PLVCaptureDeviceManager sharedManager];
    [deviceManager openMicrophone:enable];
    if (deviceManager.microGranted) {
        if (enable) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenMic message:@"已开启麦克风"];
        } else {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CloseMic message:@"已关闭麦克风"];
        }
    }
}

/// 摄像头开关
- (void)didChangeCameraSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView enable:(BOOL)enable {
    PLVCaptureDeviceManager *deviceManager = [PLVCaptureDeviceManager sharedManager];
    [deviceManager openCamera:enable];
    if (deviceManager.cameraGranted) {
        if (enable) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_OpenCamera message:@"已开启摄像头"];
        } else {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CloseCamera message:@"已关闭摄像头"];
        }
    }
}

/// 切换摄像头方向
- (void)didChangeCameraDirectionSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView front:(BOOL)isFront {
    [[PLVCaptureDeviceManager sharedManager] switchCamera:isFront];
}

#pragma mark - [ Public Method ]

- (void)audioVolumeChanged:(CGFloat)volume {
    plv_dispatch_main_async_safe(^{
        [self.configView audioVolumeChanged:volume];
    })
}

@end
