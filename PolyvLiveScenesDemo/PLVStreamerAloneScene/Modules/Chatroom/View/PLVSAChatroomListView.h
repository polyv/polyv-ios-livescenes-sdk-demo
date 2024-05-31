//
//  PLVSAChatroomListView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;
@class PLVSAChatroomListView;

@protocol PLVSAChatroomListViewDelegate <NSObject>

/// 点击到底部 回调
- (void)chatroomListViewDidScrollTableViewUp:(PLVSAChatroomListView *)listView;

/// 回复消息 回调
- (void)chatroomListView:(PLVSAChatroomListView *)listView didTapReplyMenuItem:(PLVChatModel *)model;

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)chatroomListView:(PLVSAChatroomListView *)listView alertLongContentMessage:(PLVChatModel *)model;

@end

/// 直播间聊天消息列表视图
@interface PLVSAChatroomListView : UIView

@property (nonatomic, weak) id<PLVSAChatroomListViewDelegate> delegate;

/// 发送消息
- (void)didSendMessage;

- (BOOL)didReceiveMessages;

- (void)didMessageDeleted;

- (void)didMessageCountLimitedAutoDeleted;

- (void)loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

- (void)loadHistoryFailure;

- (void)scrollsToBottom:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
