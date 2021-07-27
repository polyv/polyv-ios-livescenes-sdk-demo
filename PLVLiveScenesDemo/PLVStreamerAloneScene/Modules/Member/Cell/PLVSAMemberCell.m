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
#import <SDWebImage/UIImageView+WebCache.h>
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

/// 数据
@property (nonatomic, strong) PLVChatUser *user;

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
        
        [self.actorBgView.layer addSublayer:self.gradientLayer];
        [self.actorBgView addSubview:self.actorLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cellHeight = self.bounds.size.height;
    
    // 配置头像、禁言标志位置
    self.avatarImageView.frame = CGRectMake(32, (cellHeight - 44)/2.0, 44, 44);
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
    CGFloat buttonOriginX = self.bounds.size.width - 32 - 32;
    self.moreButton.frame = CGRectMake(buttonOriginX, (cellHeight - 32)/2.0, 32, 32);
    if (!self.moreButton.hidden) {
        buttonOriginX -= (32 + 20);
    }
    self.linkmicButton.frame = CGRectMake(buttonOriginX, (cellHeight - 32)/2.0, 32, 32);
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
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:user.avatarUrl]
                            placeholderImage:placeholder];
    
    // 配置禁言标志
    self.bannedImageView.hidden = !(user.banned && !specialType);
    
    // 配置头衔标志
    self.actorBgView.hidden = !specialType;
    self.actorLabel.hidden = !specialType;
    if (specialType) {
        self.actorLabel.text = user.actor;
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
    
    // 配置连麦按钮、更多按钮
    [self refreshMoreButtonState];
    [self refreshLinkMicButtonState];
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
    if (isLoginUser) {
        buttonHidden = YES;
    } else if (specialType) {
        buttonHidden = self.user.onlineUser ? NO : YES;
    }
    self.moreButton.hidden = buttonHidden;
}

/// 配置【连麦】按钮的显示与隐藏，还有选中状态
- (void)refreshLinkMicButtonState {
    BOOL isLoginUser = [self isLoginUser:self.user.userId];
    
    BOOL buttonHidden = NO;
    if (isLoginUser) {
        buttonHidden = YES;
    } else if (self.user.onlineUser.userType == PLVSocketUserTypeGuest) {
        buttonHidden = ![PLVRoomDataManager sharedManager].roomData.channelGuestManualJoinLinkMic;
    } else {
        buttonHidden = (self.user.onlineUser || self.user.waitUser) ? NO : YES;
    }
    self.linkmicButton.hidden = buttonHidden;
    
    BOOL buttonSelected = NO;
    if (self.user.onlineUser || self.user.waitUser) {
        buttonSelected = self.user.onlineUser ? YES : NO;
    }
    self.linkmicButton.selected = buttonSelected;
    self.linkmicButton.enabled = YES;
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

#pragma mark Utils

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)linkMicButtonAction:(id)sender {
    if (self.user.waitUser) {
        BOOL allowLinkmic = [self.delegate allowLinkMicInCell:self];
        if (allowLinkmic) {
            [self.user.waitUser wantAllowUserJoinLinkMic];
            // 刷新按钮状态为等待连麦
            self.linkmicButton.enabled = NO;
        } else {
            [PLVSAUtils showToastInHomeVCWithMessage:@"当前连麦人数已达上限"];
        }
    }else if (self.user.onlineUser){
        __weak typeof(self) weakSelf = self;
        [PLVSAUtils showAlertWithTitle:@"确定挂断连麦吗？" Message:@"" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
            [weakSelf.user.onlineUser wantCloseUserLinkMic];
        }];
    }
}

- (void)moreButtonAction:(id)sender {
    [self.delegate didTapMoreButtonInCell:self chatUser:self.user];
}

@end
