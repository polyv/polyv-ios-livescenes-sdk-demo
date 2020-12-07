//
//  PLVLCMenuAreaView.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/23.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCChatViewController.h"

@class PLVLiveVideoChannelMenuInfo, PLVLiveRoomData;

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCLivePageMenuAreaView : UIView

/// 是否处于云课堂回放场景，默认为 NO - 直播场景
@property (nonatomic, assign) BOOL inPlaybackScene;

/// 互动聊天页
@property (nonatomic, strong) PLVLCChatViewController *chatVctrl;

- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom roomData:(PLVLiveRoomData *)roomData;

/// 直播状态改变时调用，调用该方法自动将 inPlaybackScene 置为 NO
- (void)liveStatueChange:(BOOL)living;

/// 清理资源
- (void)clearResource;

@end

NS_ASSUME_NONNULL_END
