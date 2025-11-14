//
//  PLVCommodityDetailPopupView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/9/29.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVCommodityDetailPopupView;

/// 商品详情弹出页代理协议
@protocol PLVCommodityDetailPopupViewDelegate <NSObject>

@optional

/// 点击购买按钮回调
/// @param popupView 商品详情弹出页视图
/// @param productData 商品数据
- (void)plvCommodityDetailPopupView:(PLVCommodityDetailPopupView *)popupView didClickProductButton:(PLVCommodityModel *)model;

@end

@interface PLVCommodityDetailPopupView : UIView

/// 代理
@property (nonatomic, weak) id<PLVCommodityDetailPopupViewDelegate> delegate;

/// 显示商品详情弹出页
/// @param productId 商品ID
- (void)showWithProductId:(NSString *)productId;

/// 隐藏商品详情弹出页
- (void)hide;

@end

NS_ASSUME_NONNULL_END
