//
//  PLVECPlayerViewController.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/3.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLiveRoomData.h"
#import "PLVLivePlayerPresenter.h"
#import "PLVPlaybackPlayerPresenter.h"

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
- (void)updateDowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration;

/// 主播放器已结束播放
- (void)presenter:(PLVPlaybackPlayerPresenter *)presenter mainPlayerPlaybackDidFinish:(NSDictionary *)dataInfo;

@end

@interface PLVECPlayerViewController : UIViewController

@property (nonatomic, weak) id<PLVECPlayerViewControllerProtocol> delegate;

@property (nonatomic, strong, readonly) PLVLivePlayerPresenter *livePresenter;
@property (nonatomic, strong, readonly) PLVPlaybackPlayerPresenter *playbackPresenter;

/// 初始化方法
- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData;

/// 播放直播/回放
- (void)play;

/// 暂停直播/回放
- (void)pause;

/// 销毁方法
- (void)destroy;

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
