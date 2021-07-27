//
//  PLVLinkMicOnlineUser+SA.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLinkMicOnlineUser.h"

#import "PLVSALinkMicCanvasView.h"

NS_ASSUME_NONNULL_BEGIN

/// RTC在线用户模型 针对 LiveStreamerScene 手机开播-纯视频场景的UI扩展
@interface PLVLinkMicOnlineUser (SA)

/// rtcview 的容器
///
/// @note PLVLinkMicOnlineUser 的 rtcview 的容器，负责承载 rtcview；
///       [区别] rtcview : 是 PLVLinkMicOnlineUser 的属性，负责渲染 ’RTC画面‘
///       [区别] canvasView : 是 PLVLinkMicOnlineUser 的扩展属性，负责承载 rtcview；并负责手机开播场景的UI业务；
///       canvasView 可能会被移动、添加至外部视图类中；
///       当 canvasView 被移动、添加至外部时，仍被 PLVLinkMicOnlineUser 持有管理，仅 subview 图层关系改变；
@property (nonatomic, strong) PLVSALinkMicCanvasView *canvasView;

@end

NS_ASSUME_NONNULL_END
