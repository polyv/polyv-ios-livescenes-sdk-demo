//
//  PLVLSLinkMicWindowCell.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSLinkMicWindowCell.h"

#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLinkMicOnlineUser+LS.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

///数据
#import "PLVRoomDataManager.h"

@interface PLVLSLinkMicWindowCell ()

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser * userModel;

#pragma mark UI
/// view hierarchy
///
/// (PLVLCLinkMicWindowCell) self
/// └── (UIView) contentView
///      ├── (UIView) contentBackgroudView (lowest)
///      │   └── (PLVLCLinkMicCanvasView) canvasView
///      │
///      ├── (CAGradientLayer) shadowLayer
///      ├── (UIButton) micButton
///      ├── (UILabel) nicknameLabel
///      └── (UILabel) linkMicStatusLabel (top)
@property (nonatomic, strong) UIView * contentBackgroudView;      // 内容背景视图 (负责承载 不同类型的内容画面[RTC画面、PPT画面]；直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) CAGradientLayer * shadowLayer;      // 阴影背景   (负责展示 阴影背景)
@property (nonatomic, strong) CAShapeLayer * cornerRadiusLayer;   // 底部圆角
@property (nonatomic, strong) UIButton * micButton;               // 麦克风按钮 (负责展示 不同状态下的麦克风图标)
@property (nonatomic, strong) UILabel * nicknameLabel;            // 昵称文本框 (负责展示 用户昵称)
@property (nonatomic, strong) UILabel * linkMicStatusLabel;       // 连麦状态文本框 (负责展示 连麦状态)
@property (nonatomic, strong) UIImageView * speakerAuthImageView; // 显示主讲权限的图像视图 (负责展示 主讲权限)
@property (nonatomic, strong) UIImageView *timerIcon; // 计时器图标
@property (nonatomic, strong) UILabel *linkMicDuration; // 连麦时长
@property (nonatomic, assign) BOOL linkMicDurationShow;

@end

@implementation PLVLSLinkMicWindowCell

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat cellWidth = CGRectGetWidth(self.bounds);
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    
    self.contentBackgroudView.frame = self.contentView.bounds;
    self.contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGFloat shadowLayerHeight = 24.0;
    self.shadowLayer.frame = CGRectMake(0, cellHeight - shadowLayerHeight, cellWidth, shadowLayerHeight);
    self.shadowLayer.mask.frame = self.shadowLayer.bounds;
    
    if (!_cornerRadiusLayer) {
        UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:self.shadowLayer.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(8, 8)];
        self.cornerRadiusLayer = [[CAShapeLayer alloc] init];
        self.cornerRadiusLayer.frame = self.shadowLayer.bounds;
        self.cornerRadiusLayer.path = path.CGPath;
        self.shadowLayer.mask = self.cornerRadiusLayer;
    }
    
    CGFloat micButtonHeight = 14.0;
    self.micButton.frame = CGRectMake(4, cellHeight - 3 - micButtonHeight, micButtonHeight, micButtonHeight);
    
    CGFloat nicknameLabelHeight = 17.0;
    self.nicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micButton.frame) + 2,
                                          cellHeight - 2 - nicknameLabelHeight,
                                          cellWidth - 20 - 8,
                                          nicknameLabelHeight);
    
    CGSize labelSize = [self.linkMicStatusLabel sizeThatFits:CGSizeMake(MAXFLOAT, 16)];
    self.linkMicStatusLabel.frame = CGRectMake(2, 2, labelSize.width + 8, 16);
    
    CGFloat speakerImageViewOriginX = self.linkMicStatusLabel.isHidden ? 2 : CGRectGetMaxX(self.linkMicStatusLabel.frame) + 8;
    self.speakerAuthImageView.frame = CGRectMake(speakerImageViewOriginX, 2, 16, 16);
    CGFloat timerIconOriginX = self.speakerAuthImageView.isHidden ? 4 : CGRectGetMaxX(self.speakerAuthImageView.frame) + 4;
    self.timerIcon.frame = CGRectMake(timerIconOriginX, 4, 12, 12);
    self.linkMicDuration.frame = CGRectMake(CGRectGetMaxX(self.timerIcon.frame) + 3, 4, cellWidth - CGRectGetMaxX(self.timerIcon.frame) + 3, 12);
}


#pragma mark - [ Public Methods ]
- (void)setModel:(PLVLinkMicOnlineUser *)userModel {
    // 设置
    /// 数据模型
    self.userModel = userModel;
    
    /// 昵称文本
    NSString * actor = ([PLVFdUtil checkStringUseable:userModel.actor] && [self showActorLabelWithUser:userModel.userType]) ?  [NSString stringWithFormat:@"%@-",userModel.actor] : @"";
    self.nicknameLabel.text = [PLVFdUtil checkStringUseable:userModel.nickname] ? [NSString stringWithFormat:@"%@%@",actor,userModel.nickname] : [NSString stringWithFormat:@"unknown%@",userModel.linkMicUserId];
    
    [self updateLinkMicDuration:self.linkMicDurationShow];


    /// 麦克风图标
    self.micButton.selected = !userModel.currentMicOpen;
    __weak typeof(self) weakSelf = self;
    userModel.micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.userModel.linkMicUserId]) {
            weakSelf.micButton.selected = !onlineUser.currentMicOpen;
        }
    };
        
    /// 摄像画面
    BOOL isOnlyAudio = [PLVRoomDataManager sharedManager].roomData.isOnlyAudio;
    BOOL showRTCView = isOnlyAudio ? NO : userModel.currentCameraShouldShow;
    if (isOnlyAudio && userModel.userType == PLVSocketUserTypeTeacher) { //频道为音频模式 讲师需要显示封面图
        [userModel.canvasView setSplashImageWithURLString:[PLVRoomDataManager sharedManager].roomData.menuInfo.splashImg];
    }
    [userModel.canvasView rtcViewShow:showRTCView];
    userModel.cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [onlineUser.canvasView rtcViewShow:onlineUser.currentCameraShouldShow];
    };

    /// 音量
    [self setMicButtonNormalImageWithVolume:userModel.currentVolume];
    userModel.volumeChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.userModel.linkMicUserId]) {
            [weakSelf setMicButtonNormalImageWithVolume:onlineUser.currentVolume];
        }
    };
    
    /// 主讲权限
    if (userModel.userType == PLVSocketUserTypeGuest) {
        self.speakerAuthImageView.hidden = !userModel.isRealMainSpeaker;
        userModel.currentSpeakerAuthChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.linkMicUserId isEqualToString:weakSelf.userModel.linkMicUserId]) {
                weakSelf.speakerAuthImageView.hidden = !onlineUser.isRealMainSpeaker;
            }
        };
    }else{
        self.speakerAuthImageView.hidden = YES;
    }
    
    /// 连麦状态
    if (userModel.userType == PLVSocketUserTypeGuest && userModel.localUser) {
        self.linkMicStatusLabel.hidden = NO;
        [self setLinkMicStatusLabelWithInVoice:userModel.currentStatusVoice];
        [self setSpeakerAuthImageViewWithInVoice:userModel.currentStatusVoice];
        userModel.currentStatusVoiceChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.linkMicUserId isEqualToString:weakSelf.userModel.linkMicUserId]) {
                [weakSelf setLinkMicStatusLabelWithInVoice:onlineUser.currentStatusVoice];
                [weakSelf setSpeakerAuthImageViewWithInVoice:onlineUser.currentStatusVoice];
            }
        };
    }else{
        self.linkMicStatusLabel.hidden = YES;
    }
    
    [self setNeedsLayout];
}

/// 切换至 显示默认内容视图
- (void)switchToShowRtcContentView:(UIView *)rtcCanvasView{
    // 移除 contentBackgroudView 上的外部视图
    [self removeSubview:self.contentBackgroudView];
    // contentBackgroudView 移至 contentView 的最底层
    [self.contentView sendSubviewToBack:self.contentBackgroudView];
    // contentBackgroudView 承载 rtcCanvasView
    [self contentBackgroudViewAddView:rtcCanvasView];
}

/// 切换至 显示外部内容视图
- (void)switchToShowExternalContentView:(UIView *)externalContentView{
    // contentBackgroudView 移至 contentView 的最顶层
    [self.contentView bringSubviewToFront:self.contentBackgroudView];
    // contentBackgroudView 承载外部未知具体类型的视图
    [self contentBackgroudViewAddView:externalContentView];
}

- (void)updateLinkMicDuration:(BOOL)show {
    BOOL shouldShow = self.userModel.userType != PLVSocketUserTypeTeacher && show;
    if (self.userModel.currentLinkMicDuration > NSTimeIntervalSince1970) {
        shouldShow = NO;
    }
    if (shouldShow) {
        self.linkMicDuration.text = [PLVFdUtil secondsToString2:self.userModel.currentLinkMicDuration];
    }
    self.linkMicDuration.hidden = !shouldShow;
    self.timerIcon.hidden = !shouldShow;
    self.linkMicDurationShow = shouldShow;
}

#pragma mark - [ Private Methods ]
- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLSUtils imageForLinkMicResource:imageName];
}

- (void)removeSubview:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

- (void)contentBackgroudViewAddView:(UIView *)contentView{
    contentView.frame = self.contentBackgroudView.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentBackgroudView addSubview:contentView];
}

- (void)setMicButtonNormalImageWithVolume:(CGFloat)micVolume{
    int volumeLevel = ((int)(micVolume * 100 / 10)) * 10;
    NSString * micImageName = [NSString stringWithFormat:@"plvls_linkmic_mic_volume_%d",volumeLevel];
    [self.micButton setImage:[self getImageWithName:micImageName] forState:UIControlStateNormal];
}

- (void)setLinkMicStatusLabelWithInVoice:(BOOL)inLinkMic{
    if (inLinkMic) {
        self.linkMicStatusLabel.text = PLVLocalizedString(@"连麦中");
        self.linkMicStatusLabel.backgroundColor = PLV_UIColorFromRGB(@"#09C5B3");
    }else{
        self.linkMicStatusLabel.text = PLVLocalizedString(@"未连麦");
        self.linkMicStatusLabel.backgroundColor = PLV_UIColorFromRGB(@"#F1453D");
    }
}

- (void)setSpeakerAuthImageViewWithInVoice:(BOOL)inLinkMic{
    if (!inLinkMic) {
        self.speakerAuthImageView.hidden = YES;
    }
}

#pragma mark UI
- (void)setupUI{
    // 添加 视图
    [self.contentView addSubview:self.contentBackgroudView];
    [self.contentView.layer addSublayer:self.shadowLayer];
    [self.contentView addSubview:self.timerIcon];
    [self.contentView addSubview:self.linkMicDuration];
    [self.contentView addSubview:self.micButton];
    [self.contentView addSubview:self.nicknameLabel];
    [self.contentView addSubview:self.linkMicStatusLabel];
    [self.contentView addSubview:self.speakerAuthImageView];
}

#pragma mark Getter
- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.clipsToBounds = YES;
        _contentBackgroudView.layer.cornerRadius = 8.0;
    }
    return _contentBackgroudView;
}

- (CAGradientLayer *)shadowLayer{
    if (!_shadowLayer) {
        _shadowLayer = [CAGradientLayer layer];
        _shadowLayer.startPoint = CGPointMake(0.5, 0);
        _shadowLayer.endPoint = CGPointMake(0.5, 1);
        _shadowLayer.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.7].CGColor];
        _shadowLayer.locations = @[@(0), @(1.0f)];
    }
    return _shadowLayer;
}

- (UIButton *)micButton{
    if (!_micButton) {
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_micButton setImage:[self getImageWithName:@"plvls_linkmic_window_mic_open"] forState:UIControlStateNormal];
        [_micButton setImage:[self getImageWithName:@"plvls_linkmic_window_mic_close"] forState:UIControlStateSelected];
    }
    return _micButton;
}

- (UILabel *)nicknameLabel{
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc]init];
        _nicknameLabel.text = PLVLocalizedString(@"连麦人昵称");
        _nicknameLabel.textColor = [UIColor whiteColor];
        _nicknameLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _nicknameLabel;
}

- (UILabel *)linkMicStatusLabel{
    if (!_linkMicStatusLabel) {
        _linkMicStatusLabel = [[UILabel alloc]init];
        _linkMicStatusLabel.font = [UIFont fontWithName:@"PingFang SC" size:11];
        _linkMicStatusLabel.textColor = [UIColor whiteColor];
        _linkMicStatusLabel.textAlignment = NSTextAlignmentCenter;
        _linkMicStatusLabel.clipsToBounds = YES;
        _linkMicStatusLabel.layer.cornerRadius = 8;
        _linkMicStatusLabel.hidden = YES;
    }
    return _linkMicStatusLabel;
}

- (UIImageView *)speakerAuthImageView {
    if (!_speakerAuthImageView) {
        _speakerAuthImageView = [[UIImageView alloc] init];
        _speakerAuthImageView.image = [self getImageWithName:@"plvls_linkmic_speakerauth_icon"];
        _speakerAuthImageView.hidden = YES;
    }
    return _speakerAuthImageView;
}

- (BOOL)showActorLabelWithUser:(PLVSocketUserType)userType {
    return (userType == PLVSocketUserTypeGuest ||
            userType == PLVSocketUserTypeTeacher ||
            userType == PLVSocketUserTypeAssistant ||
            userType == PLVSocketUserTypeManager);
}

- (UIImageView *)timerIcon {
    if (!_timerIcon) {
        _timerIcon = [[UIImageView alloc] init];
        _timerIcon.image = [self getImageWithName:@"plvls_linkmic_cell_timer_icon"];
        _timerIcon.contentMode = UIViewContentModeScaleAspectFill;
        _timerIcon.hidden = YES;
    }
    return _timerIcon;
}

- (UILabel *)linkMicDuration {
    if (!_linkMicDuration) {
        _linkMicDuration = [[UILabel alloc]init];
        _linkMicDuration.text = [PLVFdUtil secondsToString2:self.userModel.currentLinkMicDuration];;
        _linkMicDuration.font = [UIFont systemFontOfSize:12];
        _linkMicDuration.textColor = [UIColor whiteColor];
        _linkMicDuration.textAlignment = NSTextAlignmentLeft;
        _linkMicDuration.hidden = YES;
    }
    return _linkMicDuration;
}

@end
