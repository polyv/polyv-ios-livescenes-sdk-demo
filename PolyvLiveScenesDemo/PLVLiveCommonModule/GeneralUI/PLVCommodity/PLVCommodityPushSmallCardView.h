//
//  PLVCommodityPushSmallCardView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/4/9.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVCommodityModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVCommodityPushSmallCardViewDelegate <NSObject>

/// 点击商品的回调
/// @param commodity 商品详情模型
- (void)PLVCommodityPushSmallCardViewDidClickCommodityDetail:(PLVCommodityModel *)commodity;

/// 点击职位详情的回调
/// @param data 商品详情数据
- (void)PLVCommodityPushSmallCardViewDidShowJobDetail:(NSDictionary *)data;

/// 商品库小卡片显示隐藏回调
- (void)PLVCommodityPushSmallCardViewDidShow:(BOOL)show;

@end

@interface PLVCommodityPushSmallCardView : UIView

@property (nonatomic, strong) PLVCommodityModel *model;

@property (nonatomic, weak) id<PLVCommodityPushSmallCardViewDelegate> delegate;

@property (nonatomic, assign) CGFloat visibleMinY;

- (void)showOnView:(UIView *)superView initialFrame:(CGRect)initialFrame;

- (void)hide;

// 上报日志
- (void)reportTrackEvent;

/// 更新商品点击的次数
- (void)updateProductClickTimes:(NSDictionary *)dict;

/// 发送商品点击事件
- (void)sendProductClickedEvent:(PLVCommodityModel *)model;

@end

NS_ASSUME_NONNULL_END
