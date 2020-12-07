//
//  PLVECCommodityViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVECCommodityCellModel.h"

@interface PLVECCommodityViewModel : NSObject

/// 商品cell模型
@property (nonatomic, strong, readonly) NSMutableArray<PLVECCommodityCellModel *> *cellModels;

/// 总记录数
@property (nonatomic, assign) NSInteger totalItems;

/// 是否还有更多数据
@property (nonatomic, assign) BOOL moreData;

/// 格式化标题字符串
@property (nonatomic, copy) NSAttributedString *titleAttrStr;

/// 增加一个商品模型（同时更新列表该商品之后的showId）
/// @param model 待插入的模型
/// @param first 是否插到首位
/// @return 插入的位置下标，返回非负数表示成功；-1表示插入失败
- (NSInteger)addModel:(PLVECCommodityModel *)model atFirst:(BOOL)first;

/// 删除指定id的商品模型（同时更新列表该商品之后的showId）
/// @param productId 商品id
/// @param rank 商品排序号
/// @return 指定id商品模型的数组下标，返回非负数表示成功；返回-1表示未查找到
- (NSInteger)removeModelWithProductId:(NSInteger)productId rank:(NSInteger)rank;

/// 更新已上架商品信息
/// @param model 待更新商品模型
/// @param type 1:更新；2:增加；3:删除
/// @return 操作完成后商品模型数组的下标，返回非负数表示成功；返回-1表示操作失败
- (NSInteger)updateModel:(PLVECCommodityModel *)model type:(int *)type;

/// 交换商品排序
/// @param aModel 待排序模型
/// @param anotherModel 待排序模型
/// @param completion 完成块，idx1、idx2 为处理数据的下标
/// code: 0 参数错误/无需处理；1 更新商品rank值；2 更新一条商品数据（删除&新增）；3 交换数据
- (void)switchModel:(PLVECCommodityModel *)aModel with:(PLVECCommodityModel *)anotherModel completion:(void (^)(NSInteger idx1, NSInteger idx2, int code))completion;

@end

