//
//  PLVLSChatroomListView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/16.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;

/// 聊天消息列表视图
@interface PLVLSChatroomListView : UIView

@property (nonatomic, copy) void(^didScrollTableViewUp)(void);

@property (nonatomic, copy) void(^didTapReplyMenuItem)(PLVChatModel *model);

@property (nonatomic, copy) void(^didTapBanUserMenuItem)(PLVChatModel *model);

@property (nonatomic, copy) void(^didTapKickUserMenuItem)(PLVChatModel *model);

- (void)didSendMessage;

- (BOOL)didReceiveMessages;

- (void)didMessageDeleted;

- (void)didMessageCountLimitedAutoDeleted;

- (void)loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

- (void)loadHistoryFailure;

- (void)scrollsToBottom:(BOOL)animated;

/// 开始上课/结束上课
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

@end

NS_ASSUME_NONNULL_END
