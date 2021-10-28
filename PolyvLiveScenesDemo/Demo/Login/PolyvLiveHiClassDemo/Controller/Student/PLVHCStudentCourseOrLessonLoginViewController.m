//
//  PLVHCStudentCourseOrLessonLoginViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/9.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCStudentCourseOrLessonLoginViewController.h"

//UI
#import "PLVHCStudentLoginView.h"
#import "PLVLiveScenesPrivacyViewController.h"
#import "PLVHCStudentLoginViewController.h"
#import "PLVHCNavigationController.h"

// 工具类
#import "PLVHCDemoUtils.h"

//依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static NSString *const kPLVUserDefaultStudentClassCode = @"kPLVUserDefaultStudentClassCode";

@interface PLVHCStudentCourseOrLessonLoginViewController ()<PLVHCStudentLoginViewDelegate>

// 教师背景图
@property (nonatomic, strong) UIImageView *studentBackgroundImageView;
// 返回按钮
@property (nonatomic, strong) UIButton *backButton;
//课程号或者课节号输入视图
@property (nonatomic, strong) PLVHCStudentLoginView *courseOrLessonLoginView;

@end

@implementation PLVHCStudentCourseOrLessonLoginViewController

#pragma mark - [ Life cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self readStudentClassInfo];
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
    self.courseOrLessonLoginView.frame = CGRectMake(0, viewOriginY, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - viewOriginY);
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
    [self.view addSubview:self.courseOrLessonLoginView];
}

- (void)requestCourseOrLessonSimpleInfo {
    NSString *codeString = self.courseOrLessonLoginView.textField.text;
    if (![PLVFdUtil checkStringUseable:codeString]) {
        [self showHUDWithMessage:@"请输入课程号 / 课节号"];
        return;
    }
    //纯数字为课节号
    BOOL isPureNum = [self isPureNumWithString:codeString];
    NSString *courseCode = isPureNum ? @"" : codeString;
    NSString *lessonId = isPureNum ? codeString : @"";

    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVClassAPI courseOrLessonSimpleInfoWithCourseCode:courseCode lessonId:lessonId success:^(NSDictionary * _Nonnull responseDict) {
        [hud hideAnimated:YES];
        [weakSelf saveStudentClassInfo];
        if (responseDict &&
            [responseDict.allKeys containsObject:@"watchCondition"]) {
            NSString *watchCondition = PLV_SafeStringForDictKey(responseDict, @"watchCondition");
            NSInteger loginMode = 1; //登录方式
            if ([watchCondition isEqualToString:@"NULL"]) {
                loginMode = 1;
            } else if ([watchCondition isEqualToString:@"CODE"]) {
                loginMode = 2;
            } else if ([watchCondition isEqualToString:@"WHITE_LIST"]) {
                loginMode = 3;
            } else {
                [weakSelf showHUDWithMessage:@"不支持的登录方式，请确认后重试"];
                return;
            }
            PLVHCStudentLoginViewController *loginVC = [[PLVHCStudentLoginViewController alloc] initWithCodeId:codeString isCourseCode:!isPureNum loginMode:loginMode];
            [weakSelf.navigationController pushViewController:loginVC animated:YES];
        } else {
            [weakSelf showHUDWithMessage:@"返回参数有误，请重试"];
        }
    } failure:^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        [weakSelf showHUDWithMessage:error.localizedDescription];
    }];
}

/// 保存课程或者课节号
- (void)saveStudentClassInfo {
    NSString *studentClassCode = self.courseOrLessonLoginView.textField.text;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:studentClassCode forKey:kPLVUserDefaultStudentClassCode];
    [userDefaults synchronize];
}

/// 读取课程或者课节号
- (void)readStudentClassInfo {
    NSString *studentClassCode = [[NSUserDefaults standardUserDefaults] objectForKey:kPLVUserDefaultStudentClassCode];
    if (PLV_SafeStringForValue(studentClassCode)) {
        self.courseOrLessonLoginView.textField.text = studentClassCode;
        self.courseOrLessonLoginView.agreementButton.selected = YES;
        self.courseOrLessonLoginView.loginButton.enabled = YES;
    }
}

//判断是课程号还是课节号，课程号为数字+字母，课节号为纯数字
- (BOOL)isPureNumWithString:(NSString *)string {
    if (!string || string.length == 0) return NO;
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    if ([pred evaluateWithObject:string]) {
        return YES;
    }
    return NO;
}

- (void)showHUDWithMessage:(NSString *)message {
    if (!message) return;
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = message;
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

- (PLVHCStudentLoginView *)courseOrLessonLoginView {
    if (!_courseOrLessonLoginView) {
        _courseOrLessonLoginView = [[PLVHCStudentLoginView alloc] initWithType:PLVHCStudentLoginViewType_CourseOrLesson];
        _courseOrLessonLoginView.delegate = self;
    }
    return _courseOrLessonLoginView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tapGestureAction {
    [self.courseOrLessonLoginView.textField endEditing:YES];
}

#pragma mark NSNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    UITextField *textField = self.courseOrLessonLoginView.textField;
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


#pragma mark - [Delegate]

#pragma mark - PLVHCStudentLoginViewDelegate

- (void)studentLoginViewLoginSelected:(PLVHCStudentLoginView *)loginView {
    [self requestCourseOrLessonSimpleInfo];
}

- (void)studentLoginViewAgreementSelected:(PLVHCStudentLoginView *)loginView {
    PLVLiveScenesPrivacyViewController *vctrl = [PLVLiveScenesPrivacyViewController controllerWithPolicyControllerType:PLVPolicyControllerTypeUserAgreement];
    PLVHCNavigationController *nav = [[PLVHCNavigationController alloc] initWithRootViewController:vctrl];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

@end
