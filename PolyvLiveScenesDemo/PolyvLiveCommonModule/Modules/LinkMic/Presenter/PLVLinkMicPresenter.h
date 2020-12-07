//
//  PLVLinkMicPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/7/22.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLiveRoomData.h"
#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVLinkMicStatus) {
    PLVLinkMicStatus_Unknown = 0, // 未知状态
    PLVLinkMicStatus_Open    = 2, // 讲师已开启连麦，但未加入连麦
    PLVLinkMicStatus_Waiting = 4, // 等待讲师允许中（举手中）
    PLVLinkMicStatus_Joining = 6, // 讲师已允许，正在加入，引擎正在初始化
    PLVLinkMicStatus_Joined  = 8, // 已加入连麦（连麦中）
    PLVLinkMicStatus_NotOpen = 10 // 讲师未开启连麦
};

typedef NS_ENUM(NSUInteger, PLVLinkMicMediaType) {
    PLVLinkMicMediaType_Unknown = 0, // 未知类型
    PLVLinkMicMediaType_Audio = 1,   // 音频连麦
    PLVLinkMicMediaType_Video = 2,   // 视频连麦
};

typedef NS_ENUM(NSInteger, PLVLinkMicScenesType) {
    PLVLinkMicScenesType_Unknown = 0,    // 未知连麦场景
    PLVLinkMicScenesType_BeforeLive = 1, // 旧版普通直播连麦
    PLVLinkMicScenesType_NormalLive = 2, // 新版普通直播连麦
    PLVLinkMicScenesType_CloudClass = 3  // 云课堂连麦
};

typedef NS_ENUM(NSInteger, PLVLinkMicErrorCode) {
    /** 0: 未知错误 */
    PLVLinkMicErrorCode_NoError = 0,
    /** 2: 未知错误 */
    PLVLinkMicErrorCode_UnknownError = 2,
    
    /** 200: 举手失败，需同意音视频权限 */
    PLVLinkMicErrorCode_RequestJoinFailedNoAuth = 200,
    /** 202: 举手失败，当前连麦状态不匹配，仅在 PLVLinkMicStatus_Open 状态下允许举手申请连麦 */
    PLVLinkMicErrorCode_RequestJoinFailedStatusIllegal = 202,
    /** 204: 举手失败，RtcEnable 接口请求失败，请稍后再试 */
    PLVLinkMicErrorCode_RequestJoinFailedRtcEnabledGetFail = 204,
    /** 206: 举手失败，RtcType 非法，请检查 PLVLiveVideoChannelMenuInfo.rtcType 值 */
    PLVLinkMicErrorCode_RequestJoinFailedNoRtcType = 206,
    /** 208: 举手失败，连麦 Token 更新失败，请稍后再试 */
    PLVLinkMicErrorCode_RequestJoinFailedNoToken = 208,
    /** 210: 举手失败，消息暂时无法发送 */
    PLVLinkMicErrorCode_RequestJoinFailedSocketCannotSend = 210,
    /** 212: 举手失败，joinRequest 消息发送超时 */
    PLVLinkMicErrorCode_RequestJoinFailedSocketTimeout = 212,
    
    /** 300: 取消举手失败，当前连麦状态不匹配，仅在 PLVLinkMicStatus_Waiting 状态下允许取消举手 */
    PLVLinkMicErrorCode_CancelRequestJoinFailedStatusIllegal = 300,
    
    /** 400: 加入Rtc频道失败 */
    PLVLinkMicErrorCode_JoinChannelFailed = 400,
    /** 402: 加入Rtc频道失败，当前连麦状态不匹配，仅在 PLVLinkMicStatus_Waiting 状态下允许加入频道 */
    PLVLinkMicErrorCode_JoinChannelFailedStatusIllegal = 402,
    /** 404: 加入Rtc频道失败，消息暂时无法发送 */
    PLVLinkMicErrorCode_JoinChannelFailedSocketCannotSend = 404,
    
    /** 500: 连麦中发生错误，回调 [didOccurErrorInStatus:errorCode:extraCode:] 中将附带额外的错误码 */
    PLVLinkMicErrorCode_JoinedOccurError = 500,
    
    /** 600: 退出连麦失败，当前连麦状态不匹配，仅在 PLVLinkMicStatus_Joining、PLVLinkMicStatus_Joined 状态下允许退出连麦 */
    PLVLinkMicErrorCode_LeaveChannelFailedStatusIllegal = 600,
    /** 602: 退出连麦失败，消息暂时无法发送 */
    PLVLinkMicErrorCode_LeaveChannelFailedSocketCannotSend = 602
};

@protocol PLVLinkMicPresenterDelegate;

/// 连麦管理器
///
/// @note 负责连麦全过程的逻辑实现；
///       该管理器自带 Socket事件 的监听，而无需等待外部将 Socket事件 告知管理器；
@interface PLVLinkMicPresenter : NSObject

#pragma mark 可配置项
/// 设置视图 delegate(负责处理视图相关的事务)
@property (nonatomic, weak) id <PLVLinkMicPresenterDelegate> viewDelegate;

/// 麦克风 是否默认开启
///
/// @note 仅在 [requestJoinLinkMic:] 方法调用前设置有效
///       YES:开启 NO:关闭；默认值 NO
@property (nonatomic, assign) BOOL micDefaultOpen;

/// 摄像头 是否默认开启
///
/// @note 仅在 [requestJoinLinkMic:] 方法调用前设置有效
///       YES:开启 NO:关闭；默认值 NO
@property (nonatomic, assign) BOOL cameraDefaultOpen;

/// 摄像头 是否默认前置
///
/// @note 仅在 [requestJoinLinkMic:] 方法调用前设置有效
///       YES:前置 NO:后置；默认值 YES
@property (nonatomic, assign) BOOL cameraDefaultFront;

#pragma mark 状态
/// 当前讲师是否发起连麦 (YES:讲师已开启连麦 NO:讲师未开启连麦)
@property (nonatomic, assign, readonly) BOOL linkMicOpen;

/// 当前连麦场景类型
@property (nonatomic, assign, readonly) PLVLinkMicScenesType linkMicScenesType;

/// 当前连麦媒体类型
@property (nonatomic, assign, readonly) PLVLinkMicMediaType linkMicMediaType;

/// 当前连麦状态
@property (nonatomic, assign, readonly) PLVLinkMicStatus linkMicStatus;

#pragma mark 数据
/// 当前直播间(频道)信息
@property (nonatomic, strong, readonly) PLVLiveRoomData *roomData;

/// 当前连麦 SocketToken (不为空时重连后要发送reJoinMic事件)
@property (nonatomic, copy, readonly) NSString *linkMicSocketToken;

/// 当前连麦 在线用户列表 (包含全部角色[无论是否’允许上麦‘]，包含自己)
@property (nonatomic, copy, readonly) NSArray <PLVLinkMicOnlineUser *> *onlineUserArray;

/// 当前连麦 在线参与者列表 (包含全部参与者，即 ’未上麦‘ 及 ’允许上麦‘)
@property (nonatomic, copy, readonly) NSArray *onlineViewerArray;

/// 当前连麦 允许上麦参与者列表 (仅包含允许上麦的参与者)
@property (nonatomic, copy, readonly) NSArray *onlineAllowedViewerArray;

/// 当前连麦 允许上麦嘉宾列表 (仅包含允许上麦的嘉宾)
@property (nonatomic, copy, readonly) NSArray *onlineAllowedGuestArray;

/// 当前主讲人 (讲师授予的“第一画面”)
@property (nonatomic, strong) PLVLinkMicOnlineUser * currentMainSpeaker;

/// 当前本地用户
@property (nonatomic, strong) PLVLinkMicOnlineUser * currentLocalLinkMicUser;

#pragma mark - [ 方法 ]
#pragma mark 创建
- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData ;

#pragma mark 业务
/// 举手(申请连麦)
///
/// @note 仅允许在 PLVLinkMicStatus_Open 状态下调用
- (void)requestJoinLinkMic;

/// 取消举手
///
/// @note 仅允许在 PLVLinkMicStatus_Waiting 状态下调用
- (void)cancelRequestJoinLinkMic;

/// 退出连麦
///
/// @note 仅允许在 PLVLinkMicStatus_Joining、PLVLinkMicStatus_Joined 状态下调用
- (void)quitLinkMic;

- (void)changeMainSpeakerWithLinkMicUserIndex:(NSInteger)nowMainSpeakerLinkMicUserIndex;

#pragma mark 设备控制
- (void)micOpen:(BOOL)open;

- (void)cameraOpen:(BOOL)open;

- (void)cameraSwitch:(BOOL)front;

@end

/// 连麦管理器 代理方法
@protocol PLVLinkMicPresenterDelegate <NSObject>

@optional

#pragma mark 状态变更
/// 连麦状态发生改变
///
/// @param presenter 连麦管理器
/// @param currentStatus 当前连麦状态
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
       linkMicStatusChanged:(PLVLinkMicStatus)currentStatus;

/// 连麦管理器的处理状态发生改变
///
/// 当连麦管理器处于 ’处理中‘ 状态时，不应该允许用户继续调用类似 ’重复退出Rtc、重复申请连麦‘ 等操作
/// 因此可根据此状态，来控制 外部相关UI 是否可被操作
///
/// @param presenter 连麦管理器
/// @param inProgress 处理状态 (YES:处理中，外部相关UI应该禁止操作 NO:处理结束，外部相关UI可以允许操作)
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
        operationInProgress:(BOOL)inProgress;

/// 发生错误， 当前阶段状态，提示内容 title，详情说明 des，error
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
              didOccurError:(PLVLinkMicErrorCode)errorCode
                  extraCode:(NSInteger)extraCode;

#pragma mark 连麦用户变化
/// 本地用户(自己) 已加入/已退出 连麦房间回调
///
/// @note 区分于已加入/已退出Rtc频道，加入Rtc频道不一定已加入连麦房间。
///       仅接收到此回调后，才表示已加入或已退出连麦房间
///
/// @param presenter 连麦管理器
/// @param InOut 已加入或已退出连麦房间 (YES:已加入 NO:已退出)
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
localUserDidInOutLinkMicRoom:(BOOL)InOut;

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
                 remoteUser:(PLVLinkMicOnlineUser *)linkMicUser
   didJoinedLeftLinkMicRoom:(BOOL)didJoinedLeft;

/// 添加用户 [会多次调用；已存在的用户，会重复调用；代表当前存在的用户]
/// 仅在返回的 view 刚创建的时候需要渲染RTC，所以需要view去实现协议，让presenter 确认它是否刚创建的
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray *)onlineUserArray;

#pragma mark 业务事件
/// 讲师让某位连麦人成为’主讲‘，’主讲‘角色已变更
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter mainSpeakerChangedToLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser;

/// 当前’主讲‘ 的rtc画面，需要切至 主屏/副屏 显示
/// 非连麦状态时，此回调不应被处理
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter mainSpeakerLinkMicUserId:(NSString *)mainSpeakerLinkMicUserId wannaBecomeFirstSite:(BOOL)wannaBecomeFirstSite;

/// 全部连麦成员的音频音量 回调
///
/// @param presenter 连麦管理器
/// @param volumeDict 连麦成员音量字典 (key:用户连麦ID，value:对应的流的音量值；value取值范围为 0.0 ~ 1.0)
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
reportAudioVolumeOfSpeakers:(NSDictionary<NSString *, NSNumber *> * _Nonnull)volumeDict;

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
 reportCurrentSpeakingUsers:(NSArray<PLVLinkMicOnlineUser *> * _Nonnull)currentSpeakingUsers;

/// 静音某个用户 媒体类型 关闭打开 返回是否能找到
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
              didMediaMuted:(BOOL)mute
                  mediaType:(NSString *)mediaType
                linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser;

@end

NS_ASSUME_NONNULL_END
