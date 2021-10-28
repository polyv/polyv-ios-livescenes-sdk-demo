//
//  PLVHCTeacherLoginViewController.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/8.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCTeacherLoginViewController.h"

// UI
#import "PLVHCChooseCompanyViewController.h"
#import "PLVHCChooseLessonViewController.h"
#import "PLVLiveScenesPrivacyViewController.h"
#import "PLVHCAreaCodeChooseView.h"
#import "PLVHCNavigationController.h"
#import "PLVHCLoginCustomButton.h"

// 工具类
#import "PLVHCDemoUtils.h"
#import "PLVHCTeacherLoginManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const kUserDefaultTeacherAccountInfo = @"UserDefaultTeacherAccountInfo";


@interface PLVHCTeacherLoginViewController ()<
UITextFieldDelegate,
UIGestureRecognizerDelegate,
PLVHCAreaCodeChooseViewDelegate>

// 教师背景图
@property (nonatomic, strong) UIImageView *teacherBackgroundImageView;
// 返回按钮
@property (nonatomic, strong) UIButton *backButton;
// 内容视图
@property (nonatomic, strong) UIView *contentView;
// 标题
@property (nonatomic, strong) UILabel *titleLabel;
// 讲师角色图片
@property (nonatomic, strong) UIImageView *titleImageView;
// 账号输入框
@property (nonatomic, strong) UITextField *accountTextField;
// 区号选择
@property (nonatomic, strong) UIButton *chooseAreaCodeButton;
// 当前区号
@property (nonatomic, strong) UILabel *areaCodeLabel;
// 区号选择箭头图片
@property (nonatomic, strong) UIImageView *arrowImageView;
// 区号输入按钮与输入框之间的分割线
@property (nonatomic, strong) UIView *areaCodeLine;
// 账号输入框下划线
@property (nonatomic, strong) UIView *accountLine;
// 密码输入框
@property (nonatomic, strong) UITextField *passwordTextField;
// 密码输入框下划线
@property (nonatomic, strong) UIView *passwordLine;
// 登录按钮
@property (nonatomic, strong) UIButton *loginButton;
// 登录按钮渐变layer
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
// 同意使用协议
@property (nonatomic, strong) PLVHCLoginCustomButton *agreementButton;
// 使用协议文本
@property (nonatomic, strong) UILabel *agreementLabel;
// 跳转到使用协议页按钮
@property (nonatomic, strong) UIButton *readAgreementButton;
// 显示输入框密码
@property (nonatomic, strong) UIButton *showPasswordButton;
// 记住密码按钮
@property (nonatomic, strong) PLVHCLoginCustomButton *rememberAccountButton;
// 记住密码提示文本
@property (nonatomic, strong) UILabel *rememberAccountLabel;
// 勾选协议提示图
@property (nonatomic, strong) UIImageView *agreementTipsImageView;
// 区号选择视图
@property (nonatomic, strong) PLVHCAreaCodeChooseView *areaCodeChooseView;

@end

@implementation PLVHCTeacherLoginViewController


#pragma mark - [ Lift cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self writeTeacherAccountInfo];
    [self addKeyboardEvents];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.teacherBackgroundImageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) / 2.88);
    self.backButton.frame = CGRectMake(24, 53, 36, 36);

    self.contentView.frame = CGRectMake(0, CGRectGetMaxY(self.teacherBackgroundImageView.frame) - 42, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.teacherBackgroundImageView.frame) + 42);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds byRoundingCorners:UIRectCornerTopLeft cornerRadii:CGSizeMake(40,40)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.contentView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.contentView.layer.mask = maskLayer;
    
    self.titleLabel.frame = CGRectMake(34, 33, 104, 37);
    self.titleImageView.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame) + 10, CGRectGetMidY(self.titleLabel.frame) - 24 / 2, 48, 24);
    self.chooseAreaCodeButton.frame = CGRectMake(34, CGRectGetMaxY(self.titleLabel.frame) + 38, 65, 40);
    self.accountLine.frame = CGRectMake(34, CGRectGetMaxY(self.chooseAreaCodeButton.frame) + 5, CGRectGetWidth(self.view.frame) - 34 * 2, 1);
    self.areaCodeLabel.frame = CGRectMake(0, 0, 45, 40);
    self.accountTextField.frame = CGRectMake(CGRectGetMaxX(self.chooseAreaCodeButton.frame) + 10, CGRectGetMaxY(self.titleLabel.frame) + 38, CGRectGetWidth(self.view.frame) - 34 - CGRectGetMaxX(self.chooseAreaCodeButton.frame) - 10, 40);
    self.arrowImageView.frame = CGRectMake(CGRectGetMaxX(self.areaCodeLabel.frame) + 3, CGRectGetMidY(self.areaCodeLabel.frame) - 11 / 2, 12, 11);
    self.areaCodeLine.frame = CGRectMake(CGRectGetMaxX(self.chooseAreaCodeButton.frame) + 5, CGRectGetMidY(self.chooseAreaCodeButton.frame) - 8, 1, 16);
    
    self.passwordTextField.frame = CGRectMake(34, CGRectGetMaxY(self.accountLine.frame) + 38, CGRectGetWidth(self.view.frame) - 34 * 2 - 45, 40);
    self.passwordLine.frame = CGRectMake(34, CGRectGetMaxY(self.passwordTextField.frame) + 5, CGRectGetWidth(self.view.frame) - 34 * 2, 1);
    self.showPasswordButton.frame = CGRectMake(CGRectGetMaxX(self.passwordLine.frame) - 12 - 20, CGRectGetMidY(self.passwordTextField.frame) - 18 / 2, 20, 18);

    
    self.loginButton.frame = CGRectMake(24, CGRectGetMaxY(self.passwordLine.frame)  + 37, CGRectGetWidth(self.view.frame) - 24 * 2, 50);
    self.gradientLayer.frame = self.loginButton.bounds;
    
    self.rememberAccountButton.frame = CGRectMake(CGRectGetMidX(self.contentView.frame) - 100, CGRectGetMaxY(self.loginButton.frame) + 24, 16, 16);
    self.rememberAccountLabel.frame = CGRectMake(CGRectGetMaxX(self.rememberAccountButton.frame) + 4, CGRectGetMidY(self.rememberAccountButton.frame) - 32 / 2, 200, 32);
    
    self.agreementButton.frame = CGRectMake(CGRectGetMinX(self.rememberAccountButton.frame), CGRectGetMaxY(self.rememberAccountButton.frame) + 18, 16, 16);
    self.agreementLabel.frame = CGRectMake(CGRectGetMaxX(self.agreementButton.frame) + 4, CGRectGetMidY(self.agreementButton.frame) - 32 / 2, 75, 32);
    self.readAgreementButton.frame = CGRectMake(CGRectGetMaxX(self.agreementLabel.frame), CGRectGetMinY(self.agreementLabel.frame), 80, 32);
    self.agreementTipsImageView.frame = CGRectMake(CGRectGetMinX(self.agreementButton.frame) - 13.5, CGRectGetMinY(self.agreementButton.frame) - 5 - 55, 200, 55);
    
    _areaCodeChooseView.frame = self.view.bounds;
}

- (void)dealloc {
    [self removeKeyboardEvents];
}

#pragma mark - [ Override ]

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//只支持竖屏方向
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self.view endEditing:NO];
}

- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)loginButtonAction {
    [self.view endEditing:NO];
    if (!self.agreementButton.selected) {
        self.agreementTipsImageView.hidden = NO;
    } else {
        [self loginRequest];
    }
}

- (void)readAgreementButtonAction:(UIButton *)button {
    PLVLiveScenesPrivacyViewController *vctrl = [PLVLiveScenesPrivacyViewController controllerWithPolicyControllerType:PLVPolicyControllerTypeUserAgreement];
    PLVHCNavigationController *nav = [[PLVHCNavigationController alloc] initWithRootViewController:vctrl];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)agreementButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.agreementTipsImageView.hidden = YES;
}

- (void)showPasswordButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.passwordTextField.secureTextEntry = !sender.selected;
}

- (void)areaCodeButtonAction {
    [self.view endEditing:NO];
    [self.areaCodeChooseView showInView:self.view];
}

- (void)textFieldTextChange:(UITextField *)textField {
    BOOL enabled = NO;
    enabled = self.accountTextField.text.length && self.passwordTextField.text.length;
    
    self.loginButton.enabled = enabled;
    self.gradientLayer.hidden = !enabled;
}

- (void)rememberAccountButtonAction:(UIButton *)button {
    button.selected = !button.selected;
}

#pragma mark - [ Delegate ]
#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.accountTextField]) {
        [self.accountTextField resignFirstResponder];
        [self.passwordTextField becomeFirstResponder];
    } else {
        [self.passwordTextField resignFirstResponder];
    }
 
    return YES;
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
   // 获取当前点击所在的view
    NSString *classStr = NSStringFromClass([touch.view class]);
   // 判断是否是cell
    if ([classStr isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return YES;
}

#pragma mark PLVHCAreaCodeChooseViewDelegate
- (void)areaCodeChooseView:(PLVHCAreaCodeChooseView *)areaCodeChooseView didSelectAreaCode:(NSString *)areaCode {
    if ([PLVFdUtil checkStringUseable:areaCode]) {
        self.areaCodeLabel.text = [NSString stringWithFormat:@"+%@", areaCode];
    }
}

#pragma mark - NSNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    UITextField *textField;
    if (self.accountTextField.isFirstResponder) {
        textField = self.accountTextField;
    } else if (self.passwordTextField.isFirstResponder) {
        textField = self.passwordTextField;
    } else {
        return;
    }
    CGFloat keyboardTop = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    //textfiled相对于主视图的位置
    CGRect absoluteFrame = [textField convertRect:textField.bounds toView:self.view];
    CGFloat textFieldMaxY = CGRectGetMaxY(absoluteFrame);
    CGRect currentViewFrame = self.view.frame;

    if (keyboardTop + textFieldMaxY > currentViewFrame.size.height) {
        currentViewFrame.origin.y = currentViewFrame.size.height - keyboardTop - textFieldMaxY;
    } else {
        return;
    }
    
     NSValue *animationDurationValue = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
     NSTimeInterval animationDuration;
     [animationDurationValue getValue:&animationDuration];
     
     [UIView beginAnimations:nil context:NULL];
     [UIView setAnimationDuration:animationDuration];
     
     self.view.frame = currentViewFrame;
     
     [UIView commitAnimations];
 }
 
 - (void)keyboardWillHide:(NSNotification *)notification {
     NSDictionary* userInfo = [notification userInfo];
     NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
     NSTimeInterval animationDuration;
     [animationDurationValue getValue:&animationDuration];
     
     [UIView beginAnimations:nil context:NULL];
     [UIView setAnimationDuration:animationDuration];
     
     [self.view setFrame:[UIScreen mainScreen].bounds];

     [UIView commitAnimations];
 }

#pragma mark - [ Private Method ]

- (void)setupUI {
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    tapGes.delegate = self;
    [self.view addGestureRecognizer:tapGes];
    
    [self.view addSubview:self.teacherBackgroundImageView];
    [self.view addSubview:self.backButton];
    
    /// 顶部内容
    [self.view addSubview:self.contentView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.titleImageView];
    
    /// 输入框与下划线
    [self.contentView addSubview:self.accountTextField];
    [self.contentView addSubview:self.passwordTextField];
    [self.contentView addSubview:self.showPasswordButton];
    [self.contentView addSubview:self.accountLine];
    [self.contentView addSubview:self.passwordLine];
    
    /// 区号选择
    [self.contentView addSubview:self.chooseAreaCodeButton];
    [self.chooseAreaCodeButton addSubview:self.areaCodeLabel];
    [self.chooseAreaCodeButton addSubview:self.arrowImageView];
    [self.contentView addSubview:self.areaCodeLine];

    /// 登录与使用协议
    [self.contentView addSubview:self.loginButton];
    [self.loginButton.layer insertSublayer:self.gradientLayer atIndex:0];
    [self.contentView addSubview:self.rememberAccountButton];
    [self.contentView addSubview:self.rememberAccountLabel];
    [self.contentView addSubview:self.agreementButton];
    [self.contentView addSubview:self.agreementLabel];
    [self.contentView addSubview:self.readAgreementButton];
    [self.contentView addSubview:self.agreementTipsImageView];
}

/// 保存账户信息
- (void)saveTeacherAccountInfo {
    if (self.rememberAccountButton.selected) {
        NSArray *teacherAccountInfoArray = @[self.areaCodeLabel.text, self.accountTextField.text, self.passwordTextField.text];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setValue:teacherAccountInfoArray forKey:kUserDefaultTeacherAccountInfo];
        [userDefaults synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultTeacherAccountInfo];
    }
}

/// 写入账户信息
- (void)writeTeacherAccountInfo {
    NSArray *teacherAccountInfoArray = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultTeacherAccountInfo];
    if ([PLVFdUtil checkArrayUseable:teacherAccountInfoArray]) {
        self.areaCodeLabel.text = teacherAccountInfoArray[0];
        self.accountTextField.text = teacherAccountInfoArray[1];
        self.passwordTextField.text = teacherAccountInfoArray[2];
        
        self.loginButton.enabled = YES;
        self.gradientLayer.hidden = NO;
        self.agreementButton.selected = YES;
        self.rememberAccountButton.selected = YES;
    }
}
 
- (void)addKeyboardEvents {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
 
- (void)removeKeyboardEvents {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark  Getter & Setter

- (UIImageView *)teacherBackgroundImageView {
    if (!_teacherBackgroundImageView) {
        _teacherBackgroundImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_teacher_bg_image"]];
    }
    return _teacherBackgroundImageView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_clear_back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = PLV_UIColorFromRGB(@"#171A38");
    }
    return _contentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"登录账号";
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:26];
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (UIImageView *)titleImageView {
    if (!_titleImageView) {
        _titleImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_title_teacher_image"]];
    }
    return _titleImageView;
}

- (UIButton *)chooseAreaCodeButton {
    if (!_chooseAreaCodeButton) {
        _chooseAreaCodeButton = [[UIButton alloc] init];
        [_chooseAreaCodeButton addTarget:self action:@selector(areaCodeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chooseAreaCodeButton;
}

- (UILabel *)areaCodeLabel {
    if (!_areaCodeLabel) {
        _areaCodeLabel = [[UILabel alloc] init];
        _areaCodeLabel.text = @"+86";
        _areaCodeLabel.textColor = [UIColor whiteColor];
        _areaCodeLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
    }
    return _areaCodeLabel;
}

- (UITextField *)accountTextField {
    if (!_accountTextField) {
        _accountTextField = [[UITextField alloc] init];
        NSString *holderText = @"请输入账号";
        NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:holderText];
        [placeholder addAttribute:NSForegroundColorAttributeName
                    value:PLV_UIColorFromRGBA(@"#EEEEEE",0.5)
                      range:NSMakeRange(0, holderText.length)];
        [placeholder addAttribute:NSFontAttributeName
                      value:[UIFont fontWithName:@"PingFangSC-Regular" size:16]
                      range:NSMakeRange(0, holderText.length)];
        _accountTextField.attributedPlaceholder = placeholder;
        _accountTextField.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _accountTextField.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        _accountTextField.delegate = self;
        [_accountTextField setReturnKeyType:UIReturnKeyNext];
        _accountTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [_accountTextField addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
        UIButton *clearButton = [_accountTextField valueForKey:@"_clearButton"];
        [clearButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_login_clear_btn"] forState:UIControlStateNormal];

    }
    return _accountTextField;
}

- (UITextField *)passwordTextField {
    if (!_passwordTextField) {
        _passwordTextField = [[UITextField alloc] init];
        NSString *holderText = @"请输入密码";
        NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:holderText];
        [placeholder addAttribute:NSForegroundColorAttributeName
                    value:PLV_UIColorFromRGBA(@"#EEEEEE",0.5)
                      range:NSMakeRange(0, holderText.length)];
        [placeholder addAttribute:NSFontAttributeName
                      value:[UIFont fontWithName:@"PingFangSC-Regular" size:16]
                      range:NSMakeRange(0, holderText.length)];
        _passwordTextField.attributedPlaceholder = placeholder;
        _passwordTextField.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _passwordTextField.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        _passwordTextField.secureTextEntry = YES;
        _passwordTextField.delegate = self;
        [_passwordTextField setReturnKeyType:UIReturnKeyDone];
        _passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [_passwordTextField addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
        UIButton *clearButton = [_passwordTextField valueForKey:@"_clearButton"];
        [clearButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_login_clear_btn"] forState:UIControlStateNormal];
    }
    return _passwordTextField;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_arrow_bottom"]];
    }
    return _arrowImageView;
}

- (UIView *)areaCodeLine {
    if (!_areaCodeLine) {
        _areaCodeLine = [[UIView alloc] init];
        _areaCodeLine.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.2);
    }
    return _areaCodeLine;
}

- (UIView *)accountLine {
    if (!_accountLine) {
        _accountLine = [[UIView alloc] init];
        _accountLine.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.2);
    }
    return _accountLine;
}

- (UIView *)passwordLine {
    if (!_passwordLine) {
        _passwordLine = [[UIView alloc] init];
        _passwordLine.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.2);
    }
    return _passwordLine;
}
    
- (UIButton *)loginButton {
    if (!_loginButton) {
        _loginButton = [[UIButton alloc] init];
        [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
        _loginButton.backgroundColor = PLV_UIColorFromRGB(@"#2D3452");
        _loginButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        [_loginButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF",0.5) forState:UIControlStateDisabled];
        [_loginButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF",1) forState:UIControlStateNormal];
        [_loginButton addTarget:self action:@selector(loginButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _loginButton.layer.masksToBounds = YES;
        _loginButton.layer.cornerRadius = 25;
        _loginButton.enabled = NO;
    }
    return _loginButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#00B16C").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#00E78D").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
        _gradientLayer.hidden = YES;
    }
    return _gradientLayer;
}

- (PLVHCLoginCustomButton *)rememberAccountButton {
    if (!_rememberAccountButton) {
        _rememberAccountButton = [[PLVHCLoginCustomButton alloc] init];
        [_rememberAccountButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_agreement_normal"] forState:UIControlStateNormal];
        [_rememberAccountButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_agreement_selected"] forState:UIControlStateSelected];
        [_rememberAccountButton addTarget:self action:@selector(rememberAccountButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rememberAccountButton;
}

- (UILabel *)rememberAccountLabel {
    if (!_rememberAccountLabel) {
        _rememberAccountLabel = [[UILabel alloc] init];
        _rememberAccountLabel.text = @"记住密码";
        _rememberAccountLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _rememberAccountLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5",0.6);
        _rememberAccountLabel.backgroundColor = [UIColor clearColor];
    }
    return _rememberAccountLabel;
}

- (PLVHCLoginCustomButton *)agreementButton {
    if (!_agreementButton) {
        _agreementButton = [[PLVHCLoginCustomButton alloc] init];
        [_agreementButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_agreement_normal"] forState:UIControlStateNormal];
        [_agreementButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_agreement_selected"] forState:UIControlStateSelected];
        [_agreementButton addTarget:self action:@selector(agreementButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _agreementButton;
}

- (UIButton *)showPasswordButton {
    if (!_showPasswordButton) {
        _showPasswordButton = [[UIButton alloc] init];
        [_showPasswordButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_show_password_normal"] forState:UIControlStateNormal];
        [_showPasswordButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_show_password_selected"] forState:UIControlStateSelected];
        [_showPasswordButton addTarget:self action:@selector(showPasswordButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _showPasswordButton;
}
    
- (PLVHCAreaCodeChooseView *)areaCodeChooseView {
    if (!_areaCodeChooseView) {
        _areaCodeChooseView = [[PLVHCAreaCodeChooseView alloc] init];
        _areaCodeChooseView.delegate = self;
    }
    return _areaCodeChooseView;
}

- (UILabel *)agreementLabel {
    if (!_agreementLabel) {
        _agreementLabel = [[UILabel alloc] init];
        _agreementLabel.backgroundColor = [UIColor clearColor];
        _agreementLabel.text = @"已阅读并同意";
        _agreementLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _agreementLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5",0.6);
    }
    return _agreementLabel;
}

- (UIButton *)readAgreementButton {
    if (!_readAgreementButton) {
        _readAgreementButton = [[UIButton alloc] init];
        [_readAgreementButton setTitle:@"《使用协议》" forState:UIControlStateNormal];
        [_readAgreementButton setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
        _readAgreementButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        _readAgreementButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_readAgreementButton addTarget:self action:@selector(readAgreementButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _readAgreementButton;
}

- (UIImageView *)agreementTipsImageView {
    if (!_agreementTipsImageView) {
        _agreementTipsImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_bubble_image"]];
        _agreementTipsImageView.hidden = YES;
        UILabel *label = [[UILabel alloc] init];
        label.text = @"请先勾选协议再进行登录";
        label.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        label.frame = CGRectMake(16, 15, 170, 16);
        label.textColor = PLV_UIColorFromRGB(@"#EEEEEE");
        [_agreementTipsImageView addSubview:label];
    }
    return _agreementTipsImageView;
}


#pragma mark Http Request

- (void)loginRequest {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    [hud.label setText:@"登录中..."];
    
    NSString *mobileString = self.accountTextField.text;
    NSString *passwordString = self.passwordTextField.text;
    NSString *codeString = self.areaCodeLabel.text;
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVClassAPI teacherLoginWithMobile:mobileString password:passwordString code:codeString userId:nil mutipleCompany:^(NSArray * _Nonnull responseArray) {
        [hud hideAnimated:YES];
        [self saveTeacherAccountInfo];
        
        PLVHCChooseCompanyViewController *companyVC = [[PLVHCChooseCompanyViewController alloc] initWithMobile:mobileString password:passwordString companyArray:responseArray];
        [self.navigationController pushViewController:companyVC animated:YES];
    } success:^(NSDictionary * _Nonnull responseDict, NSArray * _Nonnull lessonArray) {
        [hud hideAnimated:YES];
        [self saveTeacherAccountInfo];
        NSString *viewerId = responseDict[@"viewerId"];
        NSString *viewerName = responseDict[@"nickname"];
        NSString *token = responseDict[@"token"];
        PLVHCTokenLoginModel *loginInfo = [[PLVHCTokenLoginModel alloc] init];
        loginInfo.nickname = viewerName;
        loginInfo.userId = viewerId;
        loginInfo.token = token;
        [PLVHCTeacherLoginManager updateTeacherLoginInfo:loginInfo];;
        
        PLVHCChooseLessonViewController *lessonVC = [[PLVHCChooseLessonViewController alloc] initWithViewerId:viewerId viewerName:viewerName teacher:YES lessonArray:lessonArray];
        [self.navigationController pushViewController:lessonVC animated:YES];
    } failure:^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        
        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        hud.mode = PLVProgressHUDModeText;
        hud.label.text = error.localizedDescription;
        hud.detailsLabel.text = nil;
        [hud hideAnimated:YES afterDelay:2.0];
    }];
}

@end
