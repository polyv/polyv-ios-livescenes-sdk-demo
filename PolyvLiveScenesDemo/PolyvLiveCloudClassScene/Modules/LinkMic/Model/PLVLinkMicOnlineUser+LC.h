//
//  PLVLinkMicOnlineUser+LC.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/10/23.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLinkMicOnlineUser.h"

#import "PLVLCLinkMicCanvasView.h"

NS_ASSUME_NONNULL_BEGIN

/// 连麦用户Model针对 LiveCloudClass云课堂场景 的UI扩展
@interface PLVLinkMicOnlineUser (LC)

/// 连麦rtc画布视图
///
/// @note 连麦用户的rtcview的容器，负责承载 RTC画面；
///       可能会被移动添加至其他视图类中；
///       当被移动添加至外部时，仍被 PLVLinkMicOnlineUser 持有管理，仅 subview 图层关系改变；
@property (nonatomic, strong) PLVLCLinkMicCanvasView * canvasView;

@end

NS_ASSUME_NONNULL_END
