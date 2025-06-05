//
//  PLVSALinkMicWindowCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicWindowCell.h"

#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLinkMicOnlineUser+SA.h"

@interface PLVSALinkMicWindowCell ()

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *onlineUser;

#pragma mark UI
/// view hierarchy
///
/// (PLVSALinkMicWindowCell) self
///   └── (UIView) contentView
///          ├── (UIView) contentBackgroudView (lowest)
///          │       └── (PLVLCLinkMicCanvasView) canvasView
///          ├── (UILabel) linkMicStatusLabel
///          ├── (UILabel) nickNameLabel
///          ├── (UIButton) closeFullScreenButton
///          └── (UIButton) micButton
@property (nonatomic, strong) UIView *contentBackgroudView; // 内容背景视图 (负责承载 不同类型的内容画面[RTC画面、PPT画面]；直接决定了'内容画面'在Cell中的布局、图层、圆角)
@property (nonatomic, strong) UILabel *nickNameLabel; // 昵称文本框 (负责展示 用户昵称)
@property (nonatomic, strong) UIButton *micButton; // 麦克风按钮 (负责展示 不同状态下的麦克风图标)
@property (nonatomic, strong) UILabel *linkMicStatusLabel;       // 连麦状态文本框 (负责展示 连麦状态)
@property (nonatomic, strong) UIImageView *speakerImageView;       // 主讲权限图片视图 (负责展示 主讲状态)
@property (nonatomic, strong) UIButton *closeFullScreenButton; // 关闭全屏 按钮
@property (nonatomic, strong) UIImageView *screenSharingImageView; // 屏幕共享时 背景图
@property (nonatomic, strong) UILabel *screenSharingLabel; // 屏幕共享时 文本框
@property (nonatomic, strong) UIButton *screenSharingStopButton; // 屏幕共享停止按钮
@property (nonatomic, strong) UIImageView *timerIcon; // 计时器图标
@property (nonatomic, strong) UILabel *linkMicDuration; // 连麦时长
@property (nonatomic, assign) BOOL linkMicDurationShow;

@end

@implementation PLVSALinkMicWindowCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 当前是否处于全屏模式
    BOOL isFullScreen = self.contentView.superview != self;    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat leftPadding = isFullScreen ? 16 : (isPad ? 12 : 8);
    CGFloat bottomPadding = isFullScreen ? 32 : (isPad ? 12 : 8);
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat contentViewHeight = self.contentView.bounds.size.height;
    CGFloat statusLabelLeftPadding = isFullScreen ? 16 : 2;
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGFloat statusLabelTopPadding = isFullScreen ? statusBarHeight + 20 : 2;

    self.contentBackgroudView.frame = self.contentView.bounds;
    self.micButton.frame = CGRectMake(leftPadding, contentViewHeight - 14 - bottomPadding, 14, 14);
    self.linkMicStatusLabel.frame = CGRectMake(statusLabelLeftPadding, statusLabelTopPadding, 41, 16);
    [self layoutLinkMicStatusLabel];
    CGFloat speakerImageViewLeft = self.linkMicStatusLabel.isHidden ? statusLabelLeftPadding : CGRectGetMaxX(self.linkMicStatusLabel.frame) + 8;
    self.speakerImageView.frame = CGRectMake(speakerImageViewLeft, statusLabelTopPadding, 16, 16);
    CGFloat timerIconOriginX = self.speakerImageView.isHidden ? leftPadding : CGRectGetMaxX(self.speakerImageView.frame) + 4;
    self.timerIcon.frame = CGRectMake(timerIconOriginX, 4, 14, 14);
    self.linkMicDuration.frame = CGRectMake(CGRectGetMaxX(self.timerIcon.frame) + 3, 4, contentViewWidth - CGRectGetMaxX(self.timerIcon.frame) + 3, 14);
    self.screenSharingImageView.frame = CGRectMake((contentViewWidth - 44)/2, (contentViewHeight - 44)/2 - 20, 44, 44);
    CGFloat sharingLabelWidth = [self.screenSharingLabel sizeThatFits:CGSizeMake(MAXFLOAT, 18)].width;
    self.screenSharingLabel.frame = CGRectMake((contentViewWidth - sharingLabelWidth)/2, CGRectGetMaxY(self.screenSharingImageView.frame) + 4, sharingLabelWidth, 18);
    
    NSString *stopButtonTitle = [self.screenSharingStopButton titleForState:UIControlStateNormal] ?: PLVLocalizedString(@"结束共享");
    UIFont *stopButtonFont = self.screenSharingStopButton.titleLabel.font ?: [UIFont fontWithName:@"PingFang SC" size:14];
    CGFloat stopButtonTextWidth = [stopButtonTitle sizeWithAttributes:@{NSFontAttributeName: stopButtonFont}].width;
    CGFloat stopButtonWidth = stopButtonTextWidth + 44;
    CGFloat stopButtonHeight = 32;
    self.screenSharingStopButton.frame = CGRectMake((contentViewWidth - stopButtonWidth)/2, CGRectGetMaxY(self.screenSharingLabel.frame) + 12, stopButtonWidth, stopButtonHeight);
    
    CGFloat nickNameLabelWidth = contentViewWidth -  CGRectGetMaxX(self.micButton.frame) - leftPadding - 8;
    self.nickNameLabel.frame = CGRectMake(CGRectGetMaxX(self.micButton.frame) + 8, CGRectGetMinY(self.micButton.frame), nickNameLabelWidth, 14);
    
    self.closeFullScreenButton.hidden = !isFullScreen;
    self.closeFullScreenButton.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - 32 - 12, statusBarHeight + 16, 32, 32);
}

#pragma mark - [ Public Method ]

- (void)setUserModel:(PLVLinkMicOnlineUser *)aOnlineUser hideCanvasViewWhenCameraClose:(BOOL)hide {
    // 设置数据模型
    self.onlineUser = aOnlineUser;

    // 设置昵称文本
    NSString *nickName = self.onlineUser.nickname;
    if (aOnlineUser.userType == PLVSocketUserTypeTeacher) {
        nickName = [NSString stringWithFormat:PLVLocalizedString(@"讲师头衔-%@"), nickName];
    } else if (aOnlineUser.userType == PLVSocketUserTypeGuest) {
        nickName = [NSString stringWithFormat:PLVLocalizedString(@"嘉宾-%@"), nickName];
    }
    self.nickNameLabel.text = nickName;
    
    // 设备检测页的连麦窗口不显示以下控件
    self.nickNameLabel.hidden = self.micButton.hidden = hide;
    
    [self updateLinkMicDuration:self.linkMicDurationShow];
    
    __weak typeof(self) weakSelf = self;
    // 连麦状态
    if (aOnlineUser.userType == PLVSocketUserTypeGuest && aOnlineUser.localUser) {
        self.linkMicStatusLabel.hidden = hide;
        [self setLinkMicStatusLabelWithInVoice:aOnlineUser.currentStatusVoice];
        aOnlineUser.currentStatusVoiceChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
                [weakSelf setLinkMicStatusLabelWithInVoice:onlineUser.currentStatusVoice];
            }
        };
    } else {
        self.linkMicStatusLabel.hidden = YES;
    }
    
    // 设置麦克风开启或关闭状态及状态实时更新block
    self.micButton.selected = !aOnlineUser.currentMicOpen;
    [aOnlineUser addMicOpenChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        plv_dispatch_main_async_safe(^{
            if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
                weakSelf.micButton.selected = !onlineUser.currentMicOpen;
            }
        })
    } blockKey:self];
    
    // 设置麦克风音量及音量实时更新block
    [self updateMicButtonWithVolume:self.onlineUser.currentVolume];
    aOnlineUser.volumeChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
            [weakSelf updateMicButtonWithVolume:onlineUser.currentVolume];
        }
    };
    
    // 摄像画面
    [aOnlineUser.canvasView rtcViewShow:aOnlineUser.currentCameraShouldShow];
    aOnlineUser.cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [onlineUser.canvasView rtcViewShow:onlineUser.currentCameraShouldShow];
        if (hide) {
            if (onlineUser.currentCameraShouldShow) {
                onlineUser.canvasView.frame = weakSelf.contentBackgroudView.bounds;
                [weakSelf.contentBackgroudView addSubview:onlineUser.canvasView];
            } else {
                [onlineUser.canvasView removeFromSuperview];
            }
        }
    };
    aOnlineUser.canvasView.frame = self.contentBackgroudView.bounds;
    aOnlineUser.canvasView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (hide) {
        if (aOnlineUser.currentCameraShouldShow) {
            [self.contentBackgroudView addSubview:aOnlineUser.canvasView];
        } else {
            [aOnlineUser.canvasView removeFromSuperview];
        }
    } else {
        [self.contentBackgroudView addSubview:aOnlineUser.canvasView];
    }
    
    // 主讲权限更新
    if (aOnlineUser.userType == PLVSocketUserTypeGuest) {
        self.speakerImageView.hidden = hide || !aOnlineUser.isRealMainSpeaker;
        [aOnlineUser addCurrentSpeakerAuthChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
                weakSelf.speakerImageView.hidden = !onlineUser.isRealMainSpeaker;
                [weakSelf layoutSubviews];
            }
        } blockKey:self];
    } else {
        self.speakerImageView.hidden = YES;
    }
    
    // 屏幕共享事件的响应、更新
    [self updateScreenShareViewWithOnlineUser:aOnlineUser];
    [aOnlineUser addScreenShareOpenChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
            [weakSelf updateScreenShareViewWithOnlineUser:onlineUser];
        }
        if (!onlineUser.localUser) {
            [weakSelf callbackForRemoteUserDidScreenShare:onlineUser];
        }
    } blockKey:self];
}

- (void)updateLinkMicDuration:(BOOL)show {
    BOOL shouldShow = self.onlineUser.userType != PLVSocketUserTypeTeacher && show;
    if (self.onlineUser.currentLinkMicDuration > NSTimeIntervalSince1970) {
        shouldShow = NO;
    }
    if (shouldShow) {
        self.linkMicDuration.text = [PLVFdUtil secondsToString2:self.onlineUser.currentLinkMicDuration];
    }
    self.linkMicDuration.hidden = !shouldShow;
    self.timerIcon.hidden = !shouldShow;
    self.linkMicDurationShow = shouldShow;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.contentBackgroudView];
    [self.contentView addSubview:self.timerIcon];
    [self.contentView addSubview:self.linkMicDuration];
    [self.contentView addSubview:self.micButton];
    [self.contentView addSubview:self.nickNameLabel];
    [self.contentView addSubview:self.linkMicStatusLabel];
    [self.contentView addSubview:self.speakerImageView];
    [self.contentView addSubview:self.closeFullScreenButton];
    [self.contentView addSubview:self.screenSharingImageView];
    [self.contentView addSubview:self.screenSharingLabel];
    [self.contentView addSubview:self.screenSharingStopButton];

    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleSingleTap)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self.contentView addGestureRecognizer:singleTapGesture];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.contentView addGestureRecognizer:doubleTapGesture];

    // 只有当doubleTapGesture识别失败的时候(即识别出这不是双击操作)，singleTapGesture才能开始识别，singleTapGesture触发会有延迟
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
}

/// 根据音量更新 micButton 图标
- (void)updateMicButtonWithVolume:(CGFloat)volume {
    int volumeLevel = ((int)(volume * 100 / 10)) * 10;
    NSString *micImageName = [NSString stringWithFormat:@"plvsa_linkmic_mic_volume_%d",volumeLevel];
    UIImage *micImage = [PLVSAUtils imageForLinkMicResource:micImageName];
    [self.micButton setImage:micImage forState:UIControlStateNormal];
}

- (NSString *)imageNameWithUserType:(PLVSocketUserType)userType {
    NSString *imageName = nil;
    switch (userType) {
        case PLVSocketUserTypeGuest:
            imageName = @"plvsa_linkmic_guest_avatar";
            break;
        case PLVSocketUserTypeAssistant:
            imageName = @"plvsa_linkmic_assistant_avatar";
            break;
        default:
            imageName = @"plvsa_linkmic_student_avatar";
            break;
    }
    return imageName;
}

- (void)setLinkMicStatusLabelWithInVoice:(BOOL)inLinkMic{
    if (inLinkMic) {
        self.linkMicStatusLabel.text = PLVLocalizedString(@"连麦中");
        self.linkMicStatusLabel.backgroundColor = PLV_UIColorFromRGB(@"#09C5B3");
    }else{
        self.linkMicStatusLabel.text = PLVLocalizedString(@"未连麦");
        self.linkMicStatusLabel.backgroundColor = PLV_UIColorFromRGB(@"#F1453D");
    }
    [self layoutLinkMicStatusLabel];
}

- (void)updateScreenShareViewWithOnlineUser:(PLVLinkMicOnlineUser *)onlineUser {
    BOOL localUserScreenShareOpen = onlineUser.localUser ? onlineUser.currentScreenShareOpen : NO;
    self.screenSharingLabel.hidden = !localUserScreenShareOpen;
    self.screenSharingImageView.hidden = !localUserScreenShareOpen;
    self.screenSharingStopButton.hidden = !localUserScreenShareOpen;
    [onlineUser.canvasView rtcViewShow:!localUserScreenShareOpen && onlineUser.currentCameraShouldShow];
    onlineUser.canvasView.placeholderImageView.hidden = localUserScreenShareOpen;
}

- (void)layoutLinkMicStatusLabel {
    CGRect labelRect = self.linkMicStatusLabel.frame;
    CGSize labelSize = [self.linkMicStatusLabel sizeThatFits:CGSizeMake(MAXFLOAT, labelRect.size.height)];
    self.linkMicStatusLabel.frame = CGRectMake(labelRect.origin.x, labelRect.origin.y, labelSize.width + 8, labelRect.size.height);
}

#pragma mark Callback

- (void)callbackForDidSelectCell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicWindowCellDidSelectCell:)]) {
        [self.delegate linkMicWindowCellDidSelectCell:self];
    }
}

- (void)callbackForCellDidFullScreen:(BOOL)isFullScreen {
    plv_dispatch_main_async_safe(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicWindowCell:linkMicUser:didFullScreen:)]) {
            [self.delegate linkMicWindowCell:self linkMicUser:self.onlineUser didFullScreen:isFullScreen];
        }
    })
}

- (void)callbackForRemoteUserDidScreenShare:(PLVLinkMicOnlineUser *)onlineUser {
    plv_dispatch_main_async_safe(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicWindowCell:didScreenShareForRemoteUser:)]) {
            [self.delegate linkMicWindowCell:self didScreenShareForRemoteUser:onlineUser];
        }
    })
}

- (void)callbackForScreenSharingStop {
    plv_dispatch_main_async_safe(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicWindowCellDidClickStopScreenSharing:)]) {
            [self.delegate linkMicWindowCellDidClickStopScreenSharing:self];
        }
    })
}

#pragma mark Getter & Setter

- (UIView *)contentBackgroudView {
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.clipsToBounds = YES;
        _contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _contentBackgroudView;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:14];
        _nickNameLabel.textColor = [UIColor whiteColor];
    }
    return _nickNameLabel;
}

- (UIButton *)micButton {
    if (!_micButton) {
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_mic_volume_0"];
        UIImage *selectedImage = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_mic_close"];
        [_micButton setImage:normalImage forState:UIControlStateNormal];
        [_micButton setImage:selectedImage forState:UIControlStateSelected];
        _micButton.hidden = YES;
    }
    return _micButton;
}

- (UIButton *)closeFullScreenButton {
    if (!_closeFullScreenButton) {
        _closeFullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_fullscreen_close"];
        [_closeFullScreenButton setImage:normalImage forState:UIControlStateNormal];
        [_closeFullScreenButton addTarget:self action:@selector(closeFullScreenButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _closeFullScreenButton.hidden = YES;
    }
    return _closeFullScreenButton;
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

- (UIImageView *)speakerImageView{
    if (!_speakerImageView) {
        _speakerImageView = [[UIImageView alloc]init];
        _speakerImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_speakerauth_icon"];
        _speakerImageView.hidden = YES;
    }
    return _speakerImageView;
}

- (UIImageView *)screenSharingImageView{
    if (!_screenSharingImageView) {
        _screenSharingImageView = [[UIImageView alloc]init];
        _screenSharingImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_window_screensharing_icon"];
        _screenSharingImageView.hidden = YES;
    }
    return _screenSharingImageView;
}

- (UILabel *)screenSharingLabel{
    if (!_screenSharingLabel) {
        _screenSharingLabel = [[UILabel alloc]init];
        _screenSharingLabel.text = PLVLocalizedString(@"您正在共享屏幕");
        _screenSharingLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _screenSharingLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _screenSharingLabel.textAlignment = NSTextAlignmentCenter;
        _screenSharingLabel.hidden = YES;
    }
    return _screenSharingLabel;
}

- (UIButton *)screenSharingStopButton {
    if (!_screenSharingStopButton) {
        _screenSharingStopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _screenSharingStopButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#FF5053"];
        [_screenSharingStopButton setTitle:PLVLocalizedString(@"结束共享") forState:UIControlStateNormal];
        [_screenSharingStopButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _screenSharingStopButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        _screenSharingStopButton.layer.cornerRadius = 16;
        _screenSharingStopButton.clipsToBounds = YES;
        [_screenSharingStopButton addTarget:self action:@selector(screenSharingStopButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _screenSharingStopButton.hidden = YES;
    }
    return _screenSharingStopButton;
}

- (UIImageView *)timerIcon {
    if (!_timerIcon) {
        _timerIcon = [[UIImageView alloc] init];
        _timerIcon.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_cell_timer_icon"];
        _timerIcon.contentMode = UIViewContentModeScaleAspectFill;
        _timerIcon.hidden = YES;
    }
    return _timerIcon;
}

- (UILabel *)linkMicDuration {
    if (!_linkMicDuration) {
        _linkMicDuration = [[UILabel alloc]init];
        _linkMicDuration.text = [PLVFdUtil secondsToString2:self.onlineUser.currentLinkMicDuration];
        _linkMicDuration.font = [UIFont systemFontOfSize:14];
        _linkMicDuration.textColor = [UIColor whiteColor];
        _linkMicDuration.textAlignment = NSTextAlignmentLeft;
        _linkMicDuration.hidden = YES;
    }
    return _linkMicDuration;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeFullScreenButtonAction {
    [self callbackForCellDidFullScreen:NO];
}

- (void)screenSharingStopButtonAction {
    [self callbackForScreenSharingStop];
}

#pragma mark Gesture

- (void)handleSingleTap {
    // 全屏状态下不响应单击事件
    if (self.contentView.superview != self) {
        return;
    }

    [self callbackForDidSelectCell];
}

- (void)handleDoubleTap {
    if (!(self.onlineUser.localUser && self.onlineUser.currentScreenShareOpen)) {
        [self callbackForCellDidFullScreen:(self.contentView.superview == self)];
    }
}

@end
