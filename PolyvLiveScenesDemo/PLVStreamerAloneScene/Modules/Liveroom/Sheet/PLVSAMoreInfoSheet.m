//
//  PLVSAMoreInfoSheet.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAMoreInfoSheet.h"

// utils
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVSABitRateSheet.h"

//SDK
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVSAMoreInfoSheet ()

// UI
@property (nonatomic, strong) UILabel *baseTitleLabel; // 基础功能标题
@property (nonatomic, strong) UIButton *cameraButton; // 摄像头
@property (nonatomic, strong) UIButton *microphoneButton; // 麦克风
@property (nonatomic, strong) UIButton *cameraReverseButton; // 翻转
@property (nonatomic, strong) UIButton *mirrorButton; // 镜像
@property (nonatomic, strong) UIButton *screenShareButton; // 屏幕共享
@property (nonatomic, strong) UIButton *flashButton; // 闪光灯
@property (nonatomic, strong) UIButton *cameraBitRateButton; // 摄像头清晰度
@property (nonatomic, strong) UIButton *closeRoomButton; // 全体禁言
@property (nonatomic, strong) UIButton *beautyButton; // 美颜
@property (nonatomic, strong) UIButton *shareButton; // 分享
@property (nonatomic, strong) UIButton *badNetworkButton; // 弱网处理
@property (nonatomic, strong) UIButton *mixLayoutButton; // 混流布局
@property (nonatomic, strong) UIButton *allowRaiseHandButton; // 开启/关闭观众连麦
@property (nonatomic, strong) UIButton *linkMicSettingButton; // 连麦设置
@property (nonatomic, strong) UIButton *removeAllAudiencesButton; // 观众下麦
@property (nonatomic, strong) NSArray *buttonArray;
@property (nonatomic, strong) UILabel *interactiveTitleLabel; // 互动标题
@property (nonatomic, strong) UIButton *signInButton; // 签到
@property (nonatomic, strong) UIButton *giftRewardButton; // 礼物打赏
@property (nonatomic, strong) UIButton *giftEffectsButton; // 礼物特效
@property (nonatomic, strong) NSArray *interactiveButtonArray; // 互动
@property (nonatomic, strong) UIScrollView *scrollView; // 按钮承载视图

// 数据
@property (nonatomic, assign) NSTimeInterval allowRaiseHandButtonLastTimeInterval; // 开启/关闭观众连麦上一次点击的时间戳
@property (nonatomic, assign) BOOL closeGiftReward; // 是否关闭礼物打赏

@end

@implementation PLVSAMoreInfoSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    CGFloat heightScale = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 0.246 : 0.34;
    CGFloat widthScale = 0.37;
    CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGFloat sheetHeight = maxWH * heightScale;
    CGFloat sheetLandscapeWidth = maxWH * widthScale;
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self initUI];
        [self getGiftRewardSettings];
        
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        if (!isPad && [self.buttonArray count] > 10) { // 超过两行
            self.sheetHight += (28 + 12 + 14 + 16);
        }
        // 互动入口的高度
        self.sheetHight += 28.0 + 12.0 + 14 + 16;
        self.allowRaiseHandButtonLastTimeInterval = 0.0;
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat titleY = (self.bounds.size.height > 667 || isLandscape) ? 32 : 18;
    self.scrollView.frame = CGRectMake(0, titleY, CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame) - titleY);
    
    CGSize buttonSize = [self getMaxButtonSize];
    
    [self setControlsFrameWithButtonSize:buttonSize];
    [self setButtonInsets];
}


#pragma mark - [ Public Method ]
- (void)startClass:(BOOL)start {
    self.screenShareButton.enabled = start;
    [self changeScreenShareButtonSelectedState:NO];
}

- (void)changeFlashButtonSelectedState:(BOOL)selectedState{
    self.flashButton.selected = selectedState;
    _currentCameraFlash = self.flashButton.selected;
}

- (void)changeScreenShareButtonSelectedState:(BOOL)selectedState {
    self.screenShareButton.selected = selectedState;
    self.cameraButton.enabled = !selectedState;
    self.cameraReverseButton.enabled = !selectedState;
    self.mirrorButton.enabled = !selectedState && self.currentCameraOpen && self.currentCameraFront;
}

- (void)changeAllowRaiseHandButtonSelectedState:(BOOL)selectedState {
    self.allowRaiseHandButton.selected = selectedState;
}

#pragma mark 当前用户配置
- (void)setCurrentMicOpen:(BOOL)currentMicOpen {
    _currentMicOpen = currentMicOpen;
    self.microphoneButton.selected = currentMicOpen;
}

- (void)setStreamQuality:(PLVResolutionType)streamQuality {
    _streamQuality = streamQuality;
    [self setCameraBitRateButtonTitleAndImageWithType:streamQuality streamQualityLevel:self.streamQualityLevel];
}

- (void)setStreamQualityLevel:(NSString *)streamQualityLevel {
    _streamQualityLevel = streamQualityLevel;
    [self setCameraBitRateButtonTitleAndImageWithType:self.streamQuality streamQualityLevel:self.streamQualityLevel];
}

- (void)setCurrentCameraOpen:(BOOL)currentCameraOpen {
    _currentCameraOpen = currentCameraOpen;
    self.cameraButton.selected = currentCameraOpen;
    // 摄像头关闭，翻转 禁用
    self.cameraReverseButton.enabled = currentCameraOpen && !self.screenShareButton.selected;
    // 后置摄像头、摄像头：镜像禁用
    self.mirrorButton.enabled = currentCameraOpen && self.currentCameraFront && !self.screenShareButton.selected;
    // 前置摄像头，闪光灯 禁用
    self.flashButton.enabled = currentCameraOpen && !self.currentCameraFront && !self.screenShareButton.selected;
}

/// 本地用户的 摄像头 当前是否前置
- (void)setCurrentCameraFront:(BOOL)currentCameraFront {
    _currentCameraFront = currentCameraFront;
    self.cameraReverseButton.selected = currentCameraFront;
    
    // 前置摄像头，闪光灯 禁用
    self.flashButton.enabled = !currentCameraFront && self.currentCameraOpen;
    //后置摄像头、摄像头关闭: 镜像禁用
    self.mirrorButton.enabled = currentCameraFront && self.currentCameraOpen;
}

- (void)setCurrentCameraMirror:(BOOL)currentCameraMirror {
    _currentCameraMirror = currentCameraMirror;
    self.mirrorButton.selected = currentCameraMirror;
}

- (void)setCloseRoom:(BOOL)closeRoom {
    _closeRoom = closeRoom;
    self.closeRoomButton.selected = closeRoom;
}

- (void)setCloseGiftReward:(BOOL)closeGiftReward {
    _closeGiftReward = closeGiftReward;
    self.giftRewardButton.selected = closeGiftReward;
}

#pragma mark - [ Private Method ]

- (void)initUI {
    [self.contentView addSubview:self.scrollView];
    
    UIView *buttonSuperView = self.scrollView;
    [buttonSuperView addSubview:self.baseTitleLabel];

    // 摄像头、麦克风、前后摄像头、镜像
    [buttonSuperView addSubview:self.cameraButton];
    [buttonSuperView addSubview:self.microphoneButton];
    [buttonSuperView addSubview:self.cameraReverseButton];
    [buttonSuperView addSubview:self.mirrorButton];
    NSMutableArray *muButtonArray = [NSMutableArray arrayWithArray:@[self.cameraButton,
                                                                   self.microphoneButton,
                                                                   self.cameraReverseButton,
                                                                   self.mirrorButton]];
    
    // 美颜按钮
    if ([PLVRoomDataManager sharedManager].roomData.canUseBeauty) {
        [buttonSuperView addSubview:self.beautyButton];
        [muButtonArray addObject:self.beautyButton];
    }
    
    // 屏幕共享
    if ([PLVSAMoreInfoSheet canScreenShare]) {
        [buttonSuperView addSubview:self.screenShareButton];
        [muButtonArray addObject:self.screenShareButton];
    }
    
    // 闪光灯、清晰度
    [buttonSuperView addSubview:self.flashButton];
    [buttonSuperView addSubview:self.cameraBitRateButton];
    [muButtonArray addObjectsFromArray:@[self.flashButton,
                                       self.cameraBitRateButton]];
    
    // 全体禁言
    if ([PLVSAMoreInfoSheet canManagerCloseRoom]) {
        [buttonSuperView addSubview:self.closeRoomButton];
        [muButtonArray addObject:self.closeRoomButton];
    }
    
    // 分享
    if ([PLVSAMoreInfoSheet canShareLiveroom]) {
        [buttonSuperView addSubview:self.shareButton];
        [muButtonArray addObject:self.shareButton];
    }
    
    // 弱网处理
    [buttonSuperView addSubview:self.badNetworkButton];
    [muButtonArray addObject:self.badNetworkButton];
    
    // 混流布局
    if ([PLVSAMoreInfoSheet showMixLayoutButton]) {
        [buttonSuperView addSubview:self.mixLayoutButton];
        [muButtonArray addObject:self.mixLayoutButton];
    }
    
    self.buttonArray = [muButtonArray copy];
    
    [buttonSuperView addSubview:self.interactiveTitleLabel];
    [buttonSuperView addSubview:self.signInButton];
    NSMutableArray *muInteractiveButtonArray = [NSMutableArray arrayWithArray:@[self.signInButton]];
    if ([PLVSAMoreInfoSheet showGiftRewardRewardButton]) {
        [buttonSuperView addSubview:self.giftRewardButton];
        [muInteractiveButtonArray addObject:self.giftRewardButton];
    }
    
    [buttonSuperView addSubview:self.giftEffectsButton];
    [muInteractiveButtonArray addObject:self.giftEffectsButton];
    
    // 显示新版连麦举手
    if ([PLVSAMoreInfoSheet showLinkMicNewStrategy]) {
        [buttonSuperView addSubview:self.allowRaiseHandButton];
        [muInteractiveButtonArray addObject:self.allowRaiseHandButton];
    }
    
    // 显示观众下麦
    if ([PLVSAMoreInfoSheet showRemoveAllAudiencesButton]) {
        [buttonSuperView addSubview:self.removeAllAudiencesButton];
        [muInteractiveButtonArray addObject:self.removeAllAudiencesButton];
    }
    
    // 显示新版连麦设置
    if ([PLVSAMoreInfoSheet showLinkMicNewStrategy]) {
        [buttonSuperView addSubview:self.linkMicSettingButton];
        [muInteractiveButtonArray addObject:self.linkMicSettingButton];
    }
    
    self.interactiveButtonArray = [muInteractiveButtonArray copy];
}

#pragma mark Getter

- (UILabel *)baseTitleLabel {
    if (!_baseTitleLabel) {
        _baseTitleLabel = [[UILabel alloc] init];
        _baseTitleLabel.text = PLVLocalizedString(@"基础");
        _baseTitleLabel.font = [UIFont systemFontOfSize:14];
        _baseTitleLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _baseTitleLabel;
}

- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cameraButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_cameraButton setTitle:PLVLocalizedString(@"摄像头") forState:UIControlStateNormal];
        [_cameraButton setTitle:PLVLocalizedString(@"摄像头") forState:UIControlStateSelected];
        [_cameraButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_camera_close"] forState:UIControlStateNormal];
        [_cameraButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_camera_open"] forState:UIControlStateSelected];
        [_cameraButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_camera_disabled"] forState:UIControlStateSelected|UIControlStateDisabled];
        [_cameraButton addTarget:self action:@selector(cameraButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cameraButton;
}

- (UIButton *)microphoneButton {
    if (!_microphoneButton) {
        _microphoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _microphoneButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _microphoneButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _microphoneButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        _microphoneButton.titleLabel.numberOfLines = 0;
        [_microphoneButton setTitle:PLVLocalizedString(@"麦克风") forState:UIControlStateNormal];
        [_microphoneButton setTitle:PLVLocalizedString(@"麦克风") forState:UIControlStateSelected];
        [_microphoneButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_micphone_close"] forState:UIControlStateNormal];
        [_microphoneButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_micphone_open"] forState:UIControlStateSelected];
        [_microphoneButton addTarget:self action:@selector(microphoneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _microphoneButton;
}

- (UIButton *)cameraReverseButton {
    if (!_cameraReverseButton) {
        _cameraReverseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraReverseButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cameraReverseButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_cameraReverseButton setTitle:PLVLocalizedString(@"翻转") forState:UIControlStateNormal];
        [_cameraReverseButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_cameraReverse"] forState:UIControlStateNormal];
        [_cameraReverseButton addTarget:self action:@selector(cameraReverseButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraReverseButton;
}

- (UIButton *)mirrorButton {
    if (!_mirrorButton) {
        _mirrorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _mirrorButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _mirrorButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_mirrorButton setTitle:PLVLocalizedString(@"镜像") forState:UIControlStateNormal];
        [_mirrorButton setTitle:PLVLocalizedString(@"镜像") forState:UIControlStateSelected];
        [_mirrorButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_mirrorClose"] forState:UIControlStateNormal];
        [_mirrorButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_mirrorOpen"] forState:UIControlStateSelected];
        [_mirrorButton addTarget:self action:@selector(mirrorButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mirrorButton;
}

- (UIButton *)screenShareButton {
    if (!_screenShareButton) {
        _screenShareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _screenShareButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _screenShareButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _screenShareButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _screenShareButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        _screenShareButton.titleLabel.numberOfLines = 0;
        NSString *normalTitle = PLVLocalizedString(@"屏幕共享");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            normalTitle = [normalTitle stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        }
        [_screenShareButton setTitle:normalTitle forState:UIControlStateNormal];
        [_screenShareButton setTitle:PLVLocalizedString(@"结束共享") forState:UIControlStateSelected];
        [_screenShareButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_screenshare_open"] forState:UIControlStateNormal];
        [_screenShareButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_screenshare_close"] forState:UIControlStateSelected];
        [_screenShareButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_screenshare_disabled"] forState:UIControlStateDisabled];
        [_screenShareButton addTarget:self action:@selector(screenShareButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _screenShareButton.enabled = NO;
    }
    return _screenShareButton;
}

- (UIButton *)flashButton {
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _flashButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_flashButton setTitle:PLVLocalizedString(@"闪光灯") forState:UIControlStateNormal];
        [_flashButton setTitle:PLVLocalizedString(@"闪光灯") forState:UIControlStateSelected];
        [_flashButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_flash_close"] forState:UIControlStateNormal];
        [_flashButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_flash_open"] forState:UIControlStateSelected];
        [_flashButton addTarget:self action:@selector(flashButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashButton;
}

- (UIButton *)cameraBitRateButton {
    if (!_cameraBitRateButton) {
        _cameraBitRateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraBitRateButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cameraBitRateButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _cameraBitRateButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_cameraBitRateButton setTitle:@"" forState:UIControlStateNormal];
        [_cameraBitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_hd"] forState:UIControlStateNormal];
        [_cameraBitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_hd"] forState:UIControlStateSelected];
        [_cameraBitRateButton addTarget:self action:@selector(cameraBitRateButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraBitRateButton;
}

- (UIButton *)closeRoomButton {
    if (!_closeRoomButton) {
        _closeRoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeRoomButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _closeRoomButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _closeRoomButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _closeRoomButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
        NSString *normalTitle = isPad && !isLandscape ? PLVLocalizedString(@"开启全体禁言") : PLVLocalizedString(@"开启全体\n禁言");
        NSString *selectedTitle = isPad && !isLandscape ? PLVLocalizedString(@"取消全体禁言") : PLVLocalizedString(@"取消全体\n禁言");
        [_closeRoomButton setTitle:normalTitle forState:UIControlStateNormal];
        [_closeRoomButton setTitle:selectedTitle forState:UIControlStateSelected];
        [_closeRoomButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_allmicphoneClose"] forState:UIControlStateNormal];
        [_closeRoomButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_allmicphoneClose"] forState:UIControlStateSelected];
        [_closeRoomButton addTarget:self action:@selector(closeRoomButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeRoomButton;
}

- (UIButton *)beautyButton {
    if (!_beautyButton) {
        _beautyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _beautyButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _beautyButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_beautyButton setTitle:PLVLocalizedString(@"美颜") forState:UIControlStateNormal];
        [_beautyButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_beauty_more"] forState:UIControlStateNormal];
        [_beautyButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_beauty_more"] forState:UIControlStateSelected];
        [_beautyButton addTarget:self action:@selector(beautyButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _beautyButton;
}

- (UIButton *)shareButton {
    if (!_shareButton) {
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _shareButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _shareButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_shareButton setTitle:PLVLocalizedString(@"分享") forState:UIControlStateNormal];
        [_shareButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_share"] forState:UIControlStateNormal];
        [_shareButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_share"] forState:UIControlStateSelected];
        [_shareButton addTarget:self action:@selector(shareButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareButton;
}

- (UIButton *)badNetworkButton {
    if (!_badNetworkButton) {
        _badNetworkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _badNetworkButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _badNetworkButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_badNetworkButton setTitle:PLVLocalizedString(@"弱网处理") forState:UIControlStateNormal];
        [_badNetworkButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_badNetwork_switch_btn"] forState:UIControlStateNormal];
        [_badNetworkButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_badNetwork_switch_btn"] forState:UIControlStateSelected];
        [_badNetworkButton addTarget:self action:@selector(badNetworkButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _badNetworkButton;
}

- (UIButton *)mixLayoutButton {
    if (!_mixLayoutButton) {
        _mixLayoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _mixLayoutButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _mixLayoutButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_mixLayoutButton setTitle:PLVLocalizedString(@"混流布局") forState:UIControlStateNormal];
        [_mixLayoutButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_mixLayout_btn"] forState:UIControlStateNormal];
        [_mixLayoutButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_mixLayout_btn"] forState:UIControlStateSelected];
        [_mixLayoutButton addTarget:self action:@selector(mixLayoutButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mixLayoutButton;
}

- (UIButton *)allowRaiseHandButton {
    if (!_allowRaiseHandButton) {
        _allowRaiseHandButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _allowRaiseHandButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _allowRaiseHandButton.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        NSString *normalTitle = PLVLocalizedString(@"申请连麦");
        NSString *selectedTitle = PLVLocalizedString(@"取消申请连麦") ;
        [_allowRaiseHandButton setTitle:normalTitle forState:UIControlStateNormal];
        [_allowRaiseHandButton setTitle:selectedTitle forState:UIControlStateSelected];
        [_allowRaiseHandButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_audience_raise_hand_btn"] forState:UIControlStateNormal];
        [_allowRaiseHandButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_audience_raise_hand_btn_selected"] forState:UIControlStateSelected];
        [_allowRaiseHandButton addTarget:self action:@selector(allowRaiseHandButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _allowRaiseHandButton;
}

- (UIButton *)linkMicSettingButton {
    if (!_linkMicSettingButton) {
        _linkMicSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _linkMicSettingButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _linkMicSettingButton.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        [_linkMicSettingButton setTitle:PLVLocalizedString(@"连麦设置") forState:UIControlStateNormal];
        [_linkMicSettingButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_link_mic_setting_btn"] forState:UIControlStateNormal];
        [_linkMicSettingButton addTarget:self action:@selector(linkMicSettingButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _linkMicSettingButton;
}

- (UIButton *)removeAllAudiencesButton {
    if (!_removeAllAudiencesButton) {
        _removeAllAudiencesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _removeAllAudiencesButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _removeAllAudiencesButton.titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        [_removeAllAudiencesButton setTitle:PLVLocalizedString(@"观众下麦") forState:UIControlStateNormal];
        [_removeAllAudiencesButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_link_mic_remove_audiences_btn"] forState:UIControlStateNormal];
        [_removeAllAudiencesButton addTarget:self action:@selector(removeAllAudiencesButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _removeAllAudiencesButton.enabled = NO;
    }
    return _removeAllAudiencesButton;
}

- (UILabel *)interactiveTitleLabel {
    if (!_interactiveTitleLabel) {
        _interactiveTitleLabel = [[UILabel alloc] init];
        _interactiveTitleLabel.text = PLVLocalizedString(@"互动");
        _interactiveTitleLabel.font = [UIFont systemFontOfSize:14];
        _interactiveTitleLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _interactiveTitleLabel;
}

- (UIButton *)signInButton {
    if (!_signInButton) {
        _signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _signInButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _signInButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_signInButton setTitle:PLVLocalizedString(@"签到") forState:UIControlStateNormal];
        [_signInButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_signIn_btn"] forState:UIControlStateNormal];
        [_signInButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_signIn_btn"] forState:UIControlStateSelected];
        [_signInButton addTarget:self action:@selector(signInButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _signInButton;
}

- (UIButton *)giftRewardButton {
    if (!_giftRewardButton) {
        _giftRewardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _giftRewardButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _giftRewardButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_giftRewardButton setTitle:PLVLocalizedString(@"礼物打赏") forState:UIControlStateNormal];
        [_giftRewardButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_gift_reward_btn_open"] forState:UIControlStateNormal];
        [_giftRewardButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_gift_reward_btn_close"] forState:UIControlStateSelected];
        [_giftRewardButton addTarget:self action:@selector(giftRewardButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _giftRewardButton;
}

- (UIButton *)giftEffectsButton {
    if (!_giftEffectsButton) {
        _giftEffectsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _giftEffectsButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _giftEffectsButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_giftEffectsButton setTitle:PLVLocalizedString(@"礼物特效") forState:UIControlStateNormal];
        [_giftEffectsButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_gift_effects_btn_open"] forState:UIControlStateNormal];
        [_giftEffectsButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_gift_effects_btn_close"] forState:UIControlStateSelected];
        [_giftEffectsButton addTarget:self action:@selector(giftEffectsButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _giftEffectsButton;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.pagingEnabled = YES;
    }
    return _scrollView;
}

#pragma mark - Setters

- (void)setRemoveAllAudiencesEnable:(BOOL)removeAllAudiencesEnable {
    _removeAllAudiencesEnable = removeAllAudiencesEnable;
    if (removeAllAudiencesEnable != self.removeAllAudiencesButton.enabled) {
        self.removeAllAudiencesButton.enabled = removeAllAudiencesEnable;
    }
}

#pragma mark setButtonFrame

- (CGSize)getMaxButtonSize {
    CGFloat maxWidth = 28.0;
    CGFloat maxHeight = 28.0 + 12.0 + 14.0;
    
    for (int i = 0; i < self.buttonArray.count ; i++) {
        UIButton *button = self.buttonArray[i];
        
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:button.titleLabel.text attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}];
        CGSize titleSize = [attr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        
        maxWidth = MAX(titleSize.width, maxWidth);
        maxHeight = MAX(titleSize.height, maxHeight);
    }
    return CGSizeMake(maxWidth, maxHeight);
}

- (void)setControlsFrameWithButtonSize:(CGSize)buttonSize {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    NSInteger buttonCount = isLandscape ? 3 : (isPad ? 7 : 5); // 竖屏时（iphone）每行5个按钮、横屏时（iphone & ipad）每行3个按钮
    CGFloat defaultOriginX = isLandscape ? 38 : (isPad ? 56.0 : 21.5);
    CGFloat buttonOriginX = defaultOriginX;
    CGFloat buttonOriginY =  4;
    CGFloat buttonXPadding = (self.scrollView.bounds.size.width - buttonOriginX * 2 - buttonSize.width * buttonCount) / (buttonCount - 1);
    CGFloat buttonYPadding = (self.bounds.size.height > 667 || isLandscape) ? 18 : 16;
    if (isPad && !isLandscape) {
        buttonOriginY =  28.0;
        buttonYPadding = 30.0;
    }
    
    self.baseTitleLabel.frame = CGRectMake(defaultOriginX, 5, 40, 20);
    buttonOriginY += CGRectGetHeight(self.baseTitleLabel.frame) + 8;
    for (int i = 0; i < self.buttonArray.count ; i++) {
        UIButton *button = self.buttonArray[i];
        
        if (i % buttonCount == 0 && i != 0) { // 换行
            buttonOriginX = defaultOriginX;
            buttonOriginY += buttonSize.height + buttonYPadding;
        }
        
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonSize.width, buttonSize.height);
        buttonOriginX += buttonSize.width + buttonXPadding;
    }
    
    buttonOriginY += 30;
    self.interactiveTitleLabel.frame = CGRectMake(defaultOriginX, buttonOriginY + buttonSize.height, 80, 20);
    buttonOriginY = CGRectGetMaxY(self.interactiveTitleLabel.frame) + 8;
    buttonOriginX = defaultOriginX;
    for (int i = 0; i < self.interactiveButtonArray.count ; i++) {
        UIButton *button = self.interactiveButtonArray[i];
        if (i % buttonCount == 0 && i != 0) { // 换行
            buttonOriginX = defaultOriginX;
            buttonOriginY += buttonSize.height + buttonYPadding;
        }
        
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonSize.width, buttonSize.height);
        buttonOriginX += buttonSize.width + buttonXPadding;
    }
    
    // 设置超出视图范围可滚动选择按钮
    self.scrollView.contentSize = CGSizeMake(self.contentView.frame.size.width, buttonOriginY + buttonSize.height + 10);
}

- (void)setButtonInsets {
    NSArray *mergeButtonArray = [self.buttonArray arrayByAddingObjectsFromArray:self.interactiveButtonArray];
    for (int i = 0; i < mergeButtonArray.count ; i++) {
        UIButton *but = mergeButtonArray[i];
        CGFloat padding = 12;
        CGFloat imageBottom = but.titleLabel.intrinsicContentSize.height;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            imageBottom += padding;
        }
        
        [but setTitleEdgeInsets:
               UIEdgeInsetsMake(but.frame.size.height/2 + padding,
                                -but.imageView.frame.size.width,
                                0,
                                0)];
        [but setImageEdgeInsets:
                   UIEdgeInsetsMake(
                               0,
                               (but.frame.size.width-but.imageView.frame.size.width)/2,
                                imageBottom,
                               (but.frame.size.width-but.imageView.frame.size.width)/2)];
    }
}

#pragma mark 清晰度枚举类型、字符的转换
/// 将成字符串转换成清晰度枚举值
- (PLVResolutionType)changeBitRateTypeWithString:(NSString *)bitRatestring {
    PLVResolutionType type = PLVResolutionType360P;
    if ([bitRatestring isEqualToString:PLVLocalizedString(@"超高清")]) {
        type = PLVResolutionType1080P;
    } else if ([bitRatestring isEqualToString:PLVLocalizedString(@"超清")]) {
        type = PLVResolutionType720P;
    } else if ([bitRatestring isEqualToString:PLVLocalizedString(@"高清")]) {
        type = PLVResolutionType360P;
    } else if ([bitRatestring isEqualToString:PLVLocalizedString(@"标清")]) {
        type = PLVResolutionType180P;
    }
    return type;
}

- (void)setCameraBitRateButtonTitleAndImageWithType:(PLVResolutionType)type streamQualityLevel:(NSString *)streamQualityLevel  {
    NSString *title = @"";
    NSString *imageName = @"";
    switch (type) {
        case PLVResolutionType180P:
            title = PLVLocalizedString(@"标清");
            imageName = @"plvsa_liveroom_btn_sd";
            break;
        case PLVResolutionType360P:
            title = PLVLocalizedString(@"高清");
            imageName = @"plvsa_liveroom_btn_hd";
            break;
        case PLVResolutionType720P:
            title = PLVLocalizedString(@"超清");
            imageName = @"plvsa_liveroom_btn_fhd";
            break;
        case PLVResolutionType1080P:
            title = PLVLocalizedString(@"超高清");
            imageName = @"plvsa_liveroom_btn_uhd";
            break;
        default:
            break;
    }
    title = [NSString stringWithFormat:@"%@\n  ", title];
    NSArray<PLVClientPushStreamTemplateVideoParams *> *videoParamsArray = [PLVLiveVideoConfig sharedInstance].videoParams;
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled &&
        [PLVFdUtil checkStringUseable:streamQualityLevel] &&
        [PLVFdUtil checkArrayUseable:videoParamsArray]) {
        __block PLVClientPushStreamTemplateVideoParams *videoParam;
        [videoParamsArray enumerateObjectsUsingBlock:^(PLVClientPushStreamTemplateVideoParams * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([streamQualityLevel isEqualToString:obj.qualityLevel]) {
                videoParam = obj;
                *stop = YES;
            }
        }];
        
        if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) {
            title = [NSString stringWithFormat:@"%@\n  ", videoParam.qualityName];
        } else {
            title = [NSString stringWithFormat:@"%@\n  ", videoParam.qualityEnName];
        }
        
        if ([videoParam.qualityLevel containsString:@"FHD"]) {
            imageName = @"plvsa_liveroom_btn_uhd";
        } else if ([videoParam.qualityLevel containsString:@"SHD"]) {
            imageName = @"plvsa_liveroom_btn_fhd";
        } else if ([videoParam.qualityLevel containsString:@"HSD"]) {
            imageName = @"plvsa_liveroom_btn_hd";
        } else {
            imageName = @"plvsa_liveroom_btn_sd";
        }
    }
    
    // iPad时，文案去掉换行
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    if (isPad && [title containsString:@"\n  "]) {
        NSRange range = [title rangeOfString:@"\n  "];
        NSString *padTitle = [title substringToIndex:range.location];
        title = padTitle;
    }

    [self.cameraBitRateButton setTitle:title forState:UIControlStateNormal];
    [self.cameraBitRateButton setImage:[PLVSAUtils imageForLiveroomResource:imageName] forState:UIControlStateNormal];
}

/// 讲师、助教、管理员可以禁言操作
+ (BOOL)canManagerCloseRoom {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (userType == PLVRoomUserTypeTeacher ||
        userType == PLVRoomUserTypeAssistant ||
        userType == PLVRoomUserTypeManager) {
        return YES;
    }
    return NO;
}

/// 讲师和嘉宾可以进行屏幕共享操作
+ (BOOL)canScreenShare {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (![[PLVRoomDataManager sharedManager].roomData.menuInfo.rtcType isEqualToString:@"agora"] &&
        (userType == PLVRoomUserTypeTeacher || userType == PLVRoomUserTypeGuest)) {
        return YES;
    }
    return NO;
}

+ (BOOL)canShareLiveroom {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if ((userType == PLVRoomUserTypeTeacher || userType == PLVRoomUserTypeGuest) &&
        [PLVRoomDataManager sharedManager].roomData.menuInfo.pushSharingEnabled) {
        return YES;
    }
    return NO;
}

+ (BOOL)showMixLayoutButton {
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher && [PLVRoomDataManager sharedManager].roomData.showMixLayoutButtonEnabled;
}

+ (BOOL)showLinkMicNewStrategy {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.linkmicNewStrategyEnabled && roomData.interactNumLimit > 0 && roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
}

+ (BOOL)showRemoveAllAudiencesButton {
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
}

+ (BOOL)showGiftRewardRewardButton {
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
}

- (void)getGiftRewardSettings {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType != PLVRoomUserTypeTeacher) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
    [PLVLiveVideoAPI requestDonateWithChannelId:channelId completion:^(NSDictionary * _Nonnull data) {
        if ([PLVFdUtil checkDictionaryUseable:data]) {
            weakSelf.closeGiftReward = [PLV_SafeStringForDictKey(data, @"donateGiftEnabled") isEqualToString:@"N"];
        }
    } failure:^(NSError * _Nonnull error) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeVerbose, @"PLVSAMoreInfoSheet request donate setting error: %@", error.localizedDescription);
    }];
}

#pragma mark - Event

#pragma mark Action

- (void)cameraButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeCameraOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeCameraOpen:!self.cameraButton.selected];
    }
}

- (void)microphoneButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeMicOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeMicOpen:!self.microphoneButton.selected];
    }
}

- (void)cameraReverseButtonAction {
    __weak typeof(self) weakSelf = self;
    self.cameraReverseButton.userInteractionEnabled = NO; //控制翻转按钮点击间隔，防止短时间内重复点击
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.cameraReverseButton.userInteractionEnabled = YES;
     });
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeCameraFront:)]) {
        [self.delegate moreInfoSheet:self didChangeCameraFront:!self.cameraReverseButton.selected];
        self.currentCameraFront = !self.cameraReverseButton.selected;
    }
}

- (void)mirrorButtonAction {
    __weak typeof(self) weakSelf = self;
    self.mirrorButton.userInteractionEnabled = NO; //控制镜像按钮点击间隔，防止短时间内重复点击
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.mirrorButton.userInteractionEnabled = YES;
     });
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeMirrorOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeMirrorOpen:!self.mirrorButton.selected];
        self.currentCameraMirror = !self.mirrorButton.selected;
    }
}

- (void)screenShareButtonAction {
    [self changeScreenShareButtonSelectedState:!self.screenShareButton.isSelected];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeScreenShareOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeScreenShareOpen:self.screenShareButton.isSelected];
    }
}

- (void)flashButtonAction {
    self.flashButton.selected = !self.flashButton.selected;
    [self changeFlashButtonSelectedState:self.flashButton.selected];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeFlashOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeFlashOpen:self.flashButton.selected];
    }
}

- (void)cameraBitRateButtonAction {
    [self dismiss];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapCameraBitRateButton:)]) {
        [self.delegate moreInfoSheetDidTapCameraBitRateButton:self];
    }
}

- (void)closeRoomButtonAction {
    self.closeRoomButton.selected = !self.closeRoomButton.selected;
    self.closeRoom = self.closeRoomButton.selected;
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeCloseRoom:)]) {
        [self.delegate moreInfoSheet:self didChangeCloseRoom:self.closeRoomButton.selected];
    }
}

- (void)beautyButtonAction {
    [self dismiss];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapBeautyButton:)]) {
        [self.delegate moreInfoSheetDidTapBeautyButton:self];
    }
}

- (void)shareButtonAction {
    [self dismiss];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapShareButton:)]) {
        [self.delegate moreInfoSheetDidTapShareButton:self];
    }
}

- (void)badNetworkButtonAction {
    [self dismiss];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapBadNetworkButton:)]) {
        [self.delegate moreInfoSheetDidTapBadNetworkButton:self];
    }
}

- (void)mixLayoutButtonAction {
    [self dismiss];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapMixLayoutButton:)]) {
        [self.delegate moreInfoSheetDidTapMixLayoutButton:self];
    }
}

- (void)allowRaiseHandButtonAction {
    [self dismiss];
    if ([PLVSAMoreInfoSheet showLinkMicNewStrategy]) {
        // 防止短时间内重复点击，1s间隔内的点击会直接忽略
        NSTimeInterval curTimeInterval = [PLVFdUtil curTimeInterval];
        if (curTimeInterval - self.allowRaiseHandButtonLastTimeInterval > 1000) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapAllowRaiseHandButton:wannaChangeAllowRaiseHand:)]) {
                [self.delegate moreInfoSheetDidTapAllowRaiseHandButton:self wannaChangeAllowRaiseHand:!self.allowRaiseHandButton.selected];
            }
        }
        self.allowRaiseHandButtonLastTimeInterval = curTimeInterval;
    }
}

- (void)linkMicSettingButtonAction {
    [self dismiss];
    if ([PLVSAMoreInfoSheet showLinkMicNewStrategy]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapLinkMicSettingButton:)]) {
            [self.delegate moreInfoSheetDidTapLinkMicSettingButton:self];
        }
    }
}

- (void)removeAllAudiencesButtonAction {
    [self dismiss];
    if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapRemoveAllAudiencesButton:)]) {
        [self.delegate moreInfoSheetDidTapRemoveAllAudiencesButton:self];
    }
}

- (void)signInButtonAction {
    [self dismiss];
    if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapSignInButton:)]) {
        [self.delegate moreInfoSheetDidTapSignInButton:self];
    }
}

- (void)giftRewardButtonAction {
    self.closeGiftReward = !self.giftRewardButton.selected;
    
    __weak typeof(self) weakSelf = self;
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
    [PLVLiveVideoAPI updateDonateGiftWithChannelId:channelId donateGiftEnabled:!self.closeGiftReward completion:^{
        if ([weakSelf.delegate respondsToSelector:@selector(moreInfoSheetDidChangeCloseGiftReward:)]) {
            [weakSelf.delegate moreInfoSheetDidChangeCloseGiftReward:weakSelf];
        }
    } failure:^(NSError * _Nonnull error) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeVerbose, @"PLVSAMoreInfoSheet update donate gift request error: %@", error.localizedDescription);
        weakSelf.closeGiftReward = !weakSelf.closeGiftReward;
    }];
}

- (void)giftEffectsButtonAction {
    self.giftEffectsButton.selected = !self.giftEffectsButton.selected;

    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeCloseRoom:)]) {
        [self.delegate moreInfoSheet:self didCloseGiftEffects:self.giftEffectsButton.selected];
    }
}

@end
