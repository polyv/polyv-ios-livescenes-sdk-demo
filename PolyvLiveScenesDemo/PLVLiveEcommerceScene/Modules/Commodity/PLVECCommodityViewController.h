//
//  PLVECCommodityViewController.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/1/20.
//  Copyright © 2021 PLV. All rights reserved.
//  商品列表核心类

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECCommodityViewControllerDelegate <NSObject>

/// 商品跳转代理方法
- (void)plvCommodityViewControllerJumpToCommodityDetail:(NSURL *)commodityURL;

@end

@interface PLVECCommodityViewController : UIViewController

@property (nonatomic, weak) id<PLVECCommodityViewControllerDelegate> delegate;

/// 处理socket商品信息
///
/// @param status 商品操作信息类型
/// @param content 商品信息
- (void)receiveProductMessage:(NSInteger)status content:(id)content;

@end

NS_ASSUME_NONNULL_END
