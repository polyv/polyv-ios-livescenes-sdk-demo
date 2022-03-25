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

- (void)didSendMessage;

- (BOOL)didReceiveMessages;

- (void)didMessageDeleted;

- (void)loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

- (void)loadHistoryFailure;

- (void)scrollsToBottom:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
