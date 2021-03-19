//
//  PLVPlayerPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/12/11.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

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

#pragma mark 数据
/// 当前播放器的类型
@property (nonatomic, assign, readonly) PLVChannelVideoType currentVideoType;

/// 当前直播的 可选线路数量 (暂时仅直播支持)
@property (nonatomic, assign, readonly) NSInteger lineNum;

/// 当前直播的 线路下标 (由 0 起始；暂时仅直播支持)
@property (nonatomic, assign, readonly) NSInteger currentLineIndex;

/// 当前直播的 码率/清晰度 可选项字符串数组 (暂时仅直播支持)
@property (nonatomic, strong, readonly) NSArray <NSString *> * codeRateNamesOptions;

/// 当前直播的 码率/清晰度 (暂时仅直播支持)
@property (nonatomic, copy, readonly) NSString * currentCodeRate;

/// 当前直播回放的 播放时间点 (单位:秒；仅非直播场景下有值)
@property (nonatomic, readonly) NSTimeInterval currentPlaybackTime;

/// 当前直播回放的 视频总时长 (单位:秒；仅非直播场景下有值)
@property (nonatomic, readonly) NSTimeInterval duration;

/// 广告跳转链接
@property (nonatomic, readonly) NSString *advLinkUrl;

/// 广告播放状态
@property (nonatomic, readonly) BOOL advPlaying;

/// 广告播放状态
@property (nonatomic, assign) BOOL openAdv;

#pragma mark 状态
/// 该频道是否观看 ‘无延迟直播’
@property (nonatomic, assign, readonly) BOOL channelWatchNoDelay;

/// 无延迟直播的当前 ‘开始结束状态’
@property (nonatomic, assign, readonly) BOOL currentNoDelayLiveStart;

#pragma mark UI
/// 外部传入的，负责承载播放器画面的父视图
///
/// @note 需调用 [setupPlayerWithDisplayView:] 方法来设置
@property (nonatomic, weak, readonly) UIView * displayView;

#pragma mark - [ 方法 ]
#pragma mark 通用
/// 创建 播放器
///
/// @param videoType 视频类型
- (instancetype)initWithVideoType:(PLVChannelVideoType)videoType;

/// 设置 承载播放器画面 的父视图
///
/// @param displayView 承载播放器画面的父视图
- (void)setupPlayerWithDisplayView:(UIView *)displayView;

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

#pragma mark 非直播相关
/// 跳至某个时间点 (单位: 秒)
- (void)seekLivePlaybackToTime:(NSTimeInterval)toTime;

/// 切换倍速 (范围值 0.0~2.0)
- (void)switchLivePlaybackSpeedRate:(CGFloat)toSpeed;

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
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo;

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
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter codeRateOptions:(NSArray <NSString *> *)codeRateOptions currentCodeRate:(NSString *)currentCodeRate lineNum:(NSInteger)lineNum currentLineIndex:(NSInteger)currentLineIndex;

/// 直播播放器 需获知外部 ‘当前是否正在连麦’
///
/// @note 此回调不保证在主线程触发
///
/// @param playerPresenter 播放器管理器
- (BOOL)playerPresenterGetInLinkMic:(PLVPlayerPresenter *)playerPresenter;

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
///
/// @param playerPresenter 播放器管理器
/// @param noDelayLiveStart 当前最新的 ’无延迟直播开始结束状态’
/// @param noDelayLiveStartDidChanged ’无延迟直播开始结束状态‘ 相对上一次 是否发生变化
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter noDelayLiveStartUpdate:(BOOL)noDelayLiveStart noDelayLiveStartDidChanged:(BOOL)noDelayLiveStartDidChanged;

#pragma mark 非直播相关
/// 直播回放播放器 定时返回当前播放进度
///
/// @param playerPresenter 播放器管理器
/// @param downloadProgress 已缓存进度 (0.0 ~ 1.0)
/// @param playedProgress 已播放进度 (0.0 ~ 1.0)
/// @param playedTimeString 当前播放时间点字符串 (示例 "01:23")
/// @param durationTimeString 总时长字符串 (示例 "01:23")
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter downloadProgress:(CGFloat)downloadProgress playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString;

@end

NS_ASSUME_NONNULL_END
