//
//  PLVMemberPresenter.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/2/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PLVLinkMicOnlineUser.h"
#import "PLVLinkMicWaitUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVChatUser, PLVMemberPresenter;

/// 用户排序枚举 (该枚举与 PLVRoomUserType 相互独立；主要用于用户排序)
/// * 注意：
/// 1、不能直接使用数值来赋值使用，因数值可能随业务变化而改变
/// 2、每个枚举之间起码相差二，可用于以后业务拓展
/// 3、数值越小，排名越前，可直接调整该枚举顺序，来决定排序
/// 4、当用户为当前登录用户，且为特殊身份时，排在所有用户前面；当用户为当前登录用户，但非特殊身份时，排在当前身份用户的最前面
/// 特殊身份用户包括管理员、讲师、嘉宾、助教四种
typedef NS_ENUM(NSInteger, PLVMemberOrderIndex) {
    /// 特殊身份且为当前登录用户
    PLVMemberOrderIndex_SpecialLoginUser = 0,
    /// 管理员
    PLVMemberOrderIndex_Manager   = 2,
    /// 讲师
    PLVMemberOrderIndex_Teacher   = 4,
    /// 嘉宾
    PLVMemberOrderIndex_Guests   = 6,
    /// 参与者（RTC者）
    PLVMemberOrderIndex_Viewer = 8,
    /// 助教
    PLVMemberOrderIndex_Assistant = 10,
    /// 举手
    PLVMemberOrderIndex_WaitingLink = 12,
    /// 已上麦
    PLVMemberOrderIndex_ConnectedLink = 14,
    /// 互动课堂学生
    PLVMemberOrderIndex_SCStudent   = 15,
    /// 学生
    PLVMemberOrderIndex_Student   = 16,
    /// 云课堂学员
    PLVMemberOrderIndex_Slice     = 18,
    /// 虚拟观众
    PLVMemberOrderIndex_Dummy     = 20,
    /// 未知
    PLVMemberOrderIndex_Unknown   = 22
};

/* PLVMemberPresenter 的协议 */
@protocol PLVMemberPresenterDelegate <NSObject>

- (void)userListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter;

@optional

/// 在线成员数据发生变化
- (void)kickedUserListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter;

/// 踢出成员数据发生变化
- (NSArray *)currentOnlineUserListInMemberPresenter:(PLVMemberPresenter *)memberPresenter;

/// 获取当前等待用户列表
- (NSArray *)currentWaitUserListInMemberPresenter:(PLVMemberPresenter *)memberPresenter;

@end

@interface PLVMemberPresenter : NSObject

@property (nonatomic, weak) id<PLVMemberPresenterDelegate> delegate;

/// 是否监听维护踢出用户列表，默认为NO
/// 该属性应在调用 'start' 方法之前完成配置
@property (nonatomic, assign) BOOL monitorKickUser;

/// 聊天室在线人数
@property (nonatomic, assign, readonly) NSInteger userCount;

/// 聊天室移出人数
@property (nonatomic, assign, readonly) NSInteger kickedCount;

/// 自动获取聊天室在线列表，每间隔20秒获取一次并自动更新成员列表
- (void)start;

/// 清空聊天室成员列表数据，停止间隔20秒自动获取成员列表
- (void)stop;

/// 获取聊天室在线人数列表
- (void)loadOnlineUserList;

/// 聊天室在线人数列表数组
- (NSArray <PLVChatUser *> *)userList;

/// 聊天室移出成员列表数组
- (NSArray <PLVChatUser *> *)kickedUserList;

/// 返回指定Id的用户数据
- (PLVChatUser * _Nullable)userInListWithUserId:(NSString *)userId;

/// 讲师端踢出学员后调用，代替之前的 'removeUserWithUserId:' 方法
- (void)kickUserWithUserId:(NSString *)userId;

/// 讲师端移入学员后调用
- (void)unkickUser:(PLVChatUser *)user;

/// 讲师端禁言/取消禁言某个学员后调用
- (void)banUserWithUserId:(NSString *)userId banned:(BOOL)banned;

/// 更新成员列表中等待连麦用户数据
- (void)refreshUserListWithLinkMicWaitUserArray:(NSArray <PLVLinkMicWaitUser *>*)linkMicWaitUserArray;

/// 更新成员列表中已连麦用户数据
- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray <PLVLinkMicOnlineUser *>*)linkMicOnlineUserArray;

@end

NS_ASSUME_NONNULL_END
