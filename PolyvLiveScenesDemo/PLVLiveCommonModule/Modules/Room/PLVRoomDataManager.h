//
//  PLVRoomDataManager.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveDefine.h>
#import "PLVRoomData.h"

@class PLVChannelInfoModel;

NS_ASSUME_NONNULL_BEGIN

/// PLVRoomDataManager的协议
/// @note 允许设置多个监听者
@protocol PLVRoomDataManagerProtocol <NSObject>

@optional

/// 直播场次ID sessionId 更新
- (void)roomDataManager_didSessionIdChanged:(NSString *)sessionId;

/// 在线人数 onlineCount 更新
- (void)roomDataManager_didOnlineCountChanged:(NSUInteger)onlineCount;

/// 点赞数 likeCount 更新
- (void)roomDataManager_didLikeCountChanged:(NSUInteger)likeCount;

/// 观看数 watchCount 更新
- (void)roomDataManager_didWatchCountChanged:(NSUInteger)watchCount;

/// 播放状态 playing 更新
- (void)roomDataManager_didPlayingStatusChanged:(BOOL)playing;

/// 直播频道信息 channelInfo 更新
- (void)roomDataManager_didChannelInfoChanged:(PLVChannelInfoModel *)channelInfo;

/// 菜单信息 menuInfo 更新
- (void)roomDataManager_didMenuInfoChanged:(PLVLiveVideoChannelMenuInfo *)menuInfo;

/// 直播状态 liveState 更新
- (void)roomDataManager_didLiveStateChanged:(PLVChannelLiveStreamState)liveState;

@end

@interface PLVRoomDataManager : NSObject

/// 当前活跃的直播间数据
@property (nonatomic, strong, readonly) PLVRoomData *roomData;

/// 单例方法
+ (instancetype)sharedManager;

/// 配置当前的直播间数据，进入直播间时调用
- (void)configRoomData:(PLVRoomData *)roomData;

/// 移除当前的直播间数据，离开直播间时调用
- (void)removeRoomData;

/// 增加PLVRoomDataManagerProtocol协议的监听者
/// @param delegate 待增加的监听者
/// @param delegateQueue 执行回调的队列
- (void)addDelegate:(id<PLVRoomDataManagerProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

/// 移除PLVRoomDataManagerProtocol协议的监听者
/// @param delegate 待移除的监听者
- (void)removeDelegate:(id<PLVRoomDataManagerProtocol>)delegate;

/// 移除PLVRoomDataManagerProtocol协议的所有监听者
- (void)removeAllDelegates;

@end

NS_ASSUME_NONNULL_END
