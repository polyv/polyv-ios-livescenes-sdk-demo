//
//  PLVSAAICardView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/11/05.
//  Copyright © 2025 PLV. All rights reserved.
//
// AI 手卡浮窗视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSAAICardView,PLVCommodityModel;

@protocol PLVSAAICardViewDelegate <NSObject>

/// 外部挂件显示状态回调
/// @param aiCardView AI 手卡视图
- (void)aiCardView:(PLVSAAICardView *)aiCardView widgetStatusNeedChange:(BOOL)show;

@end

@interface PLVSAAICardView : UIView

@property (nonatomic, weak) id<PLVSAAICardViewDelegate> delegate;

/// 当前是否正在显示
@property (nonatomic, assign, readonly) BOOL isShowing;

/// 更新 AI 手卡视图
/// @param commodityModel 商品模型
- (void)updateWithCommodityModel:(PLVCommodityModel *)commodityModel;

/// 显示 AI 手卡视图
/// @param animated 是否需要动画
- (void)show:(BOOL)animated;

/// 隐藏 AI 手卡视图
/// @param animated 是否需要动画
- (void)hide:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
