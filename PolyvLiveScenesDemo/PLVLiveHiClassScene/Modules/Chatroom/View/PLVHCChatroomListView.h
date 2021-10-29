//
//  PLVHCChatroomListView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 PLV. All rights reserved.
// 聊天室 消息列表视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;
@class PLVHCChatroomListView;

@protocol PLVHCChatroomListViewDelegate <NSObject>

/// 点击到底部 回调
- (void)chatroomListViewDidScrollTableViewUp:(PLVHCChatroomListView *)listView;

/// 回复消息 回调
- (void)chatroomListView:(PLVHCChatroomListView *)listView didTapReplyMenuItem:(PLVChatModel *)model;

@end

/// 聊天室 消息列表视图
@interface PLVHCChatroomListView : UIView

@property (nonatomic, weak) id<PLVHCChatroomListViewDelegate> delegate;

/// 网络状态，发送消息前判断网络是否异常
@property (nonatomic, assign) NSInteger netState;

/// 本地发送的公聊消息（包含禁言的情况）
/// 用于刷新列表、滚动列表到底部
- (void)didSendMessage;

/// 判断当前是否在底部
- (BOOL)didReceiveMessages;

/// 有消息被删除时执行，刷新消息视图
- (void)didMessageDeleted;

/// 加载历史消息成功
/// @param noMore 是否还有更多消息
/// @param first 是否为第一页
- (void)loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

/// 加载历史消息失败时回调，结束刷新动画
- (void)loadHistoryFailure;

/// 将消息视图滑动到底部
/// @param animated 是否使用动画
- (void)scrollsToBottom:(BOOL)animated;

/// 开始直播
- (void)startClass;

/// 结束直播
- (void)finishClass;

@end

NS_ASSUME_NONNULL_END
