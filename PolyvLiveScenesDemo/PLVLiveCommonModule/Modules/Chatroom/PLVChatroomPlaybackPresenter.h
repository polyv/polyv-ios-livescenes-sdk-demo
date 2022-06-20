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
/// 每次获取的最大消息条数，默认20
//@property (nonatomic, assign) NSUInteger eachLoadingHistoryCount;

#pragma mark 只读属性

/// 频道号
@property (nonatomic, copy, readonly) NSString *channelId;
/// 回放场次id
@property (nonatomic, copy, readonly) NSString *sessionId;

#pragma mark 方法

- (instancetype)initWithChannelId:(NSString *)channelId sessionId:(NSString *)sessionId;

- (void)updateDuration:(NSTimeInterval)duration;

- (void)playbakTimeChanged;

- (void)loadMoreMessageBefore:(NSTimeInterval)playbakTime;

@end

@protocol PLVChatroomPlaybackPresenterDelegate <NSObject>

- (void)loadMessageInfoSuccess:(BOOL)success playbackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

- (NSTimeInterval)currentPlaybackTimeForChatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

- (void)didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray chatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

- (void)didChatModelsRefreshedForChatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

- (void)didLoadMoreChatModels:(NSArray <PLVChatModel *> *)modelArray chatroomPlaybackPresenter:(PLVChatroomPlaybackPresenter *)presenter;

@end

NS_ASSUME_NONNULL_END
