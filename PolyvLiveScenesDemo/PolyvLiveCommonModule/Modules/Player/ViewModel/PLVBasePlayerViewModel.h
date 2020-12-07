//
//  PLVBasePlayerViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/10.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVPlayerScalingMode) {
    PLVPlayerScalingModeNone       = 0, // No scaling
    PLVPlayerScalingModeAspectFit,      // Uniform scale until one dimension fits
    PLVPlayerScalingModeAspectFill,     // Uniform scale until the movie fills the visible bounds. One dimension may have clipped contents
    PLVPlayerScalingModeFill            // Non-uniform scale. Both render dimensions will exactly match the visible bounds
};

typedef NS_ENUM(NSInteger, PLVPlayerPlaybackState) {
    PLVPlayerPlaybackStateStopped = 0,
    PLVPlayerPlaybackStatePlaying,
    PLVPlayerPlaybackStatePaused,
    PLVPlayerPlaybackStateInterrupted,
    PLVPlayerPlaybackStateSeekingForward,
    PLVPlayerPlaybackStateSeekingBackward
};

typedef NS_OPTIONS(NSUInteger, PLVPlayerLoadState) {
    PLVPlayerLoadStateUnknown        = 0,
    PLVPlayerLoadStatePlayable       = 1 << 0,
    PLVPlayerLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    PLVPlayerLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
};

typedef NS_ENUM(NSInteger, PLVPlayerFinishReason) {
    PLVPlayerFinishReasonPlaybackEnded = 0,
    PLVPlayerFinishReasonPlaybackError,
    PLVPlayerFinishReasonUserExited
};

@interface PLVBasePlayerViewModel : NSObject

@property (nonatomic, weak) id player;

@property (nonatomic, assign) PLVPlayerScalingMode scalingMode;

@property (nonatomic, assign) PLVPlayerPlaybackState playbackState;

@property (nonatomic, assign) PLVPlayerLoadState loadState;

@end

NS_ASSUME_NONNULL_END
