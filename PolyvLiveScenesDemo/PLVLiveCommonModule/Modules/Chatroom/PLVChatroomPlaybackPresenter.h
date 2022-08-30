//
//  PLVChatroomPlaybackPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/6/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVChatroomPlaybackPresenterDelegate;

@interface PLVChatroomPlaybackPresenter : NSObject

#pragma mark 可配置属性

@property (nonatomic, weak) id<PLVChatroomPlaybackPresenterDelegate> delegate;

#pragma mark 只读属性

/// 频道号
@property (nonatomic, copy, readonly) NSString *channelId;
/// 回放场次id
@property (nonatomic, copy, readonly) NSString *sessionId;

#pragma mark 方法

/// 初始化方法
/// @param channelId 频道号
/// @param sessionId 当场回放的场次id
- (instancetype)initWithChannelId:(NSString *)channelId sessionId:(NSString *)sessionId;

/// 获取/更新回放视频时长
- (void)updateDuration:(NSTimeInterval)duration;

/// 回放视频发生seek
- (void)playbakTimeChanged;

/// 获取指定时间之前的消息
- (void)loadMoreMessageBefore:(NSTimeInterval)playbakTime;

@end

@protocol PLVChatroomPlaybackPresenterDelegate <NSObject>

/// 首次获取回放数据的分段信息后触发
/// @param success YES-已获取到回放数据分段信息 NO-获取数据失败或获取到的数据为空
- (void)loadMessageInfoSuccess:(BOOL)success playbackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

/// 每0.2秒触发一次，用来定时获取当前视频播放时间
- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

/// 随着回放时间进度的推移，出现新的聊天消息时触发
- (void)didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray chatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

/// 回放视频被seek时触发，此时内存中的聊天数组会被清空
- (void)didChatModelsRefreshedForChatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

/// 下拉加载更多消息时触发，或者在回放视频被seek，自动加载历史消息时触发
- (void)didLoadMoreChatModels:(NSArray <PLVChatModel *> *)modelArray chatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

@end

NS_ASSUME_NONNULL_END
