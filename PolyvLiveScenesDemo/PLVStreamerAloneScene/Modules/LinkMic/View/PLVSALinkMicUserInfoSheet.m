//
//  PLVSALinkMicUserInfoSheet.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicUserInfoSheet.h"

// utils
#import "PLVSAUtils.h"

// UI
#import "PLVSAStreamAlertController.h"

// 模型
#import "PLVLinkMicOnlineUser.h"
#import "PLVChatUser.h"

// 模块
#import "PLVRoomDataManager.h"

// 框架
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSALinkMicUserInfoSheet()

// UI
@property (nonatomic, strong) UIImageView *headerImageView; // 头像
@property (nonatomic, strong) UILabel *actorLabel; // 头衔
@property (nonatomic, strong) UILabel *nicknameLabel; // 昵称
@property (nonatomic, strong) UIView *lineView; // 分割线
@property (nonatomic, strong) UIButton *cameraButton; // 摄像头按钮
@property (nonatomic, strong) UIButton *micphoneButton; // 麦克风按钮
@property (nonatomic, strong) UIButton *authSpeakerButton; // 授权主讲按钮
@property (nonatomic, strong) UIButton *fullScreenButton; // 全屏按钮
@property (nonatomic, strong) UIButton *stopLinkMicButton; // 下麦按钮

// Data
@property (nonatomic, weak) PLVLinkMicOnlineUser *user;
@property (nonatomic, weak) PLVLinkMicOnlineUser *localUser;
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType; // 本地用户类型

@end

@implementation PLVSALinkMicUserInfoSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self.contentView addSubview:self.headerImageView];
        [self.contentView addSubview:self.actorLabel];
        [self.contentView addSubview:self.nicknameLabel];
        [self.contentView addSubview:self.lineView];
        [self.contentView addSubview:self.cameraButton];
        [self.contentView addSubview:self.micphoneButton];
        [self.contentView addSubview:self.authSpeakerButton];
        [self.contentView addSubview:self.fullScreenButton];
        [self.contentView addSubview:self.stopLinkMicButton];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL specialType = [self isSpecialIdentityWithUserType:self.user.userType];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat width = self.contentView.frame.size.width;
    CGFloat lineViewTop = isPad ? 24 : 12;
    CGFloat lineViewMargin = isPad ? 56 : 23.5;
   
    self.headerImageView.frame = CGRectMake((width - 66) / 2, isLandscape ? 32 :  17, 66, 66);
    
    CGFloat actorLabelWidth = [self.actorLabel sizeThatFits:CGSizeMake(width, 18)].width + 10;
    self.actorLabel.frame = CGRectMake((width - actorLabelWidth) / 2, CGRectGetMaxY(self.headerImageView.frame) - 18, actorLabelWidth, 18);
    
    self.nicknameLabel.frame = CGRectMake(lineViewMargin, CGRectGetMaxY(self.actorLabel.frame) + 9, width - lineViewMargin *2, 20);
    
    self.lineView.frame = CGRectMake(lineViewMargin, CGRectGetMaxY(self.nicknameLabel.frame) + lineViewTop, width - lineViewMargin *2, 1);
        
    NSMutableArray *buttonArray = [NSMutableArray arrayWithCapacity:6];
    if (self.viewerType == PLVRoomUserTypeGuest) {
        if (!self.authSpeakerButton.isHidden) {
            [buttonArray addObject:self.authSpeakerButton];
        }
        [buttonArray addObject:self.fullScreenButton];
    } else if(self.viewerType == PLVRoomUserTypeTeacher) {
        [buttonArray addObjectsFromArray:@[self.cameraButton,
                                           self.micphoneButton]];
        if (!self.authSpeakerButton.isHidden) {
            [buttonArray addObject:self.authSpeakerButton];
        }
        
        [buttonArray addObject:self.fullScreenButton];

        if (!specialType) {
            [buttonArray addObject:self.stopLinkMicButton];
        }
    }
    
    [self setButtonFrameWithArray:buttonArray];
    [self setButtonInsetsWithArray:buttonArray];
}

#pragma mark - [ Public Method ]

- (void)updateLinkMicUserInfoWithUser:(PLVLinkMicOnlineUser *)user localUser:(PLVLinkMicOnlineUser *)localUser {
    if (!user || ![user isKindOfClass:[PLVLinkMicOnlineUser class]] ||
        !localUser || ![localUser isKindOfClass:[PLVLinkMicOnlineUser class]] ) {
        return;
    }
    
    self.user = user;
    self.localUser = localUser;
    BOOL specialType = [self isSpecialIdentityWithUserType:user.userType];
    BOOL isTeacher = self.viewerType == PLVRoomUserTypeTeacher;
    NSString *imageName = specialType ? @"plvsa_member_teacher_avatar" : @"plvsa_member_student_avatar";
    UIImage *placeholder = [PLVSAUtils imageForMemberResource:imageName];
    [PLVSAUtils setImageView:self.headerImageView url:[NSURL URLWithString:user.avatarPic] placeholderImage:placeholder];
    if (specialType) {
        self.actorLabel.text = user.actor;
    }
    
    self.actorLabel.hidden = !specialType && user.actor;
    self.cameraButton.hidden = !isTeacher;
    self.micphoneButton.hidden = !isTeacher;
    self.authSpeakerButton.hidden = !(self.hasManageSpeakerAuth && user.userType == PLVRoomUserTypeGuest);
    self.stopLinkMicButton.hidden = specialType || !isTeacher;
    
    NSString *colorHexString = [self actorBgColorHexStringWithUserType:user.userType];
    if (colorHexString && !self.actorLabel.hidden) {
        self.actorLabel.backgroundColor = [PLVColorUtil colorFromHexString:colorHexString];
    }
    
    self.nicknameLabel.text = user.nickname;

    // 设置按钮状态
    [self refreshButtonState];
    // 添加信息变动回调监听
    [self addUserInfoChangedBlock:user];
    if (self.viewerType == PLVRoomUserTypeGuest) {
        [self addLocalUserInfoChangedBlock:localUser];
    }

    // 刷新UI
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)showInView:(UIView *)parentView {
    if (self.superview) {
        [self dismiss];
    } else {
        [super showInView:parentView];
    }
    
}
#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc] init];
        _headerImageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _headerImageView.layer.cornerRadius = 33;
        _headerImageView.layer.masksToBounds = YES;
        _headerImageView.layer.borderWidth = 2;
        _headerImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    return _headerImageView;
}

- (UILabel *)actorLabel {
    if (!_actorLabel) {
        _actorLabel = [[UILabel alloc] init];
        _actorLabel.font = [UIFont systemFontOfSize:12];
        _actorLabel.textColor = [UIColor whiteColor];
        _actorLabel.textAlignment = NSTextAlignmentCenter;
        _actorLabel.layer.cornerRadius = 9;
        _actorLabel.layer.masksToBounds = YES;
    }
    return _actorLabel;
}

- (UILabel *)nicknameLabel {
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc] init];
        _nicknameLabel.font = [UIFont systemFontOfSize:14];
        _nicknameLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _nicknameLabel.textAlignment = NSTextAlignmentCenter;
        _nicknameLabel.text = @"";
    }
    return _nicknameLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    }
    return _lineView;
}

- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _cameraButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_cameraButton setTitle:@"摄像头" forState:UIControlStateNormal];
        [_cameraButton setTitle:@"摄像头" forState:UIControlStateSelected];
        [_cameraButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_camera_close"] forState:UIControlStateNormal];
        [_cameraButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_camera_open"] forState:UIControlStateSelected];
        [_cameraButton addTarget:self action:@selector(cameraButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

- (UIButton *)micphoneButton {
    if (!_micphoneButton) {
        _micphoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _micphoneButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _micphoneButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_micphoneButton setTitle:@"麦克风" forState:UIControlStateNormal];
        [_micphoneButton setTitle:@"麦克风" forState:UIControlStateSelected];
        [_micphoneButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_micphone_close"] forState:UIControlStateNormal];
        [_micphoneButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_micphone_open"] forState:UIControlStateSelected];
        [_micphoneButton addTarget:self action:@selector(micphoneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _micphoneButton;
}

- (UIButton *)authSpeakerButton {
    if (!_authSpeakerButton) {
        _authSpeakerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _authSpeakerButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _authSpeakerButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _authSpeakerButton.titleLabel.numberOfLines = 0;
        _authSpeakerButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        NSString *buttonTitle = self.viewerType == PLVRoomUserTypeTeacher ? @"授予主讲权限" : @"移交主讲权限";
        [_authSpeakerButton setTitle:buttonTitle forState:UIControlStateNormal];
        [_authSpeakerButton setTitle:@"移除主讲权限" forState:UIControlStateSelected];
        [_authSpeakerButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_authspeaker"] forState:UIControlStateNormal];
        [_authSpeakerButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_authspeaker"] forState:UIControlStateSelected];
        [_authSpeakerButton addTarget:self action:@selector(authSpeakerButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _authSpeakerButton;
}

- (UIButton *)fullScreenButton {
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _fullScreenButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _fullScreenButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_fullScreenButton setTitle:@"全屏" forState:UIControlStateNormal];
        [_fullScreenButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_fullscreen_open"] forState:UIControlStateNormal];
        [_fullScreenButton addTarget:self action:@selector(fullScreenButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenButton;
}

- (UIButton *)stopLinkMicButton {
    if (!_stopLinkMicButton) {
        _stopLinkMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _stopLinkMicButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _stopLinkMicButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_stopLinkMicButton setTitle:@"下麦" forState:UIControlStateNormal];
        [_stopLinkMicButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_linkmic_close"] forState:UIControlStateNormal];
        [_stopLinkMicButton addTarget:self action:@selector(stopLinkMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopLinkMicButton;
}

- (PLVRoomUserType)viewerType{
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
}

#pragma mark UI

- (void)setButtonInsetsWithArray:(NSArray *)buttonArray {
    for (int i = 0; i < buttonArray.count ; i++) {
        UIButton *but = buttonArray[i];
        CGFloat padding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 8 : 5;
        CGFloat imageSizeHeight = 30;
        CGFloat imageInsetsTop = but.frame.size.height - but.titleLabel.intrinsicContentSize.height - imageSizeHeight - padding * 2;
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:but.titleLabel.text attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}];
        CGSize titleSize = [attr boundingRectWithSize:CGSizeMake(but.frame.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        
        [but setImageEdgeInsets:
         UIEdgeInsetsMake(
                          - imageInsetsTop,
                          (but.frame.size.width-but.imageView.frame.size.width)/2,
                          but.titleLabel.intrinsicContentSize.height,
                          (but.frame.size.width-but.imageView.frame.size.width)/2)];
        
        [but setTitleEdgeInsets:
               UIEdgeInsetsMake(imageSizeHeight + padding * 2,
                                -but.imageView.frame.size.width,
                                but.titleLabel.intrinsicContentSize.height * 2 - titleSize.height,
                                0)];
    }
}

- (void)setButtonFrameWithArray:(NSArray *)buttonArray {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;

    CGFloat lineButtonCount = isLandscape ? 3 : (buttonArray.count == 1 ? (isPad ? 6 : 4) : MIN(buttonArray.count, (isPad ? 6 : 4)));
    CGFloat width = self.contentView.frame.size.width;
    CGFloat buttonWidth = 60;
    CGFloat buttonHeight = 75;
    CGFloat buttonPadding = (width - buttonWidth * lineButtonCount) / (lineButtonCount + 1);
    CGFloat buttonTop = self.bounds.size.height > 667 ? 32 : 18;
    if (isPad) {
        buttonPadding = 0.28 * (width - buttonWidth * lineButtonCount) / (lineButtonCount - 1);
    }
    
    CGFloat cameraButtonLeft = isPad ? (width - buttonPadding * (lineButtonCount - 1) - buttonWidth * lineButtonCount)/2 : buttonPadding;
    CGFloat buttonOriginX = cameraButtonLeft;
    CGFloat buttonOriginY = CGRectGetMaxY(self.lineView.frame) + buttonTop;
    for (int i = 0; i < buttonArray.count ; i++) {
        UIButton *button = buttonArray[i];
        if (i != 0) {
            if (isLandscape) {
                if (i%3 == 0) {
                    buttonOriginX = cameraButtonLeft;
                    buttonOriginY += (buttonHeight + buttonTop);
                } else {
                    buttonOriginX +=(buttonWidth + buttonPadding);
                }
            } else {
                if (!isPad && i%4 == 0) {
                    buttonOriginX = cameraButtonLeft;
                    buttonOriginY += (buttonHeight + buttonTop);
                } else {
                    buttonOriginX +=(buttonWidth + buttonPadding);
                }
            }
        }
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
    }
}

#pragma mark Utils
- (BOOL)isSpecialIdentityWithUserType:(PLVSocketUserType)userType {
    if (userType == PLVSocketUserTypeGuest ||
        userType == PLVSocketUserTypeTeacher ||
        userType == PLVSocketUserTypeAssistant ||
        userType == PLVSocketUserTypeManager) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)actorBgColorHexStringWithUserType:(PLVSocketUserType)userType {
    NSString *colorHexString = nil;
    switch (userType) {
        case PLVSocketUserTypeGuest:
            colorHexString = @"#EB6165";
            break;
        case PLVSocketUserTypeTeacher:
            colorHexString = @"#F09343";
            break;
        case PLVSocketUserTypeAssistant:
            colorHexString = @"#598FE5";
            break;
        case PLVSocketUserTypeManager:
            colorHexString = @"#33BBC5";
            break;
        default:
            break;
    }
    return colorHexString;
}

// 是否有管理主讲的权限
- (BOOL)hasManageSpeakerAuth {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (userType == PLVRoomUserTypeTeacher ||
        userType == PLVRoomUserTypeAssistant ||
        userType == PLVRoomUserTypeManager) {
        return YES;
    }
    
    // 当开启了嘉宾移交权限功能，嘉宾用户拥有主讲权限时可以进行授权操作
    PLVRoomUserType guestTranAuthEnabled = [PLVRoomDataManager sharedManager].roomData.guestTranAuthEnabled;
    if (guestTranAuthEnabled && userType == PLVRoomUserTypeGuest && self.localUser.isRealMainSpeaker) {
        return YES;
    }
    
    return NO;
}

#pragma mark Data

- (void)refreshButtonState {
    self.cameraButton.selected = self.user.currentCameraOpen;
    self.micphoneButton.selected = self.user.currentMicOpen;
    self.authSpeakerButton.selected = self.user.isRealMainSpeaker;
}

- (void)addUserInfoChangedBlock:(PLVLinkMicOnlineUser *)user{
    __weak typeof(self) weakSelf = self;
    [user addCameraShouldShowChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        plv_dispatch_main_async_safe(^{
            weakSelf.cameraButton.selected = onlineUser.currentCameraShouldShow;
            weakSelf.cameraButton.enabled = YES;
        })
    } blockKey:self];
    
    [user addMicOpenChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        plv_dispatch_main_async_safe(^{
            weakSelf.micphoneButton.selected = onlineUser.currentMicOpen;
            weakSelf.micphoneButton.enabled = YES;
        })
    } blockKey:self];
    
    [user addCurrentSpeakerAuthChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        plv_dispatch_main_async_safe(^{
            weakSelf.authSpeakerButton.selected = onlineUser.isRealMainSpeaker;
        })
    } blockKey:self];
    
    [user addWillDeallocBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        plv_dispatch_main_async_safe(^{
            [weakSelf dismiss];
        })
    } blockKey:self];
}

- (void)addLocalUserInfoChangedBlock:(PLVLinkMicOnlineUser *)user {
    __weak typeof(self) weakSelf = self;
    [user addCurrentSpeakerAuthChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        plv_dispatch_main_async_safe(^{
            weakSelf.authSpeakerButton.hidden = !(weakSelf.hasManageSpeakerAuth && weakSelf.user.userType == PLVRoomUserTypeGuest);
            weakSelf.authSpeakerButton.selected = onlineUser.isRealMainSpeaker;
            [weakSelf layoutSubviews];
        })
    } blockKey:self];
}

#pragma mark - Event

#pragma mark Action

- (void)cameraButtonAction {
    self.cameraButton.selected = !self.cameraButton.selected;
    [self.user wantOpenUserCamera:self.cameraButton.selected];
    self.cameraButton.enabled = NO;
}

- (void)micphoneButtonAction {
    self.micphoneButton.selected = !self.micphoneButton.selected;
    [self.user wantOpenUserMic:self.micphoneButton.selected];
    self.micphoneButton.enabled = NO;
}

- (void)authSpeakerButtonAction {
    if (self.user.userType != PLVSocketUserTypeGuest) {
        return;
    }
    
    self.authSpeakerButtonClickBlock ? self.authSpeakerButtonClickBlock(self.user, !self.authSpeakerButton.selected) : nil;    
}

- (void)fullScreenButtonAction {
    [self dismiss];
    self.fullScreenButtonClickBlock ? self.fullScreenButtonClickBlock(self.user) : nil;
}

- (void)stopLinkMicButtonAction {
    __weak typeof(self) weakSelf = self;
    [PLVSAUtils showAlertWithMessage:@"确定下麦吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
        [weakSelf.user wantCloseUserLinkMic];
        [weakSelf dismiss];
    }];
}

@end
