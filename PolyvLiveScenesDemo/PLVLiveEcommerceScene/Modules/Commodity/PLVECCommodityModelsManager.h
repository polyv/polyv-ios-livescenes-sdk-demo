//
//  PLVECCommodityModelsManager.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/1/21.
//  Copyright © 2021 PLV. All rights reserved.
//  商品数据管理

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVCommodityModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECCommodityModelsManager : NSObject

// 商品总数量
@property (nonatomic, assign, readonly) NSInteger totalItems;
// 已加载到本地的商品数据列表
@property (nonatomic, strong, readonly) NSMutableArray<PLVCommodityModel *> *models;

/// 首次请求商品列表数据
///
/// @param completion 回调参数 error 为 nil 请求成功
- (void)loadCommodityInfoWithCompletion:(void (^)(NSError *))completion;

/// 请求商品列表更多数据
///
/// @param completion 回调参数 error 为 nil 请求成功
- (void)loadMoreCommodityInfoWithCompletion:(void (^)(NSError *))completion;

/// 处理socket商品信息
///
/// @param status 商品操作信息类型
/// @param content 商品信息
- (void)receiveProductMessage:(NSInteger)status content:(id)content;

@end

NS_ASSUME_NONNULL_END
