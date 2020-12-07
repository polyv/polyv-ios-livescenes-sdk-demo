//
//  PLVLivePlayerPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/9.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVBasePlayerPresenter.h"
#import "PLVLivePlayerViewModel.h"

@class PLVLivePlayerPresenter;
@protocol PLVLivePlayerPresenterDelegate <PLVPlayerPresenterDelegate>

@optional

/// 直播播放器状态改变回调
- (void)presenter:(PLVLivePlayerPresenter *)presenter livePlayerStateDidChange:(LivePlayerState)livePlayerState;

- (void)presenterPlayingChanged:(PLVLivePlayerPresenter *)presenter;

/// 仅在非连麦场景下，此回调应被处理。连麦场景下，此回调应被忽略
- (void)presenter:(PLVLivePlayerPresenter *)presenter cdnPlayerPPTSiteExchange:(BOOL)wannaCDNPlayerOnMainSite;

/// 频道播放选项信息更新
- (void)presenterChannelPlayOptionInfoDidUpdate:(PLVLivePlayerPresenter *)presenter;

@end

typedef void(^LoadPlayerCompletionBlock)(NSError *error);

@interface PLVLivePlayerPresenter : PLVBasePlayerPresenter

@property (nonatomic, strong, readonly) PLVLivePlayerViewModel *viewModel;

@property (nonatomic, strong, readonly) PLVLivePlayerController *player;

@property (nonatomic, weak) id<PLVLivePlayerPresenterDelegate> view;

@property (nonatomic, assign) BOOL linkMic;

/// 播放直播
- (void)playLive;

/// 暂停直播
- (void)pauseLive;

/// 播放/刷新/重新加载直播
- (void)reloadLive:(LoadPlayerCompletionBlock)completioin;

/// 切换线路
- (void)switchPlayLine:(NSUInteger)Line completion:(LoadPlayerCompletionBlock)completioin;

/// 切换码率
- (void)switchPlayCodeRate:(NSString *)codeRate completion:(LoadPlayerCompletionBlock)completioin;

/// 切换音频模式
- (void)switchAudioMode:(BOOL)audioMode;

@end
