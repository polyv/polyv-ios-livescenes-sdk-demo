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

/// 邀请某个用户加入连麦
/// @param user 邀请用户的数据
- (void)inviteUserJoinLinkMicInMemberSheet:(PLVSAMemberSheet *)memberSheet chatUser:(PLVChatUser *)user;

@end

@protocol PLVSAMemberSheetSearchDelegate <NSObject>

@optional
/// 开始搜索
/// @param keyword 搜索关键词
- (void)memberSheet:(PLVSAMemberSheet *)memberSheet didStartSearchWithKeyword:(NSString *)keyword;

/// 取消搜索
- (void)memberSheetDidCancelSearch:(PLVSAMemberSheet *)memberSheet;

/// 搜索状态变化
/// @param isSearching 是否正在搜索
- (void)memberSheet:(PLVSAMemberSheet *)memberSheet didChangeSearchState:(BOOL)isSearching;

/// 搜索结果更新
/// @param results 搜索结果
- (void)memberSheet:(PLVSAMemberSheet *)memberSheet didUpdateSearchResults:(NSArray<PLVChatUser *> *)results;

@end

@interface PLVSAMemberSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAMemberSheetDelegate> delegate;
@property (nonatomic, weak) id<PLVSAMemberSheetSearchDelegate> searchDelegate;

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

/// 开始上课/结束上课【嘉宾】
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

/// 是否开启音视频连麦
/// @param enable YES 开启，NO关闭
- (void)enableAudioVideoLinkMic:(BOOL)enable;

/// 更新搜索状态（由外部调用）
/// @param isSearching 是否正在搜索
- (void)updateSearchState:(BOOL)isSearching;

/// 更新搜索结果（由外部调用）
/// @param results 搜索结果
- (void)updateSearchResults:(NSArray<PLVChatUser *> *)results;

@end

NS_ASSUME_NONNULL_END
