//
//  PLVLiveMarqueeView.h
//  PLVFoundationSDK
//
//  Created by PLV-UX on 2021/3/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLiveMarqueeModel.h"
NS_ASSUME_NONNULL_BEGIN

/// 跑马灯2.0，适用于防录屏功能使用
@interface PLVLiveMarqueeView : UIView

/// 设置跑马灯样式(需要手动启动跑马灯动画)
/// @param marqueeModel model
- (void)setPLVLiveMarqueeModel:(PLVLiveMarqueeModel *)marqueeModel;

/// 启动跑马灯
- (void)start;

/// 暂停跑马灯
- (void)pause;

/// 停止跑马灯
- (void)stop;

@end

NS_ASSUME_NONNULL_END
