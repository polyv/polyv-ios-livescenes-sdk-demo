//
//  PLVLSBannedUserSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Codex on 2026/7/8.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVLSSideSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVChatUser, PLVLSBannedUserSheet;

@protocol PLVLSBannedUserSheetDelegate <NSObject>

/// 恢复被踢出用户观看
- (void)bannedUserSheet:(PLVLSBannedUserSheet *)bannedUserSheet recoverKickedUser:(PLVChatUser *)user;

/// 取消禁言用户
- (void)bannedUserSheet:(PLVLSBannedUserSheet *)bannedUserSheet cancelBanUser:(PLVChatUser *)user;

/// 踢出用户
- (void)bannedUserSheet:(PLVLSBannedUserSheet *)bannedUserSheet kickUser:(PLVChatUser *)user;

/// 禁言用户
- (void)bannedUserSheet:(PLVLSBannedUserSheet *)bannedUserSheet banUser:(PLVChatUser *)user;

@end

@interface PLVLSBannedUserSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSBannedUserSheetDelegate> delegate;

- (instancetype)initWithKickedUserList:(NSArray<PLVChatUser *> *)kickedUserList
                        bannedUserList:(NSArray<PLVChatUser *> *)bannedUserList;

- (void)updateKickedUserList:(NSArray<PLVChatUser *> *)kickedUserList
              bannedUserList:(NSArray<PLVChatUser *> *)bannedUserList;

- (void)updateKickedUser:(PLVChatUser *)user released:(BOOL)released;

- (void)updateBannedUser:(PLVChatUser *)user released:(BOOL)released;

@end

NS_ASSUME_NONNULL_END
