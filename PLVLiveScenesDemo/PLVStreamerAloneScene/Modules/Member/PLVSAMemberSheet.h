//
//  PLVSAMemberSheet.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVChatUser, PLVSAMemberSheet;

@protocol PLVSAMemberSheetDelegate <NSObject>

- (void)bandUsersInMemberSheet:(PLVSAMemberSheet *)memberSheet withUserId:(NSString *)userId banned:(BOOL)banned;

- (void)kickUsersInMemberSheet:(PLVSAMemberSheet *)memberSheet withUserId:(NSString *)userId;

@end

@interface PLVSAMemberSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAMemberSheetDelegate> delegate;

/// 初始化方法
/// @param userList 当前成员列表数据
/// @param userCount 在线成员总数（在线成员总数不一定等于数组userList的count）
- (instancetype)initWithUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount;

/// 更新成员列表弹层所需数据
/// @param userList 成员列表数据
/// @param userCount 在线成员总数
/// @param onlineCount 连麦人数
- (void)updateUserList:(NSArray <PLVChatUser *> *)userList
             userCount:(NSInteger)userCount
           onlineCount:(NSInteger)onlineCount;

@end

NS_ASSUME_NONNULL_END
