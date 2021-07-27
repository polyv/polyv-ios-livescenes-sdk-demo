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
///          ├── (UIView) nickNameBgView
///          │       ├── (UIImageView) avatarImageView
///          │       └── (UILabel) nickNameLabel
///          └── (UIButton) micButton
@property (nonatomic, strong) UIView *contentBackgroudView; // 内容背景视图 (负责承载 不同类型的内容画面[RTC画面、PPT画面]；直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) UIView *nickNameBgView; // 用户头像 和 用户昵称 背景视图
@property (nonatomic, strong) UIImageView *avatarImageView; // 连麦用户头像视图 (负责展示 用户头像)
@property (nonatomic, strong) UILabel *nickNameLabel; // 昵称文本框 (负责展示 用户昵称)
@property (nonatomic, strong) UIButton *micButton; // 麦克风按钮 (负责展示 不同状态下的麦克风图标)

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
    
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat contentViewHeight = self.contentView.bounds.size.height;
    
    self.contentBackgroudView.frame = self.contentView.bounds;
    self.micButton.frame = CGRectMake(contentViewWidth - 24 - 8, contentViewHeight - 24 - 8, 24, 24);
    
    CGFloat maxWidth = CGRectGetMinX(self.micButton.frame) - 8;
    CGSize nickLabelSize = [self.nickNameLabel.text boundingRectWithSize:CGSizeMake(maxWidth, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.nickNameLabel.font} context:nil].size;
    self.nickNameBgView.frame = CGRectMake(8, contentViewHeight - 36 - 8, 40 + nickLabelSize.width + 10, 36);
    self.nickNameLabel.frame = CGRectMake(40, 8, nickLabelSize.width, 20);
    self.avatarImageView.frame = CGRectMake(4, 3, 30, 30);
}

#pragma mark - [ Public Method ]

- (void)setUserModel:(PLVLinkMicOnlineUser *)aOnlineUser hideCanvasViewWhenCameraClose:(BOOL)hide {
    // 设置数据模型
    self.onlineUser = aOnlineUser;
    
    // 设置头像及昵称文本
    NSString *imageName = [self imageNameWithUserType:self.onlineUser.userType];
    UIImage *placeholder = [PLVSAUtils imageForLinkMicResource:imageName];
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:self.onlineUser.avatarPic]
                            placeholderImage:placeholder];
    self.nickNameLabel.text = [PLVFdUtil cutSting:self.onlineUser.nickname WithCharacterLength:6];
    
    // 自己的连麦窗口不显示以下控件
    self.nickNameBgView.hidden = self.micButton.hidden = self.onlineUser.localUser;
    
    __weak typeof(self) weakSelf = self;
    if (!self.onlineUser.localUser) {
        // 设置麦克风开启或关闭状态及状态实时更新block
        self.micButton.selected = !self.onlineUser.currentMicOpen;
        self.onlineUser.micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
                weakSelf.micButton.selected = !onlineUser.currentMicOpen;
            }
        };
        
        // 设置麦克风音量及音量实时更新block
        [self updateMicButtonWithVolume:self.onlineUser.currentVolume];
        self.onlineUser.volumeChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
                [weakSelf updateMicButtonWithVolume:onlineUser.currentVolume];
            }
        };
    }
    
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
    [self.contentView addSubview:self.nickNameBgView];
    [self.contentView addSubview:self.micButton];
    
    [self.nickNameBgView addSubview:self.avatarImageView];
    [self.nickNameBgView addSubview:self.nickNameLabel];
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

#pragma mark Getter & Setter

- (UIView *)contentBackgroudView {
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.clipsToBounds = YES;
        _contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _contentBackgroudView;
}

- (UIView *)nickNameBgView {
    if (!_nickNameBgView) {
        _nickNameBgView = [[UIView alloc] init];
        _nickNameBgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _nickNameBgView.layer.masksToBounds = YES;
        _nickNameBgView.layer.cornerRadius = 18.0;
        _nickNameBgView.hidden = YES;
    }
    return _nickNameBgView;
}

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.masksToBounds = YES;
        _avatarImageView.layer.cornerRadius = 15.0;
    }
    return _avatarImageView;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont boldSystemFontOfSize:14];
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

@end
