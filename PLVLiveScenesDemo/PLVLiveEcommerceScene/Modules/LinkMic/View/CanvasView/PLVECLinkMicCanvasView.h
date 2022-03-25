//
//  PLVECLinkMicCanvasView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/10/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 直播带货场景下 PLVLinkMicOnlineUser 的 rtcview 的容器
///
/// @note 负责承载 PLVLinkMicOnlineUser 的 rtcview；并负责直播带货场景的UI业务；
///       PLVLCLinkMicCanvasView 应仅负责承载，可通过调用 [addRTCView:] 添加 rtcview；
@interface PLVECLinkMicCanvasView : UIView

#pragma mark - [ 方法 ]
/// 添加 rtcview
- (void)addRTCView:(UIView *)rtcView;

/// 移除 rtcview
- (void)removeRTCView;

/// rtcview 隐藏/显示
///
/// @param rtcViewShow rtcview 隐藏或显示 (YES:显示 NO:隐藏)
- (void)rtcViewShow:(BOOL)rtcViewShow;

/// pauseWatchNoDelayImageView 隐藏/显示
///
/// @param show pauseWatchNoDelayImageView 隐藏或显示 (YES:显示 NO:隐藏)
- (void)pauseWatchNoDelayImageViewShow:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
