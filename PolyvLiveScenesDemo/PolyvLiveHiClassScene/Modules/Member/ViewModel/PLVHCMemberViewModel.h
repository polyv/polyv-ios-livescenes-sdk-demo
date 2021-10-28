//
//  PLVHCMemberViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/6.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVMemberPresenter.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVHCMemberViewModel, PLVLinkMicOnlineUser;

/*
 PLVHCMemberViewModel的协议
 @note 在主线程回调
 */
@protocol PLVHCMemberViewModelDelegate <NSObject>

- (void)onlineUserListChangedInMemberViewModel:(PLVHCMemberViewModel *)viewModel;

- (void)kickedUserListChangedInMemberViewModel:(PLVHCMemberViewModel *)viewModel;

@end

@interface PLVHCMemberViewModel : NSObject

/// PLVHCMemberViewModel代理
@property (nonatomic, weak) id<PLVHCMemberViewModelDelegate> delegate;

/// 成员common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong, readonly) PLVMemberPresenter *presenter;

/// 聊天室在线人数
@property (nonatomic, assign, readonly) NSInteger onlineCount;

/// 聊天室移出人数
@property (nonatomic, assign, readonly) NSInteger kickedCount;

/// 聊天室在线学生列表
@property (nonatomic, copy, readonly) NSArray <PLVChatUser *> *onlineUserArray;

/// 聊天室移出学生列表
@property (nonatomic, copy, readonly) NSArray <PLVChatUser *> *kickedUserArray;

#pragma mark API

/// 单例方法
+ (instancetype)sharedViewModel;

/// 创建成员模块presenter，若已上课则开始定时获取成员数据
- (void)setup;

/// 退出前调用，用于资源释放、状态位清零
- (void)clear;

/// 开始获取成员列表数据并开启自动更新
- (void)start;

/// 停止定时获取成员列表数据
- (void)stop;

/// 返回指定Id的用户数据
/// @note 可返回所有身份的用户数据
- (PLVChatUser * _Nullable)userInListWithUserId:(NSString *)userId;

/// 讲师端踢出学员后调用，代替之前的 'removeUserWithUserId:' 方法
- (void)kickUserWithUserId:(NSString *)userId;

/// 讲师端移入学员后调用
- (void)unkickUser:(PLVChatUser *)user;

/// 讲师端禁言/取消禁言某个学员后调用
- (void)banUserWithUserId:(NSString *)userId banned:(BOOL)banned;

/// 更新成员列表中已连麦用户数据
- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray <PLVLinkMicOnlineUser *>*)linkMicUserArray;

@end

NS_ASSUME_NONNULL_END
