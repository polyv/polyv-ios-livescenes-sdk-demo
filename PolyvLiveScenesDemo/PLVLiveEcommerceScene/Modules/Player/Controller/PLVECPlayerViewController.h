//
//  PLVECPlayerViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/3.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVPlayerPresenter.h"
#import "PLVLiveMarqueeView.h"

/// 网络质量（快直播独有）
typedef NS_ENUM(NSInteger, PLVECLivePlayerQuickLiveNetworkQuality) {
    PLVECLivePlayerQuickLiveNetworkQuality_NoConnection = 0,   // 无网络
    PLVECLivePlayerQuickLiveNetworkQuality_Good = 1,           // 良好
    PLVECLivePlayerQuickLiveNetworkQuality_Middle = 2,         // 一般
    PLVECLivePlayerQuickLiveNetworkQuality_Poor = 3            // 较差
};

/// 网络质量（公共流独有）
typedef NS_ENUM(NSInteger, PLVECLivePlayerPublicStreamNetworkQuality) {
    PLVECLivePlayerPublicStreamNetworkQuality_NoConnection = 0,   // 无网络
    PLVECLivePlayerPublicStreamNetworkQuality_Good = 1,           // 良好
    PLVECLivePlayerPublicStreamNetworkQuality_Middle = 2,         // 一般
    PLVECLivePlayerPublicStreamNetworkQuality_Poor = 3            // 较差
};

@class PLVECPlayerViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECPlayerViewControllerProtocol <NSObject>

@optional

#pragma mark 直播的回调

/// 刷新皮肤的多码率和多线路的按钮
- (void)playerController:(PLVECPlayerViewController *)playerController
           codeRateItems:(NSArray <NSString *>*)codeRateItems
                codeRate:(NSString *)codeRate
                   lines:(NSUInteger)lines
                    line:(NSInteger)line
        noDelayWatchMode:(BOOL)noDelayWatchMode;

/// 快直播观看下的网络质量回调
- (void)playerController:(PLVECPlayerViewController *)playerController
 quickLiveNetworkQuality:(PLVECLivePlayerQuickLiveNetworkQuality)netWorkQuality;

/// 公共流观看下的网络质量回调
- (void)playerController:(PLVECPlayerViewController *)playerController
 publicStreamNetworkQuality:(PLVECLivePlayerPublicStreamNetworkQuality)netWorkQuality;

- (void)playerControllerWannaSwitchLine:(PLVECPlayerViewController *)playerController;

- (void)playerControllerWannaFullScreen:(PLVECPlayerViewController *)playerController;

#pragma mark 回放的回调

/// 更新回放进度
- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
  currentPlaybackTimeInterval:(NSTimeInterval)currentPlaybackTimeInterval
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime;

/// 播放器 ‘回放视频信息’ 发生改变
- (void)playerController:(PLVECPlayerViewController *)playerController playbackVideoInfoDidUpdated:(PLVPlaybackVideoInfoModel *)videoInfo;

/// 播放器续播回调
- (void)playerControllerShowMemoryPlayTip:(PLVECPlayerViewController *)playerController;

#pragma mark  无延迟播放的回调

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
- (void)playerController:(PLVECPlayerViewController *)playerController
  noDelayLiveStartUpdate:(BOOL)noDelayLiveStart;

/// [无延迟直播] 无延迟观看模式 发生改变
///
/// @note 仅 无延迟直播 频道会触发，快直播不会触发该回调；
- (void)playerController:(PLVECPlayerViewController *)playerController noDelayWatchModeSwitched:(BOOL)noDelayWatchMode;

/// [无延迟直播] 无延迟直播 ‘播放或暂停’
- (void)playerController:(PLVECPlayerViewController *)playerController noDelayLiveWannaPlay:(BOOL)wannaPlay;

/// 播放器视图需要得知当前‘是否暂停无延迟观看’
- (BOOL)playerControllerGetPausedWatchNoDelay:(PLVECPlayerViewController *)playerController;

#pragma mark 跑马灯的回调

/// 跑马灯校验失败回调
- (void)customMarqueeDefaultWithError:(NSError *)error;

#pragma mark 画中画的回调
/// 画中画即将开始
/// @param playerController 播放器管理器
- (void)playerControllerPictureInPictureWillStart:(PLVECPlayerViewController *)playerController;

/// 画中画已经开始
/// @param playerController 播放器管理器
- (void)playerControllerPictureInPictureDidStart:(PLVECPlayerViewController *)playerController;

/// 画中画开启失败
/// @param playerController 播放器管理器
/// @param error 失败错误原因
- (void)playerController:(PLVECPlayerViewController *)playerController pictureInPictureFailedToStartWithError:(NSError *)error;

/// 画中画即将停止
/// @param playerController 播放器管理器
- (void)playerControllerPictureInPictureWillStop:(PLVECPlayerViewController *)playerController;

/// 画中画已经停止
/// @param playerController 播放器管理器
- (void)playerControllerPictureInPictureDidStop:(PLVECPlayerViewController *)playerController;

/// 画中画播放器播放状态改变
/// @param playerController 播放器管理器
/// @param playing  是否播放器中 YES 播放，NO 暂停
- (void)playerController:(PLVECPlayerViewController *)playerController pictureInPicturePlayingStateDidChange:(BOOL)playing;

@end

@interface PLVECPlayerViewController : UIViewController

@property (nonatomic, weak) id<PLVECPlayerViewControllerProtocol> delegate;

// 播放器区域 解决事件传递响应链的问题
@property (nonatomic, strong, readonly) UIView *displayView;

/// 跑马灯视图
@property (nonatomic, strong, readonly) PLVLiveMarqueeView *marqueeView;

/// 播放器播放状态
@property (nonatomic, assign, readonly) BOOL playing;

/// 播放器播放状态
@property (nonatomic, assign, readonly) BOOL fullScreenEnable;

/// 广告播放状态
@property (nonatomic, readonly) BOOL advertPlaying;

/// 是否为无延迟模式
@property (nonatomic, readonly) BOOL noDelayWatchMode;

/// 播放器当前是否正在播放无延迟直播
@property (nonatomic, assign, readonly) BOOL noDelayLiveWatching;

/// 该频道是否 ‘直播中’ 
@property (nonatomic, assign, readonly) BOOL channelInLive;

/// 是否在iPad上显示全屏按钮
///
/// @note NO-在iPad上竖屏时不显示全屏按钮，YES-显示
///       当项目未适配分屏时，建议设置为YES
@property (nonatomic,assign) BOOL fullScreenButtonShowOnIpad;

/// 当前直播回放的 最大播放时间点 (单位:秒；仅非直播场景下有值)
@property (nonatomic, readonly) NSTimeInterval playbackMaxPosition;

/// 播放直播/回放
- (void)play;

/// 暂停直播/回放
- (void)pause;

/// 静音 播放器
- (void)mute;

/// 取消静音 播放器
- (void)cancelMute;

/// 清理播放器
- (void)cleanPlayer;

#pragma mark 直播的API

/// 播放/刷新/重新加载直播
- (void)reload;

/// 切换线路
- (void)switchPlayLine:(NSUInteger)Line showHud:(BOOL)showHud;

/// 切换码率
- (void)switchPlayCodeRate:(NSString *)codeRate showHud:(BOOL)showHud;

/// 切换音频模式
- (void)switchAudioMode:(BOOL)audioMode;

/// 切换到无延迟观看模式
/// noDelayWatchMode : YES  无延迟观看 noDelayWatchMode : NO 普通延迟观看
- (void)switchToNoDelayWatchMode:(BOOL)noDelayWatchMode;

/// 开启画中画功能
- (void)startPictureInPicture;

/// 关闭画中画功能
- (void)stopPictureInPicture;

#pragma mark 回放的API

/// seek进度
- (void)seek:(NSTimeInterval)time;

/// 切换速率
- (void)speedRate:(NSTimeInterval)speed;

/// 切换回放
- (void)changeVid:(NSString *)vid;

#pragma mark 视图

/// 在[无延迟播放场景] 下 播放器区域中展示的一个内容视图
- (void)displayContentView:(UIView *)contentView;

/// 在[直播场景]下 控制播放器区域全屏按钮显示/隐藏
- (void)fullScreenButtonShowInView:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
