//
//  PLVLSLoginViewController.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/1/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLiveStreamerLoginViewController.h"

#import "PLVLiveScenesPrivacyViewController.h"
#import "PLVLSStreamerViewController.h"
#import "PLVSAStreamerViewController.h"

#import "PLVLoginTextField.h"
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVBugReporter.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString * const kUserDefaultAgreeUserProtocol = @"UserDefaultAgreeUserProtocol";
static NSString * const kUserDefaultUserInfo = @"UserDefaultUserInfo";

@interface PLVLiveStreamerLoginViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView; //背景图
@property (nonatomic, strong) UILabel *lbTitle;             // 标题
@property (nonatomic, strong) PLVLoginTextField *tfChannelId;     // 频道文本
@property (nonatomic, strong) PLVLoginTextField *tfNickName;      // 昵称文本
@property (nonatomic, strong) PLVLoginTextField *tfPassword;      // 密码文本
@property (nonatomic, strong) UIButton *btnLogin;           // 登录按钮
@property (nonatomic, strong) UIButton *rememberPasswordButton; // 记住密码按钮
@property (nonatomic, strong) UIButton * btnAgree;          // 协议
@property (nonatomic, strong) UIButton * btnPrivacyPolicy;  // 隐私协议
@property (nonatomic, strong) UIButton * btnUserProtocol;   // 使用协议

@end

@implementation PLVLiveStreamerLoginViewController

#pragma mark - [ Life Period ]

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    [self writeUserInfo];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self updateUI];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [PLVNetworkAccessibility stop];
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
    [self.view addSubview:self.backgroundImageView];

    [self.view addSubview:self.lbTitle];
    [self.view addSubview:self.tfChannelId];
    [self.view addSubview:self.tfPassword];
    [self.view addSubview:self.tfNickName];
    [self.view addSubview:self.btnLogin];
    [self.view addSubview:self.rememberPasswordButton];
    [self.view addSubview:self.btnAgree];
    [self.view addSubview:self.btnPrivacyPolicy];
    [self.view addSubview:self.btnUserProtocol];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tapGes];
    
    for (UIView *textField in self.view.subviews) {
        if ([textField isKindOfClass:PLVLoginTextField.class]) {
            //使用了私有的实现修改UITextField里clearButton的图片
            UIButton *clearButton = [textField valueForKey:@"_clearButton"];
            [clearButton setImage:[[self class] imageWithImageName:@"plvls_login_clear_btn"] forState:UIControlStateNormal];
        }
    }
}

- (void)updateUI {
    self.backgroundImageView.frame = self.view.bounds;
    
    CGFloat marginTop = UIViewGetHeight(self.view) > 568 ? 90 : 45;
    CGFloat uiFrameOriginX = 40;
    CGFloat uiFrameWidth = UIViewGetWidth(self.view) - 80;
    CGFloat btnLoginMarginTop = 29;

    // iPad适配
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isSmallScreen = UIViewGetWidth(self.view) <= PLVScreenWidth * 1 / 2;
    if (isPad) {
        marginTop = 116;
        btnLoginMarginTop = 70;
        if (!isSmallScreen) {
            uiFrameOriginX = UIViewGetWidth(self.view) / 4;
            uiFrameWidth = UIViewGetWidth(self.view) / 2;
        }
    }
    
    self.lbTitle.frame = CGRectMake(0, marginTop + P_SafeAreaTopEdgeInsets(), UIViewGetWidth(self.view), 42);
    
    CGRect uiFrame = CGRectMake(uiFrameOriginX, UIViewGetBottom(self.lbTitle) + marginTop, uiFrameWidth, 44);
    self.tfChannelId.frame = uiFrame;
    
    uiFrame.origin.y = UIViewGetBottom(self.tfChannelId) + 16;
    self.tfPassword.frame = uiFrame;
    
    uiFrame.origin.y = UIViewGetBottom(self.tfPassword) + 16;
    self.tfNickName.frame = uiFrame;
    
    uiFrame.origin.y = UIViewGetBottom(self.tfNickName) + btnLoginMarginTop;
    self.btnLogin.frame = uiFrame;
    
    // 记住密码
    NSAttributedString *rememberPasswordAttributedTitle = [self.rememberPasswordButton attributedTitleForState:UIControlStateNormal];
    self.rememberPasswordButton.frame = CGRectMake(uiFrameOriginX + 23, UIViewGetBottom(self.btnLogin) + 24, rememberPasswordAttributedTitle.size.width + 22, 22);
    
    // 协议
    NSAttributedString *agreeAttributedTitle = [self.btnAgree attributedTitleForState:UIControlStateNormal];
    self.btnAgree.frame = CGRectMake(UIViewGetLeft(self.rememberPasswordButton), UIViewGetBottom(self.rememberPasswordButton) + 16, 22 + agreeAttributedTitle.size.width, 22);
    NSAttributedString *attrPrivacyPolicy = [agreeAttributedTitle attributedSubstringFromRange:NSMakeRange(7, 6)];
    NSAttributedString *attrPrivacyPolicyRight = [agreeAttributedTitle attributedSubstringFromRange:NSMakeRange(13, 7)];
    
    NSAttributedString *attrUserProtocol = [agreeAttributedTitle attributedSubstringFromRange:NSMakeRange(14, 6)];
    
    uiFrame = self.btnAgree.frame;
    uiFrame.size.width = attrPrivacyPolicy.size.width;
    uiFrame.origin.x = UIViewGetRight(self.btnAgree) - attrPrivacyPolicyRight.size.width - uiFrame.size.width;
    self.btnPrivacyPolicy.frame = uiFrame;
    
    uiFrame.size.width = attrUserProtocol.size.width;
    uiFrame.origin.x = UIViewGetRight(self.btnAgree) - uiFrame.size.width;
    self.btnUserProtocol.frame = uiFrame;
    
}

// 自动填充用户信息
- (void)writeUserInfo {
    NSArray *userInfoArray = [[NSUserDefaults standardUserDefaults]objectForKey:kUserDefaultUserInfo];
    if (userInfoArray && userInfoArray.count) {
        self.tfChannelId.text = userInfoArray[1];
        self.tfPassword.text = userInfoArray[2];
        self.tfNickName.text = userInfoArray[3];
        self.btnLogin.enabled = YES;
    }
}

- (void)loginStreamerRoomWithCompletionHandler:(void (^)(void))completion {
    if (!self.btnAgree.selected) {
        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = PLVProgressHUDModeText;
        hud.label.text = @"请勾选协议";
        hud.detailsLabel.text = nil;
        [hud hideAnimated:YES afterDelay:2.0];
        return;
    }
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self)weakSelf = self;
    [PLVRoomLoginClient loginStreamerRoomWithChannelType:PLVChannelTypePPT | PLVChannelTypeAlone
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

- (void)setTFStyle:(PLVLoginTextField *)tf placeholder:(NSString *)placeholder {
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
        _lbTitle.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:30];
        _lbTitle.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _lbTitle.text = @"手机开播";
        _lbTitle.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_lbTitle];
    }
    
    return _lbTitle;
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        NSString *imageName = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? @"plvls_login_bg_ipad" : @"plvls_login_bg";
        _backgroundImageView = [[UIImageView alloc]initWithImage:[[self class] imageWithImageName:imageName]];
    }
    return _backgroundImageView;
}

- (PLVLoginTextField *)tfChannelId {
    if (! _tfChannelId) {
        _tfChannelId = [[PLVLoginTextField alloc] init];
        _tfChannelId.keyboardType = UIKeyboardTypeNumberPad;
        [self.view addSubview:_tfChannelId];
        
        [self setTFStyle:_tfChannelId placeholder:@"请输入频道号"];
    }
    
    return _tfChannelId;
}

- (PLVLoginTextField *)tfNickName {
    if (! _tfNickName) {
        _tfNickName = [[PLVLoginTextField alloc] init];
        [self.view addSubview:_tfNickName];
        
        [self setTFStyle:_tfNickName placeholder:@"请输入昵称"];
    }
    
    return _tfNickName;
}

- (PLVLoginTextField *)tfPassword {
    if (! _tfPassword) {
        _tfPassword = [[PLVLoginTextField alloc] init];
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
        _btnAgree.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 4, 0);
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

- (UIButton *)rememberPasswordButton {
    if (!_rememberPasswordButton) {
        _rememberPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rememberPasswordButton setImage:[[self class] imageWithImageName:@"plvls_login_ck_normal"] forState:UIControlStateNormal];
        [_rememberPasswordButton setImage:[[self class] imageWithImageName:@"plvls_login_ck_selected"] forState:UIControlStateSelected];
        _rememberPasswordButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 4, 0);
        _rememberPasswordButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_rememberPasswordButton addTarget:self action:@selector(rememberPasswordClickAction) forControlEvents:UIControlEventTouchUpInside];
        
        UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size: 12];
        UIColor *color = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6f);
        NSDictionary *attributes = @{NSFontAttributeName:font,
                                              NSForegroundColorAttributeName:color};
        NSString *string = @" 记住密码";
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
        [_rememberPasswordButton setAttributedTitle:attributedString forState:UIControlStateNormal];

        NSArray *userInfoArray = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultUserInfo];
        if (userInfoArray && userInfoArray.count) {
            BOOL rememberPassword = [userInfoArray.firstObject boolValue];
            if (rememberPassword) {
                _rememberPasswordButton.selected = YES;
            }
        }
    }
    return _rememberPasswordButton;
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

#pragma mark Utils

+ (UIImage *)imageWithImageName:(NSString *)imageName {
    NSString *bundleName = @"LiveStreamer";
    NSBundle *bundle = [NSBundle bundleForClass:[self class]]; // 本代码应该与资源文件存放在同个Bundle下
    NSString *bundlePath = [bundle pathForResource:bundleName ofType:@"bundle"]; // 获取到 LiveStreamer.bundle 所在 Bundle
    NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
    UIImage *image = [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
    return image;
}

/// 计算输入框文本长度
- (double)calculateTextLengthWithString:(NSString *)text {
    double strLength = 0;
    for (int i = 0; i < text.length; i++) {
        NSRange range = NSMakeRange(i, 1);
        NSString *strFromSubStr = [text substringWithRange:range];
        const char * cStringFromstr = [strFromSubStr UTF8String];
        if (cStringFromstr != NULL && strlen(cStringFromstr) == 3){
            strLength += 1;
        } else {
            strLength += 0.5;
        }
    }
    return round(strLength);
}

#pragma mark - Action
- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self.view endEditing:NO];
}

- (void)loginButtonClickAction {
    __weak typeof(self) weakSelf = self;
    [self loginStreamerRoomWithCompletionHandler:^{
        // 记住密码
        if (self.rememberPasswordButton.selected) {
            NSArray *userInfoArray = @[@(YES), self.tfChannelId.text, self.tfPassword.text, self.tfNickName.text];
            [[NSUserDefaults standardUserDefaults] setObject:userInfoArray forKey:kUserDefaultUserInfo];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultUserInfo];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];

        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        [PLVBugReporter setUserIdentifier:roomData.roomUser.viewerId];

        if (roomData.channelType == PLVChannelTypePPT) {
            PLVLSStreamerViewController *vctrl = [[PLVLSStreamerViewController alloc] init];
            vctrl.modalPresentationStyle = UIModalPresentationFullScreen;
            [weakSelf presentViewController:vctrl animated:YES completion:nil];
        } else if (roomData.channelType == PLVChannelTypeAlone) {
            PLVSAStreamerViewController *vctrl = [[PLVSAStreamerViewController alloc] init];
            vctrl.modalPresentationStyle = UIModalPresentationFullScreen;
            [weakSelf presentViewController:vctrl animated:YES completion:nil];
        }
    }];
}

- (void)rememberPasswordClickAction {
    self.rememberPasswordButton.selected = !self.rememberPasswordButton.selected;
}

- (void)agreeClickAction{
    self.btnAgree.selected = !self.btnAgree.isSelected;
    
    [[NSUserDefaults standardUserDefaults] setObject:@(self.btnAgree.isSelected)
                                              forKey:kUserDefaultAgreeUserProtocol];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)privacyPolicyClickAction {
    PLVLiveScenesPrivacyViewController *vctrl = [PLVLiveScenesPrivacyViewController controllerWithPolicyControllerType:PLVPolicyControllerTypePrivacyPolicy];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vctrl];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)userProtocolClickAction {
    PLVLiveScenesPrivacyViewController *vctrl = [PLVLiveScenesPrivacyViewController controllerWithPolicyControllerType:PLVPolicyControllerTypeUserAgreement];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vctrl];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - [ Delegate ]
#pragma mark UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    BOOL enabled = NO;
    enabled = self.tfChannelId.text.length && self.tfPassword.text.length;
    
    self.btnLogin.enabled = enabled;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }
    
    if(range.length + range.location > textField.text.length) {
        return NO;
    }
    
    NSString *toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    int maxLength;
    double newLength;
    if ([textField isEqual:self.tfChannelId]) {
        maxLength = 20;
        newLength = toBeString.length;
    } else if ([textField isEqual:self.tfPassword]) {
        maxLength = 16;
        newLength = toBeString.length;
    } else {
        maxLength = 25;
        newLength = [self calculateTextLengthWithString:toBeString];
    }
    
    if (newLength <= maxLength) {
        return YES;
    } else {
        return NO;
    }
}

@end
