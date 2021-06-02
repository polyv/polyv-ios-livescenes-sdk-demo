//
//  PLVLSLoginViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Hank on 2021/1/12.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLiveStreamerLoginViewController.h"

#import "PLVLiveStreamerPrivacyViewController.h"
#import "PLVLSStreamerViewController.h"

#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVBugReporter.h"

#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

static NSString * const kPrivacyPolicy = @"https://s2.videocc.net/app-simple-pages/privacy-policy/index.html";
static NSString * const kUserProtocol = @"https://s2.videocc.net/app-simple-pages/user-agreement/index.html";
static NSString * const kUserDefaultAgreeUserProtocol = @"UserDefaultAgreeUserProtocol";

@interface PLVLiveStreamerLoginViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *lbTitle;             // 标题
@property (nonatomic, strong) UITextField *tfChannelId;     // 频道文本
@property (nonatomic, strong) UITextField *tfNickName;      // 昵称文本
@property (nonatomic, strong) UITextField *tfPassword;      // 密码文本
@property (nonatomic, strong) UIButton *btnLogin;           // 登录按钮
@property (nonatomic, strong) UIButton * btnAgree;          // 协议
@property (nonatomic, strong) UIButton * btnPrivacyPolicy;  // 隐私协议
@property (nonatomic, strong) UIButton * btnUserProtocol;   // 使用协议
@property (nonatomic, strong) UIButton * btnMicSwitch;      // 麦克风开关
@property (nonatomic, strong) UIButton * btnCameraSwitch;   // 照相机开关
@property (nonatomic, strong) UIButton * btnCameraFront;    // 照相机方向
@property (nonatomic, strong) UIView *lineView;             // 底部横线
@property (nonatomic, strong) UILabel *lbLiveState;         //直播状态提示

@end

@implementation PLVLiveStreamerLoginViewController

#pragma mark - [ Life Period ]

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self updateUI];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//登录窗口只支持竖屏方向
}

#pragma mark - [ Private Methods ]
- (void)setupUI {
    self.view.backgroundColor = PLV_UIColorFromRGB(@"#1B202D");
    
    [self.view addSubview:self.lbTitle];
    [self.view addSubview:self.tfChannelId];
    [self.view addSubview:self.tfNickName];
    [self.view addSubview:self.tfPassword];
    [self.view addSubview:self.btnLogin];
    [self.view addSubview:self.btnAgree];
    [self.view addSubview:self.btnPrivacyPolicy];
    [self.view addSubview:self.btnUserProtocol];
    [self.view addSubview:self.btnMicSwitch];
    [self.view addSubview:self.btnCameraSwitch];
    [self.view addSubview:self.btnCameraFront];
    [self.view addSubview:self.lineView];
    [self.view addSubview:self.lbLiveState];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tapGes];
}

- (void)updateUI {
    CGFloat marginTop = UIViewGetHeight(self.view) > 568 ? 90 : 45;
    
    self.lbTitle.frame = CGRectMake(0, marginTop + P_SafeAreaTopEdgeInsets(), UIViewGetWidth(self.view), 42);
    
    CGRect uiFrame = CGRectMake(40, UIViewGetBottom(self.lbTitle) + marginTop, UIViewGetWidth(self.view) - 80, 44);
    self.tfChannelId.frame = uiFrame;
    
    uiFrame.origin.y = UIViewGetBottom(self.tfChannelId) + 16;
    self.tfNickName.frame = uiFrame;
    
    uiFrame.origin.y = UIViewGetBottom(self.tfNickName) + 16;
    self.tfPassword.frame = uiFrame;
    
    uiFrame.origin.y = UIViewGetBottom(self.tfPassword) + 70;
    self.btnLogin.frame = uiFrame;
    
    // 协议
    NSAttributedString *attributedTitle = [self.btnAgree attributedTitleForState:UIControlStateNormal];
    self.btnAgree.frame = CGRectMake(0, UIViewGetBottom(self.btnLogin) + 13, 22 + attributedTitle.size.width, 22);
    self.btnAgree.center = CGPointMake(self.btnLogin.center.x, self.btnAgree.center.y);
    
    NSAttributedString *attrPrivacyPolicy = [attributedTitle attributedSubstringFromRange:NSMakeRange(7, 6)];
    NSAttributedString *attrPrivacyPolicyRight = [attributedTitle attributedSubstringFromRange:NSMakeRange(13, 7)];
    
    NSAttributedString *attrUserProtocol = [attributedTitle attributedSubstringFromRange:NSMakeRange(14, 6)];
    
    uiFrame = self.btnAgree.frame;
    uiFrame.size.width = attrPrivacyPolicy.size.width;
    uiFrame.origin.x = UIViewGetRight(self.btnAgree) - attrPrivacyPolicyRight.size.width - uiFrame.size.width;
    self.btnPrivacyPolicy.frame = uiFrame;
    
    uiFrame.size.width = attrUserProtocol.size.width;
    uiFrame.origin.x = UIViewGetRight(self.btnAgree) - uiFrame.size.width;
    self.btnUserProtocol.frame = uiFrame;
    

    // 开关
    CGFloat marginLeft = 48, btnWidth = 36, tipHeight = 20 + 1 + 12 + 17;
    CGFloat x = (UIViewGetWidth(self.view) - 3 * btnWidth - 2 * marginLeft) / 2.0f;
    CGFloat y = UIViewGetBottom(self.btnAgree) + 145;
    if (y + btnWidth + 30 + tipHeight > UIViewGetHeight(self.view)) { // 针对小屏手机
        y = UIViewGetBottom(self.btnAgree) + (UIViewGetHeight(self.view) - UIViewGetBottom(self.btnAgree) - btnWidth - tipHeight) / 2.0f;
    }
    
    uiFrame = CGRectMake(x, y, btnWidth, btnWidth);
    self.btnMicSwitch.frame = uiFrame;
    
    uiFrame.origin.x += marginLeft + btnWidth;
    self.btnCameraSwitch.frame = uiFrame;
    
    uiFrame.origin.x += marginLeft + btnWidth;
    self.btnCameraFront.frame = uiFrame;
    
    // 底部提示
    CGFloat labelWidth = 60;
    CGFloat tipX = (UIViewGetWidth(self.view) - labelWidth)/2;
    CGFloat lineWidth = UIViewGetWidth(self.view) - 85 * 2;

    uiFrame = CGRectMake(x, y + btnWidth + 20, lineWidth, 1);
    self.lineView.frame = uiFrame;
    
    uiFrame = CGRectMake(tipX, uiFrame.origin.y + 1 + 12, labelWidth, 17);
    self.lbLiveState.frame = uiFrame;
    
}

/// 手机开播场景
- (void)loginStreamerRoomWithCompletionHandler:(void (^)(void))completion {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self)weakSelf = self;
    [PLVRoomLoginClient loginStreamerRoomWithChannelType:PLVChannelTypePPT
                                               channelId:self.tfChannelId.text
                                                password:self.tfPassword.text
                                                nickName:self.tfNickName.text
                                              completion:^{
        [hud hideAnimated:YES];
        if (completion) {
            completion();
        }
    } failure:^(NSString * _Nonnull errorMessage) {
        [hud hideAnimated:YES];
        
        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        hud.mode = PLVProgressHUDModeText;
        hud.label.text = errorMessage;
        hud.detailsLabel.text = nil;
        [hud hideAnimated:YES afterDelay:2.0];
    }];
}

- (void)setTFStyle:(UITextField *)tf placeholder:(NSString *)placeholder {
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName:PLV_UIColorFromRGBA(@"#F0F1F5", 0.6f)}];
    
    tf.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.16f);
    tf.delegate = self;
    tf.font = [UIFont systemFontOfSize:14];
    tf.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
    tf.attributedPlaceholder = attrString;
    tf.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    tf.leftViewMode = UITextFieldViewModeAlways;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.layer.cornerRadius = 22;
    tf.clipsToBounds = YES;
}

#pragma mark Getter
- (UILabel *)lbTitle {
    if (! _lbTitle) {
        _lbTitle = [[UILabel alloc] init];
        _lbTitle.font = [UIFont systemFontOfSize:30];
        _lbTitle.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _lbTitle.text = @"云直播-手机开播";
        _lbTitle.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_lbTitle];
    }
    
    return _lbTitle;
}

- (UITextField *)tfChannelId {
    if (! _tfChannelId) {
        _tfChannelId = [[UITextField alloc] init];
        _tfChannelId.keyboardType = UIKeyboardTypeNumberPad;
        [self.view addSubview:_tfChannelId];
        
        [self setTFStyle:_tfChannelId placeholder:@"请输入频道号"];
    }
    
    return _tfChannelId;
}

- (UITextField *)tfNickName {
    if (! _tfNickName) {
        _tfNickName = [[UITextField alloc] init];
        [self.view addSubview:_tfNickName];
        
        [self setTFStyle:_tfNickName placeholder:@"请输入昵称"];
    }
    
    return _tfNickName;
}

- (UITextField *)tfPassword {
    if (! _tfPassword) {
        _tfPassword = [[UITextField alloc] init];
        _tfPassword.secureTextEntry = YES;
        [self.view addSubview:_tfPassword];
        
        [self setTFStyle:_tfPassword placeholder:@"请输入密码"];
    }
    
    return _tfPassword;
}

- (UIButton *)btnLogin {
    if (! _btnLogin) {
        UIImage *imgNormal = [PLVColorUtil createImageWithColor:PLV_UIColorFromRGB(@"#4399FF")];
        UIImage *imgDisabled = [PLVColorUtil createImageWithColor:PLV_UIColorFromRGBA(@"#4399FF", 0.3f)];
        
        _btnLogin = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnLogin setBackgroundImage:imgNormal forState:UIControlStateNormal];
        [_btnLogin setBackgroundImage:imgDisabled forState:UIControlStateDisabled];
        _btnLogin.titleLabel.font = [UIFont systemFontOfSize:16];
        [_btnLogin setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
        [_btnLogin setTitle:@"登录" forState:UIControlStateNormal];
        _btnLogin.layer.cornerRadius = 22;
        _btnLogin.clipsToBounds = YES;
        [_btnLogin addTarget:self action:@selector(loginButtonClickAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_btnLogin];
        
        _btnLogin.enabled = NO;
    }
    
    return _btnLogin;
}

- (UIButton *)btnAgree {
    if (!_btnAgree) {
        _btnAgree = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnAgree setImage:[[self class] imageWithImageName:@"plvls_login_ck_normal"] forState:UIControlStateNormal];
        [_btnAgree setImage:[[self class] imageWithImageName:@"plvls_login_ck_selected"] forState:UIControlStateSelected];
        _btnAgree.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
        _btnAgree.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_btnAgree addTarget:self action:@selector(agreeClickAction) forControlEvents:UIControlEventTouchUpInside];
        
        UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size: 12];
        UIColor *normalColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6f);
        UIColor *linkColor = PLV_UIColorFromRGB(@"#F0F1F5");
        
        NSDictionary *normalAttributes = @{NSFontAttributeName:font,
                                              NSForegroundColorAttributeName:normalColor};
        NSDictionary *linkAttributes = @{NSFontAttributeName:font,
                                              NSForegroundColorAttributeName:linkColor};
        
        NSString *string = @" 已阅读并同意《隐私政策》和《使用协议》";
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
        [attributedString addAttributes:normalAttributes range:NSMakeRange(0, string.length)];
        [attributedString addAttributes:linkAttributes range:NSMakeRange(7, 6)];
        [attributedString addAttributes:linkAttributes range:NSMakeRange(14, 6)];
        [_btnAgree setAttributedTitle:attributedString forState:UIControlStateNormal];
        
        NSNumber *agree = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultAgreeUserProtocol];
        if (agree && [agree integerValue] == 1) {
            _btnAgree.selected = YES;
        }
    }
    
    return _btnAgree;
}

- (UIButton *)btnPrivacyPolicy {
    if (!_btnPrivacyPolicy) {
        _btnPrivacyPolicy = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnPrivacyPolicy addTarget:self action:@selector(privacyPolicyClickAction)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnPrivacyPolicy;
}

- (UIButton *)btnUserProtocol {
    if (!_btnUserProtocol) {
        _btnUserProtocol = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnUserProtocol addTarget:self action:@selector(userProtocolClickAction)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnUserProtocol;
}

- (UIButton *)btnMicSwitch {
    if (! _btnMicSwitch) {
        _btnMicSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnMicSwitch.selected = YES;
        [_btnMicSwitch setImage:[[self class] imageWithImageName:@"plvls_login_btn_mic_close"] forState:UIControlStateNormal];
        [_btnMicSwitch setImage:[[self class] imageWithImageName:@"plvls_login_btn_mic_open"] forState:UIControlStateSelected];
        [_btnMicSwitch addTarget:self action:@selector(micSwitchClickAction) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _btnMicSwitch;
}

- (UIButton *)btnCameraSwitch {
    if (! _btnCameraSwitch) {
        _btnCameraSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnCameraSwitch.selected = YES;
        [_btnCameraSwitch setImage:[[self class] imageWithImageName:@"plvls_login_btn_camera_close"] forState:UIControlStateNormal];
        [_btnCameraSwitch setImage:[[self class] imageWithImageName:@"plvls_login_btn_camera_open"] forState:UIControlStateSelected];
        [_btnCameraSwitch addTarget:self action:@selector(cameraSwitchClickAction) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _btnCameraSwitch;
}

- (UIButton *)btnCameraFront {
    if (! _btnCameraFront) {
        _btnCameraFront = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnCameraFront.selected = YES;
        [_btnCameraFront setImage:[[self class] imageWithImageName:@"plvls_login_btn_camera_front_close"] forState:UIControlStateNormal];
        [_btnCameraFront setImage:[[self class] imageWithImageName:@"plvls_login_btn_camera_front_open"] forState:UIControlStateSelected];
        [_btnCameraFront addTarget:self action:@selector(cameraFrontClickAction) forControlEvents:UIControlEventTouchUpInside];
    }
     
    return _btnCameraFront;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _lineView.alpha = 0.1;
        [self.view addSubview:_lineView];
    }
    return _lineView;
}

- (UILabel *)lbLiveState {
    if (!_lbLiveState) {
        _lbLiveState = [[UILabel alloc] init];
        _lbLiveState.font = [UIFont systemFontOfSize:12];
        _lbLiveState.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _lbLiveState.text = @"直播状态";
        _lbLiveState.textAlignment = NSTextAlignmentCenter;
        _lbLiveState.alpha = 0.6;
        [self.view addSubview:_lbLiveState];
    }
    return _lbLiveState;
}

#pragma mark Utils

+ (UIImage *)imageWithImageName:(NSString *)imageName {
    NSString *bundleName = @"LiveStreamer";
    NSBundle *bundle = [NSBundle bundleForClass:[self class]]; // 本代码应该与资源文件存放在同个Bundle下
    NSString *bundlePath = [bundle pathForResource:bundleName ofType:@"bundle"]; // 获取到 LiveStreamer.bundle 所在 Bundle
    NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
    UIImage *image = [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
    return image;
}

#pragma mark - Action
- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self.view endEditing:NO];
}

- (void)loginButtonClickAction {
    __weak typeof(self) weakSelf = self;
    [self loginStreamerRoomWithCompletionHandler:^{

        /// 配置默认值
        PLVRoomData * roomData = [PLVRoomDataManager sharedManager].roomData;
        roomData.localUserMicDefaultOpen = weakSelf.btnMicSwitch.selected;
        roomData.localUserCameraDefaultOpen = weakSelf.btnCameraSwitch.selected;
        roomData.localUserCameraDefaultFront = weakSelf.btnCameraFront.selected;
        
        PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;

        PLVLSStreamerViewController *vctrl = [[PLVLSStreamerViewController alloc] init];
        vctrl.modalPresentationStyle = UIModalPresentationFullScreen;
        [weakSelf presentViewController:vctrl animated:YES completion:nil];
    }];
}

- (void)agreeClickAction{
    self.btnAgree.selected = !self.btnAgree.isSelected;
    
    [[NSUserDefaults standardUserDefaults] setObject:@(self.btnAgree.isSelected)
                                              forKey:kUserDefaultAgreeUserProtocol];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BOOL enabled = self.tfChannelId.text.length > 0 && self.tfPassword.text.length > 0 && self.btnAgree.isSelected;
    self.btnLogin.enabled = enabled;
}

- (void)privacyPolicyClickAction {
    PLVLiveStreamerPrivacyViewController *vctrl = [[PLVLiveStreamerPrivacyViewController alloc] initWithUrlString:kPrivacyPolicy];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vctrl];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)userProtocolClickAction {
    PLVLiveStreamerPrivacyViewController *vctrl = [[PLVLiveStreamerPrivacyViewController alloc] initWithUrlString:kUserProtocol];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vctrl];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)micSwitchClickAction {
    self.btnMicSwitch.selected = !self.btnMicSwitch.isSelected;
}

- (void)cameraSwitchClickAction {
    self.btnCameraSwitch.selected = !self.btnCameraSwitch.isSelected;
    self.btnCameraFront.selected = self.btnCameraSwitch.isSelected;
}

- (void)cameraFrontClickAction {
    self.btnCameraFront.selected = !self.btnCameraFront.isSelected;
}

#pragma mark - [ Delegate ]
#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL enabled = NO;
    if (textField == self.tfChannelId) {
        enabled = self.tfPassword.text.length > 0;
    } else if (textField == self.tfPassword) {
        enabled = self.tfChannelId.text.length > 0;
    } else if (textField == self.tfNickName){
        enabled = self.tfPassword.text.length >0 ;
    }
    
    enabled = enabled && (string.length > 0 || textField.text.length > 1) && self.btnAgree.isSelected;
    
    self.btnLogin.enabled = enabled;
    
    return YES;
}

@end
