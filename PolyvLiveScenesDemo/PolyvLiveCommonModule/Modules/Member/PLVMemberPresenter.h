//
//  PLVMemberPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/2/5.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PLVLinkMicOnlineUser.h"
#import "PLVLinkMicWaitUser.h"

@class PLVChatUser;

NS_ASSUME_NONNULL_BEGIN

/// 用户排序枚举 (该枚举与 PLVRoomUserType 相互独立；主要用于用户排序)
/// * 注意：
/// 1、不能直接使用数值来赋值使用，因数值可能随业务变化而改变
/// 2、每个枚举之间起码相差二，因业务逻辑需要‘自己在该类中排名最前’
/// 3、数值越小，排名越前，可直接调整该枚举顺序，来决定排序
typedef NS_ENUM(NSInteger, PLVMemberOrderIndex) {
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
    /// 已上麦
    PLVMemberOrderIndex_ConnectedLink = 12,
    /// 举手
    PLVMemberOrderIndex_WaitingLink = 14,
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
@protocol PLVMemberPresenterProtocol <NSObject>

- (void)userListChanged;

@end

@interface PLVMemberPresenter : NSObject

@property (nonatomic, weak) id<PLVMemberPresenterProtocol> delegate;

/// 聊天室在线人数
@property (nonatomic, assign, readonly) NSInteger userCount;

/// 自动获取聊天室在线列表，每间隔20秒获取一次并自动更新成员列表
- (void)start;

/// 清空聊天室成员列表数据，停止间隔20秒自动获取成员列表
- (void)stop;

/// 获取聊天室在线人数列表
- (void)loadOnlineUserList;

/// 聊天室在线人数列表数组
- (NSArray <PLVChatUser *> *)userList;

/// 讲师端踢出学员后调用
- (void)removeUserWithUserId:(NSString *)userId;

/// 讲师端禁言/取消禁言某个学员后调用
- (void)banUserWithUserId:(NSString *)userId banned:(BOOL)banned;

#pragma mark 连麦业务相关
- (void)refreshUserListWithLinkMicWaitUserArray:(NSArray <PLVLinkMicWaitUser *>*)linkMicWaitUserArray;

- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray <PLVLinkMicOnlineUser *>*)linkMicOnlineUserArray;

@end

NS_ASSUME_NONNULL_END
