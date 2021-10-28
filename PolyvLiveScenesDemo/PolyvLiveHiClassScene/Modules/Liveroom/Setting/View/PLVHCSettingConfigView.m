//
//  PLVHCSettingConfigView.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/8/4.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCSettingConfigView.h"

// 模块
#import "PLVRoomDataManager.h"

// 工具
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVHCUtils.h"

// 麦克风音量最大等级
static int volumeMaxLevel = 17;
// 麦克风开关
static NSString *const kSCMicrophoneEnableConfigKey = @"kSCMicrophoneEnableConfigKey";
// 摄像头开关
static NSString *const kSCCameraEnableConfigKey = @"kSCCameraEnableConfigKey";
// 摄像头方向是否为前置
static NSString *const kSCCameraIsFrontConfigKey = @"kSCCameraIsFrontConfigKey";

@interface PLVHCSettingConfigView()

/// view hierarchy
/// [进入教室类型]
/// (PLVHCSettingConfigView) self
///          ├─ (UIView) microphoneConfigView
///          ├─ (UIView) volumeView
///          ├─ (UIView) cameraConfigView
///          ├─ (UIView) cameraDirectionConfigView
///          └─ (UIButton) enterClassButton
///
///
/// [退出教室类型]
/// (PLVHCSettingConfigView) self
///          ├─ (UIView) microphoneConfigView
///          ├─ (UIView) cameraConfigView
///          ├─ (UIView) cameraDirectionConfigView
///          ├─ (UIView) fullScreenConfigView
///          └─ (UIButton) logoutButton

@property (nonatomic, strong) UIButton *enterClassButton; // 【进入教室】按钮
@property (nonatomic, strong) UIButton *logoutButton; // 【退出教室】按钮
@property (nonatomic, strong) CAGradientLayer *gradientLayer; // 进入教室按钮渐变色
@property (nonatomic, strong) UIView *microphoneConfigView; // 麦克风开关控制区域
@property (nonatomic, strong) UIView *volumeView; // 麦克风音量等级
@property (nonatomic, strong) UIView *cameraConfigView; // 摄像头开关控制区域
@property (nonatomic, strong) UIView *cameraDirectionConfigView; // 摄像头方向控制区域
@property (nonatomic, strong) UIView *fullScreenConfigView; // 全屏开关控制区域
@property (nonatomic, strong) CALayer *cameraDirectionButtonLayer; // 切换摄像头方向按钮layer

#pragma mark 数据
@property (nonatomic, assign) PLVHCSettingConfigViewType type;
@property (nonatomic, assign) BOOL micSwitchOn; // 麦克风开关状态保存
@property (nonatomic, assign) BOOL cameraSwitchOn; // 摄像头开关状态保存
@end

@implementation PLVHCSettingConfigView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithType:(PLVHCSettingConfigViewType)type {
    self = [super init];
    if (self) {
        self.type = type;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize settingCellSize = CGSizeMake(163, 23);
    
    self.microphoneConfigView.frame = CGRectMake(20, 16, settingCellSize.width, settingCellSize.height);
    if (self.type == PLVHCSettingConfigViewEnterClass) { // 进入教室类型
        self.enterClassButton.frame = CGRectMake((CGRectGetMaxX(self.bounds) - 126) / 2, CGRectGetMaxY(self.bounds) - 16 - 36, 126, 36);
        self.gradientLayer.frame = self.enterClassButton.bounds;
        
        self.volumeView.frame = CGRectMake(48, CGRectGetMaxY(self.microphoneConfigView.frame) + 16, CGRectGetMaxX(self.bounds) - 48 - 25, 14);
        
        UISwitch *microphoneSwitch = (UISwitch *)[self viewWithTag:1];
        if (microphoneSwitch.on) {
            self.cameraConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.volumeView.frame) + 20, settingCellSize.width, settingCellSize.height);
            self.cameraDirectionConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        } else {
            self.cameraConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.microphoneConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
            self.cameraDirectionConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        }
    } else { // 退出教室类型
        self.logoutButton.frame = CGRectMake((CGRectGetMaxX(self.bounds) - 126) / 2, CGRectGetMaxY(self.bounds) - 16 - 36, 126, 36);
        self.cameraConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.microphoneConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        self.cameraDirectionConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        
        UISwitch *cameraSwitch = (UISwitch *)[self viewWithTag:2];
        if (cameraSwitch.on) {
            self.fullScreenConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraDirectionConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        } else {
            self.fullScreenConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        }
    }

}

#pragma mark - [ Public Method ]

- (void)openMediaSwitch {
    if (self.type == PLVHCSettingConfigViewEnterClass) {
        UISwitch *microphoneSwitch = (UISwitch *)[self viewWithTag:1];
        microphoneSwitch.on = YES;
        UISwitch *cameraSwitch = (UISwitch *)[self viewWithTag:2];
        cameraSwitch.on = YES;
        
        [self notifyControlSwitchAction:microphoneSwitch];
        [self notifyControlSwitchAction:cameraSwitch];
    }
}

- (void)synchronizeConfig:(NSDictionary *)dict {
    if (self.type == PLVHCSettingConfigViewLogoutClass) {
        if ([PLVFdUtil checkDictionaryUseable:dict]) {
            UISwitch *microphoneSwitch = (UISwitch *)[self viewWithTag:1];
            microphoneSwitch.on = PLV_SafeBoolForDictKey(dict, kSCMicrophoneEnableConfigKey);
            
            UISwitch *cameraSwitch = (UISwitch *)[self viewWithTag:2];
            cameraSwitch.on = PLV_SafeBoolForDictKey(dict, kSCCameraEnableConfigKey);
            
            UIButton *cameraDirectionButton = (UIButton *)[self viewWithTag:999];
            cameraDirectionButton.selected = PLV_SafeBoolForDictKey(dict, kSCCameraIsFrontConfigKey);
            
            [self notifyControlSwitchAction:microphoneSwitch];
            [self notifyControlSwitchAction:cameraSwitch];
            [self notifyCameraDirectionButtonAction:cameraDirectionButton];
        }
    }
}

- (void)microphoneSwitchChange:(BOOL)open {
    UISwitch *microphoneSwitch = (UISwitch *)[self viewWithTag:1];
    if (microphoneSwitch.on == open) {
        return;
    }
    microphoneSwitch.on = open;
    [self controlSwitchAction:microphoneSwitch];
}

- (void)cameraSwitchChange:(BOOL)open {
    UISwitch *cameraSwitch = (UISwitch *)[self viewWithTag:2];
    if (cameraSwitch.on == open) {
        return;
    }
    cameraSwitch.on = open;
    [self controlSwitchAction:cameraSwitch];
}

- (void)cameraDirectionChange:(BOOL)front {
    UIButton *cameraDirectionButton = (UIButton *)[self viewWithTag:999];
    if (cameraDirectionButton.selected != front) {
        return;
    }
    [self cameraDirectionButtonAction:cameraDirectionButton];
}

#pragma mark - [ Private Method ]

#pragma mark Initialize

- (void)setupUI {
    [self addSubview:self.microphoneConfigView];
    [self addSubview:self.cameraConfigView];
    [self addSubview:self.cameraDirectionConfigView];
    // 进入教室类型
    if (self.type == PLVHCSettingConfigViewEnterClass) {
        [self addSubview:self.volumeView];
        [self addSubview:self.enterClassButton];
    } else {
        // 退出教室类型
        [self addSubview:self.fullScreenConfigView];
        [self addSubview:self.logoutButton];
    }
}

- (UIView *)createConfigViewWithImage:(NSString *)imageString title:(NSString *)text tag:(NSInteger)tag {
    UIView *contentView = [[UIView alloc] init];

    // icon
    UIImageView *image = [[UIImageView alloc] initWithImage:[PLVHCUtils imageForLiveroomResource:imageString]];
    [contentView addSubview:image];
    image.frame = CGRectMake(0, 0, 23, 23);
    
    // 文本
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(image.frame) + 5, (CGRectGetHeight(image.frame) - 16) / 2, 42, 16)];
    label.text = text;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    label.textColor = [UIColor whiteColor];
    [contentView addSubview:label];
    
    if (tag == 1 || tag == 2 || tag == 3) { // 开关
        UISwitch *controlSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(118, -4, 38, 22)];
        controlSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75);
        controlSwitch.onTintColor = PLV_UIColorFromRGB(@"#00B16C");
        controlSwitch.tag = tag;
        [controlSwitch addTarget:self action:@selector(controlSwitchAction:) forControlEvents:UIControlEventValueChanged];
        [contentView addSubview:controlSwitch];
    } else { // 按钮
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(95, 0, 68, 23)];
        [button setTitle:@"前   后" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 11;
        button.backgroundColor = PLV_UIColorFromRGB(@"#777777");
        [contentView addSubview:button];
        [button addTarget:self action:@selector(cameraDirectionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = tag;

        self.cameraDirectionButtonLayer.frame = CGRectMake(0, 0, CGRectGetWidth(button.bounds) / 2 + 5, 23);
        [button.layer insertSublayer:self.cameraDirectionButtonLayer atIndex:0];
    }
    return contentView;
}

#pragma mark 修改子视图布局

- (void)microphoneSwitchRefreshView:(BOOL)on {
    if (self.type == PLVHCSettingConfigViewEnterClass) {
        CGSize settingCellSize = CGSizeMake(163, 23);
        if (on) {
            self.cameraConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.volumeView.frame) + 20, settingCellSize.width, settingCellSize.height);
            self.cameraDirectionConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        } else {
            self.cameraConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.microphoneConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
            self.cameraDirectionConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        }
    }
}

- (void)cameraSwitchRefreshView:(BOOL)on {
    if (self.type == PLVHCSettingConfigViewLogoutClass) {
        CGSize settingCellSize = CGSizeMake(163, 23);
        if (on) {
            self.fullScreenConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraDirectionConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        } else {
            self.fullScreenConfigView.frame = CGRectMake(CGRectGetMinX(self.microphoneConfigView.frame), CGRectGetMaxY(self.cameraConfigView.frame) + 20, settingCellSize.width, settingCellSize.height);
        }
    }
}

//是否需要禁用开关，在进入教室学生端、 在上课后、 但是未上台时需要禁用音视频开关
- (BOOL)shouldDisableSwitch {
    PLVRoomUserType viewerType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (self.type == PLVHCSettingConfigViewLogoutClass &&
        viewerType == PLVRoomUserTypeSCStudent &&
        [PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(alreadyLinkMicLocalStudentInSettingConfigView)]) {
            BOOL linkMic = [self.delegate alreadyLinkMicLocalStudentInSettingConfigView];
            return linkMic ? NO : YES;
        }
    }
    return NO;
}

#pragma mark Notify Delegate

- (void)notifyControlSwitchAction:(UISwitch *)sender {
    if (sender.tag == 1 || sender.tag == 2) {
        [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {
            if (!granted) {
                [PLVHCUtils showToastInWindowWithMessage:@"你没开通访问相机或者麦克风的权限，如要开通，请移步到:设置->隐私 进行开启"];
                sender.on = NO;
                return;
            } else {
                if (sender.tag == 1) { // 麦克风开关
                    self.micSwitchOn = sender.on;
                    self.volumeView.hidden = !sender.on;
                    [self microphoneSwitchRefreshView:sender.on];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeMicrophoneSwitchInSettingConfigView:enable:)]) {
                        [self.delegate didChangeMicrophoneSwitchInSettingConfigView:self enable:sender.on];
                    }
                } else if (sender.tag == 2) { // 摄像头开关
                    self.cameraSwitchOn = sender.on;
                    self.cameraDirectionConfigView.hidden = !sender.on;
                    [self cameraSwitchRefreshView:sender.on];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeCameraSwitchInSettingConfigView:enable:)]) {
                        [self.delegate didChangeCameraSwitchInSettingConfigView:self enable:sender.on];
                    }
                }
            }
        }];
    } else if (sender.tag == 3) { // 全屏开关
        if (self.type == PLVHCSettingConfigViewLogoutClass) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeFullScreenSwitchInSettingConfigView:fullScreen:)]) {
                [self.delegate didChangeFullScreenSwitchInSettingConfigView:self fullScreen:sender.on];
            }
        }
    }
}

/// 摄像头方向切换
- (void)notifyCameraDirectionButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        self.cameraDirectionButtonLayer.frame = CGRectMake(CGRectGetWidth(sender.bounds) / 2 - 5, 0, CGRectGetWidth(sender.bounds) + 5, 23);
    } else {
        self.cameraDirectionButtonLayer.frame = CGRectMake(0, 0, CGRectGetWidth(sender.bounds) / 2 + 5, 23);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeCameraDirectionSwitchInSettingConfigView:front:)]) {
        [self.delegate didChangeCameraDirectionSwitchInSettingConfigView:self front:!sender.selected];
    }
}

#pragma mark getter & setter

- (UIButton *)enterClassButton {
    if (!_enterClassButton) {
        _enterClassButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_enterClassButton setTitle:@"进入教室" forState:UIControlStateNormal];
        _enterClassButton.layer.masksToBounds = YES;
        _enterClassButton.layer.cornerRadius = 18.0;
        [_enterClassButton.layer insertSublayer:self.gradientLayer atIndex:0];
        _enterClassButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        [_enterClassButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_enterClassButton addTarget:self action:@selector(enterClassButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _enterClassButton;
}

- (UIButton *)logoutButton {
    if (!_logoutButton) {
        _logoutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_logoutButton setTitle:@"退出教室" forState:UIControlStateNormal];
        [_logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _logoutButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _logoutButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _logoutButton.layer.borderWidth = 1;
        _logoutButton.layer.cornerRadius = 18;
        [_logoutButton addTarget:self action:@selector(logoutButtonAction) forControlEvents:UIControlEventTouchUpInside];

    }
    return _logoutButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#00B16C").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#00E78D").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (UIView *)microphoneConfigView {
    if (!_microphoneConfigView) {
        _microphoneConfigView = [self createConfigViewWithImage:@"plvhc_liveroom_setting_microphone_icon" title:@"麦克风" tag:1];
    }
    return _microphoneConfigView;
}

- (UIView *)cameraConfigView {
    if (!_cameraConfigView) {
        _cameraConfigView = [self createConfigViewWithImage:@"plvhc_liveroom_setting_camera_icon" title:@"摄像头" tag:2];

    }
    return _cameraConfigView;
}

- (UIView *)fullScreenConfigView {
    if (!_fullScreenConfigView) {
        _fullScreenConfigView = [self createConfigViewWithImage:@"plvhc_liveroom_fullscreen_icon" title:@"全屏" tag:3];
    }
    return _fullScreenConfigView;
}

- (UIView *)cameraDirectionConfigView {
    if (!_cameraDirectionConfigView) {
        _cameraDirectionConfigView = [self createConfigViewWithImage:@"plvhc_liveroom_setting_direction_icon" title:@"方向" tag:999];
        if (self.type == PLVHCSettingConfigViewEnterClass) {
            _cameraDirectionConfigView.hidden = YES;
        }
    }
    return _cameraDirectionConfigView;
}

- (UIView *)volumeView {
    if (!_volumeView) {
        _volumeView = [[UIView alloc] init];
        _volumeView.hidden = YES;
        for (int i = 0; i < volumeMaxLevel; i++) {
            CALayer *layer = [CALayer layer];
            layer.backgroundColor = PLV_UIColorFromRGB(@"#767676").CGColor;
            layer.cornerRadius = 2.33;
            layer.masksToBounds = YES;
            layer.frame = CGRectMake(i * 8, 0, 2, 14);
            [_volumeView.layer addSublayer:layer];
        }
    }
    return _volumeView;
}

- (CALayer *)cameraDirectionButtonLayer {
    if (!_cameraDirectionButtonLayer) {
        _cameraDirectionButtonLayer = [CALayer layer];
        _cameraDirectionButtonLayer.backgroundColor = PLV_UIColorFromRGB(@"#00B16C").CGColor;
        _cameraDirectionButtonLayer.masksToBounds = YES;
        _cameraDirectionButtonLayer.cornerRadius = 11;
    }
    return _cameraDirectionButtonLayer;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)enterClassButtonAction {
    if (self.type == PLVHCSettingConfigViewEnterClass) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(didTapEnterButtonInSettingConfigView:)]) {
            [self.delegate didTapEnterButtonInSettingConfigView:self];
        }
    }
}

- (void)logoutButtonAction {
    if (self.type == PLVHCSettingConfigViewLogoutClass) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(didTapLogoutButtonInSettingConfigView:)]) {
            [self.delegate didTapLogoutButtonInSettingConfigView:self];
        }
    }
}

- (void)controlSwitchAction:(UISwitch *)sender {
    if (sender.tag == 1 || sender.tag == 2) {
        if ([self shouldDisableSwitch]) {
            BOOL senderOn = sender.tag == 1 ? self.micSwitchOn : self.cameraSwitchOn;
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setOn:senderOn animated:YES];
            });
            NSString *message = sender.tag == 1 ? @"未上台无法设置麦克风" : @"未上台无法设置摄像头";
            [PLVHCUtils showToastInWindowWithMessage:message];
            return;
        }
    }
    [self notifyControlSwitchAction:sender];
}

/// 摄像头方向切换
- (void)cameraDirectionButtonAction:(UIButton *)sender {
    if ([self shouldDisableSwitch]) {
        [PLVHCUtils showToastInWindowWithMessage:@"未上台无法设置摄像头方向"];
        return;
    }
    [self notifyCameraDirectionButtonAction:sender];
}

@end
