//
//  PLVECCommodityViewController.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/1/20.
//  Copyright © 2021 PLV. All rights reserved.
//  商品列表核心类

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECCommodityViewController, PLVCommodityModel;

@protocol PLVECCommodityViewControllerDelegate <NSObject>

/// 点击商品库中商品的回调
/// @param viewController 商品库页面控制器
/// @param commodity 商品链接url
- (void)plvECCommodityViewController:(PLVECCommodityViewController *)viewController didClickCommodityModel:(PLVCommodityModel *)commodity;

/// 点击职位详情的回调
/// @param viewController 商品库页面控制器
/// @param data 商品详情数据
- (void)plvECCommodityViewController:(PLVECCommodityViewController *)viewController didShowJobDetail:(NSDictionary *)data;

@end

@interface PLVECCommodityViewController : UIViewController

@property (nonatomic, weak) id<PLVECCommodityViewControllerDelegate> delegate;

/// 更新用户信息
/// 在用户的信息改变后进行通知
- (void)updateUserInfo;

@end

NS_ASSUME_NONNULL_END
