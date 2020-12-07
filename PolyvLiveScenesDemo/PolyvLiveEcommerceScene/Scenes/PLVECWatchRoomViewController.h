//
//  PLVECWatchRoomViewController.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/12/1.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLiveRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECWatchRoomViewController : UIViewController

/// 初始化当前控制器方法
- (instancetype)initWithLiveRoomData:(PLVLiveRoomData *)roomData;

@end

NS_ASSUME_NONNULL_END
