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
@interface PLVLCMediaPlayerSkinView : PLVLCBasePlayerSkinView

/// 此类是 PLVLCBasePlayerSkinView 的子类，更多API详见 PLVLCBasePlayerSkinView.h

@end

NS_ASSUME_NONNULL_END
