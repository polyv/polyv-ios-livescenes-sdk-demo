//
//  PLVHCLinkMicSettingPopView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicSettingPopView.h"

//工具类
#import "PLVHCUtils.h"

//模块
#import "PLVLinkMicOnlineUser.h"
#import "PLVRoomDataManager.h"
#import "PLVHCCaptureDeviceManager.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

// 麦克风开关
static NSString *const kSCMicrophoneEnableConfigKey = @"kSCMicrophoneEnableConfigKey";
// 摄像头开关
static NSString *const kSCCameraEnableConfigKey = @"kSCCameraEnableConfigKey";
// 摄像头方向是否为前置
static NSString *const kSCCameraIsFrontConfigKey = @"kSCCameraIsFrontConfigKey";
//当前用户昵称Key
static NSString *const kSCLocalPrevierUserNicknameKey = @"kSCLocalPrevierUserNicknameKey";
//当前用户头像key
static NSString *const kSCLocalPrevierUserAvatarURLKey = @"kSCLocalPrevierUserAvatarURLKey";

@interface PLVHCLinkMicSettingPopView ()

#pragma mark UI
//需要添加到的主视图
@property (nonatomic, strong, readonly) UIView *frontView;
//承载内容的视图
@property (nonatomic, strong) UIView *contentView;
//承载设备设置和文案的视图
@property (nonatomic, strong) UIView *mainView;
//头像
@property (nonatomic, strong) UIImageView *avatarImageView;
//名字
@property (nonatomic, strong) UILabel *titleLabel;
//关闭按钮
@property (nonatomic, strong) UIButton *closeButton;
// 关闭按钮渐变layer
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
//承载设备设置的视图
@property (nonatomic, strong) UIView *deviceView;
//麦克风设置(通过判断按钮selected状态判断打开或者关闭 YES 麦克风关闭 NO 麦克风开启)
@property (nonatomic, strong) PLVHCLinkMicSettingPopItemView *micView;
//摄像头设置(通过判断按钮selected状态判断打开或者关闭 YES 摄像头关闭 NO 摄像头开启)
@property (nonatomic, strong) PLVHCLinkMicSettingPopItemView *cameraView;
//画笔设置(通过判断按钮selected状态判断是否授权 YES 授权画笔 NO 未授权画笔)
@property (nonatomic, strong) PLVHCLinkMicSettingPopItemView *brushView;
//奖杯
@property (nonatomic, strong) PLVHCLinkMicSettingPopItemView *trophyView;
//用户的 摄像头 当前是否前置 selected (YES 后置，NO 前置)
@property (nonatomic, strong) PLVHCLinkMicSettingPopItemView *cameraSwitchView;
// 设置连麦视图到放大区域或恢复到连麦列表
@property (nonatomic, strong) PLVHCLinkMicSettingPopItemView *zoomSwitchView;

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *currentUser; // 当前展示的user，弱引用
@property (nonatomic, assign) BOOL localPreviewUser;//当前预览用户，只有未在上课，才会有设备预览用户
@property (nonatomic, assign) BOOL isSelf; // 当前用户是否为自己

@end

@implementation PLVHCLinkMicSettingPopView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.avatarImageView.center = CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.avatarImageView.bounds));
    self.mainView.center = CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.avatarImageView.bounds) + CGRectGetMidY(self.mainView.bounds));
    self.titleLabel.frame = CGRectMake(0, 40, CGRectGetWidth(self.mainView.bounds), 18);
    self.closeButton.frame = CGRectMake(0, CGRectGetHeight(self.mainView.bounds) - 40, CGRectGetWidth(self.mainView.bounds), 40);
    self.gradientLayer.frame = self.closeButton.bounds;
    self.deviceView.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame) + 24, CGRectGetWidth(self.mainView.bounds), 70);
    [self updateSettingContentView];
}

#pragma mark - Getter && Setter

- (UIView *)frontView {
    if ([PLVHCUtils sharedUtils].homeVC) {
        return [PLVHCUtils sharedUtils].homeVC.view;
    }
    NSEnumerator *frontToBackWindows = [UIApplication.sharedApplication.windows reverseObjectEnumerator];
    for (UIWindow *window in frontToBackWindows) {
        BOOL windowOnMainScreen = window.screen == UIScreen.mainScreen;
        BOOL windowIsVisible = !window.hidden && window.alpha > 0;
        BOOL windowLevelSupported = window.windowLevel == UIWindowLevelNormal;
        if(windowOnMainScreen && windowIsVisible && windowLevelSupported) {
            return window;
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.frame = CGRectMake(0, 0, 260, 243);
    }
    return _contentView;
}

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.frame = CGRectMake(0, 0, 60, 60);
        _avatarImageView.layer.cornerRadius = 30.0f;
        _avatarImageView.layer.masksToBounds = YES;
        _avatarImageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_teacher_icon"];
    }
    return _avatarImageView;
}

- (UIView *)mainView {
    if (!_mainView) {
        _mainView = [[UIView alloc] init];
        _mainView.frame = CGRectMake(0, 0, 260, 213);
        _mainView.layer.cornerRadius = 8.0f;
        _mainView.layer.masksToBounds = YES;
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = _mainView.bounds;
        gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#30344F"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#2D324C"].CGColor];
        gradientLayer.locations = @[@0.5, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1.0);
        [_mainView.layer addSublayer:gradientLayer];
    }
    return _mainView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0f];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIView *)deviceView {
    if (!_deviceView) {
        _deviceView = [[UIView alloc] init];
    }
    return _deviceView;
}

- (PLVHCLinkMicSettingPopItemView *)micView {
    if (!_micView) {
        _micView = [[PLVHCLinkMicSettingPopItemView alloc] init];
        _micView.bounds = CGRectMake(0, 0, 44, 70);
        _micView.hidden = NO;
        _micView.titleLabel.text = @"麦克风";
        [_micView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_mic_open"] forState:UIControlStateNormal];
        [_micView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_mic_close"] forState:UIControlStateSelected];
        [_micView.button addTarget:self action:@selector(micButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _micView;
}

- (PLVHCLinkMicSettingPopItemView *)cameraView {
    if (!_cameraView) {
        _cameraView = [[PLVHCLinkMicSettingPopItemView alloc] init];
        _cameraView.bounds = CGRectMake(0, 0, 44, 70);
        _cameraView.hidden = NO;
        _cameraView.titleLabel.text = @"摄像头";
        [_cameraView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_camera_open"] forState:UIControlStateNormal];
        [_cameraView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_camera_close"] forState:UIControlStateSelected];
        [_cameraView.button addTarget:self action:@selector(cameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraView;
}

- (PLVHCLinkMicSettingPopItemView *)brushView {
    if (!_brushView) {
        _brushView = [[PLVHCLinkMicSettingPopItemView alloc] init];
        _brushView.bounds = CGRectMake(0, 0, 44, 70);
        _brushView.hidden = YES;
        _brushView.titleLabel.text = @"画笔";
        [_brushView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_brush_unauth"] forState:UIControlStateNormal];
        [_brushView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_brush_auth"] forState:UIControlStateSelected];
        [_brushView.button addTarget:self action:@selector(brushButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _brushView;
}

- (PLVHCLinkMicSettingPopItemView *)trophyView {
    if (!_trophyView) {
        _trophyView = [[PLVHCLinkMicSettingPopItemView alloc] init];
        _trophyView.bounds = CGRectMake(0, 0, 44, 70);
        _trophyView.hidden = YES;
        _trophyView.titleLabel.text = @"奖杯";
        [_trophyView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_trophy"] forState:UIControlStateNormal];
        [_trophyView.button addTarget:self action:@selector(trophyButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _trophyView;
}

- (PLVHCLinkMicSettingPopItemView *)cameraSwitchView {
    if (!_cameraSwitchView) {
        _cameraSwitchView = [[PLVHCLinkMicSettingPopItemView alloc] init];
        _cameraSwitchView.bounds = CGRectMake(0, 0, 44, 70);
        _cameraSwitchView.hidden = YES;
        _cameraSwitchView.titleLabel.text = @"方向";
        [_cameraSwitchView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_camera_direction"] forState:UIControlStateNormal];
        [_cameraSwitchView.button addTarget:self action:@selector(cameraSwitchButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraSwitchView;
}

- (PLVHCLinkMicSettingPopItemView *)zoomSwitchView {
    if (!_zoomSwitchView) {
        _zoomSwitchView = [[PLVHCLinkMicSettingPopItemView alloc]init];
        _zoomSwitchView.bounds = CGRectMake(0, 0, 48, 70);
        _zoomSwitchView.titleLabel.text = @"放大窗口";
        [_zoomSwitchView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_linkmic_zoom"] forState:UIControlStateNormal];
        [_zoomSwitchView.button setImage:[PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_linkmic_reset"] forState:UIControlStateSelected];
        [_zoomSwitchView.button addTarget:self action:@selector(zoomSwitchViewButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _zoomSwitchView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        [_closeButton setTitle:@"关闭" forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return _closeButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#00B16C").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#00E78D").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}


- (BOOL)isSelf {
    return [self.currentUser.userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId] || self.localPreviewUser;
}

- (void)setOnlineUser:(PLVLinkMicOnlineUser *)currentUser {
    if (![currentUser isKindOfClass:[PLVLinkMicOnlineUser class]]) {
        return;
    }
    //设置讲师或者学员信息 通过传进来的用户信息
    _currentUser = currentUser;
    
    //头像
    [self updateUserAvatarWithImageURL:currentUser.avatarPic];
    
    //用户名称
    NSString *labelText = @"";
    if (PLV_SafeStringForValue(currentUser.nickname)) {
        if (currentUser.userType == PLVSocketUserTypeTeacher) {
            labelText = [NSString stringWithFormat:@"讲师-%@",currentUser.nickname];
        } else if ([[PLVHiClassManager sharedManager].groupLeaderId isEqualToString:currentUser.userId]) {
            labelText = [NSString stringWithFormat:@"组长-%@",currentUser.nickname];
        } else {
            labelText = currentUser.nickname;
        }
        labelText = labelText.length > 14 ? [[labelText substringToIndex:14] stringByAppendingString:@"..."] : labelText;
    }
    self.titleLabel.text = labelText;

    __weak typeof(self) weakSelf = self;
    //连麦按钮
    self.micView.button.selected = !currentUser.currentMicOpen;
    currentUser.micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        weakSelf.micView.button.selected = !onlineUser.currentMicOpen;
    };
    
    //摄像头按钮
    self.cameraView.button.selected = !currentUser.currentCameraShouldShow;
    currentUser.cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        weakSelf.cameraView.button.selected = !onlineUser.currentCameraShouldShow;
    };
    
    if (currentUser.userType == PLVSocketUserTypeTeacher &&
        currentUser.localUser) {
        //摄像头方向 朝前是为默认状态 朝后为选中状态
        self.cameraSwitchView.button.selected = !currentUser.currentCameraFront;
        self.zoomSwitchView.button.selected = currentUser.inLinkMicZoom;
    }
    
    //画笔
    self.brushView.button.selected = currentUser.currentBrushAuth;
    // 连麦放大视图
    self.zoomSwitchView.button.selected = currentUser.inLinkMicZoom;
    self.zoomSwitchView.titleLabel.text = currentUser.inLinkMicZoom ? @"恢复窗口" : @"放大窗口";
}


#pragma mark - [ Public Methods ]

#pragma mark show

- (void)showSettingViewWithUser:(PLVLinkMicOnlineUser *)user {
    if (!user) return;
    self.localPreviewUser = NO;
    [self setOnlineUser:user];
    [self show];
}

- (void)showLocalSettingView {
    //设置设备默认值
    self.localPreviewUser = YES;
    self.micView.button.selected = ![PLVHCCaptureDeviceManager sharedManager].micOpen;
    self.cameraView.button.selected = ![PLVHCCaptureDeviceManager sharedManager].cameraOpen;
    self.cameraSwitchView.button.selected = ![PLVHCCaptureDeviceManager sharedManager].cameraFront;
    
    PLVRoomUser *user = [PLVRoomDataManager sharedManager].roomData.roomUser;
    NSString *nickname = user.viewerName ? user.viewerName : user.viewerId;
    self.titleLabel.text = [NSString stringWithFormat:@"讲师-%@",nickname];
    [self updateUserAvatarWithImageURL:user.viewerAvatar];
    
    [self show];
}

- (void)setupLocalPrevierUserInLinkMicZoom:(BOOL)inLinkMicZoom {
    // 连麦放大视图
    self.zoomSwitchView.button.selected = inLinkMicZoom;
    self.zoomSwitchView.titleLabel.text = inLinkMicZoom ? @"恢复窗口" : @"放大窗口";
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.75];
    self.alpha = 0.0;
    self.contentView.alpha = 0.0;
    [self.contentView addSubview:self.mainView];
    [self.contentView addSubview:self.avatarImageView];
    [self.mainView addSubview:self.titleLabel];
    [self.mainView addSubview:self.closeButton];
    
    [self.mainView addSubview:self.deviceView];
    [self.deviceView addSubview:self.micView];
    [self.deviceView addSubview:self.cameraView];
    [self.deviceView addSubview:self.brushView];
    [self.deviceView addSubview:self.trophyView];
    [self.deviceView addSubview:self.cameraSwitchView];
    [self.deviceView addSubview:self.zoomSwitchView];
}

- (void)updateSettingContentView {
    NSMutableArray <PLVHCLinkMicSettingPopItemView *>*showItemViews = [NSMutableArray arrayWithCapacity:5];
    self.brushView.hidden = YES;
    self.trophyView.hidden = YES;
    self.cameraSwitchView.hidden = YES;
    [showItemViews addObject:self.micView];
    [showItemViews addObject:self.cameraView];

    if (self.isSelf) { //自己的布局
        if (self.currentUser.userType == PLVSocketUserTypeTeacher ||
            [PLVHiClassManager sharedManager].currentUserIsGroupLeader ||
            self.localPreviewUser) { // 讲师、组长、预览画面
            if (!self.cameraView.button.isSelected) {
                self.cameraSwitchView.hidden = NO;
                [showItemViews addObject:self.cameraSwitchView];
            }
        }
    } else { // 其他人的布局
        self.brushView.hidden = NO;
        [showItemViews addObject:self.brushView];
        if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) { // 老师才有授予奖杯功能
            self.trophyView.hidden = NO;
            [showItemViews addObject:self.trophyView];
        }
    }
    [showItemViews addObject:self.zoomSwitchView];
    
    NSInteger showItemCount = showItemViews.count;
    CGFloat itemViewSpacing = (6 - showItemCount) * 8; //itemView 间隙的规律
    CGFloat viewSpacing = (CGRectGetWidth(self.mainView.bounds) - itemViewSpacing * (showItemCount - 1)  - showItemCount * 44)/2;//item 左右边距
    CGFloat centerX = viewSpacing + CGRectGetWidth(self.micView.bounds)/2;
    for (PLVHCLinkMicSettingPopItemView *itemView in showItemViews) {
        itemView.center = CGPointMake(centerX, CGRectGetMidY(self.deviceView.bounds));
        centerX += (itemViewSpacing + CGRectGetWidth(self.micView.bounds));
    }
}

- (void)updateUserAvatarWithImageURL:(NSString *)imageURL {
    //占位图
    UIImage *placeholderImage = nil;
    if (self.currentUser.userType == PLVSocketUserTypeTeacher) {
        placeholderImage = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_teacher_icon"];
    } else {
        placeholderImage = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_device_student_icon"];
    }
    NSURL *avatarImageURL = [NSURL URLWithString:imageURL];
    [PLVHCUtils setImageView:self.avatarImageView url:avatarImageURL placeholderImage:placeholderImage];
}

- (void)show {
    if (!self.superview) {
        [self.frontView addSubview:self];
    }
    if (!self.contentView.superview) {
        [self addSubview:self.contentView];
    }
    self.frame = [UIApplication sharedApplication].delegate.window.bounds;
    self.contentView.center = self.center;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
        self.contentView.alpha = 1.0;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
        self.contentView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.contentView removeFromSuperview];
        [self removeFromSuperview];
    }];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeButtonAction {
    [self dismiss];
}

- (void)micButtonAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    
    if (self.localPreviewUser) {
        [[PLVHCCaptureDeviceManager sharedManager] openMicrophone:!sender.selected];
    } else {
        [self.currentUser wantOpenUserMic:!sender.isSelected];
    }
}

- (void)cameraButtonAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    
    if (self.localPreviewUser) {
        [[PLVHCCaptureDeviceManager sharedManager] openCamera:!sender.selected];
    } else {
        [self.currentUser wantOpenUserCamera:!sender.selected];
    }
    
    if (self.currentUser.userType == PLVSocketUserTypeTeacher ||
        self.localPreviewUser ||
        [PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
        [self updateSettingContentView];
    }
}

- (void)cameraSwitchButtonAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    [self dismiss];

    if (self.localPreviewUser) {
        [[PLVHCCaptureDeviceManager sharedManager] switchCamera:!sender.selected];
    } else {
        if ((self.currentUser.userType == PLVSocketUserTypeTeacher &&
            self.currentUser.localUser) ||
            [PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
            [self.currentUser wantSwitchUserFrontCamera:!sender.selected];
        }
    }
}

- (void)brushButtonAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    
    [self.currentUser wantAuthUserBrush:sender.isSelected];
}

- (void)trophyButtonAction {
    [self dismiss];
    [self.currentUser wantGrantUserCup];
}

- (void)zoomSwitchViewButtonAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    NSString *zoomTitleString = sender.selected ? @"恢复窗口" : @"放大窗口";
    self.zoomSwitchView.titleLabel.text = zoomTitleString;
    [self dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(linkMicPopView:didSwitchLinkMicWithUserModel:localPreviewUser:showInZoom:)]) {
        [self.delegate linkMicPopView:self didSwitchLinkMicWithUserModel:self.currentUser localPreviewUser:self.localPreviewUser showInZoom:sender.selected];
    }
}

@end


@implementation PLVHCLinkMicSettingPopItemView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.button];
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.button.center = CGPointMake(CGRectGetMidX(self.button.bounds), CGRectGetMidY(self.button.bounds));
    self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.button.frame) + 8, CGRectGetWidth(self.bounds), 18);
}

#pragma mark - Getter && Setter

- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.bounds = CGRectMake(0, 0, 44, 44);
    }
    return _button;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12.0f];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

@end
