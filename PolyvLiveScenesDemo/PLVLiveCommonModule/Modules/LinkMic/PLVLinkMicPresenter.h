//
//  PLVLinkMicPresenter.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/7/22.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVLinkMicPresenterRoomJoinStatus) {
    PLVLinkMicPresenterRoomJoinStatus_NotJoin = 0, // 未加入 RTC房间
    PLVLinkMicPresenterRoomJoinStatus_Joining = 2, // 正在加入 RTC房间
    PLVLinkMicPresenterRoomJoinStatus_Joined = 4,  // 已加入 RTC房间
    PLVLinkMicPresenterRoomJoinStatus_Leaving = 6, // 正在离开 RTC房间
};

typedef NS_ENUM(NSUInteger, PLVLinkMicStatus) {
    PLVLinkMicStatus_Unknown = 0, // 未知状态
    PLVLinkMicStatus_Open    = 2, // 讲师已开启连麦，但未加入连麦；【新版】连麦表示不允许观看端允许举手
    PLVLinkMicStatus_Waiting = 4, // 等待讲师允许中（举手中）
    PLVLinkMicStatus_Inviting= 6, // 讲师等待连麦邀请的应答中
    PLVLinkMicStatus_ResponseWaiting = 8, // 已同意讲师的连麦邀请
    PLVLinkMicStatus_Joining = 10,// 讲师已允许 或 学生已应答，正在加入，引擎正在初始化
    PLVLinkMicStatus_Joined  = 12,// 已加入连麦（连麦中）
    PLVLinkMicStatus_Leaving = 14,// 正在离开中
    PLVLinkMicStatus_NotOpen = 16 // 讲师未开启连麦;【新版】连麦表示不允许观看端允许举手
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
    
    /* 5xx系列错误码，将在回调 [didOccurErrorInStatus:errorCode:extraCode:] 中将附带额外的错误码 */
    /** 500: RTC遇到错误 */
    PLVLinkMicErrorCode_JoinedOccurError = 500,
    /** 502: RTC遇到错误，启动音频模块失败 */
    PLVLinkMicErrorCode_JoinedOccurErrorStartAudioFailed = 502,
    
    /** 600: 退出连麦失败，当前连麦状态不匹配，仅在 PLVLinkMicStatus_Joining、PLVLinkMicStatus_Joined 状态下允许退出连麦 */
    PLVLinkMicErrorCode_LeaveChannelFailedStatusIllegal = 600,
    /** 602: 退出连麦失败，消息暂时无法发送 */
    PLVLinkMicErrorCode_LeaveChannelFailedSocketCannotSend = 602,
    
    /** 700: 获取连麦邀请应答超时时间失败，当前连麦状态不匹配，仅在 PLVLinkMicStatus_Inviting 状态下允许获取连麦邀请超时时间 */
    PLVLinkMicErrorCode_JoinAnswerTTLFailedStatusIllegal = 700,
    /** 702: 获取连麦邀请应答超时时间失败，消息暂时无法发送 */
    PLVLinkMicErrorCode_JoinAnswerTTLFailedSocketCannotSend = 702,
    /** 704: 获取连麦邀请应答超时时间失败，joinAnswerTTL 消息发送超时 */
    PLVLinkMicErrorCode_JoinAnswerTTLFailedSocketTimeout  = 704,
    
    /** 800: 应答连麦邀请失败，当前连麦状态不匹配，仅在 PLVLinkMicStatus_Inviting 状态下允许应答连麦邀请 */
    PLVLinkMicErrorCode_AnswerInvitationFailedStatusIllegal = 800,
    /** 802: 应答连麦邀请失败，消息暂时无法发送 */
    PLVLinkMicErrorCode_AnswerInvitationFailedSocketCannotSend = 802,
    /** 804: 应答连麦邀请失败，消息发送超时 */
    PLVLinkMicErrorCode_AnswerInvitationFailedSocketTimeout = 804,
    /** 806: 应答连麦邀请失败，连麦人数达到上限 */
    PLVLinkMicErrorCode_AnswerInvitationFailedLinkMicLimited = 806,
};

@protocol PLVLinkMicPresenterDelegate;

/// 连麦管理器
///
/// @note 负责连麦全过程的逻辑实现；
///       该管理器自带 Socket事件 的监听，无需外部将 Socket事件 告知管理器；
@interface PLVLinkMicPresenter : NSObject

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// delegate
@property (nonatomic, weak) id <PLVLinkMicPresenterDelegate> delegate;

/// 连麦时视频流宽高比，默认 PLVBLinkMicStreamScale16_9
@property (nonatomic, assign) PLVBLinkMicStreamScale streamScale;

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

/// 预渲染容器
///
/// @note 因渲染机制特性，需设置‘预渲染容器’，以保证在某些特殊场景下，RTC画面能正常渲染；
///       要求：preRenderContainer 必须拥有根视图
@property (nonatomic, weak) UIView * preRenderContainer;

/// 在线连麦成员是否排序，默认不排序
///
/// @note 如果观看端不会本地更改第一画面时，可设置该字段为YES，会根据用户角色、是否本地用户、是否主讲来进行排序；
///       如果观看端会本地修改第一画面（譬如云课堂场景），则不应该设置该属性
@property (nonatomic, assign) BOOL linkMicListSort;

#pragma mark 状态
/// 当前 房间加入状态
@property (nonatomic, assign, readonly) PLVLinkMicPresenterRoomJoinStatus rtcRoomJoinStatus;

/// 当前 是否处于RTC房间中 (rtcRoomJoinStatus 为 PLVLinkMicPresenterRoomJoinStatus_Joined)
@property (nonatomic, assign, readonly) BOOL inRTCRoom;

/// 当前 讲师是否发起连麦 (YES:讲师已开启连麦 NO:讲师未开启连麦) 新版表示 讲师是否允许观众举手
@property (nonatomic, assign, readonly) BOOL linkMicOpen;

/// 当前 频道连麦场景类型
@property (nonatomic, assign, readonly) PLVChannelLinkMicSceneType linkMicSceneType;

/// 当前 频道连麦媒体类型
@property (nonatomic, assign, readonly) PLVChannelLinkMicMediaType linkMicMediaType;

/// 当前 连麦状态
@property (nonatomic, assign, readonly) PLVLinkMicStatus linkMicStatus;

/// 当前 是否连麦中 (即是否已成功上麦，linkMicStatus 为 PLVLinkMicStatus_Joined)
@property (nonatomic, assign, readonly) BOOL inLinkMic;

/// 当前 是否处理中 (’处理中‘状态下，连麦管理器的部分方法将调用不生效，以规避重复调用；可通过 [plvLinkMicPresenter:operationInProgress] 回调得知状态变化)
@property (nonatomic, assign, readonly) BOOL inProgress;

/// 当前 本地主讲用户 是否来自本地的点击操作
///
/// @note 注意，若 ‘本地操作’ 后的 ‘本地主讲用户’ 仍与 ‘真实主讲用户’ 一致。那此值将为 NO 认为是 ‘非本地操作’
@property (nonatomic, assign, readonly) BOOL localMainSpeakerUserByLocalOperation;

/// 当前 是否已暂停无延迟观看
@property (nonatomic, assign, readonly) BOOL pausedWatchNoDelay;

/// 当前观众连麦麦序
@property (nonatomic, assign, readonly) NSInteger linkMicRequestIndex;

#pragma mark 数据
/// 当前 真实主讲用户 (即 “第一画面”)
///
/// @note 代表推流端设置的“第一画面”；
///       此真实主讲用户的 [isLocalMainSpeaker] 属性可能为NO，因该属性仅表示是否为‘本地主讲用户’；
@property (nonatomic, weak, readonly) PLVLinkMicOnlineUser * realMainSpeakerUser;

/// 当前 本地主讲用户 (即 “第一画面”)
///
/// @note 仅代表当前本地的 “第一画面”，不永久代表推流端设置的“第一画面”；
///       因本地允许用户点击某位用户，来作为“第一画面”；
///       此本地主讲用户的 [isLocalMainSpeaker] 属性必为YES，因该属性仅表示是否为‘本地主讲用户’；
@property (nonatomic, weak, readonly) PLVLinkMicOnlineUser * localMainSpeakerUser;

/// 当前 本地用户
@property (nonatomic, weak, readonly) PLVLinkMicOnlineUser * currentLocalLinkMicUser;

/// 当前 RTC房间在线用户数组
@property (nonatomic, copy, readonly) NSArray <PLVLinkMicOnlineUser *> * onlineUserArray;


#pragma mark - [ 方法 ]
#pragma mark 无延迟观看
- (void)startWatchNoDelay;

- (void)stopWatchNoDelay;

/// 暂停或取消暂停 无延迟观看
///
/// @note 调用后，将改变 [pausedWatchNoDelay] 值；
///
/// @param pause 暂停或取消暂停 (YES:暂停；NO:取消暂停)
- (void)pauseWatchNoDelay:(BOOL)pause;

#pragma mark 连麦
/// 举手 (申请连麦)
///
/// @note 仅在 PLVLinkMicStatus_Open 状态下可调用成功；
///       将在讲师 ‘同意上麦’ 后，自动上麦；
- (void)requestJoinLinkMic;

/// 取消举手 (取消申请连麦)
///
/// @note 仅在 PLVLinkMicStatus_Waiting 状态下可调用成功
- (void)cancelRequestJoinLinkMic;

/// 获取服务器端 邀请连麦 剩余的等待时间
/// @param callback 获取剩余时间的回调(参数ttl: 剩余时间；当为 -1 时，说明获取数据异常)
- (void)requestInviteLinkMicTTLCallback:(void (^)(NSInteger ttl))callback;

/// 同意/拒绝 连麦邀请
///
/// @note 在讲师发送 邀请上麦 的请求后可调用
/// @param accept 是否接受连麦邀请  (YES:接受, NO:拒绝)
/// @param timeoutCancel 是否是超时取消连麦邀请（accept 为NO 时有效）
- (void)acceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel;

/// 退出连麦
///
/// @note 仅在 PLVLinkMicStatus_Joining、PLVLinkMicStatus_Joined 状态下可调用成功
- (void)leaveLinkMic;

/// 退出连麦(仅发送'退出连麦消息')
///
/// @note 区别于 [leaveLinkMic] 方法，该方法仅发送退出连麦的socket消息，不关心是否真正退出RTC房间
///       在PLVLinkMicStatus_Waiting、PLVLinkMicStatus_Joining、PLVLinkMicStatus_Joined 状态下可调用成功
///       适用场景：当前确认 PLVLinkMicPresenter 将很快销毁，希望发送 ‘退出连麦’ 的请求消息，来更新本地用户在服务器中的状态
- (void)leaveLinkMicOnlyEmit;

/// 本地请求变更’第一画面‘
- (void)changeMainSpeakerInLocalWithLinkMicUserIndex:(NSInteger)nowMainSpeakerLinkMicUserIndex;

/// 查询某个条件的用户，在数组中的下标值
///
/// @note 同步方法，非异步执行；不卡线程，无耗时操作，仅遍历逻辑；
///
/// @param filtrateBlockBlock 筛选条件Block (参数enumerateUser:遍历过程中的用户Model，请自行判断其是否符合筛选目标；返回值 BOOL，判断后告知此用户Model是否目标)
///
/// @return 根据 filtrateBlockBlock 的筛选，返回找到的目标条件用户，在数组中的下标值 (若小于0，表示查询失败无法找到)
- (NSInteger)findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 根据下标值获取连麦用户Model
///
/// @param targetIndex 下标值
- (PLVLinkMicOnlineUser *)getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

#pragma mark 设备控制
- (void)micOpen:(BOOL)open;

- (void)cameraOpen:(BOOL)open;

- (void)cameraSwitch:(BOOL)front;

@end

#pragma mark - [ 代理方法 ]
/// 连麦管理器 代理方法
@protocol PLVLinkMicPresenterDelegate <NSObject>

@optional
#pragma mark 状态变更
/// ‘房间加入状态’ 发生改变
///
/// @param presenter 连麦管理器
/// @param currentRtcRoomJoinStatus 当前 ‘房间加入状态’
/// @param inRTCRoomChanged ‘是否处于RTC房间中’ 是否发生变化
/// @param inRTCRoom 当前 ‘是否处于RTC房间中’
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
   currentRtcRoomJoinStatus:(PLVLinkMicPresenterRoomJoinStatus)currentRtcRoomJoinStatus
           inRTCRoomChanged:(BOOL)inRTCRoomChanged
                  inRTCRoom:(BOOL)inRTCRoom;

/// ‘连麦状态’ 发生改变
///
/// @param presenter 连麦管理器
/// @param currentLinkMicStatus 当前 ‘连麦状态’
/// @param inLinkMicChanged ‘是否连麦中’ 是否发生变化
/// @param inLinkMic 当前 ‘是否连麦中’
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
       currentLinkMicStatus:(PLVLinkMicStatus)currentLinkMicStatus
           inLinkMicChanged:(BOOL)inLinkMicChanged
                  inLinkMic:(BOOL)inLinkMic;

/// 连麦管理器 ‘是否正在处理’ 发生改变
///
/// @note 当连麦管理器处于 ’处理中‘ 状态时，外部可配合置灰、禁用UI按钮，以示意‘暂时不可操作’；
///       同时注意，‘处理中’ 状态下调用 PLVLinkMicPresenter 的方法，将不一定生效，以规避重复调用；
///
/// @param presenter 连麦管理器
/// @param inProgress 是否正在处理 (YES:处理中 NO:不在处理中)
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
        operationInProgress:(BOOL)inProgress;

/// 发生错误， 当前阶段状态，提示内容 title，详情说明 des，error
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
              didOccurError:(PLVLinkMicErrorCode)errorCode
                  extraCode:(NSInteger)extraCode;

/// 申请连麦时，用于更新连麦序号
/// @param linkMicIndex 连麦序号，0表示排在第一位，-1表示数据出错或结束排队
/// @note showJoinQueueNumberEnabled 为 NO 时该回调不生效
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter didLinkMicRequestIndexUpdate:(NSInteger)linkMicIndex;

#pragma mark 连麦用户变化
/// ’RTC房间在线用户数组‘ 发生改变
///
/// @param presenter 连麦管理器
/// @param onlineUserArray 当前的连麦在线用户数组
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray *)onlineUserArray;

#pragma mark 业务事件

/// 讲师让某位连麦人成为’主讲‘，’主讲‘角色已变更
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter mainSpeakerChangedToLinkMicUserId:(NSString *)linkMicUserId;

/// 当前’主讲‘ 的rtc画面，需要切至 主屏/副屏 显示
/// 非连麦状态时，此回调不应被处理
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter mainSpeakerLinkMicUserId:(NSString *)mainSpeakerLinkMicUserId mainSpeakerToMainScreen:(BOOL)mainSpeakerToMainScreen;

/// 全部连麦成员的音频音量 回调
///
/// @note 两种方式获知 “某位连麦成员的音频音量变化“，或说是以下两种回调均会被触发
///       方式一：通过此回调 [plvLinkMicPresenter:reportAudioVolumeOfSpeakers:]
///       方式二：通过 某位连麦成员的模型 PLVLinkMicOnlineUser 中的 volumeChangedBlock（适用于Cell场景）
///
/// @param presenter 连麦管理器
/// @param volumeDict 连麦成员音量字典 (key:用户连麦ID字符串，value:对应的流的音量值；value取值范围为 0.0 ~ 1.0)
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
reportAudioVolumeOfSpeakers:(NSDictionary<NSString *, NSNumber *> * _Nonnull)volumeDict;

/// 当前正在讲话的连麦成员
///
/// @param presenter 连麦管理器
/// @param currentSpeakingUsers 当前正在讲话的连麦成员数组
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
 reportCurrentSpeakingUsers:(NSArray<PLVLinkMicOnlineUser *> * _Nonnull)currentSpeakingUsers;

/// 静音某个用户 媒体类型 关闭打开 返回是否能找到
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter
              didMediaMuted:(BOOL)mute
                  mediaType:(NSString *)mediaType
                linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser;

/// 需获知 ‘当前频道是否直播中’
///
/// @note 此回调不保证在主线程触发
///
/// @param presenter 连麦管理器
- (BOOL)plvLinkMicPresenterGetChannelInLive:(PLVLinkMicPresenter *)presenter;

/// 当前下行网络质量
///
/// @param presenter 连麦管理器
/// @param rxQuality 当前下行网络质量
- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter localUserNetworkRxQuality:(PLVBLinkMicNetworkQuality)rxQuality;

/// 当前用户被老师下麦
///
/// @param presenter 连麦管理器
- (void)plvLinkMicPresenterLocalUserLinkMicWasHanduped:(PLVLinkMicPresenter *)presenter;


@end

NS_ASSUME_NONNULL_END
