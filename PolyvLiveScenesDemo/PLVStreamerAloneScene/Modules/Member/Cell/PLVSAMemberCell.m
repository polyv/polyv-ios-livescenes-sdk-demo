//
//  PLVSAMemberCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAMemberCell.h"
#import "PLVChatUser.h"
#import "PLVRoomDataManager.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSAMemberCell ()

/// UI
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIImageView *bannedImageView;
@property (nonatomic, strong) UIImageView *actorBgView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UILabel *actorLabel;
@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UIButton *linkmicButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIImageView *handUpImageView;

/// 数据
@property (nonatomic, strong) PLVChatUser *user;
@property (nonatomic, assign, readonly) BOOL startClass; // 是否开始上课
@property (nonatomic, assign, readonly) BOOL enableLinkMic; // 是否开启连麦
@property (nonatomic, assign, readonly) BOOL inviteAudioEnabled; // 是否开启邀请连麦开关

@end

@implementation PLVSAMemberCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.avatarImageView];
        [self.contentView addSubview:self.bannedImageView];
        [self.contentView addSubview:self.actorBgView];
        [self.contentView addSubview:self.nickNameLabel];
        [self.contentView addSubview:self.linkmicButton];
        [self.contentView addSubview:self.moreButton];
        [self.contentView addSubview:self.handUpImageView];
        
        [self.actorBgView.layer addSublayer:self.gradientLayer];
        [self.actorBgView addSubview:self.actorLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cellHeight = self.bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat right = [PLVSAUtils sharedUtils].areaInsets.right;
    CGFloat margin = isPad ? 56 : MAX(right, 32);

    // 配置头像、禁言标志位置
    self.avatarImageView.frame = CGRectMake(margin, (cellHeight - 44)/2.0, 44, 44);
    self.bannedImageView.frame = CGRectMake(CGRectGetMaxX(self.avatarImageView.frame) + 4 - 20, CGRectGetMaxY(self.avatarImageView.frame) - 20, 20, 20);
    
    // 配置头衔（如果有的话）位置
    CGFloat originX = CGRectGetMaxX(self.avatarImageView.frame) + 12;
    if (!self.actorBgView.hidden) {
        CGFloat actorTextWidth = [self.actorLabel.text boundingRectWithSize:CGSizeMake(100, 18)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                 attributes:@{NSFontAttributeName:self.actorLabel.font}
                                                                    context:nil].size.width;
        self.actorBgView.frame = CGRectMake(originX, (cellHeight - 18)/2.0, actorTextWidth + 2 * 8, 18);
        self.gradientLayer.frame = self.actorBgView.bounds;
        self.actorLabel.frame = self.actorBgView.bounds;
        originX += self.actorBgView.frame.size.width + 8;
    }
    
    // 配置更多按钮、连麦按钮位置
    CGFloat buttonOriginX = self.bounds.size.width - margin - 32;
    self.moreButton.frame = CGRectMake(buttonOriginX, (cellHeight - 32)/2.0, 32, 32);
    if (!self.moreButton.hidden) {
        buttonOriginX -= (32 + 20);
    }
    self.linkmicButton.frame = CGRectMake(buttonOriginX, (cellHeight - 32)/2.0, 32, 32);
    self.handUpImageView.frame = CGRectMake(CGRectGetMinX(self.linkmicButton.frame) - 20 - 4, CGRectGetMidY(self.linkmicButton.frame) - 10, 20, 20);
    if (!self.linkmicButton.hidden) {
        buttonOriginX -= 32;
    }
    
    // 配置昵称文本位置
    self.nickNameLabel.frame = CGRectMake(originX, (cellHeight - 20)/2.0, buttonOriginX - originX, 20);
}

#pragma mark - [ Public Method ]

- (void)updateUser:(PLVChatUser *)user {
    if (!user || ![user isKindOfClass:[PLVChatUser class]]) {
        return;
    }
    
    self.user = user;
    BOOL specialType = [PLVRoomUser isSpecialIdentityWithUserType:user.userType];
    
    // 配置头像
    NSString *imageName = [self imageNameWithUserType:user.userType];
    UIImage *placeholder = [PLVSAUtils imageForMemberResource:imageName];
    [PLVSAUtils setImageView:self.avatarImageView url:[NSURL URLWithString:user.avatarUrl] placeholderImage:placeholder];
    
    // 配置禁言标志
    self.bannedImageView.hidden = !(user.banned && !specialType);
    
    // 配置连麦按钮、更多按钮
    [self refreshMoreButtonState];
    [self refreshLinkMicButtonState];
    
    // 配置头衔标志
    self.actorBgView.hidden = !specialType;
    self.actorLabel.hidden = !specialType;
    if (specialType) {
        CGFloat actorTextWidth = [user.actor boundingRectWithSize:CGSizeMake(100, 18)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                 attributes:@{NSFontAttributeName:self.actorLabel.font}
                                                                    context:nil].size.width;
        CGFloat nickNameTextWidth = [user.userName boundingRectWithSize:CGSizeMake(200, 20)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                 attributes:@{NSFontAttributeName:self.nickNameLabel.font}
                                                                    context:nil].size.width;
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat margin = isPad ? 56 : 32;
        CGFloat buttonOriginX = self.bounds.size.width - margin * 2 - 88;
        if (!self.moreButton.hidden) {
            buttonOriginX -= (32 + 20);
        }
        if (!self.linkmicButton.hidden) {
            buttonOriginX -= 32;
        }
        // 优先显示昵称完整，当宽度不能完全展示头衔+昵称，头衔最多展示4个文字
        if ((nickNameTextWidth + actorTextWidth + 8 * 3) > buttonOriginX && [PLVFdUtil checkStringUseable:user.actor]) {
            self.actorLabel.text = [PLVFdUtil cutSting:user.actor WithCharacterLength:3];
        } else {
            self.actorLabel.text = user.actor;
        }
    }
    // 配置头衔背景渐变
    if (specialType) {
        UIColor *startColor = nil;
        UIColor *endColor = nil;
        [self getActorBgColorWithUserType:user.userType startColor:&startColor endColor:&endColor];
        if (startColor && endColor) {
            self.gradientLayer.colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
        }
    }
    
    // 配置昵称文本
    self.nickNameLabel.text = self.user.userName;
    
    if(self.user.waitUser) {
        __weak typeof(self) weakSelf = self;
        self.user.waitUser.linkMicStatusBlock = ^(PLVLinkMicWaitUser * _Nonnull waitUser) {
            [weakSelf refreshLinkMicButtonState];
        };
    }
}

+ (CGFloat)cellHeight {
    return 68.0;
}

#pragma mark - [ Private Method ]

#pragma mark UI

- (NSString *)imageNameWithUserType:(PLVRoomUserType)userType {
    NSString *imageName = nil;
    switch (userType) {
        case PLVRoomUserTypeGuest:
            imageName = @"plvsa_member_guest_avatar";
            break;
        case PLVRoomUserTypeTeacher:
            imageName = @"plvsa_member_teacher_avatar";
            break;
        case PLVRoomUserTypeAssistant:
            imageName = @"plvsa_member_assistant_avatar";
            break;
        case PLVRoomUserTypeManager:
            imageName = @"plvsa_member_manager_avatar";
            break;
        default:
            imageName = @"plvsa_member_student_avatar";
            break;
    }
    return imageName;
}

/// 通过参数获取头衔渐变色首尾颜色
- (void)getActorBgColorWithUserType:(PLVRoomUserType)userType
                         startColor:(UIColor **)startColor
                           endColor:(UIColor **)endColor {
    NSString *startColorHexString = nil;
    NSString *endColorHexString = nil;
    switch (userType) {
        case PLVRoomUserTypeGuest:
            startColorHexString = @"#FF2851";
            endColorHexString = @"#FE3182";
            break;
        case PLVRoomUserTypeTeacher:
            startColorHexString = @"#FFB95A";
            endColorHexString = @"#FFA336";
            break;
        case PLVRoomUserTypeAssistant:
            startColorHexString = @"#3B7DFE";
            endColorHexString = @"#75A2FE";
            break;
        case PLVRoomUserTypeManager:
            startColorHexString = @"#32B6BF";
            endColorHexString = @"#35C4CF";
            break;
        default:
            break;
    }
    *startColor = PLV_UIColorFromRGB(startColorHexString);
    *endColor = PLV_UIColorFromRGB(endColorHexString);
}

/// 配置【更多】按钮的显示与隐藏
- (void)refreshMoreButtonState {
    BOOL specialType = [PLVRoomUser isSpecialIdentityWithUserType:self.user.userType];
    BOOL isLoginUser = [self isLoginUser:self.user.userId];
    
    BOOL buttonHidden = NO;
    if (isLoginUser || ![self canManagerLinkMic]) {
        buttonHidden = YES;
    } else if (specialType) {
        buttonHidden = self.user.onlineUser ? NO : YES;
    }
    self.moreButton.hidden = buttonHidden;
}

/// 配置【连麦】按钮的显示与隐藏，还有选中状态
- (void)refreshLinkMicButtonState {
    BOOL isCanLinkMicGuest = (self.user.userType == PLVRoomUserTypeGuest); // 可以邀请连麦的嘉宾
    BOOL isCanLinkMicWatchUser = ((self.user.userType == PLVRoomUserTypeSlice || self.user.userType == PLVRoomUserTypeStudent) && self.enableLinkMic && self.inviteAudioEnabled); // 可以邀请连麦的观众
    BOOL isManagerLinkMicUser = [self canManagerLinkMic]; // 讲师等角色可以操作邀请嘉宾、观众用户连麦
    BOOL hiddenLinkMicButton = self.startClass ? ((isManagerLinkMicUser && (isCanLinkMicGuest || isCanLinkMicWatchUser)) ? NO : YES) : YES;
    self.linkmicButton.hidden = hiddenLinkMicButton;
    
    BOOL linkMicButtonSelected = (self.user.onlineUser) ? YES : NO;
    self.linkmicButton.selected = linkMicButtonSelected;
    if (linkMicButtonSelected && isManagerLinkMicUser && !self.user.onlineUser.localUser) {
        self.linkmicButton.hidden = NO;
    }
    
    BOOL canShowHandUpUser = (self.user.waitUser && self.user.waitUser.linkMicStatus == PLVLinkMicUserLinkMicStatus_HandUp && isManagerLinkMicUser); // 举手用户
    BOOL hiddenHandUpImageView = canShowHandUpUser ? NO : YES;
    self.handUpImageView.hidden = hiddenHandUpImageView;
    if (canShowHandUpUser) {
        self.linkmicButton.hidden = NO;
    }
    
    [self refreshLinkMicButtonStateWithNormal];
    if (!linkMicButtonSelected && self.user.waitUser && self.user.waitUser.linkMicStatus == PLVLinkMicUserLinkMicStatus_Inviting) {
        [self refreshLinkMicButtonStateWithInviting];
    }
}

/// 刷新按钮状态为邀请连麦中
- (void)refreshLinkMicButtonStateWithInviting {
    self.linkmicButton.userInteractionEnabled = NO;
    UIImageView *buttonImageView = self.linkmicButton.imageView;
    NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:3];
    for (NSInteger i = 0; i < 3; i ++) {
        [imageArray addObject:[PLVSAUtils imageForMemberResource:[NSString stringWithFormat:@"plvsa_member_linkmic_wait_icon_0%ld.png", i]]];
    }
    [buttonImageView setAnimationImages:[imageArray copy]];
    [buttonImageView setAnimationDuration:1];
    [buttonImageView startAnimating];
}

/// 刷新按钮状态为普通状态
- (void)refreshLinkMicButtonStateWithNormal {
    self.linkmicButton.userInteractionEnabled = YES;
    UIImageView *buttonImageView = self.linkmicButton.imageView;
    if (buttonImageView.isAnimating) {
        [buttonImageView stopAnimating];
    }
    buttonImageView.animationImages = nil;
    [self.linkmicButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_join_request"] forState:UIControlStateNormal];
}

#pragma mark Getter & Setter

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.cornerRadius = 22;
        _avatarImageView.layer.masksToBounds = YES;
    }
    return _avatarImageView;
}

- (UIImageView *)bannedImageView {
    if (!_bannedImageView) {
        _bannedImageView = [[UIImageView alloc] init];
        _bannedImageView.image = [PLVSAUtils imageForMemberResource:@"plvsa_member_banned_icon"];
        _bannedImageView.hidden = YES;
    }
    return _bannedImageView;
}

- (UIImageView *)actorBgView {
    if (!_actorBgView) {
        _actorBgView = [[UIImageView alloc] init];
        _actorBgView.layer.cornerRadius = 9;
        _actorBgView.layer.masksToBounds = YES;
        _actorBgView.hidden = YES;
    }
    return _actorBgView;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.locations = @[@(0), @(1.0)];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (UILabel *)actorLabel {
    if (!_actorLabel) {
        _actorLabel = [[UILabel alloc] init];
        _actorLabel.font = [UIFont systemFontOfSize:12];
        _actorLabel.textColor = [UIColor whiteColor];
        _actorLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _actorLabel;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:14];
        _nickNameLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    }
    return _nickNameLabel;
}

- (UIButton *)linkmicButton{
    if (!_linkmicButton) {
        _linkmicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_linkmicButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_join_request"] forState:UIControlStateNormal];
        [_linkmicButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_join_leave"] forState:UIControlStateSelected];
        [_linkmicButton addTarget:self action:@selector(linkMicButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _linkmicButton.hidden = YES;
    }
    return _linkmicButton;
}

- (UIButton *)moreButton{
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_more_btn"] forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _moreButton.hidden = YES;
    }
    return _moreButton;
}

- (UIImageView *)handUpImageView {
    if (!_handUpImageView) {
        _handUpImageView = [[UIImageView alloc] init];
        _handUpImageView.image = [PLVSAUtils imageForMemberResource:@"plvsa_member_linkmic_handup_icon"];
        _handUpImageView.hidden = YES;
    }
    return _handUpImageView;
}

- (BOOL)startClass {
    if (self.delegate && [self.delegate respondsToSelector:@selector(startClassInCell:)]) {
        return [self.delegate startClassInCell:self];
    }
    return NO;
}

- (BOOL)enableLinkMic {
    if (self.delegate && [self.delegate respondsToSelector:@selector(enableAudioVideoLinkMicInCell:)]) {
        return [self.delegate enableAudioVideoLinkMicInCell:self];
    }
    return NO;
}

- (BOOL)inviteAudioEnabled {
    return [PLVRoomDataManager sharedManager].roomData.menuInfo.inviteAudioEnabled;
}

#pragma mark Utils

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

#pragma mark - [ Event ]

#pragma mark Action

- (void)linkMicButtonAction:(id)sender {
    if (!self.linkmicButton.isSelected) {
        BOOL allowLinkmic = [self.delegate allowLinkMicInCell:self];
        if (allowLinkmic) {
            if (self.user.waitUser ||
                (self.user.userType == PLVRoomUserTypeGuest ||
                 self.user.userType == PLVRoomUserTypeSlice ||
                 self.user.userType == PLVRoomUserTypeStudent)) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didInviteUserJoinLinkMicInCell:)]) {
                    [self.delegate didInviteUserJoinLinkMicInCell:self.user];
                }
            }
            
            // 刷新按钮状态为等待连麦
            [self refreshLinkMicButtonStateWithInviting];
        } else {
            [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"当前连麦人数已达上限")];
        }
    } else {
        if (self.user.onlineUser){
            __weak typeof(self) weakSelf = self;
            [PLVSAUtils showAlertWithTitle:PLVLocalizedString(@"确定挂断连麦吗？") Message:@"" cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
                [weakSelf.user.onlineUser wantCloseUserLinkMic];
            }];
        }
    }
}

- (void)moreButtonAction:(id)sender {
    [self.delegate didTapMoreButtonInCell:self chatUser:self.user];
}

@end
