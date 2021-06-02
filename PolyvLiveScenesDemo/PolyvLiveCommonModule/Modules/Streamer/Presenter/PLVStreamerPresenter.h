//
//  PLVStreamerPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PLVLinkMicWaitUser.h"
#import "PLVLinkMicOnlineUser.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVStreamerPresenterRoomJoinStatus) {
    PLVStreamerPresenterRoomJoinStatus_NotJoin = 0, // 未加入 RTC房间
    PLVStreamerPresenterRoomJoinStatus_Joining = 2, // 正在加入 RTC房间
    PLVStreamerPresenterRoomJoinStatus_Joined = 4,  // 已加入 RTC房间
    PLVStreamerPresenterRoomJoinStatus_Leaving = 6, // 正在离开 RTC房间
};

/// 预览类型
/// @note 因 “预览类型” 涉及到视觉交互上的业务设计逻辑。因此，此处准备了两种形式
typedef NS_ENUM(NSUInteger, PLVStreamerPresenterPreviewType) {
    PLVStreamerPresenterPreviewType_Unknown = 0,   // 未知的预览类型
    PLVStreamerPresenterPreviewType_UserArray = 1, // 用户数组 预览类型 (通过在 onlineUserArray 数组中，包含本地用户，而后在列表中展示)
    PLVStreamerPresenterPreviewType_AloneView = 2, // 独立视图 预览类型 (通过在 某个独立的视图上，渲染本地用户，而直接展示)
};

@protocol PLVRTCStreamerPresenterDelegate;

/// 推流管理器
@interface PLVStreamerPresenter : NSObject

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// delegate
@property (nonatomic, weak) id <PLVRTCStreamerPresenterDelegate> delegate;

/// 麦克风 是否默认开启
///
/// @note 仅在 [prepareLocalPreviewCompletion:] 方法调用前设置有效
///       YES:开启 NO:关闭；默认值 NO
@property (nonatomic, assign) BOOL micDefaultOpen;

/// 摄像头 是否默认开启
///
/// @note 仅在 [prepareLocalPreviewCompletion:] 方法调用前设置有效
///       YES:开启 NO:关闭；默认值 NO
@property (nonatomic, assign) BOOL cameraDefaultOpen;

/// 摄像头 是否默认前置
///
/// @note 仅在 [prepareLocalPreviewCompletion:] 方法调用前设置有效
///       YES:前置 NO:后置；默认值 YES
@property (nonatomic, assign) BOOL cameraDefaultFront;

/// 预渲染容器
///
/// @note 因渲染机制特性，需设置‘预渲染容器’，以保证在某些特殊场景下，RTC画面能正常渲染；
///       要求：preRenderContainer 必须拥有根视图
@property (nonatomic, weak) UIView * preRenderContainer;

/// 预览类型
@property (nonatomic, assign) PLVStreamerPresenterPreviewType previewType;

#pragma mark 状态
/// 当前 麦克风摄像头 是否已授权限
@property (nonatomic, assign, readonly) BOOL micCameraGranted;

/// 当前 RTC房间加入状态
@property (nonatomic, assign, readonly) PLVStreamerPresenterRoomJoinStatus rtcRoomJoinStatus;

/// 当前 是否处于RTC房间中 (rtcRoomJoinStatus 为 PLVStreamerPresenterRoomJoinStatus_Joined)
@property (nonatomic, assign, readonly) BOOL inRTCRoom;

/// 当前 是否推流已开始
@property (nonatomic, assign, readonly) BOOL pushStreamStarted;

/// 当前 是否上课已开始
@property (nonatomic, assign, readonly) BOOL classStarted;

/// 当前 网络状态
///
/// @note 仅在 处于RTC房间内 期间，会通过 [plvStreamerPresenter:networkQualityDidChanged:] 回调，定时(每2秒)返回一次网络状态
@property (nonatomic, assign, readonly) PLVBLinkMicNetworkQuality networkQuality;

/// 本地用户的 麦克风 当前是否开启
@property (nonatomic, assign, readonly) BOOL currentMicOpen;

/// 本地用户的 摄像头 当前是否开启 (描述的是，该用户本身 ‘摄像头设备’ 此时是否开启)
@property (nonatomic, assign, readonly) BOOL currentCameraOpen;

/// 本地用户的 摄像头 当前是否应该显示 (描述的是，根据业务逻辑，该用户的 ‘摄像头画面’ 此时是否应该显示)
@property (nonatomic, assign, readonly) BOOL currentCameraShouldShow;

/// 本地用户的 摄像头 当前是否前置
@property (nonatomic, assign, readonly) BOOL currentCameraFront;

/// 当前 频道连麦功能是否开启（YES:连麦功能已开启 NO:连麦功能已关闭）
@property (nonatomic, assign, readonly) BOOL channelLinkMicOpen;

/// 当前 频道连麦媒体类型
@property (nonatomic, assign, readonly) PLVChannelLinkMicSceneType channelLinkMicMediaType;

#pragma mark 数据
/// 当前 场次Id
@property (nonatomic, copy, readonly) NSString * sessionId;

/// 当前 本地用户
@property (nonatomic, weak, readonly) PLVLinkMicOnlineUser * localOnlineUser;

/// 当前 等待连麦 用户数组
///
/// @note 准确的描述，应是 “按业务逻辑需对外展示的 等待连麦 用户数组”
///       即部分场景下，此数组，与服务器的 “等待加入用户数组” 并不完全对应；因本地还考虑了业务逻辑
@property (nonatomic, copy, readonly) NSArray <PLVLinkMicWaitUser *> * waitUserArray;

/// 当前 RTC房间已在线 用户数组
///
/// @note 准确的描述，应是 “按业务逻辑需对外展示的 RTC房间已在线 用户数组”
///       即部分场景下，此数组，与服务器的 “已加入用户数组” 并不完全对应；因本地还考虑了业务逻辑
@property (nonatomic, copy, readonly) NSArray <PLVLinkMicOnlineUser *> * onlineUserArray;

/// [时间] 开始推流的时间戳（单位秒；以 sessionId 成功获取为起始时间）
@property (nonatomic, assign, readonly) NSTimeInterval startPushStreamTimestamp;

/// [时间] 已有效推流时长（单位秒；不包含退至后台时间）
@property (nonatomic, assign, readonly) NSTimeInterval pushStreamValidDuration;

/// [时间] 总推流时长（单位秒；包含退至后台时间；即距离 开始推流时间点 的已过时长）
@property (nonatomic, assign, readonly) NSTimeInterval pushStreamTotalDuration;

/// [时间] 重连的累计时长（单位秒；单次推流的）
@property (nonatomic, assign, readonly) NSTimeInterval reconnectingDuration;

/// 当前 流分辨率 (清晰度)
@property (nonatomic, assign, readonly) PLVBLinkMicStreamQuality streamQuality;

#pragma mark - [ 方法 ]
/// 配置 流分辨率 (清晰度)
///
/// @param streamQuality 流分辨率
- (void)setupStreamQuality:(PLVBLinkMicStreamQuality)streamQuality;

/// 加入RTC频道
- (void)joinRTCChannel;

/// 退出 RTC频道
///
/// @note Presenter 内部将在销毁时自动调用，一般情况下，外部无需关心此方法；
- (void)leaveRTCChannel;

/// 准备本地预览
///
/// @param completion ’准备本地预览‘完成Block (可根据 prepareSuccess 得知该准备操作是否成功)
- (void)prepareLocalPreviewCompletion:(nullable void (^)(BOOL prepareSuccess))completion;

/// 设置本地画面预览的载体视图
- (void)setupLocalPreviewWithCanvaView:(nullable UIView *)canvasView;

/// 开始推流
- (void)startPushStream;

/// 停止推流
- (void)stopPushStream;

#pragma mark 课程事件管理
/// 开始上课
///
/// @note 开始推流，且发送请求修改频道状态为“开始上课”
- (void)startClass;

/// 结束上课
///
/// @note 停止推流，且发送请求修改频道状态为“结束上课”
- (void)finishClass;

#pragma mark 本地硬件管理
/// 开启或关闭 本地用户 的麦克风
///
/// @note 将触发RTC房间内其他成员，收到回调；
///
/// @param openMic 开启或关闭 麦克风 (YES:开启；NO:关闭)
- (void)openLocalUserMic:(BOOL)openMic;

/// 开启或关闭 本地用户 的摄像头
///
/// @note 将触发RTC房间内其他成员，收到回调；
///
/// @param openCamera 开启或关闭 摄像头 (YES:开启；NO:关闭)
- (void)openLocalUserCamera:(BOOL)openCamera;

/// 切换 本地用户 的前后置摄像头
///
/// @param frontCamera 切换为 前置或后置 摄像头 (YES:前置；NO:后置)
- (void)switchLocalUserCamera:(BOOL)frontCamera;

/// 切换 本地用户 的前后置摄像头
- (void)switchLocalUserFrontCamera;

#pragma mark 连麦事件管理
/// 开启或关闭 ”视频连麦“
///
/// @param open 是否开启
/// @param emitCompleteBlock ‘开启或关闭视频连麦’ 的请求发送结果Block
- (void)openVideoLinkMic:(BOOL)open emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock;

/// 开启或关闭 ”音频连麦“
///
/// @param open 是否开启
/// @param emitCompleteBlock ‘开启或关闭音频连麦’ 的请求发送结果Block
- (void)openAudioLinkMic:(BOOL)open emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock;

/// 关闭 “连麦功能”
///
/// @note 区别于 [openVideoLinkMic:emitCompleteBlock:]、[openAudioLinkMic:emitCompleteBlock:] 两个方法，该方法内部自行判断当前连麦类型，去执行“关闭连麦”的操作；
///
/// @param emitCompleteBlock 关闭 “连麦功能” 的请求发送结果Block
- (void)closeLinkMicEmitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock;

/// 允许 某位远端用户 上麦
///
/// @param waitUser 远端用户等待连麦模型
/// @param emitCompleteBlock ‘允许 某位远端用户 上麦’的请求发送结果Block
- (void)allowRemoteUserJoinLinkMic:(PLVLinkMicWaitUser *)waitUser emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock;

/// 开启或关闭 某位远端用户 的麦克风
///
/// @param onlineUser 远端用户RTC在线模型
/// @param muteMic 开启或关闭 麦克风
/// @param emitCompleteBlock ‘开启或关闭 某位远端用户 的麦克风’的请求发送结果Block
- (void)muteRemoteUserMic:(PLVLinkMicOnlineUser *)onlineUser muteMic:(BOOL)muteMic emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock;

/// 开启或关闭 某位远端用户的 摄像头
///
/// @param onlineUser 远端用户RTC在线模型
/// @param muteCamera 开启或关闭 摄像头
/// @param emitCompleteBlock ‘开启或关闭 某位远端用户的 摄像头’的请求发送结果Block
- (void)muteRemoteUserCamera:(PLVLinkMicOnlineUser *)onlineUser muteCamera:(BOOL)muteCamera emitCompleteBlock:(nullable void (^)(BOOL emitSuccess))emitCompleteBlock;

/// 挂断全部连麦用户
- (void)closeAllLinkMicUser;

/// 静音全部连麦用户的麦克风
///
/// @param muteAllMic 是否静音全部连麦用户的麦克风 (YES:静音 NO:取消静音)
- (void)muteAllLinkMicUserMic:(BOOL)muteAllMic;

#pragma mark 连麦用户管理
/// 查询某个条件的RTC在线用户，在数组中的下标值
///
/// @note 同步方法，非异步执行；不卡线程，无耗时操作，仅遍历逻辑；
///
/// @param filtrateBlockBlock 筛选条件Block (参数enumerateUser:遍历过程中的用户Model，请自行判断其是否符合筛选目标；返回值 BOOL，判断后告知此用户Model是否目标)
///
/// @return 根据 filtrateBlockBlock 的筛选，返回找到的目标条件用户，在数组中的下标值 (若小于0，表示查询失败无法找到)
- (NSInteger)findOnlineUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 根据下标值 获取RTC在线用户
///
/// @param targetIndex 下标值
- (PLVLinkMicOnlineUser *)getOnlineUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

/// 查询某个条件的等待连麦用户，在数组中的下标值
///
/// @note 同步方法，非异步执行；不卡线程，无耗时操作，仅遍历逻辑；
///
/// @param filtrateBlockBlock 筛选条件Block (参数enumerateUser:遍历过程中的用户Model，请自行判断其是否符合筛选目标；返回值 BOOL，判断后告知此用户Model是否目标)
///
/// @return 根据 filtrateBlockBlock 的筛选，返回找到的目标条件用户，在数组中的下标值 (若小于0，表示查询失败无法找到)
- (NSInteger)findWaitUserModelIndexWithFiltrateBlock:(BOOL (^)(PLVLinkMicWaitUser * _Nonnull waitUser))filtrateBlockBlock;

/// 根据下标值 获取等待连麦用户
///
/// @param targetIndex 下标值
- (PLVLinkMicWaitUser *)getWaitUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

@end


#pragma mark - [ 代理方法 ]
/// 推流管理器 代理方法
@protocol PLVRTCStreamerPresenterDelegate <NSObject>

@optional
#pragma mark 连麦用户变化
#pragma mark 状态变更
/// ‘房间加入状态’ 发生改变
///
/// @param presenter 推流管理器
/// @param currentRtcRoomJoinStatus 当前 ‘房间加入状态’
/// @param inRTCRoomChanged ‘是否处于RTC房间中’ 是否发生变化
/// @param inRTCRoom 当前 ‘是否处于RTC房间中’
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRtcRoomJoinStatus:(PLVStreamerPresenterRoomJoinStatus)currentRtcRoomJoinStatus inRTCRoomChanged:(BOOL)inRTCRoomChanged inRTCRoom:(BOOL)inRTCRoom;

/// 推流管理器 ‘是否正在处理’ 发生改变
///
/// @note 当推流管理器处于 ’处理中‘ 状态时，外部可配合置灰、禁用UI按钮，以示意‘暂时不可操作’；
///       同时注意，‘处理中’ 状态下调用 PLVStreamerPresenter 的方法，将不一定生效，以规避重复调用；
///
/// @param presenter 推流管理器
/// @param inProgress 是否正在处理 (YES:处理中 NO:不在处理中)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter operationInProgress:(BOOL)inProgress;

/// ’等待连麦用户数组‘ 发生改变
///
/// @note 关于 newWaitUserAdded ’是否新增了连麦等待用户‘，字段规则如下：
///       (1) 字段为 YES 场景一：此时收到了一条合法的连麦申请消息，而新增了等待用户
///       (2) 字段为 YES 场景二：此时服务器中的 ’等待连麦用户数组‘ 新增了等待用户
///       (3) 无论是哪种 回调场景，均必须是 “新增” 了等待用户。若未造成 “等待用户的新增”，则该字段均为 NO
///
/// @param presenter 推流管理器
/// @param waitUserArray 当前的等待连麦用户数组
/// @param newWaitUserAdded 是否新增了连麦等待用户
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicWaitUserListRefresh:(NSArray *)waitUserArray newWaitUserAdded:(BOOL)newWaitUserAdded;

/// ’RTC房间在线用户数组‘ 发生改变
///
/// @param presenter 推流管理器
/// @param onlineUserArray 当前的连麦在线用户数组
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray *)onlineUserArray;

/// 全部连麦成员的音频音量 回调
///
/// @note 两种方式获知 “某位连麦成员的音频音量变化“，或说是以下两种回调均会被触发
///       方式一：通过此回调 [PLVStreamerPresenter:reportAudioVolumeOfSpeakers:]
///       方式二：通过 某位连麦成员的模型 PLVLinkMicOnlineUser 中的 volumeChangedBlock（适用于Cell场景）
///
/// @param presenter 推流管理器
/// @param volumeDict 连麦成员音量字典 (key:用户连麦ID字符串，value:对应的流的音量值；value取值范围为 0.0 ~ 1.0)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter reportAudioVolumeOfSpeakers:(NSDictionary<NSString *, NSNumber *> * _Nonnull)volumeDict;

/// 当前正在讲话的连麦成员
///
/// @param presenter 推流管理器
/// @param currentSpeakingUsers 当前正在讲话的连麦成员数组
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter reportCurrentSpeakingUsers:(NSArray<PLVLinkMicOnlineUser *> * _Nonnull)currentSpeakingUsers;

- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter didMediaMuted:(BOOL)mute mediaType:(NSString *)mediaType linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser;

/// ‘是否推流已开始’ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter pushStreamStartedDidChanged:(BOOL)pushStreamStarted;

/// ’已有效推流时长‘ 发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter pushStreamValidDurationDidChanged:(NSTimeInterval)pushStreamValidDuration;

/// sessionId 场次Id发生变化
///
/// @param presenter 推流管理器
/// @param sessionId 当前 sessionId
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter sessionIdDidChanged:(NSString *)sessionId;

/// ‘是否上课已开始’ 发生变化
///
/// @param presenter 推流管理器
/// @param classStarted 当前 是否上课已开始
/// @param startClassInfoDict 开始上课时发出的 ‘开始上课字典’ (仅在 classStarted 为YES时有值)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter classStartedDidChanged:(BOOL)classStarted startClassInfoDict:(NSDictionary *)startClassInfoDict;

/// ‘网络状态’ 发生变化
///
/// @note 仅在 处于RTC房间内 期间，会定时(每2秒)返回一次网络状态
///
/// @param presenter 推流管理器
/// @param networkQuality 当前 ‘网络状态’ 状态值
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter networkQualityDidChanged:(PLVBLinkMicNetworkQuality)networkQuality;

/// 已挂断 某位远端用户的连麦 事件回调
///
/// @param presenter 推流管理器
/// @param onlineUser 被挂断连麦的 远端用户
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter didCloseRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser;

/// 需向外部获取文档的当前信息 事件回调
///
/// @note 此回调不保证在主线程触发
///
/// @param presenter 推流管理器
///
/// @return NSDictionary 外部返回的 文档当前信息
- (NSDictionary *)plvStreamerPresenterGetDocumentCurrentInfoDict:(PLVStreamerPresenter *)presenter;

/// 本地用户的 ’麦克风开关状态‘ 发生变化
///
/// @param presenter 推流管理器
/// @param currentMicOpen 用户的 麦克风 当前是否开启
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserMicOpenChanged:(BOOL)currentMicOpen;

/// 本地用户的 ’摄像头是否应该显示值‘ 发生变化
///
/// @param presenter 推流管理器
/// @param currentCameraShouldShow 用户的 摄像头 当前是否应该显示
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraShouldShowChanged:(BOOL)currentCameraShouldShow;

/// 本地用户的 ’摄像头前后置状态值‘ 发生变化
///
/// @param presenter 推流管理器
/// @param currentCameraFront 用户的 摄像头 当前是否前置
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraFrontChanged:(BOOL)currentCameraFront;

@end

NS_ASSUME_NONNULL_END
