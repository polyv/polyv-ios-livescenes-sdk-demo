//
//  PLVLSMemberSheet.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/29.
//  Copyright © 2021 PLV. All rights reserved.
//
// 成员列表弹层

#import "PLVLSSideSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVChatUser, PLVLSMemberSheet;

@protocol PLVLSMemberSheetDelegate <NSObject>

/// 点击全员下麦按钮触发回调
/// @param changeBlock 是否【全员下麦】成功 block，needChange-YES 表示成功
- (void)didTapCloseAllUserLinkMicInMemberSheet:(PLVLSMemberSheet *)memberSheet
                                   changeBlock:(void(^ _Nullable)(BOOL needChange))changeBlock;

/// 点击全员静音按钮触发回调
/// @param mute YES-全员静音 NO-取消全员静音
/// @param changeBlock 是否【全员静音/取消全员静音】成功 block，needChange-YES 表示成功
- (void)didTapMuteAllUserMicInMemberSheet:(PLVLSMemberSheet *)memberSheet
                                     mute:(BOOL)mute
                              changeBlock:(void(^)(BOOL needChange))changeBlock;

/// 点击连麦设置按钮触发回调
- (void)didTapLinkMicSettingInMemberSheet:(PLVLSMemberSheet *)memberSheet;

/// 禁言/取消禁言某个用户
/// @param userId 禁言/取消禁言用户ID
/// @param banned YES-禁言 NO-取消禁言
- (void)banUsersInMemberSheet:(PLVLSMemberSheet *)memberSheet
                       userId:(NSString *)userId
                       banned:(BOOL)banned;

/// 踢出某个用户
/// @param userId 踢出用户ID
- (void)kickUsersInMemberSheet:(PLVLSMemberSheet *)memberSheet
                        userId:(NSString *)userId;

/// 邀请某个用户加入连麦
/// @param user 邀请用户的数据
- (void)inviteUserJoinLinkMicInMemberSheet:(PLVLSMemberSheet *)memberSheet chatUser:(PLVChatUser *)user;

/// 拨号入会列表已更新
- (void)sipUserListDidChangedInMemberSheet:(PLVLSMemberSheet *)memberSheet;

@optional
/// 搜索文本变化回调
/// @param memberSheet 成员列表弹层
/// @param searchText 搜索文本
- (void)memberSheet:(PLVLSMemberSheet *)memberSheet didChangeSearchText:(NSString *)searchText;

/// 取消搜索回调
/// @param memberSheet 成员列表弹层
- (void)memberSheetDidCancelSearch:(PLVLSMemberSheet *)memberSheet;

@end

@interface PLVLSMemberSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSMemberSheetDelegate> delegate;

@property (nonatomic, assign) BOOL mediaGranted; /// 当前是否对麦克风和摄像头进行授权

@property (nonatomic, assign) BOOL removeAllAudiencesButtonEnable;

/// 初始化方法
/// @param userList 当前成员列表数据
/// @param userCount 在线成员总数（在线成员总数不一定等于数组userList的count）
- (instancetype)initWithUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount;

/// 开始上课/结束上课【嘉宾】
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

/// 更新成员列表弹层所需数据
/// @param userList 成员列表数据
/// @param userCount 在线成员总数
/// @param onlineCount 连麦人数
- (void)updateUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount onlineCount:(NSInteger)onlineCount;

/// 更新本地用户主讲权限
/// @param auth 本地用户是否授权主讲
- (void)updateLocalUserSpeakerAuth:(BOOL)auth;

/// 是否开启音视频连麦
/// @param enable YES 开启，NO关闭
- (void)enableAudioVideoLinkMic:(BOOL)enable;

/// 显示SIP来电提醒
- (void)showNewIncomingTelegramView;

/// 设置搜索状态
/// @param isSearching 是否正在搜索
- (void)setSearching:(BOOL)isSearching;

/// 更新搜索结果
/// @param searchResults 搜索结果列表
- (void)updateSearchResults:(NSArray <PLVChatUser *> *)searchResults;

@end

NS_ASSUME_NONNULL_END
