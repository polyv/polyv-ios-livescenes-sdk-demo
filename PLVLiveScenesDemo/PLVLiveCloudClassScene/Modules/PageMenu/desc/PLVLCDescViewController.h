//
//  PLVLCDescViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVLiveVideoChannelMenuInfo;

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCDescViewController : UIViewController

- (instancetype)initWithChannelInfo:(PLVLiveVideoChannelMenuInfo *)channelInfo content:(NSString *)content;

/// 直播状态改变时调用，调用该方法自动将 inPlaybackScene 置为 NO
- (void)updateliveStatue:(BOOL)living;

@end

NS_ASSUME_NONNULL_END
