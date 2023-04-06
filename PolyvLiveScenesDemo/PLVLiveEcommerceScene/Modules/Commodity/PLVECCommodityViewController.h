//
//  PLVECCommodityViewController.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/1/20.
//  Copyright © 2021 PLV. All rights reserved.
//  商品列表核心类

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECCommodityViewController;

@protocol PLVECCommodityViewControllerDelegate <NSObject>

/// 点击商品库中商品的回调
/// @param viewController 商品库页面控制器
/// @param linkURL 商品链接url
- (void)plvECClickProductInViewController:(PLVECCommodityViewController *)viewController linkURL:(NSURL *)linkURL;

@end

@interface PLVECCommodityViewController : UIViewController

@property (nonatomic, weak) id<PLVECCommodityViewControllerDelegate> delegate;

/// 更新用户信息
/// 在用户的信息改变后进行通知
- (void)updateUserInfo;

@end

NS_ASSUME_NONNULL_END
