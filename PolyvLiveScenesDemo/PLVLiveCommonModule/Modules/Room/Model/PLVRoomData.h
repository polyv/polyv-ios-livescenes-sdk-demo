//
//  PLVRoomData.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *PLVLCChatroomFunctionGotNotification;

/// 推流分辨率设置
typedef NS_ENUM (NSInteger, PLVResolutionType) {
    PLVResolutionType180P = 0, // 180p（标清）
    PLVResolutionType360P = 4, // 360p（高清）
    PLVResolutionType720P = 8, // 720p（超清）
};

@interface PLVRoomData : NSObject

#pragma mark 通用属性
/// 频道类型
@property (nonatomic, assign) BOOL inHiClassScene;
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
/// 是否是仅音频开播模式 【适用于手机开播场景】
@property (nonatomic, assign) BOOL isOnlyAudio;
/// 直播频道信息
@property (nonatomic, strong) PLVChannelInfoModel *channelInfo;
/// 回放视频信息
@property (nonatomic, strong) PLVPlaybackVideoInfoModel *playbackVideoInfo;
/// 菜单信息，只读属性
@property (nonatomic, strong, readonly) PLVLiveVideoChannelMenuInfo *menuInfo;
/// 用户对象，只读属性
@property (nonatomic, strong, readonly) PLVRoomUser *roomUser;
/// 播放器发送ViewLog日志所需要的后台统计参数数据模型，只读属性
@property (nonatomic, strong, readonly) PLVViewLogCustomParam *customParam;
/// 频道连麦人数，设置为不使用连麦时为0
@property (nonatomic, assign) NSUInteger interactNumLimit;
/// 是否并发限制以聊天室在线人数为准
@property (nonatomic, assign) BOOL restrictChatEnabled;
/// 最大同时在线人数
@property (nonatomic, assign) NSUInteger maxViewerCount;

#pragma mark 直播独有属性
/// 直播状态
@property (nonatomic, assign) PLVChannelLiveStreamState liveState;
/// 当前频道连麦场景类型
@property (nonatomic, assign) PLVChannelLinkMicSceneType linkMicSceneType;

#pragma mark 直播回放独有属性
/// 回放视频 vid，点播系统生成的回放id，用于大部分回放相关接口请求
@property (nonatomic, copy) NSString *vid;
/// 回放视频场次id，用于聊天室回放时请求当场直播的聊天消息
@property (nonatomic, copy) NSString *playbackSessionId;
/// 回放视频 videoId，直播系统生成的回放id，主要用于章节数据的获取
@property (nonatomic, copy) NSString *videoId;
/// 是否是点播列表
@property (nonatomic, assign) BOOL vodList;
/// 是否是直播暂存
@property (nonatomic, assign) BOOL recordEnable;
/// 暂存文件
@property (nonatomic, strong) PLVLiveRecordFileModel *recordFile;
/// 回放列表
@property (nonatomic, strong) PLVPlaybackListModel *playbackList;
/// 章节功能是否可用
@property (nonatomic, assign) BOOL sectionEnable;
/// 章节列表
@property (nonatomic, strong) NSArray<PLVLivePlaybackSectionModel *> *sectionList;

#pragma mark 聊天室独有属性

/// 禁止点赞，默认NO-允许点赞
@property (nonatomic, assign) BOOL sendLikeDisable;
/// 禁止发送图片，默认NO-允许发送图片
@property (nonatomic, assign) BOOL sendImageDisable;
/// 禁止显示欢迎语，默认NO-允许显示欢迎语
@property (nonatomic, assign) BOOL welcomeShowDisable;

#pragma mark 连麦独有属性
/// 当前 是否处于RTC房间中
@property (nonatomic, assign) BOOL inRTCRoom;
/// 当前 频道连麦媒体类型
@property (nonatomic, assign) PLVChannelLinkMicMediaType channelLinkMicMediaType;
/// 当前 频道嘉宾是否手动上麦
@property (nonatomic, assign) BOOL channelGuestManualJoinLinkMic;
/// 是否自动连麦，目前只有inHiClassScene且身份为teacher时可能为YES
@property (nonatomic, assign) BOOL autoLinkMic;
/// 连麦人数，目前只有inHiClassScene为YES时不为0
@property (nonatomic, assign) NSInteger linkNumber;

#pragma mark 推流独有属性
/// 频道账号（登录时使用的频道号）
@property (nonatomic, copy) NSString *channelAccountId;
/// 流名，只读属性
@property (nonatomic, copy) NSString *stream;
/// 当前流名，只读属性
@property (nonatomic, copy) NSString *currentStream;
/// 频道名，只读属性
@property (nonatomic, copy) NSString *channelName;
/// 推流地址，只读属性
@property (nonatomic, copy) NSString *rtmpUrl;
/// 待补充，只读属性
@property (nonatomic, assign) BOOL multiplexingEnabled;
/// 推流最大清晰度，默认为 PLVLSResolutionType720P
@property (nonatomic, assign) PLVResolutionType maxResolution;
/// 开始推流的时间戳（单位秒；以 sessionId 成功获取为起始时间）
@property (nonatomic, assign) NSTimeInterval startTimestamp;
/// 已推流时长（单位秒；不包含退至后台时间）
@property (nonatomic, assign) NSTimeInterval liveDuration;
/// 当前直播是否正在进行 （该值只对讲师身份有效）
@property (nonatomic, assign) BOOL liveStatusIsLiving;
/// 后台是否开启了美颜功能
@property (nonatomic, assign) BOOL appBeautyEnabled;


/// 设置 roomUser
- (void)setupRoomUser:(PLVRoomUser *)roomUser;

/// 获取频道菜单信息
- (void)requestChannelDetail:(void(^)(PLVLiveVideoChannelMenuInfo *channelMenuInfo))completion;

/// 上报观看热度
- (void)reportViewerIncrease;

/// 获取功能开关
- (void)requestChannelFunctionSwitch;

/// 将清晰度枚举值转换成字符串
/// @return 返回值为nil时表示参数resolutionType出错，无法转换
+ (NSString * _Nullable)resolutionStringWithType:(PLVResolutionType)resolutionType;

/// 将枚举 PLVBLinkMicStreamQuality 转换为 PLVResolutionType 枚举
+ (PLVResolutionType)resolutionTypeWithStreamQuality:(PLVBLinkMicStreamQuality)streamQuality;

/// 将枚举 PLVResolutionType 转换为 PLVBLinkMicStreamQuality 枚举
+ (PLVBLinkMicStreamQuality)streamQualityWithResolutionType:(PLVResolutionType)resolution;

@end

NS_ASSUME_NONNULL_END
