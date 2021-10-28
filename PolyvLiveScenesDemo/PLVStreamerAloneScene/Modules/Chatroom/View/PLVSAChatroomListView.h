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

@end

/// 直播间聊天消息列表视图
@interface PLVSAChatroomListView : UIView

@property (nonatomic, weak) id<PLVSAChatroomListViewDelegate> delegate;

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

/// 发送消息
- (void)didSendMessage;

- (BOOL)didReceiveMessages;

- (void)didMessageDeleted;

- (void)loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

- (void)loadHistoryFailure;

- (void)scrollsToBottom:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
