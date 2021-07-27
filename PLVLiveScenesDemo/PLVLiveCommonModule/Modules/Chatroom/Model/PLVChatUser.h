//
//  PLVChatUser.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PLVRoomUser.h"
#import "PLVLinkMicOnlineUser.h"
#import "PLVLinkMicWaitUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVChatUser : NSObject

/// 是否被禁言
@property (nonatomic, assign) BOOL banned;
/// 特殊身份
@property (nonatomic, assign) BOOL specialIdentity;
/// 用户类型/角色枚举值
@property (nonatomic, assign) PLVRoomUserType userType;
/// 用户头衔
@property (nonatomic, copy) NSString * _Nullable actor;
/// 用户类型/角色字符串
@property (nonatomic, copy)  NSString * _Nullable role;
/// 用户Id
@property (nonatomic, copy) NSString * _Nullable userId;
/// 用户昵称
@property (nonatomic, copy) NSString * _Nullable userName;
/// 用户头像地址
@property (nonatomic, copy) NSString * _Nullable avatarUrl;
/// 用户头衔字体颜色
@property (nonatomic, strong) UIColor * _Nullable actorTextColor;
/// 用户头衔背景颜色
@property (nonatomic, strong) UIColor * _Nullable actorBackgroundColor;

#pragma mark 连麦业务相关
/// 等待连麦 用户模型
@property (nonatomic, weak, nullable) PLVLinkMicWaitUser * waitUser;

/// 等待连麦用户模型 改变Block
///
/// @note 仅在 waitUser 属性值有改变时会触发；将在主线程回调；
@property (nonatomic, copy, nullable) void (^waitUserChangedBlock) (PLVLinkMicWaitUser * currentWaitUser);

/// RTC在线 用户模型
@property (nonatomic, weak, nullable) PLVLinkMicOnlineUser * onlineUser;

/// RTC在线用户模型 改变Block
///
/// @note 仅在 onlineUser 属性值有改变时会触发；将在主线程回调；
@property (nonatomic, copy, nullable) void (^onlineUserChangedBlock) (PLVLinkMicOnlineUser * currentOnlineUser);

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo;

/// 判断是否是特殊用户（非普通观众、带有头衔的用户）
- (BOOL)isUserSpecial;

@end

NS_ASSUME_NONNULL_END
