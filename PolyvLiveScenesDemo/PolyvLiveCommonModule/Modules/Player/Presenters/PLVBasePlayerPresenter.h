//
//  PLVBasePlayerPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/10.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PLVLiveRoomData.h"
#import "PLVBasePlayerViewModel.h"

#define PLVPlayerPlaybackDidFinishReasonDataInfoKey @"PLVPlayerPlaybackDidFinishReasonDataInfoKey"

NS_ASSUME_NONNULL_BEGIN

@class PLVBasePlayerPresenter;
@protocol PLVPlayerPresenterDelegate <NSObject>

@optional

/// 加载主播放器失败（原因：1.网络请求失败；2.如果是直播，该频道设置了限制条件）
- (void)presenter:(PLVBasePlayerPresenter *)presenter loadMainPlayerFailure:(NSString *)message;

/// 播放器状态改变的Message消息回调
- (void)presenter:(PLVBasePlayerPresenter *)presenter showMessage:(NSString *)message;

/// 改变视频所在窗口（主屏或副屏）的底色
- (void)changePlayerScreenBackgroundColor:(PLVBasePlayerPresenter *)presenter;

/// 主播放器获取到播放视频源的大小时执行回调
- (void)presenter:(PLVBasePlayerPresenter *)presenter videoSizeChange:(CGSize)videoSize;

/// 主播放器已准备好开始播放正片
- (void)presenter:(PLVBasePlayerPresenter *)presenter mainPlaybackIsPreparedToPlay:(NSDictionary *)dataInfo;

/// 主播放器加载状态改变
- (void)presenter:(PLVBasePlayerPresenter *)presenter mainPlayerLoadStateDidChange:(PLVPlayerLoadState)loadState;

/// 主播放器播放状态改变
- (void)presenter:(PLVBasePlayerPresenter *)presenter mainPlayerPlaybackStateDidChange:(PLVPlayerPlaybackState)playbackState;

/// 主播放器已结束播放
/// PLVPlayerPlaybackDidFinishReasonDataInfoKey NSNumber (PLVPlayerFinishReason)
- (void)presenter:(PLVBasePlayerPresenter *)presenter mainPlayerPlaybackDidFinish:(NSDictionary *)dataInfo;

/// 主播器解析SEI信息回调
- (void)presenter:(PLVBasePlayerPresenter *)presenter mainPlayerSeiDidChange:(long)timeStamp newTimeStamp:(long)newTimeStamp;

/// 频道信息更新
- (void)presenterChannelInfoChanged:(PLVBasePlayerPresenter *)presenter;

@end

@interface PLVBasePlayerPresenter : NSObject

@property (nonatomic, strong) PLVLiveRoomData *roomData;

/// 初始化方法
- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData;

- (void)setupPlayerWithDisplayView:(UIView *)displayView;

/// 根据视频源大小重新设置播放器大小、位置
- (void)setPlayerFrame:(CGRect)rect;

- (void)destroy;

- (void)cleanAllPlayers;

@end

NS_ASSUME_NONNULL_END
