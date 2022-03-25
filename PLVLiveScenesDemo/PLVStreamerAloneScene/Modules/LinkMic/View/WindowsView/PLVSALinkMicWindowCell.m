//
//  PLVSALinkMicWindowCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicWindowCell.h"

#import "PLVSAUtils.h"
#import "PLVLinkMicOnlineUser+SA.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

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
///          └── (UIButton) micButton
@property (nonatomic, strong) UIView *contentBackgroudView; // 内容背景视图 (负责承载 不同类型的内容画面[RTC画面、PPT画面]；直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) UILabel *nickNameLabel; // 昵称文本框 (负责展示 用户昵称)
@property (nonatomic, strong) UIButton *micButton; // 麦克风按钮 (负责展示 不同状态下的麦克风图标)
@property (nonatomic, strong) UILabel *linkMicStatusLabel;       // 连麦状态文本框 (负责展示 连麦状态)

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
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat padding = isPad ? 12 : 8;
    
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat contentViewHeight = self.contentView.bounds.size.height;
    
    self.contentBackgroudView.frame = self.contentView.bounds;
    self.micButton.frame = CGRectMake(padding, contentViewHeight - 14 - padding, 14, 14);
    self.linkMicStatusLabel.frame = CGRectMake(2, 2, 41, 16);

    CGFloat nickNameLabelWidth = contentViewWidth -  CGRectGetMaxX(self.micButton.frame) - padding - padding;
    self.nickNameLabel.frame = CGRectMake(CGRectGetMaxX(self.micButton.frame) + padding, CGRectGetMinY(self.micButton.frame), nickNameLabelWidth, 14);
}

#pragma mark - [ Public Method ]

- (void)setUserModel:(PLVLinkMicOnlineUser *)aOnlineUser hideCanvasViewWhenCameraClose:(BOOL)hide {
    // 设置数据模型
    self.onlineUser = aOnlineUser;

    // 设置昵称文本
    NSString *nickName = self.onlineUser.nickname;
    if (aOnlineUser.userType == PLVSocketUserTypeTeacher) {
        nickName = [NSString stringWithFormat:@"讲师头衔-%@", nickName];
    } else if (aOnlineUser.userType == PLVSocketUserTypeGuest) {
        nickName = [NSString stringWithFormat:@"嘉宾-%@", nickName];
    }
    self.nickNameLabel.text = nickName;
    
    // 设备检测页的连麦窗口不显示以下控件
    self.nickNameLabel.hidden = self.micButton.hidden = hide;
    
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
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.contentBackgroudView];
    [self.contentView addSubview:self.micButton];
    [self.contentView addSubview:self.nickNameLabel];
    [self.contentView addSubview:self.linkMicStatusLabel];
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
        self.linkMicStatusLabel.text = @"连麦中";
        self.linkMicStatusLabel.backgroundColor = PLV_UIColorFromRGB(@"#09C5B3");
    }else{
        self.linkMicStatusLabel.text = @"未连麦";
        self.linkMicStatusLabel.backgroundColor = PLV_UIColorFromRGB(@"#F1453D");
    }
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

@end
