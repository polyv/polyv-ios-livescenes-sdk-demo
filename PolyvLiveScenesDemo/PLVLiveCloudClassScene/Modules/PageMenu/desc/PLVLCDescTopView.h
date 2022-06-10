//
//  PLVLCDescTopView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVLiveVideoChannelMenuInfo;

typedef NS_ENUM(NSInteger, PLVLCLiveStatus) {
    PLVLCLiveStatusNone = 0,   // 暂无直播
    PLVLCLiveStatusWaiting,    // 等待直播
    PLVLCLiveStatusUnStart,    // 未开始
    PLVLCLiveStatusLiving,     // 直播中
    PLVLCLiveStatusEnd,        // 直播已结束
    PLVLCLiveStatusStop,       // 直播暂停
    PLVLCLiveStatusPlayback,    // 回放中
    PLVLCLiveStatusCached       // 已缓存
};

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCDescTopView : UIView

@property (nonatomic, copy) PLVLiveVideoChannelMenuInfo *channelInfo;

/// 直播状态
@property (nonatomic, assign) PLVLCLiveStatus status;

@end

NS_ASSUME_NONNULL_END
