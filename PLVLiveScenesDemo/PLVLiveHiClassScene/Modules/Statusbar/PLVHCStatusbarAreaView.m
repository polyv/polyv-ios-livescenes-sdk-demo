//
//  PLVHCStatusbarAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCStatusbarAreaView.h"

///工具类
#import "PLVHCUtils.h"

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

@property (nonatomic, assign) PLVHiClassStatusbarState state; //上课状态

@end

@implementation PLVHCStatusbarAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
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

#pragma mark - [ Public Methods ]

- (void)setClassTitle:(NSString *)title {
    if (title &&
        [title isKindOfClass:[NSString class]] &&
        title.length > 0) {
        self.classTitleLabel.text = title;
    } else {
        self.classTitleLabel.text = @"";
    }
}

- (void)setLessonId:(NSString *)lessonId {
    if (lessonId &&
        [lessonId isKindOfClass:[NSString class]] &&
        lessonId.length > 0) {
        self.lessonIdLabel.text = [NSString stringWithFormat:@"课节号 %@", lessonId];
    } else {
        self.lessonIdLabel.text = @"课节号";
    }
}

- (void)updateState:(PLVHiClassStatusbarState)state {
    self.state = state;
    switch (state) {
        case PLVHiClassStatusbarStateNotInClass: {
            self.durationLabel.hidden = YES;
            self.classStatusLabel.textColor = [UIColor whiteColor];
            self.classStatusLabel.text = @"未上课";
            break;
        }
        case PLVHiClassStatusbarStateDelayStartClass: {
            self.durationLabel.hidden = YES;
            self.classStatusLabel.textColor = [UIColor colorWithRed:255/255.0 green:38/255.0 blue:57/255.0 alpha:1/1.0];
            self.classStatusLabel.text = @"已延迟";
            break;
        }
        case PLVHiClassStatusbarStateInClass: {
            self.durationLabel.hidden = NO;
            self.classStatusLabel.textColor = [UIColor whiteColor];
            self.classStatusLabel.text = @"上课中";
            break;
        }
        case PLVHiClassStatusbarStateDelayFinishClass: {
            self.durationLabel.hidden = NO;
            self.classStatusLabel.textColor = [UIColor colorWithRed:255/255.0 green:38/255.0 blue:57/255.0 alpha:1/1.0];
            self.classStatusLabel.text = @"拖堂";
            break;
        }
        case PLVHiClassStatusbarStateFinishClass: {
            self.durationLabel.hidden = YES;
            self.classStatusLabel.textColor = [UIColor whiteColor];
            self.classStatusLabel.text = @"已下课";
            break;
        }
    }
}

- (void)updateDuration:(NSInteger)duration {
    NSString *durationStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(duration / 60 / 60)), lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    self.durationLabel.text = durationStr;
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

#pragma mark Getter && Setter

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
        _classTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
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

@end
