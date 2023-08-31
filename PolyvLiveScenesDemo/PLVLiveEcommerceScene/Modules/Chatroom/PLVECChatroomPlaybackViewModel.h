//
//  PLVECChatroomPlaybackViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/6/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatroomPlaybackPresenter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECChatroomPlaybackViewModelDelegate, PLVECChatroomPlaybackDelegate;

/// 直播带货场景聊天重放viewModel
@interface PLVECChatroomPlaybackViewModel : NSObject

#pragma mark 可配置属性

@property (nonatomic, weak) id<PLVECChatroomPlaybackDelegate> delegate;

#pragma mark 只读属性

/// 频道号
@property (nonatomic, copy, readonly) NSString *channelId;
/// 当场回放场次id
@property (nonatomic, copy, readonly) NSString *sessionId;
/// 当场回放视频id
@property (nonatomic, copy, readonly) NSString *videoId;
/// 聊天重放common层presenter
@property (nonatomic, strong, readonly) PLVChatroomPlaybackPresenter *presenter;
/// 公聊消息数组
@property (nonatomic, strong, readonly) NSMutableArray <PLVChatModel *> *chatArray;

#pragma mark 方法

/// 初始化方法
/// @param channelId 频道号
/// @param sessionId 当场回放的场次id
- (instancetype)initWithChannelId:(NSString *)channelId sessionId:(NSString *)sessionId videoId:(NSString *)videoId;

/// 获取/更新回放视频时长
- (void)updateDuration:(NSTimeInterval)duration;

/// 回放视频发生seek
- (void)playbakTimeChanged;

/// 下拉加载更多历史消息
- (void)loadMoreMessages;

/// 清理聊天消息数组以及弹幕数组，并触发回调'-clearMessageForPlaybackViewModel:'
- (void)clear;

/// 增加监听者
/// @param delegate 待增加的监听者
/// @param delegateQueue 执行回调的队列
- (void)addUIDelegate:(id<PLVECChatroomPlaybackViewModelDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

/// 移除监听者
/// @param delegate 待移除的监听者
- (void)removeUIDelegate:(id<PLVECChatroomPlaybackViewModelDelegate>)delegate;

/// 移除所有监听者
- (void)removeAllUIDelegates;

@end

/// 主页监听的单监听协议
@protocol PLVECChatroomPlaybackDelegate <NSObject>

/// 每0.2秒触发一次，用来定时获取当前视频播放时间
- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

@end

@protocol PLVECChatroomPlaybackViewModelDelegate <NSObject>

@optional

/// 调用clear方法触发
- (void)clearMessageForPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

/// 首次获取回放数据的分段信息后触发
/// @param success YES-已获取到回放数据分段信息 NO-获取数据失败或获取到的数据为空
- (void)loadMessageInfoSuccess:(BOOL)success playbackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

/// 随着回放时间进度的推移，出现新的聊天消息时触发
- (void)didReceiveNewMessagesForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

/// 回放视频被seek时触发，此时内存中的聊天数组会被清空
- (void)didMessagesRefreshedForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

/// 下拉加载更多消息时触发，或者在回放视频被seek，自动加载历史消息时触发
- (void)didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
