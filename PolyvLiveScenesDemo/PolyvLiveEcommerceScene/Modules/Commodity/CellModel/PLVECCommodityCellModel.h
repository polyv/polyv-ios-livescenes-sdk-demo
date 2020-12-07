//
//  PLVECCommodityCellModel.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/8/20.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVECCommodityModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVECCommodityCellModel;
@protocol PLVECCommodityDelegate <NSObject>

- (void)commodity:(id)commodity didSelect:(PLVECCommodityCellModel *)cellModel;

@end

/// 商品cell模型
@interface PLVECCommodityCellModel : NSObject

/// 商品模型
@property (nonatomic, strong) PLVECCommodityModel *model;

/// 封面地址
@property (nonatomic, strong) NSURL *coverUrl;

/// 实际价格
@property (nonatomic, copy) NSString *realPriceStr;

/// 原价格
@property (nonatomic, copy) NSAttributedString *priceAtrrStr;

/// 跳转链接
@property (nonatomic, copy) NSURL *jumpLinkUrl;

/// 初始化方法
- (instancetype)initWithModel:(PLVECCommodityModel *)model;

@end

NS_ASSUME_NONNULL_END
