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

/// 点击全体下麦按钮触发回调
/// @param changeBlock 是否【全体下麦】成功 block，needChange-YES 表示成功
- (void)didTapCloseAllUserLinkMicInMemberSheet:(PLVLSMemberSheet *)memberSheet
                                   changeBlock:(void(^ _Nullable)(BOOL needChange))changeBlock;

/// 点击全体静音按钮触发回调
/// @param mute YES-全体静音 NO-取消全体静音
/// @param changeBlock 是否【全体静音/取消全体静音】成功 block，needChange-YES 表示成功
- (void)didTapMuteAllUserMicInMemberSheet:(PLVLSMemberSheet *)memberSheet
                                     mute:(BOOL)mute
                              changeBlock:(void(^)(BOOL needChange))changeBlock;

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

@end

@interface PLVLSMemberSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSMemberSheetDelegate> delegate;

/// 初始化方法
/// @param userList 当前成员列表数据
/// @param userCount 在线成员总数（在线成员总数不一定等于数组userList的count）
- (instancetype)initWithUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount;

/// 更新成员列表数据、在线成员总数
- (void)updateUserList:(NSArray <PLVChatUser *> *)userList userCount:(NSInteger)userCount;

@end

NS_ASSUME_NONNULL_END
