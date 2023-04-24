//
//  PLVECLinkMicWindowCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECLinkMicWindowCell.h"
#import "PLVECUtils.h"
#import "PLVLinkMicOnlineUser+EC.h"

@interface PLVECLinkMicWindowCell ()

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *onlineUser;

#pragma mark UI
/// view hierarchy
///
/// (PLVECLinkMicWindowCell) self
///   └── (UIView) contentView
///          ├── (UIView) contentBackgroudView (lowest)
///          │       └── (PLVECLinkMicCanvasView) canvasView
///          ├── (UIButton) micButton
///          ├── (UILabel) nickNameLabel
///          └── (UIImageView) speakerImageView
@property (nonatomic, strong) UIView *contentBackgroudView; // 内容背景视图 (负责承载 不同类型的内容画面[RTC画面、PPT画面]；直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) UIButton *micButton; // 麦克风按钮 (负责展示 不同状态下的麦克风图标)
@property (nonatomic, strong) UILabel *nickNameLabel; // 昵称文本框 (负责展示 用户昵称)
@property (nonatomic, strong) UIImageView *speakerImageView; // 主讲权限图片视图 (负责展示 主讲状态)

@end

@implementation PLVECLinkMicWindowCell

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
    CGFloat leftPadding = isPad ? 12 : 8;
    CGFloat bottomPadding = isPad ? 12 : 8;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat contentViewHeight = self.contentView.bounds.size.height;
    CGFloat statusLabelLeftPadding = 2;
    CGFloat statusLabelTopPadding = 2;
    
    self.contentBackgroudView.frame = self.contentView.bounds;
    self.micButton.frame = CGRectMake(leftPadding, contentViewHeight - 14 - bottomPadding, 14, 14);
    self.speakerImageView.frame = CGRectMake(statusLabelLeftPadding, statusLabelTopPadding, 16, 16);
    
    CGFloat nickNameLabelWidth = contentViewWidth -  CGRectGetMaxX(self.micButton.frame) - leftPadding - 8;
    self.nickNameLabel.frame = CGRectMake(CGRectGetMaxX(self.micButton.frame) + 8, CGRectGetMinY(self.micButton.frame), nickNameLabelWidth, 14);
}

#pragma mark - [ Public Method ]

- (void)setUserModel:(PLVLinkMicOnlineUser *)aOnlineUser hideCanvasViewWhenCameraClose:(BOOL)hide {
    // 设置数据模型
    self.onlineUser = aOnlineUser;

    // 设置昵称文本
    if (self.onlineUser.actor) {
        self.nickNameLabel.text = [NSString stringWithFormat:@"%@-%@", self.onlineUser.actor, self.onlineUser.nickname];
    } else {
        self.nickNameLabel.text = [NSString stringWithFormat:@"%@%@", self.onlineUser.localUser ? @"(我)" : @"", self.onlineUser.nickname];
    }
    
    // 设备检测页的连麦窗口不显示以下控件
    self.nickNameLabel.hidden = self.micButton.hidden = hide;
    
    __weak typeof(self) weakSelf = self;
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
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.contentBackgroudView];
    [self.contentView addSubview:self.micButton];
    [self.contentView addSubview:self.nickNameLabel];
    [self.contentView addSubview:self.speakerImageView];
}

/// 根据音量更新 micButton 图标
- (void)updateMicButtonWithVolume:(CGFloat)volume {
    int volumeLevel = ((int)(volume * 100 / 10)) * 10;
    NSString *micImageName = [NSString stringWithFormat:@"plvec_linkmic_mic_volume_%d",volumeLevel];
    UIImage *micImage = [PLVECUtils imageForWatchResource:micImageName];
    [self.micButton setImage:micImage forState:UIControlStateNormal];
}

#pragma mark Getter & Setter

- (UIView *)contentBackgroudView {
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc] init];
        _contentBackgroudView.clipsToBounds = YES;
        _contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _contentBackgroudView;
}

- (UIButton *)micButton {
    if (!_micButton) {
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVECUtils imageForWatchResource:@"plvec_linkmic_mic_volume_0"];
        UIImage *selectedImage = [PLVECUtils imageForWatchResource:@"plvec_linkmic_window_mic_close"];
        [_micButton setImage:normalImage forState:UIControlStateNormal];
        [_micButton setImage:selectedImage forState:UIControlStateSelected];
        _micButton.hidden = YES;
    }
    return _micButton;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:14];
        _nickNameLabel.textColor = [UIColor whiteColor];
    }
    return _nickNameLabel;
}

- (UIImageView *)speakerImageView {
    if (!_speakerImageView) {
        _speakerImageView = [[UIImageView alloc] init];
        _speakerImageView.image = [PLVECUtils imageForWatchResource:@"plvec_linkmic_speakerauth_icon"];
        _speakerImageView.hidden = YES;
    }
    return _speakerImageView;
}

@end
