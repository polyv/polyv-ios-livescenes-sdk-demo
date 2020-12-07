//
//  PLVBasePlayerViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/10.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVBasePlayerViewModel.h"
#import <PLVLiveScenesSDK/PLVPlayerControllerPrivateProtocol.h>

@implementation PLVBasePlayerViewModel

- (PLVPlayerScalingMode)scalingMode {
    if ([self.player conformsToProtocol:@protocol(PLVPlayerControllerPrivateProtocol)]) {
        id<PLVPlayerControllerPrivateProtocol> playerVC = self.player;
        return (PLVPlayerScalingMode)playerVC.mainPlayer.scalingMode;
    }
    return -1;
}

- (PLVPlayerLoadState)loadState {
    if ([self.player conformsToProtocol:@protocol(PLVPlayerControllerPrivateProtocol)]) {
        id<PLVPlayerControllerPrivateProtocol> playerVC = self.player;
        return (PLVPlayerLoadState)playerVC.mainPlayer.loadState;
    }
    return -1;
}

- (PLVPlayerPlaybackState)playbackState {
    if ([self.player conformsToProtocol:@protocol(PLVPlayerControllerPrivateProtocol)]) {
        id<PLVPlayerControllerPrivateProtocol> playerVC = self.player;
        return (PLVPlayerPlaybackState)playerVC.mainPlayer.playbackState;
    }
    return -1;
}

@end
