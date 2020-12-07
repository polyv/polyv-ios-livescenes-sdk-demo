//
//  PLVLiveRoomManager.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/8/3.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVLiveRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLiveRoomManager : NSObject

/// 初始化方法
- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData;

/// 获取直播详情数据
- (void)requestLiveDetail;

/// 上报观看热度
- (void)requestPageview;

@end

NS_ASSUME_NONNULL_END
