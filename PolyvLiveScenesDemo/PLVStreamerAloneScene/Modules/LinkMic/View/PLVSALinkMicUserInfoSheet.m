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

// 框架
#import <SDWebImage/UIImageView+WebCache.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSALinkMicUserInfoSheet()

// UI
@property (nonatomic, strong) UIImageView *headerImageView; // 头像
@property (nonatomic, strong) UILabel *actorLabel; // 头衔
@property (nonatomic, strong) UILabel *nicknameLabel; // 昵称
@property (nonatomic, strong) UIView *lineView; // 分割线
@property (nonatomic, strong) UIButton *cameraButton; // 摄像头按钮
@property (nonatomic, strong) UIButton *micphoneButton; // 麦克风按钮
@property (nonatomic, strong) UIButton *stopLinkMicButton; // 下麦按钮

// Data
@property (nonatomic, weak) PLVLinkMicOnlineUser *user;

@end

@implementation PLVSALinkMicUserInfoSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight {
    self = [super initWithSheetHeight:sheetHeight];
    if (self) {
        [self.contentView addSubview:self.headerImageView];
        [self.contentView addSubview:self.actorLabel];
        [self.contentView addSubview:self.nicknameLabel];
        [self.contentView addSubview:self.lineView];
        [self.contentView addSubview:self.cameraButton];
        [self.contentView addSubview:self.micphoneButton];
        [self.contentView addSubview:self.stopLinkMicButton];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL specialType = [self isSpecialIdentityWithUserType:self.user.userType];
    
    CGFloat width = self.contentView.frame.size.width;
    CGFloat buttonWidth = 42;
    CGFloat buttonHeight = 58;
    CGFloat buttonCount = specialType ? 2 : 3;
    CGFloat buttonPadding = (width - buttonWidth * buttonCount) / (buttonCount + 1);
    CGFloat buttonMargin = self.bounds.size.height > 667 ? 32 : 18;
   
    self.headerImageView.frame = CGRectMake((width - 66) / 2, 17, 66, 66);
    
    CGFloat actorLabelWidth = [self.actorLabel sizeThatFits:CGSizeMake(width, 18)].width + 10;
    self.actorLabel.frame = CGRectMake((width - actorLabelWidth) / 2, CGRectGetMaxY(self.headerImageView.frame) - 18, actorLabelWidth, 18);
    
    self.nicknameLabel.frame = CGRectMake(23.5, CGRectGetMaxY(self.actorLabel.frame) + 9, width - 23.5 *2, 20);
    
    self.lineView.frame = CGRectMake(23.5, CGRectGetMaxY(self.nicknameLabel.frame) + 12, width - 23.5 *2, 1);
    
    if (specialType) {
        self.cameraButton.frame = CGRectMake(buttonPadding, CGRectGetMaxY(self.lineView.frame) + buttonMargin, buttonWidth, buttonHeight);
        
        self.micphoneButton.frame = CGRectMake(CGRectGetMaxX(self.cameraButton.frame) + buttonPadding, self.cameraButton.frame.origin.y, buttonWidth, buttonHeight);
        
        
    } else {
        self.micphoneButton.frame = CGRectMake((width - buttonWidth) / 2, CGRectGetMaxY(self.lineView.frame) + buttonMargin, buttonWidth, buttonHeight);
        
        self.cameraButton.frame = CGRectMake(CGRectGetMinX(self.micphoneButton.frame) - buttonPadding - buttonWidth, self.micphoneButton.frame.origin.y, buttonWidth, buttonHeight);
        
        self.stopLinkMicButton.frame = CGRectMake(CGRectGetMinX(self.micphoneButton.frame) + buttonPadding + buttonWidth, self.micphoneButton.frame.origin.y, buttonWidth, buttonHeight);
    }
    
    
    [self setButtonInsetsWithArray:@[self.cameraButton,
                                     self.micphoneButton,
                                     self.stopLinkMicButton]];
}
#pragma mark - [ Public Method ]

- (void)updateLinkMicUserInfoWithUser:(PLVLinkMicOnlineUser *)user{
    if (!user || ![user isKindOfClass:[PLVLinkMicOnlineUser class]]) {
        return;
    }
    
    self.user = user;

    BOOL specialType = [self isSpecialIdentityWithUserType:user.userType];
    
    NSString *imageName = specialType ? @"plvsa_member_teacher_avatar" : @"plvsa_member_student_avatar";
    UIImage *placeholder = [PLVSAUtils imageForMemberResource:imageName];
    [self.headerImageView sd_setImageWithURL:[NSURL URLWithString:user.avatarPic]
                            placeholderImage:placeholder];
    
    if (specialType) {
        self.actorLabel.text = user.actor;
    }
    self.actorLabel.hidden = !specialType && user.actor;
    self.stopLinkMicButton.hidden = specialType;
    
    NSString *colorHexString = [self actorBgColorHexStringWithUserType:user.userType];
    if (colorHexString && !self.actorLabel.hidden) {
        self.actorLabel.backgroundColor = [PLVColorUtil colorFromHexString:colorHexString];
    }
    
    self.nicknameLabel.text = user.nickname;

    // 设置按钮状态
    [self refreshButtonState];
    // 添加信息变动回调监听
    [self addUserInfoChangedBlock:user];
    
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

#pragma mark UI

- (void)setButtonInsetsWithArray:(NSArray *)buttonArray {
    for (int i = 0; i < buttonArray.count ; i++) {
        UIButton *but = buttonArray[i];
        CGFloat padding = 5;
        [but setTitleEdgeInsets:
         UIEdgeInsetsMake(but.frame.size.height/2 + padding,
                          (but.frame.size.width-but.titleLabel.intrinsicContentSize.width)/2-but.imageView.frame.size.width,
                          0,
                          (but.frame.size.width-but.titleLabel.intrinsicContentSize.width)/2)];
        [but setImageEdgeInsets:
         UIEdgeInsetsMake(
                          0,
                          (but.frame.size.width-but.imageView.frame.size.width)/2,
                          but.titleLabel.intrinsicContentSize.height,
                          (but.frame.size.width-but.imageView.frame.size.width)/2)];
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
#pragma mark Data

- (void)refreshButtonState {
    self.cameraButton.selected = self.user.currentCameraOpen;
    self.micphoneButton.selected = self.user.currentMicOpen;
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
    
    [user addWillDeallocBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        plv_dispatch_main_async_safe(^{
            [weakSelf dismiss];
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

- (void)stopLinkMicButtonAction {
    __weak typeof(self) weakSelf = self;
    [PLVSAUtils showAlertWithMessage:@"确定下麦吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
        [weakSelf.user wantCloseUserLinkMic];
        [weakSelf dismiss];
    }];
}

@end
