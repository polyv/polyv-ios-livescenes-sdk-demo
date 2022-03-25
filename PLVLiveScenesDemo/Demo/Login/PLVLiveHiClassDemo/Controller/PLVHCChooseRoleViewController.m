//
//  PLVHCChooseRoleViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/22.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDemoUtils.h"

// UI
#import "PLVHCChooseRoleViewController.h"
#import "PLVHCTeacherLoginViewController.h"
#import "PLVHCStudentCourseOrLessonLoginViewController.h"

// 模块
#import "PLVBugReporter.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCChooseRoleViewController ()

// 背景图
@property (nonatomic, strong) UIImageView *backgroundImageView;
// 欢迎语
@property (nonatomic, strong) UIImageView *welcomeImageView;
// 标题
@property (nonatomic, strong) UILabel *titleLabel;
// 选择学生
@property (nonatomic, strong) UIButton *chooseStudentButton;
// 选择教师
@property (nonatomic, strong) UIButton *chooseTeacherButton;

@end

@implementation PLVHCChooseRoleViewController


#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat topPadding = 0;
    if (@available(iOS 11, *)) {
        topPadding = self.view.safeAreaInsets.top;
    }
    
    self.backgroundImageView.frame = self.view.bounds;
    self.welcomeImageView.frame = CGRectMake(32, topPadding + 77, 185, 36);
    self.titleLabel.frame = CGRectMake(CGRectGetMinX(self.welcomeImageView.frame), CGRectGetMaxY(self.welcomeImageView.frame) + 9, 182, 37);
    self.chooseStudentButton.frame = CGRectMake(18, CGRectGetMaxY(self.titleLabel.frame) + 31, CGRectGetWidth(self.view.frame) - 18 * 2, 88);
    self.chooseTeacherButton.frame = CGRectMake(CGRectGetMinX(self.chooseStudentButton.frame), CGRectGetMaxY(self.chooseStudentButton.frame) + 16, CGRectGetWidth(self.chooseStudentButton.frame), CGRectGetHeight(self.chooseStudentButton.frame));
    
}

#pragma mark - [ Override ]

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//登录窗口只支持竖屏方向
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.welcomeImageView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.chooseStudentButton];
    [self.view addSubview:self.chooseTeacherButton];
}

- (UIButton *)setupChooseRoleButtonWithTitle:(NSString *)title detail:(NSString *)detail imageName:(NSString *)imageName {
    UIButton *button = [[UIButton alloc] init];
    button.backgroundColor = PLV_UIColorFromRGB(@"#2D3452");
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 16;
    
    /// 角色图片
    UIImageView *roleImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:imageName]];
    roleImageView.frame = CGRectMake(15, (88 - 48) / 2, 48, 48);
    [button addSubview:roleImageView];
    
    /// 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.frame = CGRectMake(CGRectGetMaxX(roleImageView.frame) + 16, 25, 72, 18);
    [button addSubview:titleLabel];
    
    /// 描述
    UILabel *detailLabel = [[UILabel alloc] init];
    detailLabel.text = detail;
    detailLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    detailLabel.frame = CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(titleLabel.frame) + 9, 84, 14);
    detailLabel.textColor = [UIColor whiteColor];
    [button addSubview:detailLabel];
    
    /// 箭头图
    CGFloat superViewWidth = [UIScreen mainScreen].bounds.size.width;
    UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_right_arrow_image"]];
    arrowImageView.contentMode = UIViewContentModeScaleAspectFill;
    arrowImageView.frame = CGRectMake(superViewWidth - 36 - 15 - 14, (88 - 18) / 2, 14, 18);
    [button addSubview:arrowImageView];
    
    return button;
}

#pragma mark Getter & Setter

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_bg_image"]];
    }
    return _backgroundImageView;
}

- (UIImageView *)welcomeImageView {
    if (!_welcomeImageView) {
        _welcomeImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_welcome_image"]];
    }
    return _welcomeImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"请选择你的角色";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:26];
    }
    return _titleLabel;
}

- (UIButton *)chooseStudentButton {
    if (!_chooseStudentButton) {
        _chooseStudentButton = [self setupChooseRoleButtonWithTitle:@"我是学生" detail:@"轻松在线学习" imageName:@"plvhc_student_avatar_image"];
        [_chooseStudentButton addTarget:self action:@selector(chooseStudentButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chooseStudentButton;
}

- (UIButton *)chooseTeacherButton {
    if (!_chooseTeacherButton) {
        _chooseTeacherButton = [self setupChooseRoleButtonWithTitle:@"我是老师" detail:@"轻松在线直播" imageName:@"plvhc_teacher_avatar_image"];
        [_chooseTeacherButton addTarget:self action:@selector(chooseTeacherButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chooseTeacherButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)chooseStudentButtonAction {
    PLVHCStudentCourseOrLessonLoginViewController *loginVC = [[PLVHCStudentCourseOrLessonLoginViewController alloc] init];
    [self.navigationController pushViewController:loginVC animated:YES];
}

- (void)chooseTeacherButtonAction {
    PLVHCTeacherLoginViewController *loginVC = [[PLVHCTeacherLoginViewController alloc] init];
    [self.navigationController pushViewController:loginVC animated:YES];
}

@end
