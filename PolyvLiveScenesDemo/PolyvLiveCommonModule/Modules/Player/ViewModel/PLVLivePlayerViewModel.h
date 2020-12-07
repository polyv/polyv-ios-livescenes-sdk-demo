//
//  PLVLivePlayerViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/9.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVBasePlayerViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LivePlayerState) {
    LivePlayerStateUnknown = 0,  // 状态未知
    LivePlayerStateEnd     = 1,  // 无直播
    LivePlayerStateWarmUp  = 2,  // 暖场播放
    LivePlayerStateLiving  = 3,  // 直播中
    LivePlayerStatePause   = 4,  // 直播暂停
};

@interface PLVLivePlayerViewModel : PLVBasePlayerViewModel

@property (nonatomic, assign) LivePlayerState livePlayerState; // 直播播放器状态

@property (nonatomic, assign) BOOL reOpening; // 是否正在加载channelJSON

@property (nonatomic, assign) BOOL warmUpPlaying; // 是否在暖场播放

@end

NS_ASSUME_NONNULL_END
