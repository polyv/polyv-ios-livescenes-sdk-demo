//
//  PLVLSMemberCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/29.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSMemberCell.h"
#import "PLVLSMemberCellEditView.h"
#import "PLVRoomDataManager.h"
#import "PLVChatUser.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <PLVFoundationSDK/PLVFdUtil.h>
#import "PLVLinkMicOnlineUser.h"
#import "PLVLinkMicWaitUser.h"

NSString *PLVLSMemberCellNotification = @"PLVLSMemberCellNotification";
static int kLinkMicBtnTouchInterval = 300; // 连麦按钮防止连续点击间隔:300毫秒

@interface PLVLSMemberCell ()<UIGestureRecognizerDelegate>

/// UI
@property (nonatomic, strong) PLVLSMemberCellEditView *editView;
@property (nonatomic, strong) UIView *gestureView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIImageView *actorBgView;
@property (nonatomic, strong) UILabel *actorLabel;
@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UIButton *microPhoneButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *cameraSwitchButton;
@property (nonatomic, strong) UIButton *linkmicButton;
@property (nonatomic, strong) UIButton *authSpeakerButton;
@property (nonatomic, strong) UIView *seperatorLine;
@property (nonatomic, strong) UIView *leftDragingView;  // 触发左滑view
@property (nonatomic, strong) UIImageView *handUpImageView;

/// 数据
@property (nonatomic, strong) PLVChatUser *user;
@property (nonatomic, assign) BOOL leftDraging; // 是否处于左滑状态
@property (nonatomic, assign) BOOL aloneRespondLeftDraging;
@property (nonatomic, assign) CGPoint startPoint; // 开始滑动的位置
@property (nonatomic, assign) CGPoint lastPoint; // 上一次停留的位置
@property (nonatomic, assign) BOOL isOnlyAudio; // 当前频道是否为音频模式
@property (nonatomic, assign) NSTimeInterval linkMicBtnLastTimeInterval; // 连麦按钮上一次点击的时间戳
@property (nonatomic, assign, readonly) BOOL enableLinkMic; // 是否开启连麦
@property (nonatomic, assign, readonly) BOOL startClass; // 是否开始上课
@property (nonatomic, assign, readonly) BOOL inviteAudioEnabled; // 是否开启邀请连麦开关

@property (nonatomic, strong) PLVLinkMicOnlineUserMicOpenChangedBlock micOpenChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserCameraShouldShowChangedBlock cameraShouldShowChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserCameraFrontChangedBlock cameraFrontChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock currentSpeakerAuthChangedBlock;

@end

@implementation PLVLSMemberCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.isOnlyAudio = [PLVRoomDataManager sharedManager].roomData.isOnlyAudio;
        self.linkMicBtnLastTimeInterval = 0.0;
        
        [self.contentView addSubview:self.gestureView];
        [self.contentView addSubview:self.editView];
        [self.contentView addSubview:self.seperatorLine];
        
        [self.gestureView addSubview:self.leftDragingView];
        [self.gestureView addSubview:self.avatarImageView];
        [self.gestureView addSubview:self.actorBgView];
        [self.gestureView addSubview:self.nickNameLabel];
        [self.gestureView addSubview:self.microPhoneButton];
        if (!self.isOnlyAudio) {
            [self.gestureView addSubview:self.cameraButton];
            [self.gestureView addSubview:self.cameraSwitchButton];
        }
        [self.gestureView addSubview:self.authSpeakerButton];
        [self.gestureView addSubview:self.linkmicButton];
        [self.gestureView addSubview:self.handUpImageView];

        [self.actorBgView addSubview:self.actorLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationAction:) name:PLVLSMemberCellNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.leftDraging) {
        self.gestureView.frame = CGRectMake(-208, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
    } else {
        self.gestureView.frame = self.contentView.bounds;
    }
    self.leftDragingView.frame = CGRectMake(self.bounds.size.width - 48, 0, 48, self.bounds.size.height);
    
    self.editView.frame = CGRectMake(CGRectGetMaxX(self.gestureView.frame) + 48, 0, 160, 48);
    
    self.avatarImageView.frame = CGRectMake(0, 10, 28, 28);
    
    // 配置头衔（如果有的话）位置
    CGFloat originX = CGRectGetMaxX(self.avatarImageView.frame) + 8;
    if (!self.actorBgView.hidden) {
        CGFloat actorTextWidth = [self.actorLabel.text boundingRectWithSize:CGSizeMake(100, 14)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                 attributes:@{NSFontAttributeName:self.actorLabel.font}
                                                                    context:nil].size.width;
        self.actorBgView.frame = CGRectMake(originX, (self.gestureView.bounds.size.height - 14)/2.0, actorTextWidth + 2 * 4, 14);
        self.actorLabel.frame = self.actorBgView.bounds;
        originX += self.actorBgView.frame.size.width + 4;
    }
    
    self.nickNameLabel.frame = CGRectMake(originX, 15, self.bounds.size.width - 44 * 3 + 8 - originX, 18);
    
    CGFloat rightOriginX = self.bounds.size.width - 36;
    self.linkmicButton.frame = CGRectMake(rightOriginX, 2, 44, 44);
    self.handUpImageView.frame = CGRectMake(rightOriginX - 20 - 4, 12, 20, 20);
    if (self.isOnlyAudio) {
        if (!self.authSpeakerButton.hidden) {
            self.authSpeakerButton.frame = CGRectMake(rightOriginX, 2, 44, 44);
        }
        
        self.microPhoneButton.frame = CGRectMake(rightOriginX - 44, 2, 44, 44);
    } else {
        if (!self.cameraSwitchButton.isHidden) {
            self.cameraSwitchButton.frame = CGRectMake(rightOriginX, 2, 44, 44);
            rightOriginX = CGRectGetMinX(self.cameraSwitchButton.frame) - 44;
        }
        
        if (rightOriginX == CGRectGetMinX(self.linkmicButton.frame) && !self.linkmicButton.hidden) {
            rightOriginX = CGRectGetMinX(self.linkmicButton.frame) - 44;
        }
        
        if (!self.authSpeakerButton.isHidden) {
            self.authSpeakerButton.frame = CGRectMake(rightOriginX, 2, 44, 44);
            rightOriginX = CGRectGetMinX(self.authSpeakerButton.frame) - 44;
        }
        
        if (!self.cameraButton.hidden) {
            self.cameraButton.frame = CGRectMake(rightOriginX, 2, 44, 44);
            rightOriginX = CGRectGetMinX(self.cameraButton.frame) - 44;
        }
        self.microPhoneButton.frame = CGRectMake(rightOriginX, 2, 44, 44);
    }
    self.seperatorLine.frame = CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getter & Setter

- (BOOL)enableLinkMic {
    if (self.delegate && [self.delegate respondsToSelector:@selector(enableAudioVideoLinkMicInCell:)]) {
        return [self.delegate enableAudioVideoLinkMicInCell:self];
    }
    return NO;
}

- (BOOL)startClass {
    if (self.delegate && [self.delegate respondsToSelector:@selector(startClassInCell:)]) {
        return [self.delegate startClassInCell:self];
    }
    return NO;
}

- (BOOL)inviteAudioEnabled {
    return [PLVRoomDataManager sharedManager].roomData.menuInfo.inviteAudioEnabled;
}

- (PLVLSMemberCellEditView *)editView {
    if (!_editView) {
        _editView = [[PLVLSMemberCellEditView alloc] init];
    }
    return _editView;
}

- (UIView *)gestureView {
    if (!_gestureView) {
        _gestureView = [[UIView alloc] init];
    }
    return _gestureView;
}

- (UIView *)leftDragingView{
    if (!_leftDragingView) {
        _leftDragingView = [[UIView alloc] init];
        if ([self canManagerLinkMic]) {
            _leftDragingView.userInteractionEnabled = YES;
            UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragGestureAction:)];
            gesture.delegate = self;
            [_leftDragingView addGestureRecognizer:gesture];
        }
    }
    return _leftDragingView;
}

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.cornerRadius = 14;
        _avatarImageView.layer.masksToBounds = YES;
    }
    return _avatarImageView;
}

- (UIImageView *)actorBgView {
    if (!_actorBgView) {
        _actorBgView = [[UIImageView alloc] init];
        _actorBgView.layer.cornerRadius = 4;
        _actorBgView.layer.masksToBounds = YES;
        _actorBgView.hidden = YES;
    }
    return _actorBgView;
}

- (UILabel *)actorLabel {
    if (!_actorLabel) {
        _actorLabel = [[UILabel alloc] init];
        _actorLabel.font = [UIFont systemFontOfSize:12];
        _actorLabel.textColor = PLV_UIColorFromRGB(@"#313540");
        _actorLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _actorLabel;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:12];
        _nickNameLabel.textColor = [PLVColorUtil colorFromHexString:@"#f0f1f5"];
        _nickNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _nickNameLabel;
}

- (UIButton *)microPhoneButton {
    if (!_microPhoneButton) {
        _microPhoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_microPhoneButton setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_mic_open_btn"] forState:UIControlStateNormal];
        [_microPhoneButton setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_mic_close_btn"] forState:UIControlStateSelected];
        [_microPhoneButton addTarget:self action:@selector(microPhoneButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _microPhoneButton.hidden = YES;
    }
    return _microPhoneButton;
}

- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraButton setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_camera_open_btn"] forState:UIControlStateNormal];
        [_cameraButton setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_camera_close_btn"] forState:UIControlStateSelected];
        [_cameraButton addTarget:self action:@selector(cameraButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _cameraButton.hidden = YES;
    }
    return _cameraButton;
}

- (UIButton *)cameraSwitchButton {
    if (!_cameraSwitchButton) {
        _cameraSwitchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraSwitchButton setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_camera_switch_btn"] forState:UIControlStateNormal];
        [_cameraSwitchButton addTarget:self action:@selector(cameraSwitchButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _cameraSwitchButton.hidden = YES;
    }
    return _cameraSwitchButton;
}

- (UIButton *)linkmicButton{
    if (!_linkmicButton) {
        _linkmicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_linkmicButton setImage:[PLVLSUtils imageForLinkMicResource:@"plvls_linkmic_join_request"] forState:UIControlStateNormal];
        [_linkmicButton setImage:[PLVLSUtils imageForLinkMicResource:@"plvls_linkmic_join_leave"] forState:UIControlStateSelected];
        [_linkmicButton addTarget:self action:@selector(linkMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _linkmicButton.hidden = YES;
    }
    return _linkmicButton;
}

- (UIButton *)authSpeakerButton{
    if (!_authSpeakerButton) {
        _authSpeakerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_authSpeakerButton setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_speaker_default_btn"] forState:UIControlStateNormal];
        [_authSpeakerButton setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_speaker_auth_btn"] forState:UIControlStateSelected];
        [_authSpeakerButton addTarget:self action:@selector(authSpeakerButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _authSpeakerButton.hidden = YES;
    }
    return _authSpeakerButton;
}

- (UIView *)seperatorLine {
    if (!_seperatorLine) {
        _seperatorLine = [[UIView alloc] init];
        _seperatorLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#f0f1f5" alpha:0.1];
    }
    return _seperatorLine;
}

- (UIImageView *)handUpImageView {
    if (!_handUpImageView) {
        _handUpImageView = [[UIImageView alloc] init];
        _handUpImageView.image = [PLVLSUtils imageForMemberResource:@"plvls_member_linkmic_handup_icon"];
        _handUpImageView.hidden = YES;
    }
    return _handUpImageView;
}

- (PLVLinkMicOnlineUserMicOpenChangedBlock)micOpenChangedBlock{
    if (!_micOpenChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.userId isEqualToString:weakSelf.user.userId]) {
                weakSelf.microPhoneButton.selected = !onlineUser.currentMicOpen;
            }
        };
    }
    return _micOpenChangedBlock;
}

- (PLVLinkMicOnlineUserCameraShouldShowChangedBlock)cameraShouldShowChangedBlock{
    if (!_cameraShouldShowChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.userId isEqualToString:weakSelf.user.userId]) {
                weakSelf.cameraButton.selected = !onlineUser.currentCameraShouldShow;
                weakSelf.cameraSwitchButton.enabled = !weakSelf.cameraButton.selected;
            }
        };
    }
    return _cameraShouldShowChangedBlock;
}

- (PLVLinkMicOnlineUserCameraFrontChangedBlock)cameraFrontChangedBlock{
    if (!_cameraFrontChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _cameraFrontChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.userId isEqualToString:weakSelf.user.userId]) {
                weakSelf.cameraSwitchButton.selected = !onlineUser.currentCameraFront;
            }
        };
    }
    return _cameraFrontChangedBlock;
}

- (PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock)currentSpeakerAuthChangedBlock{
    if (!_currentSpeakerAuthChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _currentSpeakerAuthChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.userId isEqualToString:weakSelf.user.userId]) {
                weakSelf.authSpeakerButton.selected = onlineUser.isRealMainSpeaker;
            }
        };
    }
    return _currentSpeakerAuthChangedBlock;
}

#pragma mark - Action

- (void)microPhoneButtonAction {
    [self checkMediaGrantedCompletion:^{
        self.microPhoneButton.selected = !self.microPhoneButton.selected;
        
        if (self.user.onlineUser) {
            [self.user.onlineUser wantOpenUserMic:!self.microPhoneButton.selected];
        }else{
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeVerbose,@"PLVLSMemberCell - microPhoneButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
        }
    }];
}

- (void)cameraButtonAction {
    [self checkMediaGrantedCompletion:^{
        self.cameraButton.selected = !self.cameraButton.selected;
        self.cameraSwitchButton.enabled = !self.cameraButton.selected;
        
        if (self.user.onlineUser) {
            [self.user.onlineUser wantOpenUserCamera:!self.cameraButton.selected];
        }else{
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeVerbose,@"PLVLSMemberCell - cameraButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
        }
    }];
}

- (void)cameraSwitchButtonAction {
    [self checkMediaGrantedCompletion:^{
        self.cameraSwitchButton.selected = !self.cameraSwitchButton.selected;
        
        if (self.user.onlineUser) {
            [self.user.onlineUser wantSwitchUserFrontCamera:!self.cameraSwitchButton.selected];
        }else{
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeVerbose,@"PLVLSMemberCell - cameraSwitchButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
        }
        
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(memberCell_didTapCameraSwitch)]) {
            [self.delegate memberCell_didTapCameraSwitch];
        }
    }];
}

- (void)linkMicButtonAction{
    // 防止短时间内重复点击，kLinkMicBtnTouchInterval间隔内的点击会直接忽略
    NSTimeInterval curTimeInterval = [PLVFdUtil curTimeInterval];
    if (curTimeInterval - self.linkMicBtnLastTimeInterval > kLinkMicBtnTouchInterval) {
        [self notifyListenerlinkMicButtonAction];
    }
    self.linkMicBtnLastTimeInterval = curTimeInterval;
}

- (void)authSpeakerButtonAction {
    self.authSpeakerButton.userInteractionEnabled = NO; // 授权按钮点击间隔，防止短时间内重复点击
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.authSpeakerButton.userInteractionEnabled = YES;
    });
    self.authSpeakerButton.selected = !self.authSpeakerButton.isSelected;
    if (self.user.onlineUser) {
        [self.user.onlineUser wantAuthUserSpeaker:self.authSpeakerButton.isSelected];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeVerbose,@"PLVLSMemberCell - authSpeakerButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
    }
}

- (void)notifyListenerlinkMicButtonAction {
    if (!self.linkmicButton.isSelected) {
        BOOL allowLinkmic = [self.delegate allowLinkMicInCell:self];
        if (allowLinkmic) {
            if (self.user.waitUser ||
                (self.user.userType == PLVRoomUserTypeGuest ||
                 self.user.userType == PLVRoomUserTypeSlice ||
                 self.user.userType == PLVRoomUserTypeStudent)) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(memberCell_inviteUserJoinLinkMic:)]) {
                    [self.delegate memberCell_inviteUserJoinLinkMic:self.user];
                }
            }
            
            // 刷新按钮状态为等待连麦
            [self refreshLinkMicButtonStateWithWait];
        } else {
            [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"当前连麦人数已达上限")];
        }
    }else {
        if (self.user.onlineUser) {
            [self.user.onlineUser wantCloseUserLinkMic];
        } else {
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeVerbose,@"PLVLSMemberCell - linkMicButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
        }
    }
}

#pragma mark - Public

- (void)updateUser:(PLVChatUser *)user {
    if (!user || ![user isKindOfClass:[PLVChatUser class]]) {
        return;
    }
    
    self.user = user;
    BOOL specialType = [PLVRoomUser isSpecialIdentityWithUserType:user.userType];
    NSString *imageName = specialType ? @"plvls_member_teacher_avatar" : @"plvls_member_student_avatar";
    UIImage *placeholder = [PLVLSUtils imageForMemberResource:imageName];
    [PLVLSUtils setImageView:self.avatarImageView url:[NSURL URLWithString:user.avatarUrl] placeholderImage:placeholder];
    
    // 配置头衔标志
    self.actorBgView.hidden = !specialType;
    self.actorLabel.hidden = !specialType;
    if (specialType) {
        CGFloat actorTextWidth = [user.actor boundingRectWithSize:CGSizeMake(100, 14)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                 attributes:@{NSFontAttributeName:self.actorLabel.font}
                                                                    context:nil].size.width;
        CGFloat nickNameTextWidth = [user.userName boundingRectWithSize:CGSizeMake(200, 18)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                 attributes:@{NSFontAttributeName:self.nickNameLabel.font}
                                                                    context:nil].size.width;
        // 优先显示昵称完整，当宽度不能完全展示头衔+昵称，头衔最多展示4个文字
        if ((nickNameTextWidth + actorTextWidth) > (self.bounds.size.width - 40 - 44 * 3) && [PLVFdUtil checkStringUseable:user.actor]) {
            self.actorLabel.text = [PLVFdUtil cutSting:user.actor WithCharacterLength:3];
        } else {
            self.actorLabel.text = user.actor;
        }
    }
    
    // 配置头衔背景渐变
    if (specialType) {
        NSString *hexString = [self actorBgColorHexstringWithUserType:user.userType];
        if (hexString) {
            self.actorBgView.backgroundColor = PLV_UIColorFromRGB(hexString);
        }
    }
    
    self.nickNameLabel.text = user.userName;
    
    self.editView.banned = user.banned;
    
    __weak typeof(self) weakSelf = self;
    [self.editView setDidTapBanButton:^(BOOL banned) {
        if (weakSelf.delegate &&
            [weakSelf.delegate respondsToSelector:@selector(memberCell_didTapBan:withUser:)]) {
            [weakSelf.delegate memberCell_didTapBan:banned withUser:weakSelf.user];
        }
        [weakSelf endLeftDrag:@(YES)];
    }];
    [self.editView setDidTapKickButton:^{
        if (weakSelf.delegate &&
            [weakSelf.delegate respondsToSelector:@selector(memberCell_didTapKickWithUser:)]) {
            [weakSelf.delegate memberCell_didTapKickWithUser:weakSelf.user];
        }
        [weakSelf endLeftDrag:@(YES)];
    }];
    
    /// 连麦相关业务
    user.waitUserChangedBlock = ^(PLVLinkMicWaitUser * _Nonnull currentWaitUser) {
        [weakSelf refreshLinkMicButtonState];
    };
    
    user.onlineUserChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull currentOnlineUser) {
        [weakSelf refreshLinkMicButtonState];
        [weakSelf refreshMediaControlButtonsState];
        [weakSelf refreshAuthControlButtonsState];
    };
    
    if(self.user.waitUser) {
        user.waitUser.linkMicStatusBlock = ^(PLVLinkMicWaitUser * _Nonnull waitUser) {
            [weakSelf refreshLinkMicButtonState];
        };
    }
    
    [self refreshLinkMicButtonState];
    [self refreshMediaControlButtonsState];
    [self refreshAuthControlButtonsState];
}

- (void)refreshLinkMicButtonState{
    BOOL isCanLinkMicGuest = (self.user.userType == PLVRoomUserTypeGuest); // 可以邀请连麦的嘉宾
    BOOL isCanLinkMicWatchUser = ((self.user.userType == PLVRoomUserTypeSlice || self.user.userType == PLVRoomUserTypeStudent) && self.enableLinkMic && self.inviteAudioEnabled); // 可以邀请连麦的观众
    BOOL isManagerLinkMicUser = [self canManagerLinkMic]; // 讲师等角色可以操作邀请嘉宾、观众用户连麦
    BOOL hiddenLinkMicButton = self.startClass ? ((isManagerLinkMicUser && (isCanLinkMicGuest || isCanLinkMicWatchUser)) ? NO : YES) : YES;
 
    BOOL linkMicButtonSelected = (self.user.onlineUser) ? YES : NO;
    self.linkmicButton.selected = linkMicButtonSelected;
    
    BOOL canShowHandUpUser = (self.user.waitUser && self.user.waitUser.linkMicStatus == PLVLinkMicUserLinkMicStatus_HandUp && isManagerLinkMicUser); // 举手用户
    BOOL hiddenHandUpImageView = canShowHandUpUser ? NO : YES;
    self.handUpImageView.hidden = hiddenHandUpImageView;
    self.linkmicButton.hidden = hiddenLinkMicButton;
    self.linkmicButton.selected = linkMicButtonSelected;
    if (linkMicButtonSelected && isManagerLinkMicUser && !self.user.onlineUser.localUser) {
        self.linkmicButton.hidden = NO;
    }
    if (canShowHandUpUser) {
        self.linkmicButton.hidden = NO;
    }
    
    [self refreshLinkMicButtonStateWithNormal];
    BOOL isInvitedUser = (!linkMicButtonSelected && self.user.waitUser && self.user.waitUser.linkMicStatus == PLVLinkMicUserLinkMicStatus_Inviting);
    if (isInvitedUser) {
        [self refreshLinkMicButtonStateWithWait];
    }
}

/// 刷新按钮状态为等待连麦
- (void)refreshLinkMicButtonStateWithWait{
    self.linkmicButton.userInteractionEnabled = NO;
    UIImageView *buttonImageView = self.linkmicButton.imageView;
    NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:3];
    for (NSInteger i = 0; i < 3; i ++) {
        [imageArray addObject:[PLVLSUtils imageForMemberResource:[NSString stringWithFormat:@"plvls_member_linkmic_wait_icon_0%ld.png", i]]];
    }
    [buttonImageView setAnimationImages:[imageArray copy]];
    [buttonImageView setAnimationDuration:1];
    [buttonImageView startAnimating];
}

/// 刷新按钮状态为普通状态
- (void)refreshLinkMicButtonStateWithNormal{
    self.linkmicButton.userInteractionEnabled = YES;
    UIImageView *buttonImageView = self.linkmicButton.imageView;
    if (buttonImageView.isAnimating) {
        [buttonImageView stopAnimating];
    }
    buttonImageView.animationImages = nil;
    [self.linkmicButton setImage:[PLVLSUtils imageForLinkMicResource:@"plvls_linkmic_join_request"] forState:UIControlStateNormal];
}

- (void)refreshMediaControlButtonsState{
    BOOL isLoginUser = [self isLoginUser:self.user.userId];
    self.microPhoneButton.hidden = !isLoginUser;
    self.cameraButton.hidden = !isLoginUser;
    self.cameraSwitchButton.hidden = !isLoginUser;
    
    if (self.user.onlineUser) {
        self.microPhoneButton.hidden = !([self canManagerLinkMic] || isLoginUser);
        self.microPhoneButton.selected = !self.user.onlineUser.currentMicOpen;
        [self.user.onlineUser addMicOpenChangedBlock:self.micOpenChangedBlock blockKey:self];
         
        BOOL cameraButtonShow = ([PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType == PLVChannelLinkMicMediaType_Video) && [self canManagerLinkMic];
        if (isLoginUser ||
            (self.user.onlineUser.userType == PLVSocketUserTypeGuest && [self canManagerLinkMic])) {
            cameraButtonShow = YES;
        }
        self.cameraButton.hidden = !cameraButtonShow;
        self.cameraButton.selected = !self.user.onlineUser.currentCameraShouldShow;
        self.cameraSwitchButton.enabled = !self.cameraButton.selected;
        [self.user.onlineUser addCameraShouldShowChangedBlock:self.cameraShouldShowChangedBlock blockKey:self];
        
        self.cameraSwitchButton.selected = !self.user.onlineUser.currentCameraFront;
        [self.user.onlineUser addCameraFrontChangedBlock:self.cameraFrontChangedBlock blockKey:self];
    }
}

- (void)refreshAuthControlButtonsState {
    self.authSpeakerButton.hidden = YES;
    if (self.user.onlineUser) {
        BOOL showSpeakerAuthButton = [self hasManageSpeakerAuth] && self.user.onlineUser.userType == PLVRoomUserTypeGuest;
        self.authSpeakerButton.hidden = !showSpeakerAuthButton;
        self.authSpeakerButton.selected = self.user.onlineUser.isRealMainSpeaker;
        [self.user.onlineUser addCurrentSpeakerAuthChangedBlock:self.currentSpeakerAuthChangedBlock blockKey:self];
    }
}

- (void)showLeftDragAnimation {
    self.leftDraging = YES;
    [self leftDragAnimation];
    [self performSelector:@selector(endLeftDrag:) withObject:@(YES) afterDelay:3];
}

- (void)closeLinkmicAndCamera {
    self.microPhoneButton.selected = self.cameraButton.selected = YES;
}

+ (CGFloat)cellHeight {
    return 48.0;
}

#pragma mark - Left Drage Related

- (void)dragGestureAction:(id)sender {
    BOOL isLoginUser = [self isLoginUser:self.user.userId];
    BOOL specialType = [PLVRoomUser isSpecialIdentityWithUserType:self.user.userType];
    if (self.leftDraging || isLoginUser || specialType) {
        return;
    }
    
    UIPanGestureRecognizer *gesture = (UIPanGestureRecognizer *)sender;
    CGPoint point = [gesture locationInView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (point.x < self.gestureView.bounds.size.width - 88) {
            gesture.state = UIGestureRecognizerStateCancelled;
            return;
        }
        self.startPoint = point;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if (point.x > self.lastPoint.x) {
            gesture.state = UIGestureRecognizerStateCancelled;
            return;
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        if (point.x > self.lastPoint.x) {
            return;
        }
        if (self.startPoint.x - point.x < 48 ||
            fabs(self.startPoint.y - point.y) > 48) {
            return;
        }
        self.leftDraging = YES;
        [self leftDragAnimation];
    }
    
    self.lastPoint = point;
}

- (void)leftDragAnimation {
    [UIView animateWithDuration:0.3 animations:^{
        self.gestureView.frame = CGRectMake(-208, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        self.editView.frame = CGRectMake(CGRectGetMaxX(self.gestureView.frame) + 48, 0, 160, 48);
    }];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(memberCell_didEditing:)]) {
        [self.delegate memberCell_didEditing:YES];
    }
}

- (void)endLeftDrag:(NSNumber *)animation {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(endLeftDrag:) object:@(YES)];
    
    if (!self.leftDraging) {
        return;
    }
    
    if (animation.boolValue) {
        [UIView animateWithDuration:0.3 animations:^{
            self.gestureView.frame = self.contentView.bounds;
            self.editView.frame = CGRectMake(CGRectGetMaxX(self.gestureView.frame) + 48, 0, 160, 48);
        }];
    } else {
        self.gestureView.frame = self.contentView.bounds;
        self.editView.frame = CGRectMake(CGRectGetMaxX(self.gestureView.frame) + 48, 0, 160, 48);
    }
    
    self.leftDraging = NO;
    [self.editView reset];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(memberCell_didEditing:)]) {
        [self.delegate memberCell_didEditing:NO];
    }
}

- (void)notificationAction:(id)sender {
    [self endLeftDrag:@(NO)];
}

#pragma mark - Private

- (NSString *)actorBgColorHexstringWithUserType:(PLVRoomUserType)userType {
    NSString *hexString = nil;
    switch (userType) {
        case PLVRoomUserTypeGuest:
            hexString = @"#4399FF";
            break;
        case PLVRoomUserTypeTeacher:
            hexString = @"#FFC161";
            break;
        case PLVRoomUserTypeAssistant:
            hexString = @"#33BBC5";
            break;
        case PLVRoomUserTypeManager:
            hexString = @"#EB6165";
            break;
        default:
            break;
    }
    return hexString;
}

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

/// 讲师、助教、管理员可以管理连麦操作
- (BOOL)canManagerLinkMic {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (userType == PLVRoomUserTypeTeacher ||
        userType == PLVRoomUserTypeAssistant ||
        userType == PLVRoomUserTypeManager) {
        return YES;
    } else {
        return NO;
    }
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
    BOOL isRealMainSpeaker = [self.delegate localUserIsRealMainSpeakerInCell:self];
    if (guestTranAuthEnabled && userType == PLVRoomUserTypeGuest && isRealMainSpeaker) {
        return YES;
    }
    
    return NO;
}

- (void)checkMediaGrantedCompletion:(void (^)(void))completion  {
    BOOL isLoginUser = [self isLoginUser:self.user.userId];
    if (!isLoginUser) {
        completion();
        return;
    }
    PLVAuthorizationType type = self.isOnlyAudio ? PLVAuthorizationTypeMediaAudio : PLVAuthorizationTypeMediaAudioAndVideo;
    [PLVAuthorizationManager requestAuthorizationWithType:type completion:^(BOOL granted) {
        if (granted) {
            completion();
        } else {
            [PLVLSUtils showAlertWithTitle:PLVLocalizedString(@"音视频权限申请")
                                   message:PLVLocalizedString(@"请前往“设置-隐私”开启权限")
                         cancelActionTitle:PLVLocalizedString(@"取消")
                         cancelActionBlock:nil
                        confirmActionTitle:PLVLocalizedString(@"前往设置") confirmActionBlock:^{
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url];
                    }
            }];
        }
    }];
}

#pragma mark - [ Delegate ]

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if (touch.view == self.leftDragingView) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return !self.aloneRespondLeftDraging;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.leftDragingView) {
        self.aloneRespondLeftDraging = YES;
    }else{
        self.aloneRespondLeftDraging = NO;
    }
    return view;
}

@end
