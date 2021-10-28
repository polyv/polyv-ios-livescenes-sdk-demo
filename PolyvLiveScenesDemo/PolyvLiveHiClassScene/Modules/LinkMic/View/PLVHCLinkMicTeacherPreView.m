//
//  PLVHCLinkMicTeacherPreView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/9/2.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCLinkMicTeacherPreView.h"
#import "PLVRoomDataManager.h"

// 工具类
#import "PLVHCUtils.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <AVFoundation/AVFoundation.h>

// 麦克风开关
static NSString *const kSCMicrophoneEnableConfigKey = @"kSCMicrophoneEnableConfigKey";
// 摄像头开关
static NSString *const kSCCameraEnableConfigKey = @"kSCCameraEnableConfigKey";
// 摄像头方向是否为前置
static NSString *const kSCCameraIsFrontConfigKey = @"kSCCameraIsFrontConfigKey";
//当前用户昵称Key
static NSString *const kSCLocalPrevierUserNicknameKey = @"kSCLocalPrevierUserNicknameKey";
//当前用户头像key
static NSString *const kSCLocalPrevierUserAvatarURLKey = @"kSCLocalPrevierUserAvatarURLKey";

@interface PLVHCLinkMicTeacherPreView ()

@property (nonatomic, strong) UIView *preView;  // 摄像头预览区域
@property (nonatomic, strong) UILabel *maxNicknameLabel; //大昵称
@property (nonatomic, strong) UILabel *minNicknameLabel; //小昵称
@property (nonatomic, strong) UIImageView *micImageView; //麦克风
@property (nonatomic, strong) PLVHCLinkMicStudentRoleTeacherPreView *studentRoleTeacherPreView; //学生角色的讲师预览图

#pragma mark 工具
/// 摄像头
@property (nonatomic, strong) AVCaptureSession *avSession;
@property (nonatomic, strong) AVCaptureDeviceInput *avVideoInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *avPreLayer;
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition; // 摄像头方向

#pragma mark 数据
@property (nonatomic, strong) NSMutableDictionary *configDict; // 该数据对应PLVHCSettingSheet的configView开关状态
@property (nonatomic, assign) PLVRoomUserType userType;//用户类型

@end

@implementation PLVHCLinkMicTeacherPreView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = PLV_UIColorFromRGB(@"#1B1C2D");
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.userType = roomData.roomUser.viewerType;
        [self setupUI];
        if (self.userType == PLVRoomUserTypeTeacher) {
            [self setupUserModule];
            [self setupVideo];
            [self setupNotification];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.userType == PLVRoomUserTypeTeacher) {
        self.preView.frame = self.bounds;
        self.avPreLayer.frame = self.bounds;
        self.micImageView.frame = CGRectMake(2, CGRectGetHeight(self.bounds) - 2 - 10,  10, 10);
        self.minNicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micImageView.frame) + 2, CGRectGetMinY(self.micImageView.frame), CGRectGetWidth(self.bounds) - CGRectGetMaxX(self.micImageView.frame) - 4, 10);
        self.maxNicknameLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    } else {
        self.studentRoleTeacherPreView.frame = self.bounds;
    }
}

- (void)dealloc {
    [self clear];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Public Method ]

- (void)startRunning {
    if (_avSession) {
        [self.avSession startRunning];
    }
}

- (void)clear {
    if (_avSession) {
        [self.avSession stopRunning];
    }
}

- (void)teacherPreViewEnableMicrophone:(BOOL)enable {
    NSString *micImageName = enable ? @"plvhc_linkmic_micopen_icon" : @"plvhc_linkmic_micclose_icon";
    self.micImageView.image = [PLVHCUtils imageForLinkMicResource:micImageName];
    plv_dict_set(self.configDict, kSCMicrophoneEnableConfigKey, @(enable));
}

- (void)teacherPreViewEnableCamera:(BOOL)enable {
    plv_dict_set(self.configDict, kSCCameraEnableConfigKey, @(enable));
    self.avPreLayer.hidden = !enable;
    if (enable) {
        self.minNicknameLabel.hidden = NO;
        self.maxNicknameLabel.hidden = YES;
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
        self.minNicknameLabel.hidden = YES;
        self.maxNicknameLabel.hidden = NO;
        for (AVCaptureInput *oldInput in self.avPreLayer.session.inputs) {
            [self.avPreLayer.session removeInput:oldInput];
        }
    }
}

- (void)teacherPreViewSwitchCameraFront:(BOOL)switchFront {
    plv_dict_set(self.configDict, kSCCameraIsFrontConfigKey, @(switchFront));
    AVCaptureDevicePosition direction = switchFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    self.devicePosition = direction;
    BOOL cameraEnable = PLV_SafeBoolForDictKey(self.configDict, kSCCameraEnableConfigKey);
    if (!cameraEnable) {
        return;
    }
    
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

- (void)setupUI {
    if (self.userType == PLVRoomUserTypeTeacher) {
        [self addSubview:self.preView];
        [self addSubview:self.maxNicknameLabel];
        [self addSubview:self.minNicknameLabel];
        [self addSubview:self.micImageView];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [self addGestureRecognizer:tapGesture];
    } else {
        [self addSubview:self.studentRoleTeacherPreView];
    }
}

- (void)setupUserModule {
    PLVRoomUser *user = [PLVRoomDataManager sharedManager].roomData.roomUser;
    NSString *nickname = user.viewerName ? user.viewerName : user.viewerId;
    self.maxNicknameLabel.text = nickname;
    self.minNicknameLabel.text = nickname;
    plv_dict_set(self.configDict, kSCLocalPrevierUserNicknameKey, nickname);
    plv_dict_set(self.configDict, kSCLocalPrevierUserAvatarURLKey, user.viewerAvatar);
}

- (void)setupVideo {
    /// 麦克风、摄像头权限检测
    [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {
        if (granted) {
            // 摄像头预览（模拟器运行无法开启摄像头）
            #if !(TARGET_IPHONE_SIMULATOR)
                [self setupVideoCaptureDevice];
            #endif
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
    [self.preView.layer addSublayer:self.avPreLayer];

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureConnection *previewLayerConnection = self.avPreLayer.connection;
    AVCaptureVideoOrientation videoOrientation = interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? AVCaptureVideoOrientationLandscapeLeft : AVCaptureVideoOrientationLandscapeRight;
    [previewLayerConnection setVideoOrientation:videoOrientation];
}

- (void)setupNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

#pragma mark Getter & Setter

- (UIView *)preView {
    if (!_preView) {
        _preView = [[UIView alloc] init];
    }
    return _preView;
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

- (UILabel *)minNicknameLabel {
    if (!_minNicknameLabel) {
        _minNicknameLabel = [[UILabel alloc] init];
        _minNicknameLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _minNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:8];
        _minNicknameLabel.text = @"";
    }
    return _minNicknameLabel;
}

- (UILabel *)maxNicknameLabel {
    if (!_maxNicknameLabel) {
        _maxNicknameLabel = [[UILabel alloc] init];
        _maxNicknameLabel.frame = CGRectMake(0, 0, 56, 34);
        _maxNicknameLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _maxNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:12];
        _maxNicknameLabel.text = @"";
        _maxNicknameLabel.textAlignment = NSTextAlignmentCenter;
        _maxNicknameLabel.numberOfLines = 2;
    }
    return _maxNicknameLabel;
}

- (UIImageView *)micImageView {
    if (!_micImageView) {
        _micImageView = [[UIImageView alloc] init];
        _micImageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_micopen_icon"];
    }
    return _micImageView;
}

- (PLVHCLinkMicStudentRoleTeacherPreView *)studentRoleTeacherPreView {
    if (!_studentRoleTeacherPreView) {
        _studentRoleTeacherPreView = [[PLVHCLinkMicStudentRoleTeacherPreView alloc] init];
    }
    return _studentRoleTeacherPreView;
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

#pragma mark Gesture

- (void)tapGestureAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(teacherPreView:didSelectAtUserConfig:)]) {
        [self.delegate teacherPreView:self didSelectAtUserConfig:self.configDict];
    }
}

#pragma mark Notification

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureConnection *previewLayerConnection = self.avPreLayer.connection;
    AVCaptureVideoOrientation videoOrientation = interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? AVCaptureVideoOrientationLandscapeLeft : AVCaptureVideoOrientationLandscapeRight;
    [previewLayerConnection setVideoOrientation:videoOrientation];
}

@end

@interface PLVHCLinkMicStudentRoleTeacherPreView ()
@property (nonatomic, strong) UILabel *teacherNicknameLabel; //讲师昵称
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *micImageView;
@property (nonatomic, strong) UIImageView *placeholderImageView; //讲师未上课占位图
@end

@implementation PLVHCLinkMicStudentRoleTeacherPreView

#pragma mark - [ Life Cycle ]
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
        [self setupTeacherNickname];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.micImageView.frame = CGRectMake(2, CGRectGetHeight(self.bounds) - 2 - 10,  10, 10);
    self.teacherNicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micImageView.frame) + 2, CGRectGetMinY(self.micImageView.frame), CGRectGetWidth(self.bounds) - CGRectGetMaxX(self.micImageView.frame) - 4, 10);
    self.titleLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    self.placeholderImageView.frame = self.bounds;
}

- (UILabel *)teacherNicknameLabel {
    if (!_teacherNicknameLabel) {
        _teacherNicknameLabel = [[UILabel alloc] init];
        _teacherNicknameLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _teacherNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:8];
    }
    return _teacherNicknameLabel;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.frame = CGRectMake(0, 0, 80, 20);
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        _titleLabel.text = @"老师准备中";
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIImageView *)micImageView {
    if (!_micImageView) {
        _micImageView = [[UIImageView alloc] init];
        _micImageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_micopen_icon"];
    }
    return _micImageView;
}

- (UIImageView *)placeholderImageView {
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_teacher_noclass_icon"];
    }
    return _placeholderImageView;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.micImageView];
    [self addSubview:self.teacherNicknameLabel];
}

- (void)setupTeacherNickname {
    NSString *courseCode = [PLVRoomDataManager sharedManager].roomData.lessonInfo.courseCode;
    NSString *lessonId = [PLVRoomDataManager sharedManager].roomData.lessonInfo.lessonId;
    __weak typeof(self) weakSelf = self;
    void(^successBlock)(NSArray * _Nonnull responseArray) = ^(NSArray * _Nonnull responseArray) {
        if (![PLVFdUtil checkArrayUseable:responseArray]) {
            return;
        }
        NSDictionary *lessonDict = responseArray.firstObject;
        NSString *teacherName = PLV_SafeStringForDictKey(lessonDict, @"teacherName");
        if ([PLVFdUtil checkStringUseable:teacherName]) {
            teacherName = [NSString stringWithFormat:@"老师-%@",teacherName];
        } else {
            teacherName = @"老师";
        }
        weakSelf.teacherNicknameLabel.text = teacherName;
    };
    [PLVLiveVClassAPI watcherLessonListWithCourseCode:courseCode lessonId:lessonId success:successBlock failure:^(NSError * _Nonnull error) {
        [PLVHCUtils showToastInWindowWithMessage:error.localizedDescription];
    }];
}

@end
