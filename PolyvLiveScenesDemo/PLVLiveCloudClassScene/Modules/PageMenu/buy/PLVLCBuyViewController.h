//
//  PLVLCBuyViewController.h
//  PolyvLiveScenesDemo
//
//  Created by 黄佳玮 on 2022/4/11.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCBuyViewController;

@protocol PLVLCBuyViewControllerDelegate <NSObject>

/// 点击商品库中商品的回调
/// @param viewController 商品库页面控制器
/// @param linkURL 商品链接url
- (void)plvLCClickProductInViewController:(PLVLCBuyViewController *)viewController linkURL:(NSURL *)linkURL;

@end

/// 边看边买 商品列表 页面
@interface PLVLCBuyViewController : UIViewController

@property (nonatomic, strong, readonly) UIView *contentBackgroudView;

@property (nonatomic, weak) id<PLVLCBuyViewControllerDelegate> delegate;

/// 更新用户信息
/// 在用户的信息改变后进行通知
- (void)updateUserInfo;

- (void)rollbackProductPageContentView;

@end

NS_ASSUME_NONNULL_END
