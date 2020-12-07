//
//  PLVLiveRoomData.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/26.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVLiveChannelConfig.h"

#define KEYPATH_LIVEROOM_SESSIONID @"sessionId"
#define KEYPATH_LIVEROOM_CHANNEL @"channelMenuInfo"
#define KEYPATH_LIVEROOM_LIKECOUNT @"likeCount"
#define KEYPATH_LIVEROOM_VIEWCOUNT @"watchViewCount"
#define KEYPATH_LIVEROOM_ONLINECOUNT @"onlineCount"
#define KEYPATH_LIVEROOM_LIVESTATE @"liveState"
#define KEYPATH_LIVEROOM_LINES @"lines"
#define KEYPATH_LIVEROOM_DURATION @"duration"
#define KEYPATH_LIVEROOM_PLAYING @"playing"
#define KEYPATH_LIVEROOM_CHANNELINFO @"channelInfo"

NS_ASSUME_NONNULL_BEGIN

extern NSString *PLVLCChatroomFunctionGotNotification;

/// 枚举
/// 观看页的视频类型
typedef NS_ENUM(NSUInteger, PLVWatchRoomVideoType) {
    PLVWatchRoomVideoType_Live = 0,         // 视频类型为 直播
    PLVWatchRoomVideoType_LivePlayback = 2, // 视频类型为 直播回放 (注:特指直播结束后的回放，有别于‘点播’)
};

/// 直播间数据（房间信息、状态） !!!TODO:要移除 Live 的特征，变成一个房间属性
@interface PLVLiveRoomData : NSObject

#pragma mark 通用
@property (nonatomic, assign) PLVWatchRoomVideoType videoType;
/// 直播频道信息（配置信息）
@property (nonatomic, strong, readonly) PLVLiveChannelConfig *channel;
/// 直播频道信息（后台信息）
@property (nonatomic, strong, readonly) PLVLiveVideoChannelMenuInfo *channelMenuInfo;
/// 直播频道信息
@property (nonatomic, strong) PLVLiveVideoChannel * channelInfo;

/// 点赞数
@property (nonatomic, assign) NSUInteger likeCount;
/// 观看热度
@property (nonatomic, assign) NSUInteger watchViewCount;
/// 在线人数
@property (nonatomic, assign) NSUInteger onlineCount;

/// 音频模式
@property (nonatomic, assign) BOOL audioMode;

/// 当前线路
@property (nonatomic, assign) NSUInteger curLine;
/// 多线路
@property (nonatomic, assign) NSUInteger lines;
/// 当前码率
@property (nonatomic, copy) NSString *curCodeRate;
/// 码率列表
@property (nonatomic, copy) NSArray<NSString *> *codeRateItems;

/// 播放状态
@property (nonatomic, assign) BOOL playing;

#pragma mark 聊天室功能开关状态

@property (nonatomic, assign) BOOL sendLikeDisable; /// 禁止点赞，默认NO-允许点赞
@property (nonatomic, assign) BOOL sendImageDisable; /// 禁止发送图片，默认NO-允许发送图片
@property (nonatomic, assign) BOOL welcomeShowDisable; /// 禁止显示欢迎语，默认NO-允许显示欢迎语

#pragma mark 直播场景
/// 直播状态
@property (nonatomic, assign) PLVLiveStreamState liveState;

/// 当前直播 sessionId
@property (nonatomic, copy) NSString *sessionId;

#pragma mark 直播回放场景
/// 视频时长
@property (nonatomic, assign) NSTimeInterval duration;
/// 播放进度
@property (nonatomic, assign) CGFloat playedProgress;
/// 当前播放时间点 (单位:秒)
@property (nonatomic, assign) CGFloat currentTime;

#pragma mark Init method

- (instancetype)initWithLiveChannel:(PLVLiveChannelConfig *)channel;

+ (instancetype)liveRoomDataWithLiveChannel:(PLVLiveChannelConfig *)channel;

#pragma mark API

/// 更新频道信息
- (void)updateChannelInfo:(PLVLiveVideoChannelMenuInfo *)channelInfo;

/// 获取聊天室功能开关
- (void)loadFunctionSwitch;

#pragma mark - 便捷属性获取

/// 频道号，等同 self.channel.channelId
- (NSString *)channelId;

/// 视频 vid，等同 self.channel.vid
- (NSString *)vid;

/// 帐号 userId，等同 self.channel.account.userId
- (NSString *)userIdForAccount;

/// 观看用户 userId，等同 self.channel.watchUser.userId
- (NSString *)userIdForWatchUser;

/// 帐号信息，等同 self.channel.account
- (PLVLiveAccount *)account;

/// 观看用户信息，等同 self.channel.watchUser
- (PLVLiveWatchUser *)watchUser;

@end

NS_ASSUME_NONNULL_END
