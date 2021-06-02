//
//  PLVRoomData.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *PLVLCChatroomFunctionGotNotification;

/// 推流分辨率设置
typedef NS_ENUM (NSInteger, PLVLSResolutionType) {
    PLVLSResolutionType720P = 0, // 超清
    PLVLSResolutionType360P = 1, // 高清
    PLVLSResolutionType180P = 2 // 标清
};

@interface PLVRoomData : NSObject

#pragma mark 通用属性
/// 频道类型
@property (nonatomic, assign) PLVChannelType channelType;
/// 视频类型
@property (nonatomic, assign) PLVChannelVideoType videoType;
/// 频道号（主频道号）
@property (nonatomic, copy) NSString *channelId;
/// 直播场次ID（仅当讲师‘正在推流时’，可拿到最新的场次ID）
@property (nonatomic, copy) NSString *sessionId;
/// 在线人数
@property (nonatomic, assign) NSUInteger onlineCount;
/// 点赞数
@property (nonatomic, assign) NSUInteger likeCount;
/// 观看数
@property (nonatomic, assign) NSUInteger watchCount;
/// 播放状态
@property (nonatomic, assign) BOOL playing;
/// 直播频道信息
@property (nonatomic, strong) PLVChannelInfoModel *channelInfo;
/// 菜单信息，只读属性
@property (nonatomic, strong, readonly) PLVLiveVideoChannelMenuInfo *menuInfo;
/// 用户对象，只读属性
@property (nonatomic, strong, readonly) PLVRoomUser *roomUser;
/// 播放器发送ViewLog日志所需要的后台统计参数数据模型，只读属性
@property (nonatomic, strong, readonly) PLVViewLogCustomParam *customParam;
/// 本地用户的麦克风 是否默认开启 (默认值 NO)
@property (nonatomic, assign) BOOL localUserMicDefaultOpen;
/// 本地用户的摄像头 是否默认开启 (默认值 NO)
@property (nonatomic, assign) BOOL localUserCameraDefaultOpen;
/// 本地用户的摄像头 是否默认前置 (默认值 NO)
@property (nonatomic, assign) BOOL localUserCameraDefaultFront;


#pragma mark 直播独有属性
/// 直播状态
@property (nonatomic, assign) PLVChannelLiveStreamState liveState;
/// 当前频道连麦场景类型
@property (nonatomic, assign) PLVChannelLinkMicSceneType linkMicSceneType;

#pragma mark 直播回放独有属性
/// 回放视频 vid
@property (nonatomic, copy) NSString *vid;
/// 是否是点播列表
@property (nonatomic, assign) BOOL vodList;

#pragma mark 聊天室独有属性

/// 禁止点赞，默认NO-允许点赞
@property (nonatomic, assign) BOOL sendLikeDisable;
/// 禁止发送图片，默认NO-允许发送图片
@property (nonatomic, assign) BOOL sendImageDisable;
/// 禁止显示欢迎语，默认NO-允许显示欢迎语
@property (nonatomic, assign) BOOL welcomeShowDisable;

#pragma mark 连麦独有属性

/// 当前 频道连麦媒体类型
@property (nonatomic, assign) PLVChannelLinkMicSceneType channelLinkMicMediaType;
/// 当前 频道嘉宾是否手动上麦
@property (nonatomic, assign) BOOL channelGuestManualJoinLinkMic;

#pragma mark 推流独有属性

/// 流名，只读属性
@property (nonatomic, copy) NSString *stream;
/// 频道名，只读属性
@property (nonatomic, copy) NSString *channelName;
/// 推流地址，只读属性
@property (nonatomic, copy) NSString *rtmpUrl;
/// 待补充，只读属性
@property (nonatomic, assign) BOOL multiplexingEnabled;
/// 推流最大清晰度，默认为 PLVLSResolutionType720P
@property (nonatomic, assign) PLVLSResolutionType maxResolution;
/// 开始推流的时间戳（单位秒；以 sessionId 成功获取为起始时间）
@property (nonatomic, assign) NSTimeInterval startTimestamp;
/// 已推流时长（单位秒；不包含退至后台时间）
@property (nonatomic, assign) NSTimeInterval liveDuration;

/// 获取频道菜单信息
- (void)requestChannelDetail:(void(^)(PLVLiveVideoChannelMenuInfo *channelMenuInfo))completion;

/// 上报观看热度
- (void)reportViewerIncrease;

/// 获取功能开关
- (void)requestChannelFunctionSwitch;

/// 设置 roomUser
- (void)setupRoomUser:(PLVRoomUser *)roomUser;

/// 获取商品列表
- (void)requestCommodityList:(NSUInteger)channelId rank:(NSUInteger)rank count:(NSUInteger)count completion:(void (^)(NSUInteger total, NSArray<PLVCommodityModel *> *commoditys))completion failure:(void (^)(NSError *))failure;

@end

NS_ASSUME_NONNULL_END
