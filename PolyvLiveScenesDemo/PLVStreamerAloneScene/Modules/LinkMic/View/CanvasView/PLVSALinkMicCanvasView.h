//
//  PLVSALinkMicCanvasView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播-纯视频场景下负责承载 PLVLinkMicOnlineUser 的 rtcview 的容器
///
/// @note 负责承载 PLVLinkMicOnlineUser 的 rtcview；并负责UI业务；
///       PLVSALinkMicCanvasView 应仅负责承载，可通过调用 [addRTCView:] 添加 rtcview；
@interface PLVSALinkMicCanvasView : UIView

#pragma mark - [ 属性 ]

/// 背景视图 (负责展示 占位图)
//@property (nonatomic, strong, readonly) UIImageView * placeholderImageView;

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
