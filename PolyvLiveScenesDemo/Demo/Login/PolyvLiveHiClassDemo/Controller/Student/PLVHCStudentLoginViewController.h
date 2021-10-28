//
//  PLVHCStudentLoginViewController.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/9.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCStudentLoginViewController : UIViewController

/// 初始化方法
/// @param codeId  课程号或者课节号，从isCourseCode字段区分
/// @param isCourseCode 是否是课程号，
/// @param loginMode 学生登录方式 1. 无条件登录  2.学生码登录 3.白名单登录
- (instancetype)initWithCodeId:(NSString *)codeId
                  isCourseCode:(BOOL)isCourseCode
                     loginMode:(NSInteger)loginMode;

@end

NS_ASSUME_NONNULL_END
