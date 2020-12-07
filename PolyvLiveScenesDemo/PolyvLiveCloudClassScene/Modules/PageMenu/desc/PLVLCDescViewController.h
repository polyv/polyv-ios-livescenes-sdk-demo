//
//  PLVLCDescViewController.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVLiveVideoChannelMenuInfo;

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCDescViewController : UIViewController

/// 是否处于云课堂回放场景，默认为 NO - 直播场景
@property (nonatomic, assign) BOOL inPlaybackScene;

- (instancetype)initWithChannelInfo:(PLVLiveVideoChannelMenuInfo *)channelInfo content:(NSString *)content;

/// 直播状态改变时调用，调用该方法自动将 inPlaybackScene 置为 NO
- (void)liveStatueChange:(BOOL)living;

@end

NS_ASSUME_NONNULL_END
