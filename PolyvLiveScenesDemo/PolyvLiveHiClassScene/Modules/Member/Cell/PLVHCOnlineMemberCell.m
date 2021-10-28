//
//  PLVHCOnlineMemberCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/3.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCOnlineMemberCell.h"

/// 工具
#import "PLVHCUtils.h"

/// 数据
#import "PLVChatUser.h"
#import "PLVRoomDataManager.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

typedef NS_ENUM(NSInteger, PLVHCOnlineMemberCellControlStatus) {
    PLVHCOnlineMemberCellControlStatusUnknown,
    PLVHCOnlineMemberCellControlStatusNormal,
    PLVHCOnlineMemberCellControlStatusOnline,
    PLVHCOnlineMemberCellControlStatusWait
};

@interface PLVHCOnlineMemberCell ()

#pragma mark UI
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UIImageView *handUpImageView;
@property (nonatomic, strong) UIButton *linkMicButton;
@property (nonatomic, strong) UIButton *authBrushButton;
@property (nonatomic, strong) UIButton *micButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UILabel *rewardLabel;
@property (nonatomic, strong) UIButton *banButton;
@property (nonatomic, strong) UIButton *kickButton;

#pragma mark 数据
@property (nonatomic, strong) PLVChatUser *chatUser;
@property (nonatomic, assign) PLVHCOnlineMemberCellControlStatus controlStatus;
@property (nonatomic, strong) NSTimer *loadTimer;
@property (nonatomic, assign) NSInteger maxLoadDuration; //上下台时最大加载时长
@property (nonatomic, strong) PLVLinkMicOnlineUserGrantCupCountChangedBlock grantCupCountChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserBrushAuthChangedBlock brushAuthChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserMicOpenChangedBlock micOpenChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserCameraShouldShowChangedBlock cameraShouldShowChangedBlock;

@end

@implementation PLVHCOnlineMemberCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#22273D"];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat selfWidth = self.bounds.size.width;
    self.bgView.frame = CGRectMake(8, 0, selfWidth - 16, self.bounds.size.height);
    
    // 以下控件位置的计算都跟headerView对齐
    CGFloat headerLeftViewWidth = selfWidth * 0.36;
    CGFloat headerRightViewWidth = selfWidth - headerLeftViewWidth;
    self.nicknameLabel.frame = CGRectMake(24, 17, headerLeftViewWidth - 24 - 30, 14);
    CGFloat headerLabelWidth = (headerRightViewWidth - 22.0) / 7.0;
    CGFloat frameOriginX = self.bounds.size.width - 22 - headerLabelWidth + (headerLabelWidth - 40)/2.0;
    self.kickButton.frame = CGRectMake(frameOriginX, 2, 40, 44);
    frameOriginX -= headerLabelWidth;
    self.banButton.frame = CGRectMake(frameOriginX, 2, 40, 44);
    frameOriginX -= headerLabelWidth;
    self.rewardLabel.frame = CGRectMake(frameOriginX, 2, 40, 44);
    frameOriginX -= headerLabelWidth;
    self.cameraButton.frame = CGRectMake(frameOriginX, 2, 40, 44);
    frameOriginX -= headerLabelWidth;
    self.micButton.frame = CGRectMake(frameOriginX, 2, 40, 44);
    frameOriginX -= headerLabelWidth;
    self.authBrushButton.frame = CGRectMake(frameOriginX, 2, 40, 44);
    frameOriginX -= headerLabelWidth;
    self.linkMicButton.frame = CGRectMake(frameOriginX, 2, 40, 44);
    frameOriginX -= headerLabelWidth;
    self.handUpImageView.frame = CGRectMake(frameOriginX, 2, 40, 44);
}

#pragma mark - [ Public Method ]

- (void)setChatUser:(PLVChatUser *)user even:(BOOL)even {
    self.bgView.hidden = even;
    
    if (!user || ![user isKindOfClass:[PLVChatUser class]]) {
        self.chatUser = nil;
        self.nicknameLabel.text = @"";
        return;
    }
    
    self.chatUser = user;
    if (PLV_SafeStringForValue(user.userName)) {
        self.nicknameLabel.text = user.userName;
    }
    self.banButton.selected = user.banned;
    self.handUpImageView.hidden = !user.currentHandUp;
    self.rewardLabel.text = [NSString stringWithFormat:@"%ld", (long)user.cupCount];
    if (self.controlStatus == PLVHCOnlineMemberCellControlStatusWait) {
        [self refreshControlButtonsStateWait];
    } else {
        [self refreshControlButtonsState];
        [self refreshMediaControlsState];
    }

    __weak typeof(self) weakSelf = self;
    user.onlineUserChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull currentOnlineUser) {
        [weakSelf refreshControlButtonsState];
        [weakSelf refreshMediaControlsState];
    };
    if (user.onlineUser) {
        self.authBrushButton.selected = user.onlineUser.currentBrushAuth;
        [self addUserInfoChangedBlock:user.onlineUser];
    }
}

+ (CGFloat)cellHeight {
    return 48.0;
}

- (void)updateUserLinkMicAnswer:(BOOL)success {
    if (!success) {
        [self stopLinkMicLoading];
    }
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.bgView];
    [self.contentView addSubview:self.nicknameLabel];
    [self.contentView addSubview:self.handUpImageView];
    [self.contentView addSubview:self.linkMicButton];
    [self.contentView addSubview:self.authBrushButton];
    [self.contentView addSubview:self.micButton];
    [self.contentView addSubview:self.cameraButton];
    [self.contentView addSubview:self.rewardLabel];
    [self.contentView addSubview:self.banButton];
    [self.contentView addSubview:self.kickButton];
}

- (void)refreshControlButtonsState {
    if (self.chatUser.onlineUser) {
        [self refreshControlButtonsStateOnline];
    } else {
        [self refreshControlButtonsStateNormal];
    }
 }

- (void)refreshControlButtonsStateNormal {
    if (self.controlStatus == PLVHCOnlineMemberCellControlStatusNormal) {
        return;
    }
    
    self.controlStatus = PLVHCOnlineMemberCellControlStatusNormal;
    UIImageView *buttonImageView = self.linkMicButton.imageView;
    if (buttonImageView.isAnimating) {
        [buttonImageView stopAnimating];
    }
    buttonImageView.animationImages = nil;
    self.linkMicButton.enabled = YES;
    self.linkMicButton.selected = NO;
    [self.linkMicButton setImage:nil forState:UIControlStateNormal];
    [self.linkMicButton setTitle:@"上台" forState:UIControlStateNormal];
    [self.linkMicButton setTitleColor:[PLVColorUtil colorFromHexString:@"#78A7ED"] forState:UIControlStateNormal];
    self.micButton.selected = NO;
    self.authBrushButton.selected = NO;
    self.cameraButton.selected = NO;
    UIImage *micDisabledImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_mic_disabled_btn"];
    [self.micButton setImage:micDisabledImage forState:UIControlStateNormal];
    UIImage *brushDisabledImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_pen_btn_disable"];
    [self.authBrushButton setImage:brushDisabledImage forState:UIControlStateNormal];
    UIImage *cameraDisabledImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_camera_disabled_btn"];
    [self.cameraButton setImage:cameraDisabledImage forState:UIControlStateNormal];
}

- (void)refreshControlButtonsStateWait {
    UIImageView *buttonImageView = self.linkMicButton.imageView;
    if (self.controlStatus == PLVHCOnlineMemberCellControlStatusWait &&
        buttonImageView.animationImages) {
        if (!buttonImageView.isAnimating) {
            [buttonImageView startAnimating];
        }
        return;
    }
    
    self.controlStatus = PLVHCOnlineMemberCellControlStatusWait;
    self.linkMicButton.enabled = NO;
    self.linkMicButton.selected = NO;
    UIImage *firstImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_linkmic_loading_01"];
    [self.linkMicButton setImage:firstImage forState:UIControlStateNormal];
    [self.linkMicButton setTitle:@"" forState:UIControlStateNormal];
    ///设置按钮等待状态
    NSArray *imageArray = @[
        firstImage,
        [PLVHCUtils imageForMemberResource:@"plvhc_member_linkmic_loading_02"],
        [PLVHCUtils imageForMemberResource:@"plvhc_member_linkmic_loading_03"]];
    buttonImageView.animationImages = imageArray;
    buttonImageView.animationDuration= 1.2;
    buttonImageView.animationRepeatCount = 0;
    if (!buttonImageView.isAnimating) {
        [buttonImageView startAnimating];
    }
}

- (void)refreshControlButtonsStateOnline {
    if (self.controlStatus == PLVHCOnlineMemberCellControlStatusOnline) {
        return;
    }
    
    self.controlStatus = PLVHCOnlineMemberCellControlStatusOnline;
    [self notifyUserLinkMicComplete];
    
    UIImageView *buttonImageView = self.linkMicButton.imageView;
    if (buttonImageView.isAnimating) {
        [buttonImageView stopAnimating];
    }
    buttonImageView.animationImages = nil;
    self.linkMicButton.enabled = YES;
    self.linkMicButton.selected = YES;
    [self.linkMicButton setImage:nil forState:UIControlStateNormal];
    [self.linkMicButton setTitle:@"下台" forState:UIControlStateNormal];
    [self.linkMicButton setTitleColor:[PLVColorUtil colorFromHexString:@"#F24453"] forState:UIControlStateNormal];
    UIImage *micNormalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_mic_open_btn"];
    [self.micButton setImage:micNormalImage forState:UIControlStateNormal];
    UIImage *brushNormalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_pen_btn_normal"];
    [self.authBrushButton setImage:brushNormalImage forState:UIControlStateNormal];
    UIImage *cameraNormalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_camera_open_btn"];
    [self.cameraButton setImage:cameraNormalImage forState:UIControlStateNormal];
}

- (void)refreshMediaControlsState {
    if (!self.chatUser.onlineUser) {
        return;
    }
    self.micButton.selected = !self.chatUser.onlineUser.currentMicOpen;
    self.cameraButton.selected = !self.chatUser.onlineUser.currentCameraShouldShow;
}

- (void)addUserInfoChangedBlock:(PLVLinkMicOnlineUser *)user {
    //授予奖杯
    [user addGrantCupCountChangedBlock:self.grantCupCountChangedBlock blockKey:self];
    //授予画笔
    [user addBrushAuthStateChangedBlock:self.brushAuthChangedBlock blockKey:self];
    //麦克风
    [user addMicOpenChangedBlock:self.micOpenChangedBlock blockKey:self];
    //摄像头
    [user addCameraShouldShowChangedBlock:self.cameraShouldShowChangedBlock blockKey:self];
}

- (void)startLinkMicLoading {
    //上台会有延迟，根据onlineUserChangedBlock和updateUserLinkMicAnswer关闭加载计时器
    self.maxLoadDuration = 30;
    [self refreshControlButtonsStateWait];
    self.loadTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(loadTimerEvent) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.loadTimer forMode:NSRunLoopCommonModes];
    [self.loadTimer fire];
}

- (void)stopLinkMicLoading {
    self.maxLoadDuration = 0;
    self.loadTimer = nil;
    [self refreshControlButtonsState];
    [self refreshMediaControlsState];
}

#pragma mark Notify Delegate

- (void)notifyUserLinkMic:(BOOL)linkMic {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicInOnlineMemberCell:linkMicUser:linkMic:)]) {
        [self.delegate linkMicInOnlineMemberCell:self linkMicUser:self.chatUser linkMic:linkMic];
    }
}

- (void)notifyUserLinkMicComplete {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicCompleteInOnlineMemberCell:linkMicUser:)]) {
        [self.delegate linkMicCompleteInOnlineMemberCell:self linkMicUser:self.chatUser];
    }
}

#pragma mark Getter & Setter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
        _bgView.layer.cornerRadius = 8;
    }
    return _bgView;
}

- (UILabel *)nicknameLabel {
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc] init];
        _nicknameLabel.font = [UIFont systemFontOfSize:14];
        _nicknameLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8];
    }
    return _nicknameLabel;
}

- (UIImageView *)handUpImageView {
    if (!_handUpImageView) {
        _handUpImageView = [[UIImageView alloc] init];
        _handUpImageView.image = [PLVHCUtils imageForMemberResource:@"plvhc_member_handup_icon"];
        _handUpImageView.contentMode = UIViewContentModeCenter;
        _handUpImageView.hidden = YES;
    }
    return _handUpImageView;
}

- (UIButton *)linkMicButton {
    if (!_linkMicButton) {
        _linkMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _linkMicButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        [_linkMicButton setTitle:@"上台" forState:UIControlStateNormal];
        [_linkMicButton setTitleColor:[PLVColorUtil colorFromHexString:@"#78A7ED"] forState:UIControlStateNormal];
        [_linkMicButton addTarget:self action:@selector(linkMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _linkMicButton;
}

- (UIButton *)authBrushButton {
    if (!_authBrushButton) {
        _authBrushButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_pen_btn_normal"];
        UIImage *selectedImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_pen_btn_selected"];
        [_authBrushButton setImage:normalImage forState:UIControlStateNormal];
        [_authBrushButton setImage:selectedImage forState:UIControlStateSelected];
        [_authBrushButton addTarget:self action:@selector(authBrushButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _authBrushButton;
}

- (UIButton *)micButton {
    if (!_micButton) {
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_mic_open_btn"];
        UIImage *selectedImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_mic_close_btn"];
        UIImage *disabledImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_mic_disabled_btn"];
        [_micButton setImage:normalImage forState:UIControlStateNormal];
        [_micButton setImage:selectedImage forState:UIControlStateSelected];
        [_micButton setImage:disabledImage forState:UIControlStateDisabled];
        [_micButton addTarget:self action:@selector(micButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _micButton;
}

- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_camera_open_btn"];
        UIImage *selectedImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_camera_close_btn"];
        UIImage *disabledImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_camera_disabled_btn"];
        [_cameraButton setImage:normalImage forState:UIControlStateNormal];
        [_cameraButton setImage:selectedImage forState:UIControlStateSelected];
        [_cameraButton setImage:disabledImage forState:UIControlStateDisabled];
        [_cameraButton addTarget:self action:@selector(cameraButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

- (UILabel *)rewardLabel {
    if (!_rewardLabel) {
        _rewardLabel = [[UILabel alloc] init];
        _rewardLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _rewardLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        _rewardLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _rewardLabel;
}

- (UIButton *)banButton {
    if (!_banButton) {
        _banButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_ban_btn_normal"];
        UIImage *selectedImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_ban_btn_selected"];
        [_banButton setImage:normalImage forState:UIControlStateNormal];
        [_banButton setImage:selectedImage forState:UIControlStateSelected];
        [_banButton addTarget:self action:@selector(banButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _banButton;
}

- (UIButton *)kickButton {
    if (!_kickButton) {
        _kickButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_kick_btn"];
        [_kickButton setImage:normalImage forState:UIControlStateNormal];
        [_kickButton addTarget:self action:@selector(kickButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _kickButton;
}

- (PLVLinkMicOnlineUserGrantCupCountChangedBlock)grantCupCountChangedBlock {
    if (!_grantCupCountChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _grantCupCountChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([weakSelf.chatUser.userId isEqualToString:onlineUser.userId]) {
                weakSelf.chatUser.cupCount = onlineUser.currentCupCount;
                weakSelf.rewardLabel.text = [NSString stringWithFormat:@"%ld", (long)onlineUser.currentCupCount];
            }
        };
    }
    return _grantCupCountChangedBlock;
}

- (PLVLinkMicOnlineUserBrushAuthChangedBlock)brushAuthChangedBlock {
    if (!_brushAuthChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _brushAuthChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([weakSelf.chatUser.userId isEqualToString:onlineUser.userId]) {
                weakSelf.authBrushButton.selected = onlineUser.currentBrushAuth;
            }
        };
    }
    return _brushAuthChangedBlock;
}

- (PLVLinkMicOnlineUserMicOpenChangedBlock)micOpenChangedBlock {
    if (!_micOpenChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([weakSelf.chatUser.userId isEqualToString:onlineUser.userId]) {
                weakSelf.micButton.selected = !onlineUser.currentMicOpen;
            }
        };
    }
    return _micOpenChangedBlock;
}

- (PLVLinkMicOnlineUserCameraShouldShowChangedBlock)cameraShouldShowChangedBlock {
    if (!_cameraShouldShowChangedBlock) {
        __weak typeof(self) weakSelf = self;
       _cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
           if ([weakSelf.chatUser.userId isEqualToString:onlineUser.userId]) {
               weakSelf.cameraButton.selected = !onlineUser.currentCameraShouldShow;
           }
       };
    }
    return _cameraShouldShowChangedBlock;
}

- (void)setLoadTimer:(NSTimer *)loadTimer {
    if (_loadTimer) {
        [_loadTimer invalidate];
        _loadTimer = nil;
    }
    if (loadTimer) {
        _loadTimer = loadTimer;
    }
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)linkMicButtonAction {
    if (self.chatUser.onlineUser) {
        __weak typeof(self) weakSelf = self;
        [PLVHCUtils showAlertWithTitle:@"学生下台" message:@"要将该学生下台吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
            [weakSelf startLinkMicLoading];
            //下台时，如果用户此时有画笔权限，需要先移除画笔权限
            if (weakSelf.authBrushButton.isSelected && weakSelf.chatUser.onlineUser.currentBrushAuth) {
                [self authBrushButtonAction];
            }
            [weakSelf notifyUserLinkMic:NO];
        }];
      } else  {
          BOOL allowLinkmic = [self.delegate allowLinkMicInCell:self];
          if (allowLinkmic) {
              [self startLinkMicLoading];
              [self notifyUserLinkMic:YES];
          } else {
              [PLVHCUtils showToastInWindowWithMessage:@"当前连麦人数已达上限"];
          }
      }
}

- (void)authBrushButtonAction {
    if (!self.chatUser.onlineUser) {
        [PLVHCUtils showToastInWindowWithMessage:@"该学生还未上台"];
        return;
    }
    
    self.authBrushButton.selected = !self.authBrushButton.isSelected;
    if (self.chatUser.onlineUser) {
        [self.chatUser.onlineUser wantAuthUserBrush:self.authBrushButton.selected];
    } else {
        NSLog(@"PLVHCOnlineMemberCell - authBrushButtonAction may be failed , onlineUser nil, userId %@",self.chatUser.userId);
    }
}

- (void)micButtonAction {
    if (!self.chatUser.onlineUser) {
        [PLVHCUtils showToastInWindowWithMessage:@"该学生还未上台"];
        return;
    }
    
    self.micButton.selected = !self.micButton.isSelected;
    if (self.chatUser.onlineUser) {
        [self.chatUser.onlineUser wantOpenUserMic:!self.micButton.selected];
    } else {
        NSLog(@"PLVHCOnlineMemberCell - micButtonAction may be failed , onlineUser nil, userId %@",self.chatUser.userId);
    }
}

- (void)cameraButtonAction {
    if (!self.chatUser.onlineUser) {
        [PLVHCUtils showToastInWindowWithMessage:@"该学生还未上台"];
        return;
    }
    
    self.cameraButton.selected = !self.cameraButton.isSelected;
    if (self.chatUser.onlineUser) {
        [self.chatUser.onlineUser wantOpenUserCamera:!self.cameraButton.selected];
    }else{
        NSLog(@"PLVHCOnlineMemberCell - cameraButtonAction may be failed, onlineUser nil, userId %@",self.chatUser.userId);
    }
}

- (void)banButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(banUserInOnlineMemberCell:bannedUser:banned:)]) {
        [self.delegate banUserInOnlineMemberCell:self bannedUser:self.chatUser banned:!self.banButton.selected];
    }
}

- (void)kickButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(kickUserInOnlineMemberCell:kickedUser:)]) {
        [self.delegate kickUserInOnlineMemberCell:self kickedUser:self.chatUser];
    }
}

#pragma mark Timer

- (void)loadTimerEvent {
    self.maxLoadDuration --;
    if (self.maxLoadDuration <= 0 ||
        self.controlStatus != PLVHCOnlineMemberCellControlStatusWait) {
        [self stopLinkMicLoading];
    }
}

@end
