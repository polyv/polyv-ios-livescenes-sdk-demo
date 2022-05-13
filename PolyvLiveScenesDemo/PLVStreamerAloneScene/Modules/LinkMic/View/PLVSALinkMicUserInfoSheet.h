//
//  PLVSALinkMicUserInfoSheet.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVLinkMicOnlineUser;

/// 连麦用户信息弹窗
@interface PLVSALinkMicUserInfoSheet : PLVSABottomSheet

@property (nonatomic, copy) void (^fullScreenButtonClickBlock) (PLVLinkMicOnlineUser *user); // 全屏按钮 点击的回调
@property (nonatomic, copy) void (^authSpeakerButtonClickBlock) (PLVLinkMicOnlineUser *user, BOOL auth); // 授权主讲按钮 点击的回调

/// 展示连麦用户信息弹窗
/// @param user 连麦用户信息
- (void)updateLinkMicUserInfoWithUser:(PLVLinkMicOnlineUser *)user;

@end

NS_ASSUME_NONNULL_END
