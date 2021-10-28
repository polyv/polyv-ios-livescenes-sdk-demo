//
//  PLVHCStatusbarAreaView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCStatusbarAreaView.h"

///工具类
#import "PLVHCUtils.h"

/// 模块
#import "PLVRoomDataManager.h"

/// 拖堂最多到4小时
static NSInteger KPLVMaxDelayDuration = 4 * 60 * 60;

@interface PLVHCStatusbarAreaView ()

#pragma mark UI

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *lessonIdLabel;//课节号
@property (nonatomic, strong) UILabel *classStatusLabel;//上课状态
@property (nonatomic, strong) UILabel *durationLabel;//上课持续时间
@property (nonatomic, strong) UILabel *classTitleLabel;//课题
@property (nonatomic, strong) UILabel *delayTimeLabel;//网络延迟
@property (nonatomic, strong) UIImageView *signalImageView;//信号
@property (nonatomic, strong) UIView *lineView;

#pragma mark 数据
@property (nonatomic, assign) NSTimeInterval lessonFinishTimestamp;//课程结束时的时间戳，用于判断是否拖堂
@property (nonatomic, assign) NSTimeInterval duration;// 已上课时长
@property (nonatomic, assign) PLVHiClassLessonStatus classStatus;//上课状态
@property (nonatomic, strong) NSTimer *durationTimer;//上课时长计时器

@end

@implementation PLVHCStatusbarAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
        [self setupModule];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
    CGFloat edgeInsetsTop = edgeInsets.top;
    CGFloat edgeInsetsLeft = MAX(edgeInsets.left, 36);
    CGFloat edgeInsetsRight = MAX(edgeInsets.right, 36);
    self.contentView.frame = CGRectMake(edgeInsetsLeft, edgeInsetsTop, CGRectGetWidth(self.bounds) - edgeInsetsLeft - edgeInsetsRight, CGRectGetHeight(self.bounds) - edgeInsetsTop);
}

#pragma mark - Getter && Setter

- (UILabel *)lessonIdLabel {
    if (!_lessonIdLabel) {
        _lessonIdLabel = [[UILabel alloc] init];
        _lessonIdLabel.textColor = [UIColor whiteColor];
        _lessonIdLabel.font = [UIFont systemFontOfSize:12];
        _lessonIdLabel.textAlignment = NSTextAlignmentLeft;
        _lessonIdLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _lessonIdLabel.text = @"课节号";
    }
    return _lessonIdLabel;
}
- (UILabel *)classStatusLabel {
    if (!_classStatusLabel) {
        _classStatusLabel = [[UILabel alloc] init];
        _classStatusLabel.textColor = [UIColor whiteColor];
        _classStatusLabel.font = [UIFont systemFontOfSize:12];
        _classStatusLabel.textAlignment = NSTextAlignmentCenter;
        _classStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _classStatusLabel;
}
- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont boldSystemFontOfSize:12];
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _durationLabel;
}
- (UILabel *)classTitleLabel {
    if (!_classTitleLabel) {
        _classTitleLabel = [[UILabel alloc] init];
        _classTitleLabel.textColor = [UIColor whiteColor];
        _classTitleLabel.font = [UIFont systemFontOfSize:13];
        _classTitleLabel.textAlignment = NSTextAlignmentCenter;
        _classTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _classTitleLabel;
}
- (UILabel *)delayTimeLabel {
    if (!_delayTimeLabel) {
        _delayTimeLabel = [[UILabel alloc] init];
        _delayTimeLabel.textColor = [PLVColorUtil colorFromHexString:@"#ADADC0"];
        _delayTimeLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _delayTimeLabel.textAlignment = NSTextAlignmentLeft;
        _delayTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _delayTimeLabel.text = @"0ms";
    }
    return _delayTimeLabel;
}
- (UIImageView *)signalImageView {
    if (!_signalImageView) {
        _signalImageView = [[UIImageView alloc] init];
        _signalImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _signalImageView.image = [PLVHCUtils imageForStatusbarResource:@"plvhc_statusbar_signal_icon_unknown"];
    }
    return _signalImageView;
}
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
        _lineView.backgroundColor = [UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:0.6];
        _lineView.layer.cornerRadius = 1;
    }
    return _lineView;
}

//获取当前时间戳
- (NSTimeInterval)currentTimestamp {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    return timestamp;
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    [self updateClassDuration:duration];
}

- (void)setDurationTimer:(NSTimer *)durationTimer {
    if(_durationTimer) {
        [_durationTimer invalidate];
        _durationTimer = nil;
    }
    if(durationTimer) {
        _durationTimer = durationTimer;
    }
}

#pragma mark - [ Public Methods ]

- (void)delayStartClass {
    [self setupClassStatus:PLVHiClassLessonStatusDelayInClass];
}

- (void)startClass {
    [self setupClassStatus:PLVHiClassLessonStatusInClass];
    __weak typeof(self) weakSelf = self;
    [self getClassDurationSuccess:^(NSInteger duration) {
        weakSelf.duration = duration;
        [weakSelf startClassTimer];
    }];
}

- (void)finishClass {
    [self setupClassStatus:PLVHiClassLessonStatusFinishClass];
    self.duration = 0;
    self.durationTimer = nil;
}

- (void)setNetworkQuality:(PLVBLinkMicNetworkQuality)networkQuality {
    NSString *imageName = @"plvhc_statusbar_signal_icon_unknown";
    switch (networkQuality) {
        case PLVBLinkMicNetworkQualityUnknown:
            imageName = @"plvhc_statusbar_signal_icon_unknown";
            break;
        case PLVBLinkMicNetworkQualityGood:
            imageName = @"plvhc_statusbar_signal_icon_good";
            break;
        case PLVBLinkMicNetworkQualityFine:
            imageName = @"plvhc_statusbar_signal_icon_good";
            break;
        case PLVBLinkMicNetworkQualityBad:
            imageName = @"plvhc_statusbar_signal_icon_fine";
            break;
        case PLVBLinkMicNetworkQualityDown:
            imageName = @"plvhc_statusbar_signal_icon_bad";
            break;
    }
    self.signalImageView.image = [PLVHCUtils imageForStatusbarResource:imageName];
}

/// 设置网络延迟
- (void)setNetworkDelayTime:(NSInteger)delayTime {
    delayTime = MAX(0,delayTime);
    delayTime = MIN(999, delayTime);
    self.delayTimeLabel.text = [NSString stringWithFormat:@"%zdms", delayTime];
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.lessonIdLabel];
    [self.contentView addSubview:self.lineView];
    [self.contentView addSubview:self.classStatusLabel];
    [self.contentView addSubview:self.durationLabel];
    [self.contentView addSubview:self.classTitleLabel];
    [self.contentView addSubview:self.delayTimeLabel];
    [self.contentView addSubview:self.signalImageView];
    [self addViewConstraints];
}

- (void)setupModule {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSString *channelName = roomData.channelName;
    channelName = channelName.length > 12 ? [[channelName substringToIndex:12] stringByAppendingString:@"..."] : channelName;
    self.classTitleLabel.text = [NSString stringWithFormat:@"%@", channelName];
    self.lessonIdLabel.text = [NSString stringWithFormat:@"课节号 %@", roomData.lessonInfo.lessonId];
    self.lessonFinishTimestamp = roomData.lessonInfo.lessonEndTime;
    [self setupClassStatus:roomData.lessonInfo.lessonStatus];
}

- (void)updateClassDuration:(NSTimeInterval)duration {
    //拖堂最长时间为4个小时 还剩10分钟的时候需要提醒，到四小时强制结束
    if (KPLVMaxDelayDuration - duration  == 10 * 60) {
        [PLVHCUtils showToastInWindowWithMessage:@"拖堂时间过长，10分钟后将强制下课"];
    }
    if (duration >= KPLVMaxDelayDuration) {
        self.durationTimer = nil;
        [self notifyForcedFinishClass];
        return;
    }

    //拖堂 当前时间大于实际设置的下课时间
    if (self.classStatus != PLVHiClassLessonStatusDelayFinishClass &&
        self.currentTimestamp > self.lessonFinishTimestamp) {
        [self setupClassStatus:PLVHiClassLessonStatusDelayFinishClass];
    }
    
    NSString *durationStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(duration / 60 / 60)), lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    self.durationLabel.text = durationStr;
}

- (void)setupClassStatus:(PLVHiClassLessonStatus)classStatus {
    _classStatus = classStatus;
    self.durationLabel.hidden = YES;
    switch (classStatus) {
        case PLVHiClassLessonStatusNotInClass:
            self.classStatusLabel.textColor = [UIColor whiteColor];
            self.classStatusLabel.text = @"未上课";
            break;
        case PLVHiClassLessonStatusDelayInClass:
            self.classStatusLabel.textColor = [UIColor colorWithRed:255/255.0 green:38/255.0 blue:57/255.0 alpha:1/1.0];
            self.classStatusLabel.text = @"已延迟";
            break;
        case PLVHiClassLessonStatusInClass:
            self.durationLabel.hidden = NO;
            self.classStatusLabel.textColor = [UIColor whiteColor];
            self.classStatusLabel.text = @"上课中";
            break;
        case PLVHiClassLessonStatusDelayFinishClass:
            self.durationLabel.hidden = NO;
            self.classStatusLabel.textColor = [UIColor colorWithRed:255/255.0 green:38/255.0 blue:57/255.0 alpha:1/1.0];
            self.classStatusLabel.text = @"拖堂";
            break;
        case PLVHiClassLessonStatusFinishClass:
            self.classStatusLabel.textColor = [UIColor whiteColor];
            self.classStatusLabel.text = @"已下课";
            break;
        default:
            break;
    }
}

- (void)startClassTimer {
    self.durationTimer = [NSTimer timerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(classDurationTimer) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.durationTimer forMode:NSRunLoopCommonModes];
}

- (void)getClassDurationSuccess:(void(^)(NSInteger duration))successHandler {
    void(^successBlock)(NSDictionary *dict) = ^(NSDictionary *dict) {
        NSInteger inClassTime = PLV_SafeIntegerForDictKey(dict, @"inClassTime");
        successHandler ? successHandler(inClassTime) : nil;
    };
    void(^failureBlock)(NSError * error) = ^(NSError * error) {
        NSString *errorDes = error.userInfo[NSLocalizedDescriptionKey];
        [PLVHCUtils showToastInWindowWithMessage:errorDes];
    };
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    BOOL isTeacher = roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
    if (isTeacher) {
        [PLVLiveVClassAPI teacherLessonDetailWithLessonId:roomData.lessonInfo.lessonId success:successBlock failure:failureBlock];
    } else {
        [PLVLiveVClassAPI watcherLessonDetailWithCourseCode:roomData.lessonInfo.courseCode lessonId:roomData.lessonInfo.lessonId success:successBlock failure:failureBlock];
    }
}

#pragma mark Notify Delegate

- (void)notifyForcedFinishClass {
    if (self.delegate && [self.delegate respondsToSelector:@selector(statusbarAreaViewDidForcedFinishClass:)]) {
        [self.delegate statusbarAreaViewDidForcedFinishClass:self];
    }
}

#pragma mark Add Constraints

- (void)addViewConstraints {
    NSLayoutConstraint *lessonIdLayoutLeft = [NSLayoutConstraint constraintWithItem:self.lessonIdLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint *lessonIdLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.lessonIdLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    NSLayoutConstraint *lessonIdLayoutWidth = [NSLayoutConstraint constraintWithItem:self.lessonIdLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:90];
    
    NSLayoutConstraint *lineLayoutWidth = [NSLayoutConstraint constraintWithItem:self.lineView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:1];
    NSLayoutConstraint *lineLayoutHeight = [NSLayoutConstraint constraintWithItem:self.lineView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:12];
    NSLayoutConstraint *lineLayoutLeft = [NSLayoutConstraint constraintWithItem:self.lineView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.lessonIdLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:5];
    NSLayoutConstraint *lineLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.lineView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];;
    
    NSLayoutConstraint *statusLayoutLeft = [NSLayoutConstraint constraintWithItem:self.classStatusLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.lineView attribute:NSLayoutAttributeRight multiplier:1.0 constant:5];
    NSLayoutConstraint *statusLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.classStatusLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint *timeLayoutLeft = [NSLayoutConstraint constraintWithItem:self.durationLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.classStatusLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:7];
    NSLayoutConstraint *timeLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.durationLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint *titleLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.classTitleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0.0];
    NSLayoutConstraint *titleLayoutCenterX = [NSLayoutConstraint constraintWithItem:self.classTitleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0.0];
    NSLayoutConstraint *titleLayoutWidth = [NSLayoutConstraint constraintWithItem:self.classTitleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:180];
    
    NSLayoutConstraint *delayLayoutRight = [NSLayoutConstraint constraintWithItem:self.delayTimeLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    NSLayoutConstraint *delayLayoutWidth = [NSLayoutConstraint constraintWithItem:self.delayTimeLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:25];
    NSLayoutConstraint *delayLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.delayTimeLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint *signalLayoutCenterY = [NSLayoutConstraint constraintWithItem:self.signalImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    NSLayoutConstraint *signalLayoutRight = [NSLayoutConstraint constraintWithItem:self.signalImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.delayTimeLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant: -6.0];
    NSLayoutConstraint *signalLayoutWidth = [NSLayoutConstraint constraintWithItem:self.signalImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:16];
    NSLayoutConstraint *signalLayoutHeigt= [NSLayoutConstraint constraintWithItem:self.signalImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:16];

    [self.contentView addConstraints:@[lessonIdLayoutLeft,
                                       lessonIdLayoutCenterY,
                                       lessonIdLayoutWidth,
                                       lineLayoutWidth,
                                       lineLayoutHeight,
                                       lineLayoutLeft,
                                       lineLayoutCenterY,
                                       statusLayoutLeft,
                                       statusLayoutCenterY,
                                       timeLayoutLeft,
                                       timeLayoutCenterY,
                                       titleLayoutCenterX,
                                       titleLayoutCenterY,
                                       titleLayoutWidth,
                                       delayLayoutRight,
                                       delayLayoutWidth,
                                       delayLayoutCenterY,
                                       signalLayoutRight,
                                       signalLayoutCenterY,
                                       signalLayoutWidth,
                                       signalLayoutHeigt]];
}

#pragma mark - [ Event ]
#pragma mark Timer

- (void)classDurationTimer {
    self.duration ++;
}

@end
