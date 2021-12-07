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

/// PLVHCLiveroomViewModel 的回调
/// @note 均在主线程触发
@protocol PLVHCLiveroomViewModelDelegate <NSObject>

@optional

#pragma mark 通用回调

/// 开始上课，通知主页面上课,需要主页面开始上课的动作
- (void)liveroomViewModelStartClass:(PLVHCLiveroomViewModel *)viewModel;

/// 下课操作，通知主页面下课操作
- (void)liveroomViewModelFinishClass:(PLVHCLiveroomViewModel *)viewModel;

/// 上课时长发生变化，仅当前处于上课中时会触发
- (void)liveroomViewModelDurationChanged:(PLVHCLiveroomViewModel *)viewModel duration:(NSInteger)duration;

/// 退出教室
- (void)liveroomViewModelReadyExitClassroom:(PLVHCLiveroomViewModel *)viewModel;

#pragma mark 学生回调

/// 退出教室进入课节号/课程码登录页
- (void)liveroomViewModelReadyExitClassroomToStudentLogin:(PLVHCLiveroomViewModel *)viewModel;

/// 上课倒计时结束后未上课(上课延误) 用于更新状态栏上课状态
- (void)liveroomViewModelDelayInClass:(PLVHCLiveroomViewModel *)viewModel;

/// 进入分组成功
- (void)liveroomViewModelDidJoinGroupSuccess:(PLVHCLiveroomViewModel *)viewModel ackData:(NSDictionary *)data;

/// 进入分组后，获取到分组名称、组长ID、组长名称
- (void)liveroomViewModelDidGroupLeaderUpdate:(PLVHCLiveroomViewModel *)viewModel
                                    groupName:(NSString *)groupName
                                groupLeaderId:(NSString *)groupLeaderId
                              groupLeaderName:(NSString *)groupLeaderName;

/// 结束分组
- (void)liveroomViewModelDidLeaveGroup:(PLVHCLiveroomViewModel *)viewModel ackData:(NSDictionary *)data;

/// 【找老师帮助】请求已取消
- (void)liveroomViewModelDidCancelRequestHelp:(PLVHCLiveroomViewModel *)viewModel;

@end

@interface PLVHCLiveroomViewModel : NSObject

/// PLVHCLiveroomViewModelDelegate代理
@property (nonatomic, weak) id<PLVHCLiveroomViewModelDelegate> delegate;

#pragma mark 【讲师端】【学生端】

/// 单例方法
+ (instancetype)sharedViewModel;

/// 启动管理器
- (void)setup;

/// 退出前调用，用于资源释放、状态位清零
- (void)clear;

/// 进入教室
/// 进入教室后 讲师端第一次会有引导页；学生端如果未上课会有倒计时
- (void)enterClassroom;

///点击退出教室按钮
///【学生端】如果是在上课中则弹窗提醒，确认后退出。
///【讲师端】如果是在上课中则弹窗提醒，确认后退出（如果已拖堂，讲师没在推流，服务器那边会修改课节的状态为下课）
- (void)exitClassroom;

#pragma mark 【教师端】

///开始上课
///点击主页面的开始上课后执行，主要处理了一部分弹窗类和上课逻辑 通过 liveroomViewModelStartClass 回调通知处理完成
- (void)startClass;

///结束课程
///主页面需要结束课程才执行的，主要处理了一部分弹窗类(非强制下课时)和下课逻辑 通过 liveroomViewModelFinishClass 回调通知处理完成
- (void)finishClass;

#pragma mark 【学生端】

/// 学生端收到上台连麦的邀请后进行弹窗提醒，点击立即上台或倒计时结束执行confirmHandler
- (void)remindStudentInvitedJoinLinkMicWithConfirmHandler:(void(^)(void))confirmHandler;;

@end

NS_ASSUME_NONNULL_END
