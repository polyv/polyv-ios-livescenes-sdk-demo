//
//  PLVPlayerPresenter.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/12/11.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVAdvertView.h"
#import "PLVDefaultPageView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVPlayerPresenterDelegate;

/// 播放器管理器
///
/// @note 支持 直播、直播回放
///
/// @code
/// // 使用演示
/// self.playerPresenter = [[PLVPlayerPresenter alloc] initWithRoomData:roomData videoType:videoType];
/// self.playerPresenter.delegate = self;
/// [self.playerPresenter setupPlayerWithDisplayView:playerSuperview];
/// @endcode
@interface PLVPlayerPresenter : NSObject

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// delegate
@property (nonatomic, weak) id <PLVPlayerPresenterDelegate> delegate;

/// 视频加载缓慢时缺省页显示时间，默认15秒
@property (nonatomic, assign) NSInteger defaultPageShowDuration;

/// 退到后台 是否自动开启小窗播放
@property (nonatomic, assign) BOOL updateCanAutoStartPictureInPicture;

#pragma mark 数据
/// 当前播放器的频道号
@property (nonatomic, copy, readonly) NSString * channelId;

/// 当前播放器的类型
@property (nonatomic, assign, readonly) PLVChannelVideoType currentVideoType;

/// 当前最新“频道信息”对象（当前“当前播放器的频道号 channelId”的“频道信息”）
@property (nonatomic, assign, readonly, nullable) PLVChannelInfoModel * currentChannelInfo;

/// 当前直播的 可选线路数量 (暂时仅直播支持)
@property (nonatomic, assign, readonly) NSInteger lineNum;

/// 当前直播的 线路下标 (由 0 起始；暂时仅直播支持)
@property (nonatomic, assign, readonly) NSInteger currentLineIndex;

/// 当前直播的 码率/清晰度 可选项字符串数组 (暂时仅直播支持)
@property (nonatomic, strong, readonly) NSArray <NSString *> * codeRateNamesOptions;

/// 当前直播的 码率/清晰度 (暂时仅直播支持)
@property (nonatomic, copy, readonly) NSString * currentCodeRate;

/// 当前播放器是否正在播放音频
@property (nonatomic, assign, readonly) BOOL audioMode;

/// 当前直播回放的 播放时间点 (单位:秒；仅非直播场景下有值)
@property (nonatomic, readonly) NSTimeInterval currentPlaybackTime;

/// 当前直播回放的 最大播放时间点 (单位:秒；仅非直播场景下有值)
@property (nonatomic, readonly) NSTimeInterval playbackMaxPosition;

/// 当前直播回放的 视频总时长 (单位:秒；仅非直播场景下有值)
@property (nonatomic, readonly) NSTimeInterval duration;

/// 广告播放状态
@property (nonatomic, readonly) BOOL advertPlaying;

/// 是否允许点击暖场图片跳转到相应的链接（默认允许）
@property (nonatomic, assign) BOOL warmUpHrefEnable;

/// 回放视频ID(请求'直播回放视频的信息'接口返回的视频Id，与后台回放列表看到的vid不是同一个数据)
@property (nonatomic, copy, readonly) NSString *videoId;

/// 文件ID(请求'直播回放视频的信息'接口返回的文件Id，与后台回放列表看到的vid不是同一个数据，适用于暂存/素材库)
@property (nonatomic, copy, readonly) NSString *fileId;

#pragma mark 状态
/// 当前“播放器的频道号”是否与“外部频道号”一致
@property (nonatomic, assign, readonly) BOOL channelMatchExternal;

/// 当前频道的 ‘直播流状态’
///
/// @note 此属性也可通过 [PLVRoomDataManager sharedManager].roomData.liveState 进行访问
@property (nonatomic, assign, readonly) PLVChannelLiveStreamState currentStreamState;

/// 该频道是否 ‘直播中’ (以 ‘直播流状态’ 作为依据)
@property (nonatomic, assign, readonly) BOOL channelInLive;

/// 该频道是否配置为观看 ‘无延迟直播’ (以 后台配置数据 作为依据；当 [channelMatchExternal] 为NO时，此值无意义，而恒为NO)
@property (nonatomic, assign, readonly) BOOL channelWatchNoDelay;

/// 播放器当前是否加载 ‘无延迟直播’（以 当前直播播放器是否加载无延迟 作为依据；）
@property (nonatomic, assign, readonly) BOOL currentPlayerWatchNoDelay;

/// 该频道是否观看 ‘快直播’( 以 后台配置数据 作为依据；当 [channelMatchExternal] 为NO时，此值无意义，而恒为NO)
@property (nonatomic, assign, readonly) BOOL channelWatchQuickLive;

/// 该频道是否观看 ‘公共流’
@property (nonatomic, assign, readonly) BOOL channelWatchPublicStream;

/// 播放器当前是否加载 ‘快直播’（以 当前直播播放器是否加载快直播 作为依据；）
@property (nonatomic, assign, readonly) BOOL currentPlayerWatchQuickLive;

/// 当前是否为无延迟观看模式（包括无延迟直播和快直播）
@property (nonatomic, assign, readonly) BOOL noDelayWatchMode;

/// 播放器当前是否正在播放无延迟直播
@property (nonatomic, assign, readonly) BOOL noDelayLiveWatching;

/// 播放器当前是否正在播放快直播
@property (nonatomic, assign, readonly) BOOL quickLiveWatching;

/// 播放器当前是否正在播放公共流
@property (nonatomic, assign, readonly) BOOL publicStreamWatching;

/// 无延迟直播的当前 ‘开始结束状态’
@property (nonatomic, assign, readonly) BOOL currentNoDelayLiveStart;

/// 播放器当前的缩放尺寸
@property (nonatomic, assign,readonly) IJKMPMovieScalingMode scalingMode;

/// 当前播放器是否播放中
@property (nonatomic, assign, readonly) BOOL isPlaying;

/// 播放器是否正在播放暖场视频
@property (nonatomic, assign, readonly) BOOL playingWarmUpVideo;

#pragma mark UI
/// 外部传入的，负责承载播放器画面的父视图
///
/// @note 需调用 [setupPlayerWithDisplayView:] 方法来设置
@property (nonatomic, weak, readonly) UIView * displayView;

/// 暖场图片（当前频道存在暖场图片时显示）
@property (nonatomic, strong, readonly) UIImageView *warmUpImageView;

/// LOGO视图（当前频道存在播放器LOGO时显示）
@property (nonatomic, readonly) UIImageView *logoImageView;

/// 缺省页视图（当前频道播放器报错时显示）
@property (nonatomic, readonly) PLVDefaultPageView *defaultPageView;

/// 广告视图（当前频道存在片头广告或暂停广告时显示）
@property (nonatomic, readonly) PLVAdvertView *advertView;

#pragma mark - [ 方法 ]
#pragma mark 通用
/// 创建 播放器
///
/// @note 默认以 PLVRoomDataManager 中 roomData 的数据进行播放器初始化
///
/// @param videoType 视频类型
- (instancetype)initWithVideoType:(PLVChannelVideoType)videoType;

/// 通过指定数据 创建 播放器
///
/// @note 该方法不会读取 PLVRoomDataManager 中 roomData 的数据
///       对于不同的 videoType视频类型，参数传入要求不同；
///
/// @param videoType 视频类型（必传）
/// @param channelId 频道号Id（必传）
/// @param vodId 直播回放Id (PLVChannelVideoType_Live 时传值无效，PLVChannelVideoType_Playback 时且 recordEnable 为 YES 时传值无效；PLVChannelVideoType_Playback 时且 recordEnable 为 NO 时必传)
/// @param vodList 是否是“点播列表”视频 (PLVChannelVideoType_Live 时传值无效；PLVChannelVideoType_Playback 时且 recordEnable 为 NO 时必传)
/// @param recordFile 暂存视频模型（PLVChannelVideoType_Live 时传值无效；PLVChannelVideoType_Playback 时且 recordEnable 为 YES 时必传）
/// @param recordEnable 是否是“暂存”视频可用 (PLVChannelVideoType_Live 时传值无效；PLVChannelVideoType_Playback 时必传)

- (instancetype)initWithVideoType:(PLVChannelVideoType)videoType channelId:(NSString * _Nonnull)channelId vodId:(NSString * _Nullable)vodId vodList:(BOOL)vodList recordFile:(PLVLiveRecordFileModel * _Nullable)recordFile recordEnable:(BOOL)recordEnable;

/// 设置 承载播放器画面 的父视图
///
/// @param displayView 承载播放器画面的父视图
- (void)setupPlayerWithDisplayView:(UIView *)displayView;


/// 设置 播放器 的缩放尺寸
///
/// @param scalingMode 缩放尺寸，默认为IJKMPMovieScalingModeAspectFit
- (void)setupScalingMode:(IJKMPMovieScalingMode)scalingMode;

/// 清理播放器
- (void)cleanPlayer;

/// 恢复播放
///
/// @note 对于 直播 将重新加载直播；
///       对于 回放/点播 将恢复播放；
- (BOOL)resumePlay;

/// 暂停播放
- (BOOL)pausePlay;

/// 静音 播放器
- (void)mute;

/// 取消静音 播放器
- (void)cancelMute;

#pragma mark 直播相关
/// 切换 ’当前码率‘
///
/// @note 暂时仅直播支持清晰度切换，直播回放暂时不支持
///
/// @param codeRate 目标 码率/清晰度
- (void)switchLiveToCodeRate:(NSString *)codeRate;

/// 切换 ’当前线路‘
///
/// @param lineIndex 目标 线路 (由 0 起始；比如切至线路1，则传入 0)
- (void)switchLiveToLineIndex:(NSInteger)lineIndex;

/// 开启或关闭 音频模式
- (void)switchLiveToAudioMode:(BOOL)audioMode;

/// 开启或关闭 无延迟直播模式
- (void)switchToNoDelayWatchMode:(BOOL)noDelayWatchMode;

/// 开启画中画功能
/// @param originView 画中画播放器的起始视图
- (void)startPictureInPictureFromOriginView:(UIView *)originView;

/// 关闭画中画功能
- (void)stopPictureInPicture;

/// 更新测试模式状态
/// @param testModeStatus 测试状态模式
- (void)updateTestModeStatus:(BOOL)testModeStatus;

#pragma mark 非直播相关
/// 跳至某个时间点 (单位: 秒)
- (void)seekLivePlaybackToTime:(NSTimeInterval)toTime;

/// 切换倍速 (范围值 0.0~2.0)
- (void)switchLivePlaybackSpeedRate:(CGFloat)toSpeed;

/// 切换回放视频
/// @param vid 回放视频id
- (void)changeVid:(NSString *)vid;

/// 切换回放视频
/// @param vid 回放视频id
/// @param forceClear 是否强制清理
- (void)changeVid:(NSString *)vid forceClear:(BOOL)forceClear;

/// 切换暂存视频
/// @param fileId 暂存视频fileId
- (void)changeFileId:(NSString *)fileId;

/// 切换暂存视频
/// @param fileId 暂存视频fileId
/// @param forceClear 是否强制清理
- (void)changeFileId:(NSString *)fileId forceClear:(BOOL)forceClear;

#pragma mark 播放速度记忆功能
/// 获取支持的播放速度数组
- (NSArray<NSString *> *)getSupportedPlaybackSpeeds;

/// 获取缓存的播放速度
- (CGFloat)getCachedPlaybackSpeed;

/// 获取缓存播放速度对应的UI选中索引
- (NSInteger)getCachedPlaybackSpeedIndex;

/// 自动恢复保存的播放速度（仅回放场景有效）
- (void)restoreCachedPlaybackSpeed;

@end

@protocol PLVPlayerPresenterDelegate <NSObject>

@optional
#pragma mark - [ 代理方法 ]
#pragma mark 通用
/// 播放器 ‘正在播放状态’ 发生改变
///
/// @param playerPresenter 播放器管理器
/// @param playing 是否正在播放
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter playerPlayingStateDidChanged:(BOOL)playing;

/// 播放器 发生错误
///
/// @param playerPresenter 播放器管理器
/// @param errorMessage 错误描述
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter loadPlayerFailureWithMessage:(NSString *)errorMessage;

/// 播放器 ‘视频大小’ 发生改变
///
/// @param playerPresenter 播放器管理器
/// @param videoSize 当前视频大小
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter videoSizeChange:(CGSize)videoSize;

/// 播放器 ‘SEI信息’ 发生改变
///
/// @param playerPresenter 播放器管理器
/// @param timeStamp 附带的时间戳信息
/// @param newTimeStamp 最新时间戳
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter seiDidChange:(long)timeStamp newTimeStamp:(long)newTimeStamp;

/// 播放器 ‘频道信息’ 发生改变
///
/// @param playerPresenter 播放器管理器
/// @param channelInfo 当前最新 ’频道信息‘ 对象
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo;

/// 播放器 ‘回放视频信息’ 发生改变
///
/// @param playerPresenter 播放器管理器
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter playbackVideoInfoDidUpdated:(PLVPlaybackVideoInfoModel *)videoInfo;

/// 播放器 切换线路
///
/// @param playerPresenter 播放器管理器
- (void)playerPresenterWannaSwitchLine:(PLVPlayerPresenter *)playerPresenter;

/// 播放器 正在刷新
///
/// @param playerPresenter 播放器管理器
- (void)playerPresenterResumePlaying:(PLVPlayerPresenter *)playerPresenter;

/// 播放器 是否启用防录屏
/// @note 仅开启防录屏开关，才会进行回调
///
/// @param start 是否正在防录屏
-  (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter preventScreenCapturing:(BOOL)start;

#pragma mark 直播相关
/// 直播 ‘流状态’ 更新
///
/// @param playerPresenter 播放器管理器
/// @param newestStreamState 当前最新的 ’流状态’
/// @param streamStateDidChanged ’流状态‘ 相对上一次 是否发生变化
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter streamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged;

/// 直播播放器 ‘码率可选项、当前码率、线路可选数、当前线路‘ 发生改变
///
/// @param playerPresenter 播放器管理器
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter
   currentDefinitionUrl:(NSString *)currentDefinitionUrl
       definitionsArray:(NSArray<NSDictionary *> *)definitionsArray
        codeRateOptions:(NSArray <NSString *> *)codeRateOptions
        currentCodeRate:(NSString *)currentCodeRate
                lineNum:(NSInteger)lineNum
       currentLineIndex:(NSInteger)currentLineIndex;

/// 直播播放器 需获知外部 ‘当前是否正在连麦’
///
/// @note 此回调不保证在主线程触发
///
/// @param playerPresenter 播放器管理器
- (BOOL)playerPresenterGetInLinkMic:(PLVPlayerPresenter *)playerPresenter;

/// 直播播放器 需获知外部 ‘当前是否暂停无延迟观看’
///
/// @note 此回调不保证在主线程触发
///
/// @param playerPresenter 播放器管理器
- (BOOL)playerPresenterGetPausedWatchNoDelay:(PLVPlayerPresenter *)playerPresenter;

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
///
/// @param playerPresenter 播放器管理器
/// @param noDelayLiveStart 当前最新的 ’无延迟直播开始结束状态’
/// @param noDelayLiveStartDidChanged ’无延迟直播开始结束状态‘ 相对上一次 是否发生变化
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter noDelayLiveStartUpdate:(BOOL)noDelayLiveStart noDelayLiveStartDidChanged:(BOOL)noDelayLiveStartDidChanged;

/// [快直播] 快直播网络质量检测
///
/// @param playerPresenter 播放器管理器
/// @param netWorkQuality 当前网络质量
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter quickLiveNetworkQuality:(PLVLivePlayerQuickLiveNetworkQuality)netWorkQuality;

/// [公共流] 公共流网络质量检测
///
/// @param playerPresenter 播放器管理器
/// @param netWorkQuality 当前网络质量
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter publicStreamNetworkQuality:(PLVPublicStreamPlayerNetworkQuality)netWorkQuality;

/// 播放器 广告‘正在播放状态’ 发生改变
///
/// @param playerPresenter 播放器管理器
/// @param playing 是否正在播放
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter advertViewPlayingStateDidChanged:(BOOL)playing;

#pragma mark 非直播相关
/// 直播回放播放器 定时返回当前播放进度
///
/// @param playerPresenter 播放器管理器
/// @param downloadProgress 已缓存进度 (0.0 ~ 1.0)
/// @param playedProgress 已播放进度 (0.0 ~ 1.0)
/// @param playedTimeString 当前播放时间点字符串 (示例 "01:23")
/// @param durationTimeString 总时长字符串 (示例 "01:23")
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter downloadProgress:(CGFloat)downloadProgress playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString;

/// 直播回放播放器 播放中断（网络原因或者其它原因）
- (void)playerPresenterPlaybackInterrupted:(PLVPlayerPresenter *)playerPresenter;

#pragma mark 画中画相关
/// 画中画即将开始
/// @param playerPresenter 播放器管理器
- (void)playerPresenterPictureInPictureWillStart:(PLVPlayerPresenter *)playerPresenter;

/// 画中画已经开始
/// @param playerPresenter 播放器管理器
- (void)playerPresenterPictureInPictureDidStart:(PLVPlayerPresenter *)playerPresenter;

/// 画中画开启失败
/// @param playerPresenter 播放器管理器
/// @param error 失败错误原因
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter pictureInPictureFailedToStartWithError:(NSError *)error;

/// 画中画即将停止
/// @param playerPresenter 播放器管理器
- (void)playerPresenterPictureInPictureWillStop:(PLVPlayerPresenter *)playerPresenter;

/// 画中画已经停止
/// @param playerPresenter 播放器管理器
- (void)playerPresenterPictureInPictureDidStop:(PLVPlayerPresenter *)playerPresenter;

/// 画中画播放器播放状态改变
/// @param playerPresenter 播放器管理器
/// @param playing 是否正在播放
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter pictureInPicturePlayerPlayingStateDidChange:(BOOL)playing;

@end

NS_ASSUME_NONNULL_END
