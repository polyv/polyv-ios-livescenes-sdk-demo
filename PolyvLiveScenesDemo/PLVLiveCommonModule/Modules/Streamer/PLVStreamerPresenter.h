//
//  PLVStreamerPresenter.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
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
    PLVStreamerPresenterPreviewType_UserArray = 1, // 用户数组 预览类型 (适用于：通过在 onlineUserArray 数组中包含本地用户，来在列表中展示)
    PLVStreamerPresenterPreviewType_AloneView = 2, // 独立视图 预览类型 (适用于：通过在 某个独立的视图上，渲染本地用户，来直接展示)
};

typedef NS_ENUM(NSInteger, PLVStreamerPresenterErrorCode) {
    /// -1: 未知错误
    PLVStreamerPresenterErrorCode_UnknownError = -1,
    /// 0: 无错误
    PLVStreamerPresenterErrorCode_NoError = 0,
    
    /// 100: 上课失败，发送请求修改频道状态失败
    PLVStreamerPresenterErrorCode_StartClassFailedEmitFailed = 100,
    
    /// 300: 推流失败，网络错误
    PLVStreamerPresenterErrorCode_StartClassFailedNetError = 300,
    
    /// 400: 更新RTCToken失败，网络错误
    PLVStreamerPresenterErrorCode_UpdateRTCTokenFailedNetError = 400,
};

@protocol PLVStreamerPresenterDelegate;

/// 推流管理器
///
/// @note 支持旁路CDN推流、支持课程管理、支持RTC连麦、连麦用户管理
///
/// @code
/// // 使用演示 (具体参数及调用时机，请根据业务场景所需，进行实际设置)
/// self.streamerPresenter = [[PLVStreamerPresenter alloc] init];
/// self.streamerPresenter.delegate = self;
/// self.streamerPresenter.previewType = PLVStreamerPresenterPreviewType_UserArray;
///
/// // 设置 麦克风、摄像头默认配置
/// self.streamerPresenter.micDefaultOpen = YES;
/// self.streamerPresenter.cameraDefaultOpen = YES;
/// self.streamerPresenter.cameraDefaultFront = YES;
///
/// // 设置 流属性配置
/// [self.streamerPresenter setupStreamScale:PLVBLinkMicStreamScale16_9];
/// [self.streamerPresenter setupStreamQuality:PLVBLinkMicStreamQuality720P];
/// [self.streamerPresenter setupLocalVideoPreviewSameAsRemoteWatch:NO];
///
/// // 设置 混流配置
/// [self.streamerPresenter setupMixLayoutType:PLVRTCStreamerMixLayoutType_MainSpeaker];
///
/// // 准备本地预览 (实际调用建议参考Demo)
/// [self.streamerPresenter prepareLocalMicCameraPreviewCompletion:^(BOOL granted, BOOL prepareSuccess) {
///     [weakSelf.streamerPresenter setupLocalPreviewWithCanvaView:nil setupCompletion:^(BOOL setupResult) {
///         [weakSelf.streamerPresenter startLocalMicCameraPreviewByDefault];
///     }
/// }
///
/// // 加入RTC频道
/// [self.streamerPresenter joinRTCChannel];
/// @endcode
@interface PLVStreamerPresenter : NSObject

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// delegate
@property (nonatomic, weak) id <PLVStreamerPresenterDelegate> delegate;

/// 麦克风 是否默认开启
///
/// @note 仅在 [setupLocalPreviewWithCanvaView:] 方法调用前设置有效
///       YES:开启 NO:关闭；默认值 NO
@property (nonatomic, assign) BOOL micDefaultOpen;

/// 摄像头 是否默认开启
///
/// @note 仅在 [setupLocalPreviewWithCanvaView:] 方法调用前设置有效
///       YES:开启 NO:关闭；默认值 NO
@property (nonatomic, assign) BOOL cameraDefaultOpen;

/// 摄像头 是否默认前置
///
/// @note 仅在 [setupLocalPreviewWithCanvaView:] 方法调用前设置有效
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

/// 当前 是否推流已开始 (推流开始，不代表上课已开始；’上课是否开始‘ 请见 [classStarted] )
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

/// 本地用户的 闪光灯 当前是否开启
@property (nonatomic, assign, readonly) BOOL currentCameraTorchOpen;

/// 当前 本地视频预览画面 镜像类型
@property (nonatomic, assign, readonly) PLVBRTCVideoMirrorMode localVideoMirrorMode;

/// 当前 频道连麦功能是否开启（YES:连麦功能已开启 NO:连麦功能已关闭）
@property (nonatomic, assign, readonly) BOOL channelLinkMicOpen;

/// 当前 频道连麦媒体类型
@property (nonatomic, assign, readonly) PLVChannelLinkMicMediaType channelLinkMicMediaType;

/// 当前 流宽高比 (默认值:PLVBLinkMicStreamScale16_9)
@property (nonatomic, assign, readonly) PLVBLinkMicStreamScale streamScale;

/// 当前 流清晰度 (默认值:PLVBLinkMicStreamQuality180P)
@property (nonatomic, assign, readonly) PLVBLinkMicStreamQuality streamQuality;

/// 当前 混流布局模式 (值不为 1、2、3 的情况下，默认以 PLVRTCStreamerMixLayoutType_Single 作替代使用)
@property (nonatomic, assign, readonly) PLVRTCStreamerMixLayoutType mixLayoutType;

/// 当前 ‘本地视频预览’与‘远端观看’的镜像效果 是否一致
///
/// @note YES: 本地视频预览镜像，则远端观看效果亦镜像，即效果保持一致；
///       NO: 本地视频预览无论是否镜像，远端观看效果均不镜像，即效果相互独立，互不干扰；
///       默认 NO；修改此项配置，可调用 [setupLocalVideoPreviewSameAsRemoteWatch:] 方法
@property (nonatomic, assign, readonly) BOOL localVideoPreviewSameAsRemoteWatch;

/// 当前频道的 ‘直播流状态’
///
/// @note 枚举类型详见 PLVCloudClassSDK/PLVLiveDefine.h
@property (nonatomic, assign, readonly) PLVChannelLiveStreamState currentStreamState;

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

/// 当前 连麦在线 用户数组
///
/// @note 准确的描述，应是 “按业务逻辑需对外展示的 连麦在线 用户数组”
///       即部分场景下，此数组，与服务器的 “已加入用户数组” 并不完全对应；因本地还考虑了业务逻辑
@property (nonatomic, copy, readonly) NSArray <PLVLinkMicOnlineUser *> * onlineUserArray;

/// [推流时间] 开始推流的时间戳
///
/// @note 单位秒，带小数，可精确至毫秒；
///       以获取 sessionId 成功为起始时间点；
///       仅在属性 [pushStreamStarted] 为 YES 时有值;
@property (nonatomic, assign, readonly) NSTimeInterval startPushStreamTimestamp;

/// [推流时间] 已有效推流时长
///
/// @note 单位秒，带小数，可精确至毫秒；
///       不包含重连时长；若退至后台期间，推流未断开，也将算入‘已有效推流时长’中；
///       仅在属性 [pushStreamStarted] 为 YES 时有值；
@property (nonatomic, assign, readonly) NSTimeInterval pushStreamValidDuration;

/// [推流时间] 总推流时长
///
/// @note 单位秒，带小数，可精确至毫秒；
///       包含重连时长；即距离 开始推流时间戳 的已过时长；
///       仅在属性 [pushStreamStarted] 为 YES 时有值；
@property (nonatomic, assign, readonly) NSTimeInterval pushStreamTotalDuration;

/// [推流时间] 当前 远端已推流时长
///
/// @note 单位秒，带小数，可精确至毫秒；
///       注意，该时间是基于 ’获取所得的 开始推流时间戳‘ 计算出的远端已推流时间，非本地实际统计所得；
///       和其他的 [推流时间] 属性，在’数据来源‘上有本质的区别；
///       适用于 非讲师角色；
@property (nonatomic, assign, readonly) NSTimeInterval currentRemotePushDuration;

/// [重连时间] 单次重连时长
///
/// @note 单位秒，带小数，可精确至毫秒；
///       一次推流中，可能有多次重连，此属性为 单次重连时长；
@property (nonatomic, assign, readonly) NSTimeInterval reconnectingThisTimeDuration;

/// [重连时间] 全部重连累计时长
///
/// @note 单位秒，带小数，可精确至毫秒；
///       一次推流中，可能有多次重连，此属性为 全部重连累计时长（包括当前此刻，无论是否 ’重连中‘ 或 ’重连结束‘）；
@property (nonatomic, assign, readonly) NSTimeInterval reconnectingTotalDuration;


#pragma mark - [ 方法 ]
#pragma mark 基础调用
/// 准备 本地麦克风、摄像头画面预览
///
/// @note （1）调用后，将触发系统弹窗，向用户索要 “麦克风、摄像头” 权限同意；
///       （2）若授权同意，且 previewType 类型为 PLVStreamerPresenterPreviewType_UserArray，
///       则本地用户对象将加入进 ’onlineUserArray连麦在线用户数组’，成功加入则触发 [plvStreamerPresenter:linkMicWaitUserListRefresh:newWaitUserAdded:] 回调；
///       （3）支持在未加入RTC频道前调用
///
/// @param completion ’准备本地预览‘完成Block
///        granted: 麦克风摄像头权限是否已获得
///        prepareSuccess: 本地调用是否成功 (YES表示‘权限获取成功’+‘本地用户添加成功’；NO表示其中一项未执行成功)
- (void)prepareLocalMicCameraPreviewCompletion:(nullable void (^)(BOOL granted, BOOL prepareSuccess))completion;

/// 配置 ‘本地预览画面’ 的载体视图
///
/// @note 若 previewType 类型为 PLVStreamerPresenterPreviewType_UserArray，则 canvasView 可传nil，原因可见对应枚举值的说明；
///
/// @param canvasView ‘本地预览画面’ 的载体视图
/// @param setupCompletion 配置结果Block (YES:配置成功 NO:配置失败)
- (void)setupLocalPreviewWithCanvaView:(nullable UIView *)canvasView setupCompletion:(nullable void (^)(BOOL setupResult))setupCompletion;

/// 开始 本地麦克风、摄像头画面预览
///
/// @note 调用该方法前，需先调用 [prepareLocalMicCameraPreviewCompletion:]、[setupLocalPreviewWithCanvaView:] 进行准备工作；
///       将根据 [micDefaultOpen]、[cameraDefaultOpen]、[cameraDefaultFront] 三项默认值，进行硬件启动；
- (void)startLocalMicCameraPreviewByDefault;

/// 加入RTC频道
///
/// @note 该方法被调用，则表达 ‘外部希望加入RTC频道’。但实际是否加入，根据业务产品要求，还将依据于本地用户的具体角色来决定，如下：
///       （1）讲师角色，调用该方法后，将直接加入RTC频道
///       （2）嘉宾角色，调用该方法后，将开始监听 ‘流状态’，仅在‘直播中’状态下会加入RTC频道，非'直播中'将自动退出RTC频道
///
/// @note 若加入成功，将触发 [plvStreamerPresenter:currentRtcRoomJoinStatus:inRTCRoomChanged:inRTCRoom:] 回调
- (void)joinRTCChannel;

/// 退出RTC频道
///
/// @note 该方法被调用，则表达 ‘外部希望退出RTC频道’，将直接退出RTC频道；
///
/// @note Presenter 内部将在销毁时自动调用，一般情况下，外部无需关心此方法；
- (void)leaveRTCChannel;

#pragma mark 课程事件管理
/// 开始上课
///
/// @note 区别于 [startPushStream] 方法，该方法将开始推流，且发送请求修改频道状态为“开始上课”;
///       嘉宾角色调用无效；
///
/// @return 执行结果 (0: 成功；<0: 失败)
- (int)startClass;

/// 结束上课
///
/// @note 区别于 [stopPushStream] 方法，该方法将停止推流，且发送请求修改频道状态为“结束上课”;
///       兼容嘉宾角色调用，嘉宾角色调用时，仅负责退出直播间；
- (void)finishClass;

#pragma mark 流管理
/// 配置 流宽高比
///
/// @param streamScale 流宽高比
- (void)setupStreamScale:(PLVBLinkMicStreamScale)streamScale;

/// 配置 流清晰度
///
/// @note 支持在 未推流、正在推流 期间进行调用
///
/// @param streamQuality 流清晰度
- (void)setupStreamQuality:(PLVBLinkMicStreamQuality)streamQuality;

/// 配置 ‘本地视频预览’与‘远端观看’的镜像效果 是否一致
///
/// @note YES: 本地视频预览镜像，则远端观看效果亦镜像，即效果保持一致；
///       NO: 本地视频预览无论是否镜像，远端观看效果均不镜像，即效果相互独立，互不干扰；
- (void)setupLocalVideoPreviewSameAsRemoteWatch:(BOOL)localSameAsRemote;

#pragma mark CDN流管理
/// 开始推流
///
/// @note 区别于 [startClass] 方法，该方法仅负责开始推流
///
/// @return 执行结果 (0: 成功；<0: 失败)
- (int)startPushStream;

/// 停止推流
///
/// @note 区别于 [finishClass] 方法，该方法仅负责停止推流
- (void)stopPushStream;

/// 配置 混流布局模式
///
/// @param mixLayoutType 混流布局模式
- (void)setupMixLayoutType:(PLVRTCStreamerMixLayoutType)mixLayoutType;

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

/// 开启或关闭 本地用户 的闪光灯
///
/// @param openCameraTorch 开启或关闭 闪光灯 (YES:开启；NO:关闭)
- (void)openLocalUserCameraTorch:(BOOL)openCameraTorch;

/// 配置 本地视频预览画面 的镜像类型
///
/// @param mirrorMode 本地视频预览画面的镜像类型 (默认值:PLVBRTCVideoMirrorMode_Auto)
- (void)setupLocalVideoPreviewMirrorMode:(PLVBRTCVideoMirrorMode)mirrorMode;

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

#pragma mark 连麦用户管理
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

#pragma mark 连麦用户查找
/// 查询某个条件的‘连麦在线用户’，在数组中的下标值
///
/// @note 同步方法，非异步执行；不卡线程，无耗时操作，仅遍历逻辑；
///
/// @param filtrateBlockBlock 筛选条件Block (参数enumerateUser:遍历过程中的用户Model，请自行判断其是否符合筛选目标；返回值 BOOL，判断后告知此用户Model是否目标)
///
/// @return 根据 filtrateBlockBlock 的筛选，返回找到的目标条件用户，在数组中的下标值 (若小于0，表示查询失败无法找到)
- (NSInteger)findOnlineUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock;

/// 根据下标值 获取‘连麦在线用户’模型
///
/// @param targetIndex 下标值
- (PLVLinkMicOnlineUser *)getOnlineUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

/// 查询某个条件的‘等待连麦用户’，在数组中的下标值
///
/// @note 同步方法，非异步执行；不卡线程，无耗时操作，仅遍历逻辑；
///
/// @param filtrateBlockBlock 筛选条件Block (参数enumerateUser:遍历过程中的用户Model，请自行判断其是否符合筛选目标；返回值 BOOL，判断后告知此用户Model是否目标)
///
/// @return 根据 filtrateBlockBlock 的筛选，返回找到的目标条件用户，在数组中的下标值 (若小于0，表示查询失败无法找到)
- (NSInteger)findWaitUserModelIndexWithFiltrateBlock:(BOOL (^)(PLVLinkMicWaitUser * _Nonnull waitUser))filtrateBlockBlock;

/// 根据下标值 获取‘等待连麦用户’模型
///
/// @param targetIndex 下标值
- (PLVLinkMicWaitUser *)getWaitUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex;

@end


#pragma mark - [ 代理方法 ]
/// 推流管理器 代理方法
@protocol PLVStreamerPresenterDelegate <NSObject>

@optional
#pragma mark RTC房间事件
/// ‘RTC房间加入状态’ 发生改变
///
/// @note 根据业务逻辑，作以下说明：
///       对于讲师角色，加入RTC房间不代表’开始上课‘。’开始上课‘ 请以 [plvStreamerPresenter:classStartedDidChanged:startClassInfoDict:] 回调为准；
///       对于嘉宾角色，加入RTC房间则代表’已开始上课‘；
///       对于部分RTC场景下，currentRtcRoomJoinStatus回调为PLVStreamerPresenterRoomJoinStatus_Joined则立刻调用 “麦克风、摄像头的开关API” 可能会导致调用无效，请另择时机或参考Demo调用顺序；
///
/// @param presenter 推流管理器
/// @param currentRtcRoomJoinStatus 当前 ‘房间加入状态’
/// @param inRTCRoomChanged ‘是否处于RTC房间中’ 是否发生变化
/// @param inRTCRoom 当前 ‘是否处于RTC房间中’
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRtcRoomJoinStatus:(PLVStreamerPresenterRoomJoinStatus)currentRtcRoomJoinStatus inRTCRoomChanged:(BOOL)inRTCRoomChanged inRTCRoom:(BOOL)inRTCRoom;

/// 本地用户 ‘网络状态’ 发生变化
///
/// @note 仅在 处于RTC房间内 期间，会定时(每2秒)返回一次网络状态
///
/// @param presenter 推流管理器
/// @param networkQuality 当前 ‘网络状态’ 状态值
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter networkQualityDidChanged:(PLVBLinkMicNetworkQuality)networkQuality;

#pragma mark 课程事件
/// 当前频道 sessionId 场次Id发生变化
///
/// @param presenter 推流管理器
/// @param sessionId 当前 sessionId
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter sessionIdDidChanged:(NSString *)sessionId;

/// ‘是否上课已开始’ 发生变化
///
/// @note ’开始推流‘ 不代表 ’开始上课‘；开始上课请以此回调为准；
///       该回调，表示本地对 ’上课状态‘ 的即时更新，适用于 讲师角色；
///
/// @param presenter 推流管理器
/// @param classStarted 当前 是否上课已开始
/// @param startClassInfoDict 开始上课时发出的 ‘开始上课字典’ (仅在 classStarted 为YES时有值；若当前场景，不涉及PPT模块，可不关心此参数)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter classStartedDidChanged:(BOOL)classStarted startClassInfoDict:(NSDictionary *)startClassInfoDict;

/// 直播 ‘流状态’ 更新
///
/// @note 该回调，表示外部对 ’上课状态‘ 的即时获取，适用于 非讲师角色；
///       如：嘉宾角色使用 PLVStreamerPresenter 并调用 [joinRTCChannel] 方法后，将定时触发该回调；
///
/// @param presenter 推流管理器
/// @param newestStreamState 当前最新的 ’流状态’
/// @param streamStateDidChanged ’流状态‘ 相对上一次 是否发生变化
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter streamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged;

/// 需向外部获取文档的当前信息 事件回调
///
/// @note 若当前场景，不涉及PPT模块(非三分屏频道)，可不关心此回调；
///       此回调不保证在主线程触发；
///
/// @param presenter 推流管理器
///
/// @return NSDictionary 外部返回的 文档当前信息
- (NSDictionary *)plvStreamerPresenterGetDocumentCurrentInfoDict:(PLVStreamerPresenter *)presenter;

#pragma mark CDN推流事件
/// ‘是否推流已开始’ 发生变化
///
/// @note ’开始推流‘ 不代表 ’开始上课‘；开始上课请以此 [plvStreamerPresenter:classStartedDidChanged:startClassInfoDict:] 回调为准；
///
/// @param presenter 推流管理器
/// @param pushStreamStarted 当前 是否推流已开始
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter pushStreamStartedDidChanged:(BOOL)pushStreamStarted;

/// 当前 ’已有效推流时长‘ 定时回调
///
/// @note 仅在属性 [pushStreamStarted] 为 YES 时，每1秒回调通知一次最新值；
///       在即将 清零重置 前，会回调一次 最终的数值，无论此刻是否已间隔足够1秒；
///       在 清零重置 后，也将回调一次；
///
/// @param presenter 推流管理器
/// @param pushStreamValidDuration 已有效推流时长 (单位秒，带小数，可精确至毫秒)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentPushStreamValidDuration:(NSTimeInterval)pushStreamValidDuration;

/// 当前 ’单次重连时长‘ 定时回调
///
/// @note 仅在属性 [pushStreamStarted] 为 YES 时，每1秒回调通知一次最新值；
///       在即将 清零重置 前，会回调一次 最终的数值，无论此刻是否已间隔足够1秒；
///       在 清零重置 后，也将回调一次；
///
/// @param presenter 推流管理器
/// @param reconnectingThisTimeDuration 单次重连时长 (单位秒，带小数，可精确至毫秒)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentReconnectingThisTimeDuration:(NSInteger)reconnectingThisTimeDuration;

/// 当前远端 ’已推流时长‘ 定时回调
///
/// @note 基于 ’获取到的 开始推流时间戳‘ 计算所得；
///       每1秒回调通知一次最新值；
///       适用于 非讲师角色；
///
/// @param presenter 推流管理器
/// @param currentRemotePushDuration 当前远端 已推流时长 (单位秒，带小数，可精确至毫秒；具体解释可见 [currentRemotePushDuration] 属性说明)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter currentRemotePushDuration:(NSTimeInterval)currentRemotePushDuration;

#pragma mark 本地用户硬件事件
/// 本地用户的 ’麦克风开关状态‘ 发生变化
///
/// @param presenter 推流管理器
/// @param currentMicOpen 本地用户的 麦克风 当前是否开启
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserMicOpenChanged:(BOOL)currentMicOpen;

/// 本地用户的 ’摄像头是否应该显示值‘ 发生变化
///
/// @param presenter 推流管理器
/// @param currentCameraShouldShow 本地用户的 摄像头 当前是否应该显示
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraShouldShowChanged:(BOOL)currentCameraShouldShow;

/// 本地用户的 ’摄像头前后置状态值‘ 发生变化
///
/// @param presenter 推流管理器
/// @param currentCameraFront 本地用户的 摄像头 当前是否前置
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraFrontChanged:(BOOL)currentCameraFront;

/// 本地用户的 ’闪光灯开关状态‘ 发生变化
///
/// @param presenter 推流管理器
/// @param currentCameraTorchOpen 本地用户的 闪光灯 当前是否开启
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter localUserCameraTorchOpenChanged:(BOOL)currentCameraTorchOpen;

#pragma mark 连麦用户事件
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
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicWaitUserListRefresh:(NSArray <PLVLinkMicWaitUser *>*)waitUserArray newWaitUserAdded:(BOOL)newWaitUserAdded;

/// ’连麦在线用户数组‘ 发生改变
///
/// @param presenter 推流管理器
/// @param onlineUserArray 当前 连麦在线用户数组
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray <PLVLinkMicOnlineUser *>*)onlineUserArray;

/// 连麦在线用户的 ’音频流禁用状态‘ 发生改变
///
/// @param presenter 推流管理器
/// @param linkMicOnlineUser 连麦在线用户
/// @param audioMuted 当前 ’音频流是否禁用‘
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicOnlineUser:(PLVLinkMicOnlineUser *)linkMicOnlineUser audioMuted:(BOOL)audioMuted;

/// 连麦在线用户的 ’视频流禁用状态‘ 发生改变
///
/// @param presenter 推流管理器
/// @param linkMicOnlineUser 连麦在线用户
/// @param videoMuted 当前 ’视频流是否禁用‘
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter linkMicOnlineUser:(PLVLinkMicOnlineUser *)linkMicOnlineUser videoMuted:(BOOL)videoMuted;

/// 已挂断 某位远端连麦用户 事件回调
///
/// @param presenter 推流管理器
/// @param onlineUser 被挂断的 远端连麦用户
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter didCloseRemoteUserLinkMic:(PLVLinkMicOnlineUser *)onlineUser;

/// 全部连麦成员的音频音量 回调
///
/// @note 两种方式获知 “某位连麦成员的音频音量变化“，或说是以下两种回调均会被触发
///       方式一：通过此回调 [PLVStreamerPresenter:reportAudioVolumeOfSpeakers:]
///       方式二：通过 某位连麦成员的模型 PLVLinkMicOnlineUser 中的 volumeChangedBlock（适用于Cell场景）
///
/// @param presenter 推流管理器
/// @param volumeDict 连麦成员音量字典 (key:用户连麦ID字符串，value:对应的流的音量值；value取值范围为 0.0 ~ 1.0)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter reportAudioVolumeOfSpeakers:(NSDictionary<NSString *, NSNumber *> * _Nonnull)volumeDict;

/// 当前正在讲话的连麦用户数组
///
/// @param presenter 推流管理器
/// @param currentSpeakingUsers 当前正在讲话的连麦用户数组
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter reportCurrentSpeakingUsers:(NSArray<PLVLinkMicOnlineUser *> * _Nonnull)currentSpeakingUsers;

#pragma mark 管理器状态事件
/// 推流管理器 ‘发生错误’ 回调
///
/// @param presenter 推流管理器
/// @param error 错误对象 (error.code 对应 PLVStreamerPresenterErrorCode 错误码；)
/// @param fullErrorCodeString 完整错误码字符串 (若需展示错误码，推荐直接使用此值，因该值自动包含底层模块的错误码值，更能体现错误细节)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter didOccurError:(NSError *)error fullErrorCode:(NSString *)fullErrorCodeString;

/// 推流管理器 ‘是否正在处理’ 发生改变
///
/// @note 当推流管理器处于 ’处理中‘ 状态时，外部可配合置灰、禁用UI按钮，以示意‘暂时不可操作’；
///       同时注意，‘处理中’ 状态下调用 PLVStreamerPresenter 的方法，将不一定生效，以规避重复调用；
///
/// @param presenter 推流管理器
/// @param inProgress 是否正在处理 (YES:处理中 NO:不在处理中)
- (void)plvStreamerPresenter:(PLVStreamerPresenter *)presenter operationInProgress:(BOOL)inProgress;

@end

NS_ASSUME_NONNULL_END
