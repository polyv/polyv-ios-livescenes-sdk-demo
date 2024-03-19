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
@property (nonatomic, strong, readonly) UIImageView * placeholderImageView;

/// 是否母房间用户
@property (nonatomic, assign) BOOL masterUser;

/// 是否支持矩阵直播间转推母房间回放
@property (nonatomic, assign) BOOL supportMatrixPlayback;

@property (nonatomic, strong, readonly) UIVisualEffectView *effectView; // 用于调整高斯模糊背景图格式

#pragma mark - [ 方法 ]
/// 添加 rtcview
- (void)addRTCView:(UIView *)rtcView;

/// 移除 rtcview
- (void)removeRTCView;

/// rtcview 隐藏/显示
///
/// @param rtcViewShow rtcview 隐藏或显示 (YES:显示 NO:隐藏)
/// @param placeHolderImage 占位图，传空不显示
/// @param fill 占位图是否铺满显示 (YES:铺满CanvasView NO:竖屏时上部居中显示，横屏时左侧居中显示，用于主讲传图片时的预览场景)
- (void)rtcViewShow:(BOOL)rtcViewShow placeHolderImage:(UIImage * _Nullable)placeHolderImage imageShouldFill:(BOOL)fill;

/// 配置母房间用户时需要显示的封面图
- (void)setupSplashImg:(NSString * _Nullable)splashImg;

@end

NS_ASSUME_NONNULL_END
