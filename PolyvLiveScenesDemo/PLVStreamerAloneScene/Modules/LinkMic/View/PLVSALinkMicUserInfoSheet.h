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

/// 初始化方法
/// @param sheetHeight 弹层弹出高度
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight;

/// 展示连麦用户信息弹窗
/// @param user 连麦用户信息
- (void)updateLinkMicUserInfoWithUser:(PLVLinkMicOnlineUser *)user;

@end

NS_ASSUME_NONNULL_END
