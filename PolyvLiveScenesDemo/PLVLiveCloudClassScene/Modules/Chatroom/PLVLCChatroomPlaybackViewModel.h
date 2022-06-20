//
//  PLVLCChatroomPlaybackViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/6/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatroomPlaybackPresenter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCChatroomPlaybackViewModelDelegate, PLVLCChatroomPlaybackDelegate;

@interface PLVLCChatroomPlaybackViewModel : NSObject

#pragma mark 可配置属性

@property (nonatomic, weak) id<PLVLCChatroomPlaybackDelegate> delegate;

#pragma mark 只读属性

/// 频道号
@property (nonatomic, copy, readonly) NSString *channelId;
/// 回放场次id
@property (nonatomic, copy, readonly) NSString *sessionId;
/// 聊天室common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong, readonly) PLVChatroomPlaybackPresenter *presenter;
/// 公聊消息数组
@property (nonatomic, strong, readonly) NSMutableArray <PLVChatModel *> *chatArray;

#pragma mark 方法

- (instancetype)initWithChannelId:(NSString *)channelId sessionId:(NSString *)sessionId;

- (void)updateDuration:(NSTimeInterval)duration;

- (void)playbakTimeChanged;

- (void)loadMoreMessages;

- (void)clear;

/// 增加监听者
/// @param delegate 待增加的监听者
/// @param delegateQueue 执行回调的队列
- (void)addUIDelegate:(id<PLVLCChatroomPlaybackViewModelDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

/// 移除监听者
/// @param delegate 待移除的监听者
- (void)removeUIDelegate:(id<PLVLCChatroomPlaybackViewModelDelegate>)delegate;

/// 移除所有监听者
- (void)removeAllUIDelegates;

@end

@protocol PLVLCChatroomPlaybackDelegate <NSObject>

/// 每0.2秒触发一次，用来定时获取当前视频播放时间
- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 上报需插入弹幕的文本，间隔1秒触发一次
/// 用于显示‘播放器弹幕’
/// @param content 弹幕文本
- (void)didReceiveDanmu:(NSString * )content chatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

@end

@protocol PLVLCChatroomPlaybackViewModelDelegate <NSObject>

@optional

- (void)clearMessageForPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

- (void)loadMessageInfoSuccess:(BOOL)success playbackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 新增聊天消息，UI需检查是否需要显示新消息提示
- (void)didReceiveNewMessagesForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 刷新聊天消息列表，列表应滚动到底部
- (void)didMessagesRefreshedForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 往上滚动，列表滚动到最顶部
- (void)didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
