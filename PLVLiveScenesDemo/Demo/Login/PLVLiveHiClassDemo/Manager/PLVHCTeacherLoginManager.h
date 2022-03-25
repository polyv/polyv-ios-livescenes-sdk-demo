//
//  PLVHCTeacherLoginManager.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/9/6.
//  Copyright © 2021 PLV. All rights reserved.
//
// 讲师登录模块管理 token缓存处理，控制器导航

#import <Foundation/Foundation.h>
#import "PLVHCTokenLoginModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCTeacherLoginManager : NSObject

///讲师登录信息相关的
///讲师的登录信息，如果登录就会保存有token信息，上课后关联lessonId，下课后清空lessonId；
+ (PLVHCTokenLoginModel *)readLoginInfo;
///保存更新登录信息
+ (void)updateTeacherLoginInfo:(PLVHCTokenLoginModel *)loginInfo;
///更新登录关联的课节ID
+ (void)updateTeacherLoginLessonId:(NSString * _Nullable)lessonId;
///清除登录信息
+ (void)clearTeacherLoginInfo;

/// 控制器导航相关的
///讲师打开app后加载主页面
+ (void)loadMainViewController;
/// 控制器 - 讲师退出登录
+ (void)teacherLogoutFromViewController:(UIViewController *)viewController;
/// 控制器 - 讲师退出教室
+ (void)teacherExitClassroomFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
