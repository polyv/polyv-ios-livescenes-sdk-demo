//
//  PLVLCDescViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCDescTopView.h"

@class PLVLiveVideoChannelMenuInfo;

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCDescViewController : UIViewController

- (instancetype)initWithChannelInfo:(PLVLiveVideoChannelMenuInfo *)channelInfo content:(NSString *)content;

/// 直播状态改变时调用
- (void)updateLiveStatus:(PLVLCLiveStatus)liveStatus;

@end

NS_ASSUME_NONNULL_END
