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

@class PLVPlaybackResumeConfig;

/// 推流分辨率设置
typedef NS_ENUM (NSInteger, PLVResolutionType) {
    PLVResolutionType180P = 0, // 180p（标清）
    PLVResolutionType360P = 4, // 360p（高清）
    PLVResolutionType480P = 8, // 480p（高标清）
    PLVResolutionType720P = 12, // 720p（超清）
    PLVResolutionType1080P = 16, // 1080p（超高清）
};

/// 推流画质优先设置
typedef NS_ENUM (NSInteger, PLVQualityPreferenceType) {
    PLVQualityPreferenceTypeClear = 0, // 画质优先
    PLVQualityPreferenceTypeSmooth = 1, // 流畅度优先
};

/// 混流布局类型
typedef NS_ENUM(NSInteger, PLVMixLayoutType) {
    PLVMixLayoutType_Single = 1, // 单人模式
    PLVMixLayoutType_Tile = 2, // 平铺模式
    PLVMixLayoutType_MainSpeaker = 3, // 主讲模式
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
/// 嘉宾是否有移交主讲的权限 【适用于手机开播场景】
@property (nonatomic, assign) BOOL guestTranAuthEnabled;
/// 当前直播间的频道信息
@property (nonatomic, strong) PLVChannelInfoModel *channelInfo;
/// 当前播放器的频道信息 (因播放器具备‘独立运作’的特性，因此 [playerChannelInfo] 与 [channelInfo] 可能对应的频道号不一致)
@property (nonatomic, strong) PLVChannelInfoModel *playerChannelInfo;
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
/// 双师模式且当前频道为小房间时，当前是否接收大房间的转播
@property (nonatomic, assign) BOOL listenMain;
/// 是否双师模式
@property (nonatomic, assign, readonly) BOOL transmitMode;
/// 防录屏开关，默认 NO
/// @note 直播以及回放场景下有效，开启防录屏开关时，不支持画中画功能；连麦场景下不结束连麦，非连麦场景会自动暂停，待录屏开启后尝试自动播放
@property (nonatomic, assign) BOOL captureScreenProtect;
/// 全屏保护开关，默认 NO
/// @note YES-开启防录屏开关且录屏时，将整个观看页隐藏；NO-开启防录屏开关且录屏时，仅播放器和连麦区域隐藏
@property (nonatomic, assign) BOOL fullScreenProtectWhenCaptureScreen;
/// 防系统截屏开关，默认NO
/// @note 直播和回放场景有效， 开启防系统截屏后，不支持系统画中画播放
@property (nonatomic, assign) BOOL systemScreenShotProtect;

/// 退出直播间 自动启动小窗播放  默认NO
@property (nonatomic, assign) BOOL disableStartPipWhenExitLiveRoom;
/// 退到app 后台 自动启动小窗播放 默认NO
@property (nonatomic, assign) BOOL disableStartPipWhenEnterBackground;

/// 系统小窗开关控制说明
///  1）系统版本 14.0 以上（15.0 以上支持自动启动小窗）
///  2）防录屏开关 关闭
///  3）防截屏开关 关闭
///  4）平台管理后台开启小窗功能 开启
///  5）退出直播间自动开启小窗开关 开启
///  6）app退到后台自动开启小窗开关 开启
///  7）播放器状态  播放中
///
/// 退到app 后台，是否可以自动开启小窗播放
/// @note YES ，需要满足小窗开关条件 1）2）3）4）5）6）7）
@property (nonatomic, assign, readonly) BOOL canAutoStartPictureInPicture;

/// 离开直播间页面 开启小窗
/// @Note YES, 需要满足条件 1）2）3）4）5）7）
@property (nonatomic, assign, readonly) BOOL needStartPictureInPictureWhenExitLiveRoom;

/// 是否支持小窗功能
/// @note YES 需要满足 1）2）3）4)
@property (nonatomic, assign, readonly) BOOL canSupportPictureInPicure;

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
/// 回放列表是否可用
@property (nonatomic, assign) BOOL playbackListEnable;
/// 章节功能是否可用
@property (nonatomic, assign) BOOL sectionEnable;
/// 章节列表
@property (nonatomic, strong) NSArray<PLVLivePlaybackSectionModel *> *sectionList;
/// 无网络且播放离线缓存情况下是否展示直播介绍页面
@property (nonatomic, assign) BOOL noNetWorkOfflineIntroductionEnabled;
/// 回放续播配置，默认为10秒阈值
@property (nonatomic, strong) PLVPlaybackResumeConfig *playbackResumeConfig;

#pragma mark 聊天室独有属性

/// 禁止点赞，默认NO-允许点赞
@property (nonatomic, assign) BOOL sendLikeDisable;
/// 禁止发送图片，默认NO-允许发送图片
@property (nonatomic, assign) BOOL sendImageDisable;
/// 禁止显示欢迎语，默认NO-允许显示欢迎语
@property (nonatomic, assign) BOOL welcomeShowDisable;
/// 开启显示举报反馈，默认NO-不显示举报反馈
@property (nonatomic, assign) BOOL watchFeedbackEnabled;
/// 条件红包是否开启，默认NO-不开启
@property (nonatomic, assign) BOOL conditionLotteryEnabled;

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
/// 推流默认清晰度
@property (nonatomic, assign) PLVResolutionType defaultResolution;
/// 推流默认清晰度等级
@property (nonatomic, copy) NSString *defaultResolutionLevel;
/// 开始推流的时间戳（单位秒；以 sessionId 成功获取为起始时间）
@property (nonatomic, assign) NSTimeInterval startTimestamp;
/// 已推流时长（单位秒；不包含退至后台时间）
@property (nonatomic, assign) NSTimeInterval liveDuration;
/// 当前直播是否正在进行 （该值只对讲师身份有效）
@property (nonatomic, assign) BOOL liveStatusIsLiving;
/// 后台是否开启了美颜功能 高级美颜
@property (nonatomic, assign) BOOL appBeautyEnabled;
/// 美颜类型  保利威轻美颜 高级美颜优先级高于轻美颜
@property (nonatomic, copy) NSString *appBeautyType;
/// 美颜sdk需要和rtc 匹配， 增加判断是否可以使用美颜
@property (nonatomic, assign, readonly) BOOL canUseBeauty;
/// 是否支持轻美颜
@property (nonatomic, assign, readonly) BOOL lightBeautyEnabled;
/// 是否支持AI 抠像
@property (nonatomic, assign, readonly) BOOL mattingEnabled;

/// 后台开启 APP纯视频横屏开播 默认比例(16:9 , 4:3)
@property (nonatomic, copy) NSString *appWebStartResolutionRatio;
/// 后台是否开启 APP纯视频横屏开播可调比例功能
@property (nonatomic, assign) BOOL appWebStartResolutionRatioEnabled;
/// 当前推流宽高比（仅适用于纯视频横屏开播）
@property (nonatomic, assign) PLVBLinkMicStreamScale streamScale;
/// 支持默认横屏开播，YES默认横屏开播，NO不开启（仅适用于纯视频开播）
@property (nonatomic, assign) BOOL appDefaultLandScapeEnabled;
/// 支持默认开启后置摄像头，YES默认开启后置摄像头，NO不开启（仅适用于纯视频开播）
@property (nonatomic, assign) BOOL appDefaultPureViewEnabled;
/// 支持默认混流布局类型（仅适用于纯视频开播）
@property (nonatomic, assign, readonly) PLVMixLayoutType defaultMixLayoutType;
/// 推流画质优先/流畅优先，默认画质优先
@property (nonatomic, assign, readonly) PLVQualityPreferenceType pushQualityPreference;
/// 连麦默认打开 开关，audio默认开启语音连麦，video默认打开视频连麦，N连麦默认不打开，默认值为N
@property (nonatomic, copy) NSString *userDefaultOpenMicLinkEnabled;
/// 新版连麦模式开关， YES默认使用新版连麦界面，NO默认使用旧版连麦界面
@property (nonatomic, assign) BOOL linkmicNewStrategyEnabled;
/// 新版连麦默认类型类型，audio默认开启语音连麦，video默认打开视频连麦，N连麦默认不打开，默认值为N
@property (nonatomic, copy) NSString *defaultOpenMicLinkEnabled;
// 频道默认开关，仅新版连麦生效
@property (nonatomic, assign, readonly) PLVChannelLinkMicMediaType defaultChannelLinkMicMediaType;
// 后台是否显示混流布局按钮，YES显示，NO不显示
@property (nonatomic, assign) BOOL showMixLayoutButtonEnabled;
// 后台是否显示横竖屏按钮，YES显示，NO不显示（仅适用于纯视频开播）
@property (nonatomic, assign) BOOL showOrientationButtonEnabled;
// 是否开启桌面消息，YES开启，NO关闭（仅适用于纯视频开播）
@property (nonatomic, assign) BOOL desktopChatEnabled;
// 开播端是否显示成员列表开关
@property (nonatomic, assign) BOOL appStartMemberListEnabled;
// 开播端是否显示混流布局开关
@property (nonatomic, assign) BOOL appStartMultiplexingLayoutEnabled;
// 开播端是否显示签到开关
@property (nonatomic, assign) BOOL appStartCheckinEnabled;
// 开播端是否显示礼物打赏开关
@property (nonatomic, assign) BOOL appStartGiftDonateEnabled;
// 开播端是否显示礼物特效开关
@property (nonatomic, assign) BOOL appStartGiftEffectEnabled;

#pragma mark SIP独有属性
/// 支持SIP模式
@property (nonatomic, assign) BOOL sipEnabled;
/// SIP入会号码
@property (nonatomic, copy) NSString *sipNumber;
/// SIP入会密码
@property (nonatomic, copy) NSString *sipPassword;

/// 设置 roomUser
- (void)setupRoomUser:(PLVRoomUser *)roomUser;

/// 获取频道菜单信息
- (void)requestChannelDetail:(void(^)(PLVLiveVideoChannelMenuInfo *channelMenuInfo))completion;

/// 上报观看热度
- (void)reportViewerIncrease;

/// 获取功能开关
- (void)requestChannelFunctionSwitch;

/// 配置pushQualityPreference枚举值
- (void)setupPushQualityPreference:(NSString *)pushQualityPreferenceString;

/// 前端获取原生用户信息参数
- (NSDictionary *)nativeAppUserParamsWithExtraParam:(NSDictionary * _Nullable)extraParam;

///  更新入会信息
- (void)updateSipInfo;

/// 将清晰度枚举值转换成字符串
/// @return 返回值为nil时表示参数resolutionType出错，无法转换
+ (NSString * _Nullable)resolutionStringWithType:(PLVResolutionType)resolutionType;

/// 将枚举 PLVBLinkMicStreamQuality 转换为 PLVResolutionType 枚举
+ (PLVResolutionType)resolutionTypeWithStreamQuality:(PLVBLinkMicStreamQuality)streamQuality;

/// 将枚举 PLVResolutionType 转换为 PLVBLinkMicStreamQuality 枚举
+ (PLVBLinkMicStreamQuality)streamQualityWithResolutionType:(PLVResolutionType)resolution;

/// 将枚举 PLVRTCStreamerMixLayoutType 转换为 PLVMixLayoutType 枚举
+ (PLVMixLayoutType)mixLayoutTypeWithStreamerMixLayoutType:(PLVRTCStreamerMixLayoutType)streamerType;

/// 将枚举 PLVMixLayoutType 转换为 PLVRTCStreamerMixLayoutType 枚举
+ (PLVRTCStreamerMixLayoutType)streamerMixLayoutTypeWithMixLayoutType:(PLVMixLayoutType)mixLayoutType;

/// 将清晰度枚举值转换成字符串
/// @return 返回值为nil时表示参数resolutionType出错，无法转换
+ (NSString * _Nullable)mixLayoutTypeStringWithType:(PLVMixLayoutType)mixLayoutType;

@end

#pragma mark - PLVPlaybackResumeConfig 回放续播配置

@interface PLVPlaybackResumeConfig : NSObject

/// 是否启用自定义续播阈值，默认YES
@property (nonatomic, assign) BOOL enabled;

/// 头部阈值（秒），播放位置小于此值时不续播，默认10秒
/// 例如：设置为1，表示播放位置小于1秒时从头播放
@property (nonatomic, assign) NSTimeInterval headThreshold;

/// 尾部阈值（秒），剩余时长小于此值时不续播，默认10秒
/// 例如：设置为1，表示剩余时长小于1秒时从头播放
@property (nonatomic, assign) NSTimeInterval tailThreshold;

/// 创建默认配置（头尾都是10秒）
+ (instancetype)defaultConfig;

/// 创建自定义配置
/// @param headThreshold 头部阈值
/// @param tailThreshold 尾部阈值
+ (instancetype)configWithHeadThreshold:(NSTimeInterval)headThreshold
                           tailThreshold:(NSTimeInterval)tailThreshold;

@end

NS_ASSUME_NONNULL_END
