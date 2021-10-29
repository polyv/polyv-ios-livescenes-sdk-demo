//
//  PLVHCLinkMicCanvasView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 互动学堂场景下负责承载 PLVLinkMicOnlineUser 的 rtcview 的容器
///
/// @note 负责承载 PLVLinkMicOnlineUser 的 rtcview；并负责UI业务；
///       PLVHCLinkMicCanvasView 应仅负责承载，可通过调用 [addRTCView:] 添加 rtcview；
@interface PLVHCLinkMicCanvasView : UIView

#pragma mark - [ 方法 ]
/// 添加 rtcview
- (void)addRTCView:(UIView *)rtcView;

/// 移除 rtcview
- (void)removeRTCView;

/// rtcview 隐藏/显示
///
/// @param rtcViewShow rtcview 隐藏或显示 (YES:显示 NO:隐藏)
- (void)rtcViewShow:(BOOL)rtcViewShow;

@end

NS_ASSUME_NONNULL_END
