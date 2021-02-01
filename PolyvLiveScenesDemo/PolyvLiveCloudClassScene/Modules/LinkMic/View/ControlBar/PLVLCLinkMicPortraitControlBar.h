//
//  PLVLCLinkMicPortraitControlBar.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/7/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCLinkMicControlBarProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 连麦悬浮控制栏 (用于 竖屏时 显示)
///
/// @note 负责展示 ‘申请连麦’、‘挂断连麦’、‘开关音视频硬件’ 等控件
///       外部可通过 [refreshControlBarFrame:] 方法设置 frame 大小，而无需外部计算frame值
@interface PLVLCLinkMicPortraitControlBar : UIView <PLVLCLinkMicControlBarProtocol>

/// 此类遵循 <PLVLCLinkMicControlBarProtocol> 实现，具体API详见 PLVLCLinkMicControlBarProtocol.h

@end

NS_ASSUME_NONNULL_END
