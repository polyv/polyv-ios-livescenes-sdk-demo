//
//  PLVECPlayerViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/3.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

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
                    line:(NSInteger)line;

#pragma mark 回放的回调

/// 更新回放进度
- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime;

@end

@interface PLVECPlayerViewController : UIViewController

@property (nonatomic, weak) id<PLVECPlayerViewControllerProtocol> delegate;

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

#pragma mark 回放的API

/// seek进度
- (void)seek:(NSTimeInterval)time;

/// 切换速率
- (void)speedRate:(NSTimeInterval)speed;

@end

NS_ASSUME_NONNULL_END
