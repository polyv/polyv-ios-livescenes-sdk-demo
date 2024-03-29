//
//  PLVLinkMicWaitUser.h
//  PLVLiveStreamerDemo
//
//  Created by Lincal on 2021/4/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVLinkMicUserDefine.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatUser, PLVLinkMicWaitUser;

/// 回调定义
///
/// [状态] 用户的 ’连麦状态‘ 改变Block
typedef void (^PLVLinkMicWaitUserLinkMicStatusChangedBlock)(PLVLinkMicWaitUser * waitUser);
/// [事件] 用户模型 即将销毁 回调Block
typedef void (^PLVLinkMicWaitUserWillDeallocBlock)(PLVLinkMicWaitUser * waitUser);

/// 等待连麦用户模型
///
/// @note 描述及代表了一位 等待连麦 的用户
@interface PLVLinkMicWaitUser : NSObject

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// [事件] 用户模型 即将销毁 回调Block
///
/// @note 不保证在主线程回调
@property (nonatomic, copy, nullable) PLVLinkMicWaitUserWillDeallocBlock willDeallocBlock;

/// [状态] 用户 连麦状态改变 回调Block
///
/// @note 不保证在主线程回调
@property (nonatomic, copy, nullable) PLVLinkMicWaitUserLinkMicStatusChangedBlock linkMicStatusBlock;

#pragma mark 数据
/// 用户聊天室Id
@property (nonatomic, copy, readonly) NSString * userId;

/// 用户连麦Id
@property (nonatomic, copy, readonly) NSString * linkMicUserId;

/// 用户头衔
@property (nonatomic, copy, nullable, readonly) NSString * actor;

/// 用户昵称 (若是本地用户，将自动拼接‘(我)‘后缀)
@property (nonatomic, copy, nullable, readonly) NSString * nickname;

/// 用户头像
@property (nonatomic, copy, nullable, readonly) NSString * avatarPic;

/// 用户类型
@property (nonatomic, assign, readonly) PLVSocketUserType userType;

/// 原始的 用户数据字典
@property (nonatomic, strong, readonly) NSDictionary * originalUserDict;

#pragma mark 状态
/// 用户 当前是否举手 (注意：仅在 [userType] 为Guests时，此值有意义)
@property (nonatomic, assign, readonly) BOOL currentRaiseHand;

/// 用户 当前是否答复同意加入 (注意：仅在 [userType] 为Guests时，此值有意义)
@property (nonatomic, assign, readonly) BOOL currentAnswerAgreeJoin;

/// 用户 当前的连麦状态 (注意：仅在 [userType] 为Guests、slice、student时，此值有意义)
@property (nonatomic, assign, readonly) PLVLinkMicUserLinkMicStatus linkMicStatus;

#pragma mark - [ 方法 ]
#pragma mark 创建
/// 通过数据字典创建模型
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

/// 通过 PLVChatUser 数据模型 创建模型 (适用于远端用户)
+ (instancetype)modelWithChatUser:(PLVChatUser *)chatUser;

#pragma mark 状态更新
/// 更新用户的 ‘当前举手状态值’
///
/// @note 仅在 [userType] 为Guests、slice、student时，调用此方法生效；
- (void)updateUserCurrentRaiseHand:(BOOL)raiseHand;

/// 更新用户的 ‘当前是否答复同意加入状态值’
///
/// @note 仅在 [userType] 为Guests时，调用此方法生效；
- (void)updateUserCurrentAnswerAgreeJoin:(BOOL)answerAgreeJoin;

/// 更新用户的 ‘当前连麦状态值’
///
/// @note 仅在 [userType] 为Guests、slice、student时，调用此方法生效；
- (void)updateUserCurrentLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus;

#pragma mark 多接收方回调配置
/// 使用 blockKey 添加一个 ’用户模型 即将销毁‘ 回调Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [willDeallocBlock]，将更加便捷；
///       (2) 具体回调规则，与 [willDeallocBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’用户模型 即将销毁‘ 回调Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addWillDeallocBlock:(PLVLinkMicWaitUserWillDeallocBlock)strongBlock blockKey:(id)weakBlockKey;

@end

NS_ASSUME_NONNULL_END
