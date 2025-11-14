//
//  PLVLCBuyViewController.h
//  PolyvLiveScenesDemo
//
//  Created by 黄佳玮 on 2022/4/11.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCBuyViewController, PLVCommodityModel;

@protocol PLVLCBuyViewControllerDelegate <NSObject>

/// 点击商品库中商品的回调
/// @param viewController 商品库页面控制器
/// @param commodity 商品详情模型
- (void)plvLCClickProductInViewController:(PLVLCBuyViewController *)viewController commodityModel:(PLVCommodityModel *)commodity;

/// 点击商品库中商品讲解的回调
/// @param viewController 商品库页面控制器
/// @param commodity 商品详情模型
- (void)plvLCClickProductExplainedInViewController:(PLVLCBuyViewController *)viewController commodityModel:(PLVCommodityModel *)commodity;

/// 点击职位详情的回调
/// @param viewController 商品库页面控制器
/// @param data 商品详情数据
- (void)plvLCBuyViewController:(PLVLCBuyViewController *)viewController didShowJobDetail:(NSDictionary *)data;

/// 点击商品详情的回调
/// @param viewController 商品库页面控制器
/// @param data 商品详情数据
- (void)plvLCBuyViewController:(PLVLCBuyViewController *)viewController didShowProductDetail:(NSDictionary *)data;

/// 关闭商品库弹窗页面的回调
- (void)plvLCCloseProductViewInViewController:(PLVLCBuyViewController *)viewController;

@end

/// 边看边买 商品列表 页面
@interface PLVLCBuyViewController : UIViewController

@property (nonatomic, strong, readonly) UIView *contentBackgroudView;

@property (nonatomic, weak) id<PLVLCBuyViewControllerDelegate> delegate;

/// 更新用户信息
/// 在用户的信息改变后进行通知
- (void)updateUserInfo;

- (void)rollbackProductPageContentView;

/// 横屏展示边看边买
- (void)showInLandscape;

@end

NS_ASSUME_NONNULL_END
