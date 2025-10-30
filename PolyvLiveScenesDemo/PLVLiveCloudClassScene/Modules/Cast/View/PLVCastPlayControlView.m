//
//  PLVCastPlayControlView.m
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCastPlayControlView.h"
#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <PLVFoundationSDK/PLVFdUtil.h>
#import "PLVMultiLanguageManager.h"


@interface PLVCastPlayControlView ()

#pragma mark UI
@property (nonatomic, strong) UIView *castBgView;
@property (nonatomic, strong) UIImageView *deviceImgageView;
@property (nonatomic, strong) UILabel *deviceLabel;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *quitButton;
@property (nonatomic, strong) UIButton *deviceButton;
@property (nonatomic, strong) UIButton *definitionButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *fullScreenButton;

#pragma mark 数据
@property (nonatomic, assign) BOOL isShow; /// 皮肤是否显示中

@end

@implementation PLVCastPlayControlView

#pragma mark - Life Cycle

- (void)dealloc {
    [self removeOrientationObserver];
}
        
- (instancetype)init {
    self = [super init];
    if (self) {
        self.alpha = 0;
        self.userInteractionEnabled = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor blackColor];
        
        self.castBgView.alpha = 0;
        
        [self createUI];
        [self addOrientationObserver];
    }
    return self;
}

- (void)layoutSubviews {
    BOOL isFullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    CGSize deviceImageSize;
    
    if (isFullScreen) {
        deviceImageSize = CGSizeMake(CGRectGetWidth(self.frame) * 0.54, CGRectGetHeight(self.frame) * 0.32);
        self.deviceImgageView.frame = CGRectMake((CGRectGetWidth(self.frame) - deviceImageSize.width) / 2, CGRectGetHeight(self.frame) / 2 - deviceImageSize.height, deviceImageSize.width, deviceImageSize.height);
        self.deviceLabel.frame = CGRectMake(0, (deviceImageSize.height - 17) / 2 - 10, deviceImageSize.width, 17);
        self.deviceButton.frame = CGRectMake((deviceImageSize.width - 100)/2, CGRectGetMaxY(self.deviceLabel.frame) + 22.5, 100, 20);
        self.definitionButton.frame = CGRectMake((CGRectGetWidth(self.frame) - 86) / 2, CGRectGetMaxY(self.deviceImgageView.frame) + 30, 86, 26);
    } else {
        deviceImageSize = self.deviceImgageView.image.size;
        self.deviceImgageView.frame = CGRectMake((CGRectGetWidth(self.frame) - deviceImageSize.width) / 2, 45, deviceImageSize.width, deviceImageSize.height);
        self.deviceLabel.frame = CGRectMake(0, 5, deviceImageSize.width, 17);
        self.deviceButton.frame = CGRectMake((deviceImageSize.width - 100)/2, deviceImageSize.height - 20 - 5, 100, 20);
        self.definitionButton.frame = CGRectMake((CGRectGetWidth(self.frame) - 86) / 2, CGRectGetMaxY(self.deviceImgageView.frame) + 25, 86, 26);
    }
    
    self.backButton.frame = CGRectMake(0, 0, 44, 44);
    self.quitButton.frame = CGRectMake(CGRectGetWidth(self.frame) - 44, 0, 44, 44);
    self.playButton.frame = CGRectMake(0, CGRectGetHeight(self.frame) - 44, 44, 44);
    self.fullScreenButton.frame = CGRectMake(CGRectGetWidth(self.frame) - 44, CGRectGetHeight(self.frame) - 44, 44, 44);

}

#pragma mark - Initialize

- (void)createUI {
    [self addSubview:self.deviceImgageView];
    [self.deviceImgageView addSubview:self.deviceLabel];
    [self.deviceImgageView addSubview:self.deviceButton];
    
    [self addSubview:self.definitionButton];
    [self addSubview:self.backButton];
    [self addSubview:self.quitButton];
    [self addSubview:self.playButton];
    [self addSubview:self.fullScreenButton];
}

#pragma mark - Getter & Setter

- (UIView *)castBgView {
    if (!_castBgView) {
        _castBgView = [[UIView alloc] init];
        _castBgView.backgroundColor = [UIColor blackColor];
        _castBgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _castBgView.alpha = 0;
    }
    return _castBgView;
}

- (UIImageView *)deviceImgageView {
    if (!_deviceImgageView) {
        _deviceImgageView = [[UIImageView alloc] init];
        _deviceImgageView.image = [PLVLCUtils imageForCastResource:@"plv_cast_bg"];
        _deviceImgageView.userInteractionEnabled = YES;
    }
    return _deviceImgageView;
}

- (UILabel *)deviceLabel {
    if (!_deviceLabel) {
        _deviceLabel = [[UILabel alloc] init];
        _deviceLabel.font = [UIFont boldSystemFontOfSize:15];
        _deviceLabel.textColor = [UIColor whiteColor];
        _deviceLabel.textAlignment = NSTextAlignmentCenter;
        _deviceLabel.text = @"客厅的小米盒子";
    }
    return _deviceLabel;
}

- (UIButton *)deviceButton {
    if (!_deviceButton) {
        _deviceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deviceButton setTitle:PLVLocalizedString(@"切换设备 >") forState:UIControlStateNormal];
        [_deviceButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.7] forState:UIControlStateNormal];
        _deviceButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_deviceButton addTarget:self action:@selector(deviceButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deviceButton;
}

- (UIButton *)definitionButton {
    if (!_definitionButton) {
        _definitionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_definitionButton setTitle:PLVLocalizedString(@"清晰度") forState:UIControlStateNormal];
        [_definitionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _definitionButton.titleLabel.font = [UIFont systemFontOfSize:13];
        _definitionButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#979797"].CGColor;
        _definitionButton.layer.borderWidth = 1;
        _definitionButton.layer.cornerRadius = 26/2.0;
        [_definitionButton addTarget:self action:@selector(definitionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _definitionButton;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)quitButton {
    if (!_quitButton) {
        _quitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_quitButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_quit"] forState:UIControlStateNormal];
        [_quitButton addTarget:self action:@selector(quitButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _quitButton;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_play"] forState:UIControlStateNormal];
        [_playButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_pause"] forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (UIButton *)fullScreenButton {
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_fullscreen"] forState:UIControlStateNormal];
        [_fullScreenButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_exfull"] forState:UIControlStateSelected];
        [_fullScreenButton addTarget:self action:@selector(fullScreenButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
        _fullScreenButton.selected = !isPortrait;
    }
    return _fullScreenButton;
}

- (void)setDeviceName:(NSString *)deviceName {
    if (deviceName && [deviceName isKindOfClass:[NSString class]] && deviceName.length > 0) {
        _deviceName = [deviceName copy];
        self.deviceLabel.text = _deviceName;
    }
}

- (void)setDefinition:(NSString *)definition {
    if (definition && [definition isKindOfClass:[NSString class]] && definition.length > 0) {
        _definition = [definition copy];
        [self.definitionButton setTitle:_definition forState:UIControlStateNormal];
    }
}

- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    self.playButton.selected = _playing;
}

#pragma mark - Public

- (void)show {
    if (self.castBgView.alpha == 1) {
        return;
    }
    [UIView animateWithDuration:0.33 animations:^{
        self.castBgView.alpha = 1;
        self.alpha = 1;
        self.userInteractionEnabled = YES;
        self.isShow = YES;
    }];
}

- (void)hide {
    if (self.castBgView.alpha == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.33 animations:^{
            self.castBgView.alpha = 0;
            self.alpha = 0;
            self.userInteractionEnabled = NO;
            self.isShow = NO;
        }];
    });
}

#pragma mark - NSNotification

- (void)addOrientationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interfaceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)removeOrientationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
    self.fullScreenButton.selected = !isPortrait;
}

#pragma mark - Action

- (void)backButtonAction:(id)sender {
    if (self.delegate) {
        [self.delegate castControlBackButtonClick];
    }
}

- (void)quitButtonAction:(id)sender {
    if (self.delegate) {
        [self.delegate castControlQuitButtonClick];
    }
}

- (void)deviceButtonAction:(id)sender {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
    if (!isPortrait) {
        [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationPortrait];
    }
    
    if (self.delegate) {
        [self.delegate castControlDeviceButtonClick];
    }
}

- (void)definitionButtonAction:(id)sender {
    if (self.delegate) {
        [self.delegate castControlDefinitionButtonClick];
    }
}

- (void)playButtonAction:(id)sender {
    self.playButton.selected = !self.playButton.selected;
    if (self.delegate) {
        [self.delegate castControlPlayButtonClick:self.playButton.selected];
    }
}

- (void)fullScreenButtonAction:(id)sender {
    self.fullScreenButton.selected = !self.fullScreenButton.selected;
    if (self.delegate) {
        [self.delegate castControlFullScreenButtonClick];
    }
}

@end
