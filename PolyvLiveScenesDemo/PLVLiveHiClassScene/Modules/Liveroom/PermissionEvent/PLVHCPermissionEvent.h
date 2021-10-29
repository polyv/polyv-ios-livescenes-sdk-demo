//
//  PLVHCPermissionEvent.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/8/3.
//  Copyright © 2021 PLV. All rights reserved.
// TEACHER_SET_PERMISSION 事件管理器
// 用于奖杯授予、学生举手事件的发送与事件回调监听

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCPermissionEvent;

@protocol PLVHCPermissionEventDelegate <NSObject>

@optional
/// 举手状态有变化 回调
/// @note 在主线程触发
/// @param raiseHandStatus 举手状态 YES:举手，NO:取消举手(此动作由服务器发起)
/// @param userId 举手的用户Id
/// @param raiseHandCount 举手人数
- (void)permissionEvent:(PLVHCPermissionEvent *)permissionEvent didChangeRaiseHandStatus:(BOOL)raiseHandStatus userId:(NSString *)userId raiseHandCount:(NSInteger)raiseHandCount;

/// 被授予奖杯 回调
/// @note 在主线程触发
/// @param userId 被授予奖杯的用户Id
- (void)permissionEvent:(PLVHCPermissionEvent *)permissionEvent didGrantCupWithUserId:(NSString *)userId;

@end


@interface PLVHCPermissionEvent : NSObject

/// 代理
@property (nonatomic, weak) id<PLVHCPermissionEventDelegate> delegate;

/// 单例方法
+ (instancetype)sharedInstance;

/// 启动管理器
- (void)setup;

/// 退出前调用，用于资源释放、状态位清零
- (void)clear;

/// 发送授予用户奖杯消息，讲师端专用接口
/// @param userId 用户ID
- (BOOL)sendGrantCupMessageWithUserId:(NSString *)userId;

/// 发送举手消息，学生接口
/// @param userId 用户ID
- (BOOL)sendRaiseHandMessageWithUserId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
