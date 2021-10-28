//
//  PLVHCStudentLoginViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/9.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCStudentLoginViewController.h"

//UI
#import "PLVHCStudentLoginView.h"
#import "PLVLiveScenesPrivacyViewController.h"
#import "PLVHCChooseLessonViewController.h"
#import "PLVHCHiClassViewController.h"

// 工具类
#import "PLVHCDemoUtils.h"

// 模块
#import "PLVRoomLoginClient.h"

//依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>


static NSString *const kPLVUserDefaultStudentLoginNickname = @"kPLVUserDefaultStudentLoginNickname";

@interface PLVHCStudentLoginViewController ()<PLVHCStudentLoginViewDelegate>

// 教师背景图
@property (nonatomic, strong) UIImageView *studentBackgroundImageView;
// 返回按钮
@property (nonatomic, strong) UIButton *backButton;
//登录操作视图
@property (nonatomic, strong) PLVHCStudentLoginView *loginView;
//登录模式
@property (nonatomic, assign) PLVHCStudentLoginViewType loginMode;
//是否是课程号登录
@property (nonatomic, assign) BOOL isCourseCode;
//编号可能是课程号或者课节号 通过isCourseCode字段区分
@property (nonatomic, copy) NSString *codeId;

@end

@implementation PLVHCStudentLoginViewController

#pragma mark - [ Life cycle ]

- (instancetype)initWithCodeId:(NSString *)codeId
                  isCourseCode:(BOOL)isCourseCode
                     loginMode:(NSInteger)loginMode {
    self = [super init];
    if (self) {
        self.codeId = codeId;
        self.isCourseCode = isCourseCode;
        self.loginMode = MIN(loginMode, PLVHCStudentLoginViewType_WhiteList);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self addKeyboardEvents];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat bottomPadding = 0;
    if (@available(iOS 11.0, *)) {
        bottomPadding = self.view.safeAreaInsets.bottom;
    }
    self.studentBackgroundImageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 292);
    self.backButton.frame = CGRectMake(24, 53, 36, 36);
    CGFloat viewOriginY = CGRectGetMaxY(self.studentBackgroundImageView.frame) - 42;
    self.loginView.frame = CGRectMake(0, viewOriginY, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - viewOriginY);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (void)dealloc {
    [self removeKeyboardEvents];
}

#pragma mark - [ Override ]

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//只支持竖屏方向
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
    [self.view addGestureRecognizer:tapGesture];
    [self.view addSubview:self.studentBackgroundImageView];
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.loginView];
    if (_loginMode == PLVHCStudentLoginViewType_Null ||
        _loginMode == PLVHCStudentLoginViewType_Code) {
        NSString *nickname = [self readStudentNickname];
        if ([PLVFdUtil checkStringUseable:nickname]) {
            self.loginView.textField.text = nickname;
            self.loginView.loginButton.enabled = YES;
        }
    }
}

- (void)studentLoginRequest {
    NSString *courseCode = _isCourseCode ? _codeId : @"";
    NSString *lessonId = _isCourseCode ? @"" : _codeId;
    
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self) weakSelf = self;
    void(^failureBlock)(NSString *errorMessage) = ^(NSString *errorMessage) {
        [hud hideAnimated:YES];
        [weakSelf showHUDWithMessage:errorMessage];
    };
    void(^loginSuccessBlock)(NSDictionary *responseDict, NSArray *lessonArray) = ^(NSDictionary *responseDict, NSArray *lessonArray) { // 登录成功页面跳转回调
        NSString *viewerId = responseDict[@"viewerId"];
        NSString *viewerName = responseDict[@"nickname"];
        if (weakSelf.isCourseCode) { //课程号登录跳转到选择课节号页面
            [hud hideAnimated:YES];
            
            PLVHCChooseLessonViewController *lessonVC = [[PLVHCChooseLessonViewController alloc] initWithViewerId:viewerId viewerName:viewerName teacher:NO lessonArray:lessonArray];
            lessonVC.courseCode = courseCode;
            lessonVC.lessonId = lessonId;
            [weakSelf.navigationController pushViewController:lessonVC animated:YES];
        } else { //课节号登录
            [PLVRoomLoginClient watcherEnterHiClassWithViewerId:viewerId
                                                        viewerName:viewerName
                                                        courseCode:@""
                                                          lessonId:lessonId
                                                        completion:^{
                PLVHCHiClassViewController *vctrl = [[PLVHCHiClassViewController alloc] init];
                //避免跳转时卡顿
                plv_dispatch_main_async_safe(^{
                    [hud hideAnimated:YES];
                    [weakSelf.navigationController pushViewController:vctrl animated:YES];
                    [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
                })
            } failure:failureBlock];
        }
    };

    if (_loginMode == PLVHCStudentLoginViewType_Null) {
        [self studentNoneConditionLoginWithCourseCode:courseCode lessonId:lessonId successHandler:loginSuccessBlock failure:failureBlock];
    } else if (_loginMode == PLVHCStudentLoginViewType_Code) {
        [self studentVerifyCodeLoginWithCourseCode:courseCode lessonId:lessonId successHandler:loginSuccessBlock failure:failureBlock];
    }  else if (_loginMode == PLVHCStudentLoginViewType_WhiteList) {
        [self studentWhiteListLoginWithCourseCode:courseCode lessonId:lessonId successHandler:loginSuccessBlock failure:failureBlock];
    }
}

- (void)studentNoneConditionLoginWithCourseCode:(NSString * _Nullable)courseCode
                                       lessonId:(NSString * _Nullable)lessonId
                                 successHandler:(void (^)(NSDictionary *responseDict, NSArray *lessonArray))successHandler
                                        failure:(void (^)(NSString *errorMessage))failure {
    NSString *name = self.loginView.textField.text;
    if (![PLVFdUtil checkStringUseable:name]) {
        failure ? failure(@"请设置你的名称") : nil;
        return;
    }
    [self updateStudentNickname:name];
    [PLVLiveVClassAPI watcherVerifyNoneWithCourseCode:courseCode lessonId:lessonId name:name success:successHandler failure:^(NSError * _Nonnull error) {
        failure ? failure(error.localizedDescription) : nil;
    }];
}

- (void)studentVerifyCodeLoginWithCourseCode:(NSString * _Nullable)courseCode
                                    lessonId:(NSString * _Nullable)lessonId
                              successHandler:(void (^)(NSDictionary *responseDict, NSArray *lessonArray))successHandler
                                     failure:(void (^)(NSString *errorMessage))failure {
    NSString *name = self.loginView.textField.text;
    NSString *code = self.loginView.passwordTextField.text;
    if (![PLVFdUtil checkStringUseable:name] ||
        ![PLVFdUtil checkStringUseable:code]) {
        failure ? failure(@"请输入你的验证信息") : nil;
        return;
    }
    [self updateStudentNickname:name];
    [PLVLiveVClassAPI watcherVerifyCodeWithCourseCode:courseCode lessonId:lessonId name:name code:code success:successHandler failure:^(NSError * _Nonnull error) {
        failure ? failure(error.localizedDescription) : nil;
    }];
}

- (void)studentWhiteListLoginWithCourseCode:(NSString * _Nullable)courseCode
                                   lessonId:(NSString * _Nullable)lessonId
                             successHandler:(void (^)(NSDictionary *responseDict, NSArray *lessonArray))successHandler
                                    failure:(void (^)(NSString *errorMessage))failure {
    NSString *studentCode = self.loginView.textField.text;
    if (![PLVFdUtil checkStringUseable:studentCode]) {
        failure ? failure(@"请输入学生码") : nil;
        return;
    }
    [PLVLiveVClassAPI watcherVerifyWhiteListWithCourseCode:courseCode lessonId:lessonId studentCode:studentCode success:successHandler failure:^(NSError * _Nonnull error) {
        failure ? failure(error.localizedDescription) : nil;
    }];
}

/// 学生昵称
- (void)updateStudentNickname:(NSString *)nickname {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:nickname forKey:kPLVUserDefaultStudentLoginNickname];
    [userDefaults synchronize];
}

/// 读取学生昵称
- (NSString *)readStudentNickname {
    NSString *nickname = [[NSUserDefaults standardUserDefaults] stringForKey:kPLVUserDefaultStudentLoginNickname];
    if ([PLVFdUtil checkStringUseable:nickname]) {
        return nickname;
    }
    return nil;
}

- (void)showHUDWithMessage:(NSString *)message {
    if (!message) return;
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = message;
    hud.detailsLabel.text = nil;
    [hud hideAnimated:YES afterDelay:2.0];
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

#pragma mark NSNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    //根据类型判断需要设置的textfield偏移
    UITextField *textField;
    if (self.loginView.textField.isFirstResponder) {
        textField = self.loginView.textField;
    } else if (self.loginView.passwordTextField.isFirstResponder) {
        textField = self.loginView.passwordTextField;
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

#pragma mark  Getter & Setter

- (UIImageView *)studentBackgroundImageView {
    if (!_studentBackgroundImageView) {
        _studentBackgroundImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_student_bg_image"]];
    }
    return _studentBackgroundImageView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_student_loginback_btn"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (PLVHCStudentLoginView *)loginView {
    if (!_loginView) {
        _loginView = [[PLVHCStudentLoginView alloc] initWithType:_loginMode];
        _loginView.delegate = self;
    }
    return _loginView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tapGestureAction {
    [self.loginView.textField endEditing:YES];
    if (_loginMode == PLVHCStudentLoginViewType_Code) {
        [self.loginView.passwordTextField endEditing:YES];
    }
}

#pragma mark - [Delegate]

#pragma mark - PLVHCStudentLoginViewDelegate

- (void)studentLoginViewLoginSelected:(PLVHCStudentLoginView *)loginView {
    [self studentLoginRequest];
}

@end
