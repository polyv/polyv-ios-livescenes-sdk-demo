//
//  PLVHCSettingSheet.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

// UI
#import "PLVHCSettingSheet.h"
#import "PLVHCSettingConfigView.h"

// 工具
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCSettingSheet ()<PLVHCSettingConfigViewDelegate>

@property (nonatomic, strong) PLVHCSettingConfigView *configView;

@end

@implementation PLVHCSettingSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.configView];

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.configView.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)superView {
    [superView addSubview:self];
}

- (void)dismiss {
    [self removeFromSuperview];
}

- (void)synchronizeConfig:(NSDictionary *)dict {
    if ([PLVFdUtil checkDictionaryUseable:dict]) {
        [self.configView synchronizeConfig:dict];
    }
}

- (void)microphoneSwitchChange:(BOOL)open {
    [self.configView microphoneSwitchChange:open];
}

- (void)cameraSwitchChange:(BOOL)open {
    [self.configView cameraSwitchChange:open];
}

- (void)cameraDirectionChange:(BOOL)front {
    [self.configView cameraDirectionChange:front];
}

#pragma mark - [ Private Method ]

#pragma mark Getter & Setter

- (PLVHCSettingConfigView *)configView {
    if (!_configView) {
        _configView = [[PLVHCSettingConfigView alloc] initWithType:PLVHCSettingConfigViewLogoutClass];
        _configView.backgroundColor = PLV_UIColorFromRGB(@"#242940");
        _configView.layer.masksToBounds = YES;
        _configView.layer.cornerRadius = 16;
        _configView.delegate = self;
    }
    return _configView;
}

#pragma mark - [ Delegate ]

#pragma mark PLVHCSettingConfigViewDelegate

- (void)didTapLogoutButtonInSettingConfigView:(PLVHCSettingConfigView *)configView {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(didTapLogoutButtonInSettingSheet:)]) {
        [self.delegate didTapLogoutButtonInSettingSheet:self];
    }
}

/// 麦克风开关
- (void)didChangeMicrophoneSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView enable:(BOOL)enable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeMicrophoneSwitchInSettingSheet:enable:)]) {
        [self.delegate didChangeMicrophoneSwitchInSettingSheet:self enable:enable];
    }
}

/// 摄像头开关
- (void)didChangeCameraSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView enable:(BOOL)enable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeCameraSwitchInSettingSheet:enable:)]) {
        [self.delegate didChangeCameraSwitchInSettingSheet:self enable:enable];
    }
}

/// 切换摄像头方向
- (void)didChangeCameraDirectionSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView front:(BOOL)isFront {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeCameraDirectionSwitchInSettingSheet:front:)]) {
        [self.delegate didChangeCameraDirectionSwitchInSettingSheet:self front:isFront];
    }
}

/// 全屏切换
- (void)didChangeFullScreenSwitchInSettingConfigView:(PLVHCSettingConfigView *)configView fullScreen:(BOOL)fullScreen {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeFullScreenSwitchInSettingSheet:fullScreen:)]) {
        [self.delegate didChangeFullScreenSwitchInSettingSheet:self fullScreen:fullScreen];
    }
}

- (BOOL)alreadyLinkMicLocalStudentInSettingConfigView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(alreadyLinkMicLocalStudentInSettingSheet)]) {
        return [self.delegate alreadyLinkMicLocalStudentInSettingSheet];
    }
    return YES;
}

@end
