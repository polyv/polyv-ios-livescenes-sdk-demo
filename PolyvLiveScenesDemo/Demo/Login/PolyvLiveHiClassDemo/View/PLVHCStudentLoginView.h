//
//  PLVHCStudentLoginView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/9.
//  Copyright © 2021 polyv. All rights reserved.
//
// - 学生登录时输入视图包含四种样式

#import <UIKit/UIKit.h>
#import "PLVHCLoginCustomButton.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVHCStudentLoginViewType) {
    PLVHCStudentLoginViewType_CourseOrLesson = 0, //课程号或者课节号登录查询
    PLVHCStudentLoginViewType_Null, //无条件观看
    PLVHCStudentLoginViewType_Code, //验证码观看
    PLVHCStudentLoginViewType_WhiteList, //白名单观看
};

@class PLVHCStudentLoginView;

@protocol PLVHCStudentLoginViewDelegate <NSObject>

@optional

/// 选择查看协议的回调
/// @param loginView 当前view视图
- (void)studentLoginViewAgreementSelected:(PLVHCStudentLoginView *)loginView;

/// 登录按钮点击的回调
/// @param loginView 当前view视图
- (void)studentLoginViewLoginSelected:(PLVHCStudentLoginView *)loginView;

@end

@interface PLVHCStudentLoginView : UIView

///学生登录视图代理
@property(nonatomic, weak) id<PLVHCStudentLoginViewDelegate> delegate;
///登录视图的输入按钮分别对应四种样式的:课程号或者课节号、输入学生码、设置名称
@property (nonatomic, strong) UITextField *textField;
///密码输入框 仅在 PLVHCStudentLoginViewType_Code 时生效
@property (nonatomic, strong) UITextField *passwordTextField;
///登录按钮
@property (nonatomic, strong) UIButton *loginButton;
/// 同意使用协议 仅在 PLVHCStudentLoginViewType_Code 时生效
@property (nonatomic, strong) PLVHCLoginCustomButton *agreementButton;

#pragma mark - Methods

/// 初始化方法，根据样式初始化view
/// @param type 页面样式
- (instancetype)initWithType:(PLVHCStudentLoginViewType)type;

@end

NS_ASSUME_NONNULL_END
