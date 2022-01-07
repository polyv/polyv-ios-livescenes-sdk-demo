//
//  PLVECPlayerViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/3.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 网络质量（快直播独有）
typedef NS_ENUM(NSInteger, PLVECLivePlayerQuickLiveNetworkQuality) {
    PLVECLivePlayerQuickLiveNetworkQuality_NoConnection = 0,   // 无网络
    PLVECLivePlayerQuickLiveNetworkQuality_Good = 1,           // 良好
    PLVECLivePlayerQuickLiveNetworkQuality_Middle = 2,         // 一般
    PLVECLivePlayerQuickLiveNetworkQuality_Poor = 3            // 较差
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

#pragma mark 回放的回调

/// 更新回放进度
- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime;

#pragma mark  无延迟播放的回调

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
- (void)playerController:(PLVECPlayerViewController *)playerController
  noDelayLiveStartUpdate:(BOOL)noDelayLiveStart;

#pragma mark 跑马灯的回调

/// 跑马灯校验失败回调
- (void)customMarqueeDefaultWithError:(NSError *)error;

@end

@interface PLVECPlayerViewController : UIViewController

@property (nonatomic, weak) id<PLVECPlayerViewControllerProtocol> delegate;

// 播放器区域 解决事件传递响应链的问题
@property (nonatomic, strong, readonly) UIView *displayView;

/// 播放器播放状态
@property (nonatomic, assign, readonly) BOOL playing;

/// 广告跳转链接
@property (nonatomic, readonly) NSString *advLinkUrl;

/// 广告播放状态
@property (nonatomic, readonly) BOOL advPlaying;

/// 播放直播/回放
- (void)play;

/// 暂停直播/回放
- (void)pause;

/// 静音 播放器
- (void)mute;

/// 取消静音 播放器
- (void)cancelMute;

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

#pragma mark 回放的API

/// seek进度
- (void)seek:(NSTimeInterval)time;

/// 切换速率
- (void)speedRate:(NSTimeInterval)speed;

#pragma mark 视图

/// 在[无延迟播放场景] 下 播放器区域中展示的一个内容视图
- (void)displayContentView:(UIView *)contentView;

@end

NS_ASSUME_NONNULL_END
