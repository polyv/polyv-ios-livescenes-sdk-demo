//
//  PLVSALinkMicPreviewView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/11/30.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSALinkMicPreviewView.h"
#import "PLVCaptureDeviceManager.h"
#import "PLVSAUtils.h"
#import "PLVCLinkMicUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <AudioToolbox/AudioToolbox.h>

static NSString *kPLVSAUserLinkMicPreConfig = @"kPLVSAUserLinkMicPreConfig";
static NSInteger kPLVSALinkMicInvitationAnswerTTL = 30; // 连麦邀请等待时间(秒)

@interface PLVSALinkMicPreMediaSwitchView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *switchView;
@property (nonatomic, strong) UISwitch *mediaSwitch;

@end

@interface PLVSALinkMicPreviewView ()

#pragma mark 数据
@property (nonatomic, strong) NSTimer *inviteLinkMicTimer; // 邀请连麦计时器
@property (nonatomic, assign) NSTimeInterval acceptInviteLinkMicLimitTs; //  接受邀请连麦的限制时间
@property (nonatomic, assign) SystemSoundID soundID; // 音效id
@property (nonatomic, assign) BOOL isPlaying; // 是否正在播放背景音乐
@property (nonatomic, assign, readonly) NSTimeInterval currentTimestamp; // 当前时间戳

#pragma mark UI
@property (nonatomic, strong) UIView *backgroundView; // 背景视图
@property (nonatomic, strong) UIVisualEffectView *effectView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *cameraPreView;
@property (nonatomic, strong) UIImageView *cameraDisableImageView; // 摄像头关闭提示icon
@property (nonatomic, strong) UILabel *cameraDisableLabel; // 摄像头关闭提示label
@property (nonatomic, strong) PLVSALinkMicPreMediaSwitchView *cameraSwitchView;
@property (nonatomic, strong) PLVSALinkMicPreMediaSwitchView *micSwitchView;
@property (nonatomic, strong) UIImageView *tipsImageView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIButton *rejectButton;
@property (nonatomic, strong) UIButton *linkMicButton;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *avPreLayer;
@property (nonatomic, strong, readonly) UISwitch *cameraSwitch;
@property (nonatomic, strong, readonly) UISwitch *micSwitch;

@end

@implementation PLVSALinkMicPreviewView

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        self.micSwitchView.mediaSwitch.on = YES;
        self.cameraSwitchView.mediaSwitch.on = YES;
        [self saveUserLinkMicPreConfig];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.frame = self.superview.bounds;
    BOOL currentLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    CGFloat verticalControlMargin = 8;
    CGFloat contentViewHeigth = (self.isOnlyAudio?0:(32 + verticalControlMargin * 2));
    CGFloat contentViewWidth = 0.0f;
    CGFloat contentViewOriginX = 0.0f;
    CGFloat contentViewOriginY = 0.0f;
    CGFloat preViewHeight = 0.0;
    CGFloat leftMargin = 24.0f;
    CGFloat safeAreaRight = 0.0f;
    if (currentLandscape) {
        if (isPad) {
            contentViewHeigth += 434;
            contentViewWidth = 440;
            verticalControlMargin = 10;
            preViewHeight = 200;
            contentViewOriginX = (viewWidth - contentViewWidth)/2;
            contentViewOriginY = (viewHeight - contentViewHeigth)/2;
        } else {
            contentViewHeigth = CGRectGetHeight(self.frame);
            safeAreaRight = [PLVSAUtils sharedUtils].areaInsets.right;
            contentViewWidth = 330;
            CGFloat scalingRatio = contentViewHeigth/375;
            preViewHeight = ceilf(scalingRatio * 143);
            verticalControlMargin = scalingRatio * 6;
            contentViewOriginX = viewWidth - contentViewWidth - safeAreaRight;
            contentViewOriginY = 0.0;
        }
    } else {
        if (isPad) {
            contentViewHeigth += 510;
            contentViewWidth = 525;
            verticalControlMargin = 12;
            preViewHeight = 255;
            contentViewOriginX = (viewWidth - contentViewWidth)/2;
            contentViewOriginY = (viewHeight - contentViewHeigth)/2;
        } else {
            contentViewHeigth += 404;
            contentViewWidth = CGRectGetWidth(self.frame);
            preViewHeight = 184;
            contentViewOriginX = 0.0;
            contentViewOriginY = viewHeight - contentViewHeigth;
        }
    }
    
    self.backgroundView.frame = CGRectMake(contentViewOriginX, contentViewOriginY, contentViewWidth + safeAreaRight, contentViewHeigth);
    self.effectView.frame = self.backgroundView.bounds;
    self.contentView.frame = CGRectMake(0, 0, contentViewWidth, contentViewHeigth);
    self.titleLabel.frame = CGRectMake(leftMargin, verticalControlMargin, contentViewWidth - leftMargin * 2, 32);
    self.cameraPreView.frame = CGRectMake(leftMargin, CGRectGetMaxY(self.titleLabel.frame) + verticalControlMargin, contentViewWidth - leftMargin * 2, preViewHeight);
    CGFloat cameraImageViewWidth = CGRectGetWidth(self.cameraDisableImageView.bounds);
    CGFloat cameraImageViewHeight = CGRectGetHeight(self.cameraDisableImageView.bounds);
    self.cameraDisableImageView.frame = CGRectMake((CGRectGetWidth(self.cameraPreView.bounds) - cameraImageViewWidth)/2 , (CGRectGetHeight(self.cameraPreView.bounds) - cameraImageViewHeight)/2, cameraImageViewWidth, cameraImageViewHeight);
    self.cameraDisableLabel.frame = CGRectMake(CGRectGetMidX(self.cameraDisableImageView.frame) - 90, CGRectGetMaxY(self.cameraDisableImageView.frame), 180, 16);
    self.avPreLayer.frame = self.cameraPreView.bounds;
    self.cameraSwitchView.frame = CGRectMake(leftMargin, CGRectGetMaxY(self.cameraPreView.frame) + verticalControlMargin, contentViewWidth - leftMargin * 2, 32);
    CGFloat controlOriginY = self.isOnlyAudio ? CGRectGetMaxY(self.cameraPreView.frame) : CGRectGetMaxY(self.cameraSwitchView.frame);
    self.micSwitchView.frame = CGRectMake(leftMargin, controlOriginY + verticalControlMargin * 2, contentViewWidth - leftMargin * 2, 32);
    controlOriginY = CGRectGetMaxY(self.micSwitchView.frame) + verticalControlMargin * 2;
    // 非iPad 横屏 音频模式
    if (!isPad && currentLandscape && self.isOnlyAudio) {
        controlOriginY = contentViewHeigth - 40 - verticalControlMargin * 6 - 18;
    }
    self.tipsImageView.frame = CGRectMake(leftMargin, controlOriginY, 12, 12);
    CGFloat tipsLabelWidth = contentViewWidth - (CGRectGetMaxX(self.tipsImageView.frame) + verticalControlMargin + leftMargin);
    CGSize tipsLabelSize = [self.tipsLabel sizeThatFits:CGSizeMake(tipsLabelWidth, MAXFLOAT)];
    self.tipsLabel.frame = CGRectMake(CGRectGetMaxX(self.tipsImageView.frame) + verticalControlMargin, CGRectGetMidY(self.tipsImageView.frame) - 8, tipsLabelWidth, tipsLabelSize.height);
    CGFloat buttonWidth = (contentViewWidth - leftMargin * 3)/2;
    controlOriginY = (currentLandscape && !isPad) ? (CGRectGetHeight(self.contentView.frame) - 40 - 16) : (CGRectGetMaxY(self.tipsLabel.frame) + verticalControlMargin * 3);
    self.rejectButton.frame = CGRectMake(leftMargin, controlOriginY, buttonWidth, 40);
    self.linkMicButton.frame = CGRectMake(CGRectGetMaxX(self.rejectButton.frame) + leftMargin, CGRectGetMinY( self.rejectButton.frame), buttonWidth, 40);
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || ![PLVSAUtils sharedUtils].isLandscape) {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.backgroundView.bounds;
        UIRectCorner corners =  [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? UIRectCornerAllCorners : (UIRectCornerTopLeft | UIRectCornerTopRight);
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.backgroundView.bounds
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(8.0, 8.0)].CGPath;
        self.backgroundView.layer.mask = maskLayer;
    }
}

#pragma mark - [ Public Methods ]

- (void)showLinkMicPreviewView:(BOOL)show {
    if (self.hidden == !show) {
        return;
    }
    
    self.hidden = !show;
    if (show) {
        if (!self.isOnlyAudio) {
            [[PLVCaptureDeviceManager sharedManager] startVideoCapture];
            self.avPreLayer = [PLVCaptureDeviceManager sharedManager].avPreLayer;
            self.avPreLayer.frame = self.cameraPreView.bounds;
            [self.cameraPreView.layer addSublayer:self.avPreLayer];
        }
        [self synchLocalLinkMicPreConfig];
        [self createInviteLinkMicTimer];
        [self startPlayBgm];
    } else {
        if (!self.isOnlyAudio) {
            self.avPreLayer = nil;
            [[PLVCaptureDeviceManager sharedManager] releaseVideoResource];
        }
        [self stopPlayBgm];
        [self destroyInviteLinkMicTimer];
    }
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.hidden = YES;
    [self addSubview:self.backgroundView];
    [self.backgroundView addSubview:self.effectView];
    [self.backgroundView addSubview:self.contentView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.cameraPreView];
    [self.cameraPreView addSubview:self.cameraDisableImageView];
    [self.cameraPreView addSubview:self.cameraDisableLabel];
    [self.contentView addSubview:self.cameraSwitchView];
    [self.contentView addSubview:self.micSwitchView];
    [self.contentView addSubview:self.tipsImageView];
    [self.contentView addSubview:self.tipsLabel];
    [self.contentView addSubview:self.rejectButton];
    [self.contentView addSubview:self.linkMicButton];
}

- (void)saveUserLinkMicPreConfig {
    NSDictionary *dict = @{@"cameraEnable" : @(self.cameraSwitch.on),
                         @"micEnable" : @(self.micSwitch.on)};
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kPLVSAUserLinkMicPreConfig];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)synchLocalLinkMicPreConfig {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kPLVSAUserLinkMicPreConfig];
    self.micSwitch.on = PLV_SafeBoolForDictKey(dict, @"micEnable");
    [self micSwitchAction:self.micSwitch];
    self.cameraSwitch.on = self.isOnlyAudio ? NO : PLV_SafeBoolForDictKey(dict, @"cameraEnable");
    [self cameraSwitchAction:self.cameraSwitch];
}

- (void)createInviteLinkMicTimer {
    if (_inviteLinkMicTimer) {
        [self destroyInviteLinkMicTimer];
    }
    self.acceptInviteLinkMicLimitTs = self.currentTimestamp + kPLVSALinkMicInvitationAnswerTTL * 1000;
    _inviteLinkMicTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(inviteLinkMicTimerAction) userInfo:nil repeats:YES];
}

- (void)startPlayBgm {
    if (self.isPlaying) {
        [self stopPlayBgm];
    }
    if (self.soundID) {
        if (@available(iOS 9.0, *)) {
            self.isPlaying = YES;
            __weak typeof(self) weakSelf = self;
            AudioServicesPlaySystemSoundWithCompletion(self.soundID, ^{
                [weakSelf stopPlayBgm];
            });
        }
    }
}

- (void)stopPlayBgm {
    if (self.isPlaying) {
        AudioServicesDisposeSystemSoundID(self.soundID);
        self.soundID = 0;
        self.isPlaying = NO;
    }
}

- (void)destroyInviteLinkMicTimer {
    [_inviteLinkMicTimer invalidate];
    _inviteLinkMicTimer = nil;
}

#pragma mark Callback

- (void)callbackForAcceptLinkMicInvitation {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvSALinkMicPreviewViewAcceptLinkMicInvitation:)]) {
        [self.delegate plvSALinkMicPreviewViewAcceptLinkMicInvitation:self];
    }
}

- (void)callbackForCancelLinkMicInvitationReason:(PLVSACancelLinkMicInvitationReason)reason {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvSALinkMicPreviewView:cancelLinkMicInvitationReason:)]) {
        [self.delegate plvSALinkMicPreviewView:self cancelLinkMicInvitationReason:reason];
    }
}

- (void)callbackForInviteLinkMicTTLCallback:(void (^)(NSInteger ttl))callback {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvSALinkMicPreviewView:inviteLinkMicTTL:)]) {
        [self.delegate plvSALinkMicPreviewView:self inviteLinkMicTTL:callback];
    }
}

#pragma mark Getter
- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor clearColor];
    }
    return _backgroundView;
}

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:16];
    }
    return _titleLabel;
}

- (UIView *)cameraPreView {
    if (!_cameraPreView) {
        _cameraPreView = [[UIView alloc] init];
        _cameraPreView.layer.cornerRadius = 4.0f;
        _cameraPreView.layer.masksToBounds = YES;
    }
    return _cameraPreView;
}

- (UIImageView *)cameraDisableImageView {
    if (!_cameraDisableImageView) {
        _cameraDisableImageView = [[UIImageView alloc] init];
    }
    return _cameraDisableImageView;
}
- (UILabel *)cameraDisableLabel {
    if (!_cameraDisableLabel) {
        _cameraDisableLabel = [[UILabel alloc] init];
        _cameraDisableLabel.text = PLVLocalizedString(@"已关摄像头");
        _cameraDisableLabel.textAlignment = NSTextAlignmentCenter;
        _cameraDisableLabel.textColor = [PLVColorUtil colorFromHexString:@"#757575" alpha:0.4];
        _cameraDisableLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
    }
    return _cameraDisableLabel;
}

- (PLVSALinkMicPreMediaSwitchView *)cameraSwitchView {
    if (!_cameraSwitchView) {
        _cameraSwitchView = [[PLVSALinkMicPreMediaSwitchView alloc] init];
        _cameraSwitchView.titleLabel.text = PLVLocalizedString(@"摄像头");
        _cameraSwitchView.imageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_pre_camera_icon"];
        [_cameraSwitchView.mediaSwitch addTarget:self action:@selector(cameraSwitchAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _cameraSwitchView;
}

- (PLVSALinkMicPreMediaSwitchView *)micSwitchView {
    if (!_micSwitchView) {
        _micSwitchView = [[PLVSALinkMicPreMediaSwitchView alloc] init];
        _micSwitchView.titleLabel.text = PLVLocalizedString(@"麦克风");
        _micSwitchView.imageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_pre_mic_icon"];
        [_micSwitchView.mediaSwitch addTarget:self action:@selector(micSwitchAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _micSwitchView;
}

- (UISwitch *)cameraSwitch {
    return self.cameraSwitchView.mediaSwitch;
}

- (UISwitch *)micSwitch {
    return self.micSwitchView.mediaSwitch;
}

- (UIImageView *)tipsImageView {
    if (!_tipsImageView) {
        _tipsImageView = [[UIImageView alloc] init];
        _tipsImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_pre_tips_icon"];
    }
    return _tipsImageView;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.textColor = [PLVColorUtil colorFromHexString:@"#ffffff" alpha:0.6];
        _tipsLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _tipsLabel.text = PLVLocalizedString(@"连麦将收集人像信息，确认上麦视为同意");
        _tipsLabel.numberOfLines = 0;
    }
    return _tipsLabel;
}

- (UIButton *)rejectButton {
    if (!_rejectButton) {
        _rejectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rejectButton.layer.cornerRadius = 20.0f;
        _rejectButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#3082FE"].CGColor;
        _rejectButton.layer.borderWidth = 1.0f;
        _rejectButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        [_rejectButton setTitleColor:[PLVColorUtil colorFromHexString:@"#3082FE"] forState:UIControlStateNormal];
        [_rejectButton setTitle:PLVLocalizedString(@"暂不连麦") forState:UIControlStateNormal];
        [_rejectButton addTarget:self action:@selector(rejectLinkMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rejectButton;
}

- (UIButton *)linkMicButton {
    if (!_linkMicButton) {
        _linkMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _linkMicButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
        _linkMicButton.layer.cornerRadius = 20.0f;
        _linkMicButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        [_linkMicButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_linkMicButton setTitle:PLVLocalizedString(@"开始连麦") forState:UIControlStateNormal];
        [_linkMicButton addTarget:self action:@selector(linkMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _linkMicButton;
}

- (NSTimeInterval)currentTimestamp {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

- (SystemSoundID)soundID {
    if (!_soundID || _soundID == 0) {
        SystemSoundID soundID = 0;
        CFURLRef url = (__bridge CFURLRef)[PLVCLinkMicUtils URLForCLinkMicResource:@"plv_linkmic_invitation_bgm.wav"];
        AudioServicesCreateSystemSoundID(url, &soundID);
        _soundID = soundID;
    }
    return _soundID;
}

- (BOOL)cameraOpen {
    return self.cameraSwitch.on;
}

- (BOOL)micOpen {
    return self.micSwitch.on;
}

#pragma mark Setter

- (void)setIsOnlyAudio:(BOOL)isOnlyAudio {
    _isOnlyAudio = isOnlyAudio;
    if (_isOnlyAudio) {
        self.titleLabel.text = PLVLocalizedString(@"邀请你语音连麦");
        self.cameraDisableImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_pre_onlyaudio_icon"];
        self.cameraPreView.backgroundColor = [PLVColorUtil colorFromHexString:@"#E1EEFF"];
        self.cameraDisableLabel.hidden = YES;
        self.cameraSwitchView.hidden = YES;
        self.cameraDisableImageView.frame = CGRectMake(0, 0, 120, 88);
    } else {
        self.titleLabel.text = PLVLocalizedString(@"邀请你视频连麦");
        self.cameraDisableImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_pre_camera_close"];
        self.cameraPreView.backgroundColor = [PLVColorUtil colorFromHexString:@"#EEEEEE"];
        self.cameraDisableLabel.hidden = NO;
        self.cameraSwitchView.hidden = NO;
        self.cameraDisableImageView.frame = CGRectMake(0, 0, 80, 80);
    }
    [self setNeedsLayout];
}

#pragma mark - [ Event ]

#pragma mark Action
- (void)rejectLinkMicButtonAction {
    [self showLinkMicPreviewView:NO];
    [self callbackForCancelLinkMicInvitationReason:PLVSACancelLinkMicInvitationReason_Manual];
}

- (void)linkMicButtonAction {    
    PLVCaptureDeviceType type = self.isOnlyAudio ? PLVCaptureDeviceTypeMicrophone : PLVCaptureDeviceTypeCameraAndMicrophone;
    NSString *message = [NSString stringWithFormat:PLVLocalizedString(@"参与直播需要%@权限，请前往系统设置开启权限"), (self.isOnlyAudio ? PLVLocalizedString(@"麦克风") : PLVLocalizedString(@"摄像头与麦克风"))];
    __weak typeof(self) weakSelf = self;
    [[PLVCaptureDeviceManager sharedManager] requestAuthorizationWithType:type grantedRefuseTips:message completion:^(BOOL granted) {
        if (granted) {
            [weakSelf callbackForAcceptLinkMicInvitation];
        } else {
            [weakSelf callbackForCancelLinkMicInvitationReason:PLVSACancelLinkMicInvitationReason_Permissions];
        }
        [weakSelf showLinkMicPreviewView:NO];
    }];
}

- (void)cameraSwitchAction:(UISwitch *)sender {
    if (!sender.on || [PLVCaptureDeviceManager sharedManager].cameraGranted) { // 关闭摄像头预览 或者 已经授权
        [[PLVCaptureDeviceManager sharedManager] openCamera:sender.on];
        [self saveUserLinkMicPreConfig];
    } else { // 未授权且希望开启摄像头
        __weak typeof(self) weakSelf = self;
        NSString *message = PLVLocalizedString(@"参与直播需要摄像头权限，请前往系统设置开启权限");
        [[PLVCaptureDeviceManager sharedManager] requestAuthorizationWithType:PLVCaptureDeviceTypeCamera grantedRefuseTips:message completion:^(BOOL granted) {
            if (!granted) {
                weakSelf.cameraSwitch.on = granted;
            }
            [weakSelf saveUserLinkMicPreConfig];
            [[PLVCaptureDeviceManager sharedManager] openCamera:granted];
        }];
    }
}

- (void)micSwitchAction:(UISwitch *)sender {
    if (!sender.on || [PLVCaptureDeviceManager sharedManager].microGranted) { // 关闭麦克风 或者 已经授权
        [self saveUserLinkMicPreConfig];
    } else { // 未授权且希望开启麦克风
        __weak typeof(self) weakSelf = self;
        NSString *message = PLVLocalizedString(@"参与直播需要麦克风权限，请前往系统设置开启权限");
        [[PLVCaptureDeviceManager sharedManager] requestAuthorizationWithType:PLVCaptureDeviceTypeMicrophone grantedRefuseTips:message completion:^(BOOL granted) {
            if (!granted) {
                weakSelf.micSwitch.on = granted;
            }
            [weakSelf saveUserLinkMicPreConfig];
        }];
    }
}

#pragma mark Timer

- (void)inviteLinkMicTimerAction {
    NSInteger leftTime = round((self.acceptInviteLinkMicLimitTs - self.currentTimestamp)/1000);
    if (leftTime <= 0) {
        [self showLinkMicPreviewView:NO];
        [self callbackForCancelLinkMicInvitationReason:PLVSACancelLinkMicInvitationReason_Timeout];
        return;
    }
        
    if((kPLVSALinkMicInvitationAnswerTTL - leftTime)%9 == 0) { // 更新倒计时时间
        __weak typeof(self) weakSelf = self;
        NSTimeInterval socketSendTs = self.currentTimestamp;
        [self callbackForInviteLinkMicTTLCallback:^(NSInteger ttl) {
            if (ttl > -1) {
                NSTimeInterval socketAckTs = weakSelf.currentTimestamp;
                weakSelf.acceptInviteLinkMicLimitTs = socketSendTs + (socketAckTs - socketSendTs)/2 + ttl * 1000;
            }
        }];
    }
    
    NSString *rejectButtonTitle = [NSString stringWithFormat:PLVLocalizedString(@"暂不连麦(%lds)"), leftTime];
    [self.rejectButton setTitle:rejectButtonTitle forState:UIControlStateNormal];
}

@end

@implementation PLVSALinkMicPreMediaSwitchView

- (instancetype)init {
    if (self = [super init]) {
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.switchView];
        [self.switchView addSubview:self.mediaSwitch];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(0, (CGRectGetHeight(self.frame) - 24)/2, 24, 24);
    self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 8, 0, 100, CGRectGetHeight(self.frame));
    self.switchView.frame = CGRectMake(CGRectGetWidth(self.frame) - 32, (CGRectGetHeight(self.frame) - 18)/2, 32, 18);
    self.mediaSwitch.frame = self.switchView.bounds;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:16];
    }
    return _titleLabel;
}

- (UIView *)switchView {
    if (!_switchView) {
        _switchView = [[UIView alloc] init];
        _switchView.layer.cornerRadius = 9.0;
        _switchView.backgroundColor = [PLVColorUtil colorFromHexString:@"#ADADC0"];
    }
    return _switchView;
}

- (UISwitch *)mediaSwitch {
    if (!_mediaSwitch) {
        _mediaSwitch = [[UISwitch alloc] init];
        _mediaSwitch.transform = CGAffineTransformMakeScale(0.627, 0.58);
        _mediaSwitch.onTintColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
    }
    return _mediaSwitch;
}

@end
