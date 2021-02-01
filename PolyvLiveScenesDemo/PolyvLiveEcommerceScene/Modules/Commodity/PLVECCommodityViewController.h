//
//  PLVECCommodityViewController.h
//  PolyvLiveScenesDemo
//
//  Created by Hank on 2021/1/20.
//  Copyright © 2021 polyv. All rights reserved.
//  商品列表核心类

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECCommodityDelegate <NSObject>

/// 商品跳转代理方法
- (void)jumpToGoodsDetail:(NSURL *)goodsURL;

@end

@interface PLVECCommodityViewController : UIViewController

@property (nonatomic, weak) id<PLVECCommodityDelegate> delegate;

/// 处理socket商品信息
///
/// @param status 商品操作信息类型
/// @param content 商品信息
- (void)receiveProductMessage:(NSInteger)status content:(id)content;

@end

NS_ASSUME_NONNULL_END
