//
//  PLVLCLinkMicCanvasView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/22.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 连麦RTC画布视图
///
/// @note 负责承载 RTC画面；
///       此View应仅负责承载，可通过调用 [addRTCView:] 添加RTC画面 (RTC画面不应直接渲染在此View上，避免画面变动而产生多次渲染问题)
@interface PLVLCLinkMicCanvasView : UIView

@property (nonatomic, strong, readonly) UIImageView * placeholderImageView; // 背景视图 (负责展示 占位图)

/// 添加RTC画面
///
/// @note 仅负责承载
///
/// @param rtcView RTC画面视图
- (void)addRTCView:(UIView *)rtcView;

/// 移除RTC画面视图
- (void)removeRTCView;

/// RTC画面 关闭/打开
///
/// @param rtcViewShow RTC画面 关闭或打开 (YES:打开展示 NO:关闭隐藏)
- (void)rtcViewShow:(BOOL)rtcViewShow;

@end

NS_ASSUME_NONNULL_END
