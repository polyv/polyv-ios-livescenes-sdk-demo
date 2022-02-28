//
//  PLVHCMemberViewModel.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/6.
//  Copyright © 2021 PLV. All rights reserved.
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

/// 成员列表在线成员数据发生变化
- (void)onlineUserListChangedInMemberViewModel:(PLVHCMemberViewModel *)viewModel;

/// 成员列表被踢出成员数据发生变化
- (void)kickedUserListChangedInMemberViewModel:(PLVHCMemberViewModel *)viewModel;

/// 【讲师端】举手状态有变化
/// @param raiseHandStatus 举手状态 YES:举手，NO:取消举手(此动作由服务器发起)
/// @param raiseHandCount 举手人数
- (void)raiseHandStatusChanged:(PLVHCMemberViewModel *)viewModel status:(BOOL)raiseHandStatus count:(NSInteger)raiseHandCount;

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

/// 获取聊天室在线人数列表
- (void)loadOnlineUserList;

/// 返回指定Id的用户数据
/// @note 可返回所有身份的用户数据
- (PLVChatUser * _Nullable)userInListWithUserId:(NSString *)userId;

/// 讲师端踢出学员后调用，代替之前的 'removeUserWithUserId:' 方法
- (void)kickUserWithUserId:(NSString *)userId;

/// 讲师端移入学员后调用
- (void)unkickUser:(PLVChatUser *)user;

/// 讲师端禁言/取消禁言某个学员后调用
- (void)banUserWithUserId:(NSString *)userId banned:(BOOL)banned;

/// 收到授权画笔的事件时，更新用户的 ‘画笔授权状态’
/// @param userId 画笔授权事件相关用户
/// @param auth 是否授权（YES授权 NO取消授权）
- (void)brushPermissionWithUserId:(NSString *)userId auth:(BOOL)auth;

/// 更新成员列表中已连麦用户数据
- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray <PLVLinkMicOnlineUser *>*)linkMicUserArray;

@end

NS_ASSUME_NONNULL_END
