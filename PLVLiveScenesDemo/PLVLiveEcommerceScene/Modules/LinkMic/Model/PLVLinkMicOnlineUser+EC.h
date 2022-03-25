//
//  PLVLinkMicOnlineUser+EC.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/10/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLinkMicOnlineUser.h"

#import "PLVECLinkMicCanvasView.h"

NS_ASSUME_NONNULL_BEGIN

/// RTC在线用户模型 针对 EcommerceScene直播带货场景 的UI扩展
@interface PLVLinkMicOnlineUser (EC)

/// rtcview 的容器
///
/// @note PLVLinkMicOnlineUser 的 rtcview 的容器，负责承载 rtcview；
///       [区别] rtcview : 是 PLVLinkMicOnlineUser 的属性，负责渲染 ’RTC画面‘
///       [区别] canvasView : 是 PLVLinkMicOnlineUser 的扩展属性，负责承载 rtcview；并负责直播带货场景的UI业务；
///       canvasView 可能会被添加至外部视图类中；
///       当 canvasView 被添加至外部时，仍被 PLVLinkMicOnlineUser 持有管理，仅 subview 图层关系改变；
@property (nonatomic, strong) PLVECLinkMicCanvasView * canvasView;

@end

NS_ASSUME_NONNULL_END
