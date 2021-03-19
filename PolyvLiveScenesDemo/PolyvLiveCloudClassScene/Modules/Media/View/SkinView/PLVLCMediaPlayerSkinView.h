//
//  PLVLCMediaPlayerSkinView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/16.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCBasePlayerSkinView.h"

NS_ASSUME_NONNULL_BEGIN

/// 媒体播放器皮肤视图 (用于 竖屏时 显示)
///
/// @note 外部对 SkinView 的frame布局，无需特别考虑安全区域。SkinView 内部具备对安全区域的判断及兼容。
///       注意：在观看页中，竖屏与横屏场景，各用了对应的皮肤视图类，并会存在两个皮肤视图对象，即：
///       竖屏场景 --> PLVLCMediaPlayerSkinView
///       横屏场景 --> PLVLCLiveRoomPlayerSkinView
///       分开两个类，两个对象，目的是便于对两种场景的自定义需求；
///       但需注意的地方是，调试过程中，要有意识区分 ”当前你调试的是哪个对象？" 特别是当你在父类 PLVLCBasePlayerSkinView 中 输出打印 或 查看状态值 时；
@interface PLVLCMediaPlayerSkinView : PLVLCBasePlayerSkinView

/// 此类是 PLVLCBasePlayerSkinView 的子类，更多API详见 PLVLCBasePlayerSkinView.h

@end

NS_ASSUME_NONNULL_END
