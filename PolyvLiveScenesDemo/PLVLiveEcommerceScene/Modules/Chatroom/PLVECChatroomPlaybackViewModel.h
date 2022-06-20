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

@protocol PLVECChatroomPlaybackViewModelDelegate;

@interface PLVECChatroomPlaybackViewModel : NSObject

#pragma mark 可配置属性

@property (nonatomic, weak) id<PLVECChatroomPlaybackViewModelDelegate> delegate;

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

@end

@protocol PLVECChatroomPlaybackViewModelDelegate <NSObject>

- (void)clearMessageForPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

- (void)loadMessageInfoSuccess:(BOOL)success playbackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

/// 每0.2秒触发一次，用来定时获取当前视频播放时间
- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

/// 新增聊天消息，UI需检查是否需要显示新消息提示
- (void)didReceiveNewMessagesForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

/// 刷新聊天消息列表，列表应滚动到底部
- (void)didMessagesRefreshedForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

/// 往上滚动，列表滚动到最顶部
- (void)didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:(PLVECChatroomPlaybackViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
