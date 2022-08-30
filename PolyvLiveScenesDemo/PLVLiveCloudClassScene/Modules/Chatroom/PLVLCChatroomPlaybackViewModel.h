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

/// 云课堂场景聊天回放viewModel
@interface PLVLCChatroomPlaybackViewModel : NSObject

#pragma mark 可配置属性

@property (nonatomic, weak) id<PLVLCChatroomPlaybackDelegate> delegate;

#pragma mark 只读属性

/// 频道号
@property (nonatomic, copy, readonly) NSString *channelId;
/// 当场回放的场次id
@property (nonatomic, copy, readonly) NSString *sessionId;
/// 聊天回放common层presenter
@property (nonatomic, strong, readonly) PLVChatroomPlaybackPresenter *presenter;
/// 公聊消息数组，私聊无聊天回放
@property (nonatomic, strong, readonly) NSMutableArray <PLVChatModel *> *chatArray;

#pragma mark 方法

/// 初始化方法
/// @param channelId 频道号
/// @param sessionId 当场回放的场次id
- (instancetype)initWithChannelId:(NSString *)channelId sessionId:(NSString *)sessionId;

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
- (void)addUIDelegate:(id<PLVLCChatroomPlaybackViewModelDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

/// 移除监听者
/// @param delegate 待移除的监听者
- (void)removeUIDelegate:(id<PLVLCChatroomPlaybackViewModelDelegate>)delegate;

/// 移除所有监听者
- (void)removeAllUIDelegates;

@end

/// 主页监听的单监听协议
@protocol PLVLCChatroomPlaybackDelegate <NSObject>

/// 每0.2秒触发一次，用来定时获取当前视频播放时间
- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 上报需插入弹幕的文本，间隔1秒触发一次
/// 用于显示‘播放器弹幕’
/// @param content 弹幕文本
- (void)didReceiveDanmu:(NSString * )content chatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

@end

/// 需要展示聊天列表的视图所需要监听的多监听协议
@protocol PLVLCChatroomPlaybackViewModelDelegate <NSObject>

@optional

/// 调用clear方法触发
- (void)clearMessageForPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 首次获取回放数据的分段信息后触发
/// @param success YES-已获取到回放数据分段信息 NO-获取数据失败或获取到的数据为空
- (void)loadMessageInfoSuccess:(BOOL)success playbackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 随着回放时间进度的推移，出现新的聊天消息时触发
- (void)didReceiveNewMessagesForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 回放视频被seek时触发，此时内存中的聊天数组会被清空
- (void)didMessagesRefreshedForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

/// 下拉加载更多消息时触发，或者在回放视频被seek，自动加载历史消息时触发
- (void)didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
