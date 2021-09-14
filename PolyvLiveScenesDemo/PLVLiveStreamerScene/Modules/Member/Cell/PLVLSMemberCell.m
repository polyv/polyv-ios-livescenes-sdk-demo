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
#import <SDWebImage/UIImageView+WebCache.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <PLVFoundationSDK/PLVFdUtil.h>
#import "PLVLinkMicOnlineUser.h"
#import "PLVLinkMicWaitUser.h"

NSString *PLVLSMemberCellNotification = @"PLVLSMemberCellNotification";

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
@property (nonatomic, strong) UIView *seperatorLine;
@property (nonatomic, strong) UIView *leftDragingView;  // 触发左滑view

/// 数据
@property (nonatomic, strong) PLVChatUser *user;
@property (nonatomic, assign) BOOL leftDraging; // 是否处于左滑状态
@property (nonatomic, assign) BOOL aloneRespondLeftDraging;
@property (nonatomic, assign) CGPoint startPoint; // 开始滑动的位置
@property (nonatomic, assign) CGPoint lastPoint; // 上一次停留的位置

@property (nonatomic, strong) PLVLinkMicOnlineUserMicOpenChangedBlock micOpenChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserCameraShouldShowChangedBlock cameraShouldShowChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserCameraFrontChangedBlock cameraFrontChangedBlock;

@end

@implementation PLVLSMemberCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.gestureView];
        [self.contentView addSubview:self.editView];
        [self.contentView addSubview:self.seperatorLine];
        
        [self.gestureView addSubview:self.leftDragingView];
        [self.gestureView addSubview:self.avatarImageView];
        [self.gestureView addSubview:self.actorBgView];
        [self.gestureView addSubview:self.nickNameLabel];
        [self.gestureView addSubview:self.microPhoneButton];
        [self.gestureView addSubview:self.cameraButton];
        [self.gestureView addSubview:self.cameraSwitchButton];
        [self.gestureView addSubview:self.linkmicButton];
        
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
    
    self.linkmicButton.frame = CGRectMake(self.bounds.size.width - 36, 2, 44, 44);
    self.cameraSwitchButton.frame = CGRectMake(self.bounds.size.width - 36, 2, 44, 44);
    self.cameraButton.frame = CGRectMake(CGRectGetMinX(self.cameraSwitchButton.frame) - 44, 2, 44, 44);
    self.microPhoneButton.frame = CGRectMake(CGRectGetMinX(self.cameraButton.frame) - 44, 2, 44, 44);
    self.seperatorLine.frame = CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getter & Setter

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

- (UIView *)seperatorLine {
    if (!_seperatorLine) {
        _seperatorLine = [[UIView alloc] init];
        _seperatorLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#f0f1f5" alpha:0.1];
    }
    return _seperatorLine;
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

#pragma mark - Action

- (void)microPhoneButtonAction {
    self.microPhoneButton.selected = !self.microPhoneButton.selected;
    
    if (self.user.onlineUser) {
        [self.user.onlineUser wantOpenUserMic:!self.microPhoneButton.selected];
    }else{
        NSLog(@"PLVLSMemberCell - microPhoneButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
    }
}

- (void)cameraButtonAction {
    self.cameraButton.selected = !self.cameraButton.selected;
    self.cameraSwitchButton.enabled = !self.cameraButton.selected;
    
    if (self.user.onlineUser) {
        [self.user.onlineUser wantOpenUserCamera:!self.cameraButton.selected];
    }else{
        NSLog(@"PLVLSMemberCell - cameraButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
    }
}

- (void)cameraSwitchButtonAction {
    self.cameraSwitchButton.selected = !self.cameraSwitchButton.selected;
    
    if (self.user.onlineUser) {
        [self.user.onlineUser wantSwitchUserFrontCamera:!self.cameraSwitchButton.selected];
    }else{
        NSLog(@"PLVLSMemberCell - cameraSwitchButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(memberCell_didTapCameraSwitch)]) {
        [self.delegate memberCell_didTapCameraSwitch];
    }
}

- (void)linkMicButtonAction{
    if (self.user.waitUser) {
        [self.user.waitUser wantAllowUserJoinLinkMic];
        // 刷新按钮状态为等待连麦
        [self refreshLinkMicButtonStateWithWait];
    }else if (self.user.onlineUser){
        [self.user.onlineUser wantCloseUserLinkMic];
    }else{
        NSLog(@"PLVLSMemberCell - linkMicButtonAction may be failed , onlineUser nil, userId %@",self.user.userId);
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
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:user.avatarUrl]
                            placeholderImage:placeholder];
    
    // 配置头衔标志
    self.actorBgView.hidden = !specialType;
    self.actorLabel.hidden = !specialType;
    if (specialType) {
        self.actorLabel.text = user.actor;
    }
    
    // 配置头衔背景渐变
    if (specialType) {
        NSString *hexString = [self actorBgColorHexstringWithUserType:user.userType];
        if (hexString) {
            self.actorBgView.backgroundColor = PLV_UIColorFromRGB(hexString);
        }
    }
    
    self.nickNameLabel.text = [PLVFdUtil cutSting:user.userName WithCharacterLength:8];
    
    self.editView.banned = user.banned;
    
    __weak typeof(self) weakSelf = self;
    [self.editView setDidTapBanButton:^(BOOL banned) {
        if (weakSelf.delegate &&
            [weakSelf.delegate respondsToSelector:@selector(memberCell_didTapBan:withUer:)]) {
            [weakSelf.delegate memberCell_didTapBan:banned withUer:weakSelf.user];
        }
        [weakSelf endLeftDrag:@(YES)];
    }];
    [self.editView setDidTapKickButton:^{
        if (weakSelf.delegate &&
            [weakSelf.delegate respondsToSelector:@selector(memberCell_didTapKickWithUer:)]) {
            [weakSelf.delegate memberCell_didTapKickWithUer:weakSelf.user];
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
    };
    
    [self refreshLinkMicButtonState];
    [self refreshMediaControlButtonsState];
}

- (void)refreshLinkMicButtonState{
    BOOL isLoginUser = [self isLoginUser:self.user.userId];
    BOOL hiddenLinkMicButton = isLoginUser ? YES: ((self.user.waitUser || self.user.onlineUser) && [self canManagerLinkMic] ? NO : YES);
    BOOL hiddenLinkMicButtonSelected = self.user.onlineUser ? YES : NO;
    
    if (self.user.onlineUser.userType == PLVSocketUserTypeGuest) {
        hiddenLinkMicButton = ![PLVRoomDataManager sharedManager].roomData.channelGuestManualJoinLinkMic;
    }
    
    self.linkmicButton.hidden = hiddenLinkMicButton;
    self.linkmicButton.selected = hiddenLinkMicButtonSelected;
    // 刷新按钮状态为普通状态
    if (!hiddenLinkMicButtonSelected && !isLoginUser) {
        [self refreshLinkMicButtonStateWithNormal];
    }
}

/// 刷新按钮状态为等待连麦
- (void)refreshLinkMicButtonStateWithWait{
    [self.linkmicButton setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_linkmicing_icon_1"] forState:UIControlStateNormal];
}

/// 刷新按钮状态为普通状态
- (void)refreshLinkMicButtonStateWithNormal{
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

- (void)showLeftDragAnimation {
    self.leftDraging = YES;
    [self leftDragAnimation];
    [self performSelector:@selector(endLeftDrag:) withObject:@(YES) afterDelay:3];
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

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.leftDragingView) {
        self.aloneRespondLeftDraging = YES;
    }else{
        self.aloneRespondLeftDraging = NO;
    }
    return view;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if (touch.view == self.leftDragingView) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return !self.aloneRespondLeftDraging;
}


@end
