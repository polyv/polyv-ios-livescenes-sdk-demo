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

/// RTC在线用户模型 针对 LiveCloudClass云课堂场景 的UI扩展
@interface PLVLinkMicOnlineUser (LC)

/// rtcview 的容器
///
/// @note PLVLinkMicOnlineUser 的 rtcview 的容器，负责承载 rtcview；
///       [区别] rtcview : 是 PLVLinkMicOnlineUser 的属性，负责渲染 ’RTC画面‘
///       [区别] canvasView : 是 PLVLinkMicOnlineUser 的扩展属性，负责承载 rtcview；并负责云课堂场景的UI业务；
///       canvasView 可能会被移动、添加至外部视图类中；
///       当 canvasView 被移动、添加至外部时，仍被 PLVLinkMicOnlineUser 持有管理，仅 subview 图层关系改变；
@property (nonatomic, strong) PLVLCLinkMicCanvasView * canvasView;

@end

NS_ASSUME_NONNULL_END
