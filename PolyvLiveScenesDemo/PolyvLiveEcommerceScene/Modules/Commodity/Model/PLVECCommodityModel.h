//
//  PLVECCommodityModel.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 商品模型
@interface PLVECCommodityModel : NSObject

/// 商品主键
@property (nonatomic, assign) NSInteger productId;
/// 排序号
@property (nonatomic, assign) NSInteger rank;
/// 显示序号
@property (nonatomic, assign) NSInteger showId;
/// 商品名称
@property (nonatomic, copy) NSString *name;
/// 原价格
@property (nonatomic, copy) NSString *price;
/// 实际价格
@property (nonatomic, copy) NSString *realPrice;
/// 封面图片地址
@property (nonatomic, copy) NSString *cover;
/// 状态：1上架，2下架
@property (nonatomic, assign) NSInteger status;
/// 商品链接类型, 10:通用链接,使用link字段，11:多平台链接，使用mobileAppLink字段
@property (nonatomic, assign) NSInteger linkType;
/// 商品链接，通用链接
@property (nonatomic, copy) NSString *link;
/// 移动端app链接，默认为空串
@property (nonatomic, copy) NSString *mobileAppLink;

+ (instancetype)modelWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
