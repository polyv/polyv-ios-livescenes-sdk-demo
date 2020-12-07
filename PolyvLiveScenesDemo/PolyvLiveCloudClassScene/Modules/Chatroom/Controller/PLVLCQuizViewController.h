//
//  PLVLCQuizViewController.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVLiveRoomData;

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCQuizViewController : UIViewController

/// 初始化方法
- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData;

/// 清理资源
- (void)clearResource;

@end

NS_ASSUME_NONNULL_END
