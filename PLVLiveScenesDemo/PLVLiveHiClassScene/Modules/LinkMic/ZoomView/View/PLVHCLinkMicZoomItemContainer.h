//
//  PLVHCLinkMicZoomItemContainer.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/11/15.
//  Copyright © 2021 PLV. All rights reserved.
// 每一个连麦放大视图 负责展出每一个连麦视图，支持移动、放大、缩小

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCLinkMicZoomModel,PLVLinkMicOnlineUser;

/// 单点视图 回调Block
typedef void (^PLVHCLinkMicZoomItemContainerTapActionBlock)(PLVLinkMicOnlineUser * _Nullable data);
/// 移动视图 回调Block
typedef void (^PLVHCLinkMicZoomItemContainerMoveActionBlock)(PLVHCLinkMicZoomModel *zoomModel);
/// 放大视图 回调Block
typedef void (^PLVHCLinkMicZoomItemContainerZoomActionBlock)(PLVHCLinkMicZoomModel *zoomModel);

@interface PLVHCLinkMicZoomItemContainer : UIView

#pragma mark 数据
/// 视图模型
@property (nonatomic, strong, readonly) PLVHCLinkMicZoomModel *zoomModel;

#pragma mark 交互、点击事件回调
/// 单点视图 回调Block
@property (nonatomic, copy) PLVHCLinkMicZoomItemContainerTapActionBlock tapActionBlock;
/// 移动视图 回调Block
@property (nonatomic, copy) PLVHCLinkMicZoomItemContainerMoveActionBlock moveActionBlock;
/// 移动视图 回调Block
@property (nonatomic, copy) PLVHCLinkMicZoomItemContainerZoomActionBlock zoomActionBlock;

/// 承载展示外部视图
///
/// @param externalView 外部视图
- (void)displayExternalView:(UIView *)externalView;

/// 设置视图数据模型
///
/// @param zoomModel 数据模型
- (void)setupZoomModel:(PLVHCLinkMicZoomModel *)zoomModel;

@end

NS_ASSUME_NONNULL_END
