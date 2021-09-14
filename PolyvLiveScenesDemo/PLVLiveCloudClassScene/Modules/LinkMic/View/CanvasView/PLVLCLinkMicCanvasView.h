//
//  PLVLCLinkMicCanvasView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/22.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// 云课堂场景下 PLVLinkMicOnlineUser 的 rtcview 的容器
///
/// @note 负责承载 PLVLinkMicOnlineUser 的 rtcview；并负责云课堂场景的UI业务；
///       PLVLCLinkMicCanvasView 应仅负责承载，可通过调用 [addRTCView:] 添加 rtcview；
@interface PLVLCLinkMicCanvasView : UIView

#pragma mark - [ 属性 ]
/// 背景视图 (负责展示 占位图)
@property (nonatomic, strong, readonly) UIImageView * placeholderImageView;

#pragma mark - [ 方法 ]
/// 添加 rtcview
- (void)addRTCView:(UIView *)rtcView;

/// 移除 rtcview
- (void)removeRTCView;

/// rtcview 隐藏/显示
///
/// @param rtcViewShow rtcview 隐藏或显示 (YES:显示 NO:隐藏)
- (void)rtcViewShow:(BOOL)rtcViewShow;

/// 更新 ‘网络状态视图’ 状态
///
/// @param status 网络状态值 (对应不同的网络状态图标)
- (void)updateNetworkQualityImageViewWithStatus:(PLVBLinkMicNetworkQuality)status;

@end

NS_ASSUME_NONNULL_END
