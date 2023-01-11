//
//  PLVHCLinkMicTeacherPreView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/9/2.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicTeacherPreView.h"
#import "PLVRoomDataManager.h"

// 工具类
#import "PLVHCUtils.h"

// 模块
#import "PLVCaptureDeviceManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <AVFoundation/AVFoundation.h>

@interface PLVHCLinkMicTeacherPreView ()

@property (nonatomic, strong) UIView *preView;  // 摄像头预览区域
@property (nonatomic, strong) UILabel *maxNicknameLabel; //大昵称
@property (nonatomic, strong) UILabel *minNicknameLabel; //小昵称
@property (nonatomic, strong) UIImageView *micImageView; //麦克风
@property (nonatomic, strong) PLVHCLinkMicStudentRoleTeacherPreView *studentRoleTeacherPreView; //学生角色的讲师预览图

#pragma mark 工具
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *avPreLayer;

#pragma mark 数据
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
            PLVRoomUser *user = [PLVRoomDataManager sharedManager].roomData.roomUser;
            NSString *nickname = user.viewerName ? user.viewerName : user.viewerId;
            self.maxNicknameLabel.text = nickname;
            self.minNicknameLabel.text = nickname;
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.userType == PLVRoomUserTypeTeacher) {
        self.preView.frame = self.bounds;
        self.avPreLayer.frame = self.preView.bounds;
        self.micImageView.frame = CGRectMake(2, CGRectGetHeight(self.bounds) - 2 - 10,  10, 10);
        self.minNicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micImageView.frame) + 2, CGRectGetMinY(self.micImageView.frame), CGRectGetWidth(self.bounds) - CGRectGetMaxX(self.micImageView.frame) - 4, 10);
        self.maxNicknameLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    } else {
        self.studentRoleTeacherPreView.frame = self.bounds;
    }
}

#pragma mark - [ Public Method ]

- (void)startPreview {
    if (self.userType == PLVRoomUserTypeTeacher) {
        self.avPreLayer = [PLVCaptureDeviceManager sharedManager].avPreLayer;
        [self.preView.layer addSublayer:self.avPreLayer];
        self.avPreLayer.frame = self.preView.bounds;
    }
}

- (void)enableLocalMic:(BOOL)enable {
    if (self.userType == PLVRoomUserTypeTeacher) {
        NSString *micImageName = enable ? @"plvhc_linkmic_micopen_icon" : @"plvhc_linkmic_micclose_icon";
        self.micImageView.image = [PLVHCUtils imageForLinkMicResource:micImageName];
    }
}

- (void)enableLocalCamera:(BOOL)enable {
    if (self.userType == PLVRoomUserTypeTeacher) {
        self.avPreLayer.hidden = !enable;
        self.minNicknameLabel.hidden = !enable;
        self.maxNicknameLabel.hidden = enable;
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

#pragma mark Getter & Setter

- (UIView *)preView {
    if (!_preView) {
        _preView = [[UIView alloc] init];
    }
    return _preView;
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

#pragma mark - [ Event ]

#pragma mark Gesture

- (void)tapGestureAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTeacherPreViewSelected:)]) {
        [self.delegate didTeacherPreViewSelected:self];
    }
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
    NSString *courseCode = [PLVHiClassManager sharedManager].courseCode;
    NSString *lessonId = [PLVHiClassManager sharedManager].lessonId;
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

