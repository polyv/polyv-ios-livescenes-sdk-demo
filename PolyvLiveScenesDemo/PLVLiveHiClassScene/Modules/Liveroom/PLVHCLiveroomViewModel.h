//
//  PLVHCLiveroomViewModel.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCLiveroomViewModel;

@protocol PLVHCLiveroomViewModelDelegate <NSObject>

@optional

/// 【讲师端、学生端】
///开始上课，通知主页面上课
/// @param success YES 上课成功 需要主页面开始上课的动作 NO上课失败弹窗提示
- (void)liveroomViewModelStartClass:(PLVHCLiveroomViewModel *)viewModel
                            success:(BOOL)success;

/// 【讲师端、学生端】
///下课操作，通知主页面下课操作
/// @param success YES 下课成功 需要主页面开始下课的动作 NO下课失败弹窗提示
- (void)liveroomViewModelFinishClass:(PLVHCLiveroomViewModel *)viewModel
                             success:(BOOL)success;

/// 【讲师端、学生端】
/// 讲师或者学生端 通知主页面需要退出教室的回调 学生端为收到socket消息  讲师端为主动结束课程后
- (void)liveroomViewModelReadyExitClassroom:(PLVHCLiveroomViewModel *)viewModel;

/// 【学生端】
/// 上课倒计时结束后未上课(上课延误) 用于更新状态栏上课状态
- (void)liveroomViewModelDelayInClass:(PLVHCLiveroomViewModel *)viewModel;

/// 【学生端】
/// 学生执行上台连麦操作回调
- (void)liveroomViewModelStudentAnswerJoinLinkMic:(PLVHCLiveroomViewModel *)viewModel;

@end

@interface PLVHCLiveroomViewModel : NSObject

/// PLVHCLiveroomViewModelDelegate代理
@property (nonatomic, weak) id<PLVHCLiveroomViewModelDelegate> delegate;

///【学生端】是否有下节课，退出登录需要用到
@property (nonatomic, assign, readonly) BOOL haveNextClass;

/// 单例方法
+ (instancetype)sharedViewModel;

/// 启动管理器
- (void)setup;

/// 退出前调用，用于资源释放、状态位清零
- (void)clear;

#pragma mark 【讲师端】【学生端】

/// 进入教室
/// 进入教室后 讲师端第一次会有引导页；学生端如果未上课会有倒计时
- (void)enterClassroom;

///开始上课
///点击主页面的开始上课后执行，主要处理了一部分弹窗类和上课逻辑 通过 liveroomViewModelStartClass 回调通知处理完成
- (void)startClass;

///结束课程
///主页面需要结束课程才执行的，主要处理了一部分弹窗类(非强制下课时)和下课逻辑 通过 liveroomViewModelFinishClass 回调通知处理完成
/// @param forced 是否是强制下课(YES 强制下课 NO正常下课)
- (void)finishClassIsForced:(BOOL)forced;

///点击退出教室按钮
///【学生端】如果是在上课中则弹窗提醒，确认后退出。
///【讲师端】如果是在上课中则弹窗提醒，确认后退出（如果已拖堂，讲师没在推流，服务器那边会修改课节的状态为下课）
- (void)exitClassroom;

#pragma mark 【学生端】

/// 学生端收到上台连麦的邀请后进行弹窗提醒。立即上台或等待倒计时结束后上台，执行回调 liveroomViewModelStudentAnswerJoinLinkMic
- (void)remindStudentInvitedJoinLinkMic;

@end

NS_ASSUME_NONNULL_END
