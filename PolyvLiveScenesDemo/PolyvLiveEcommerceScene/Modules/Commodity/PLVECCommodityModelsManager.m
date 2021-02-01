//
//  PLVECCommodityModelsManager.m
//  PolyvLiveScenesDemo
//
//  Created by Hank on 2021/1/21.
//  Copyright © 2021 polyv. All rights reserved.
//  商品数据管理

#import "PLVECCommodityModelsManager.h"
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>
#import "PLVRoomDataManager.h"

@interface PLVECCommodityModelsManager ()

// 商品总数量
@property (nonatomic, assign) NSInteger totalItems;
// 已加载到本地的商品数据列表
@property (nonatomic, strong) NSMutableArray<PLVCommodityModel *> *models;
// 请求接口数据中
@property (nonatomic, assign) BOOL loading;

@end

@implementation PLVECCommodityModelsManager

#pragma mark - [ Life Period ]
- (instancetype)init {
    if (self = [super init]) {
        _totalItems = -1;
        _models = [NSMutableArray array];
    }
    
    return self;
}

- (void)loadCommodityInfoWithCompletion:(void (^)(NSError *))completion {
    [self requestCommodityInfo:0 completion:completion];
}

- (void)loadMoreCommodityInfoWithCompletion:(void (^)(NSError *))completion {
    if (self.totalItems == -1 || self.totalItems == self.models.count) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    // 商品列表是倒序，所以获取本地商品列表中最小的商品排序号
    NSUInteger minRank = self.models.count ? [self.models.lastObject rank] : 0;
    [self requestCommodityInfo:minRank completion:completion];
}

- (void)receiveProductMessage:(NSInteger)status content:(id)content {
    if (![content isKindOfClass:NSDictionary.class] && ![content isKindOfClass:NSArray.class]) {
        return;
    }
    
    NSInteger productId = PLV_SafeIntegerForDictKey(content, @"productId");
    NSInteger rank = PLV_SafeIntegerForDictKey(content, @"rank");
    switch (status) {
        case 1: { // 上架商品
            PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:content];
            NSInteger index = [self addModel:model atFirst:NO];
            NSLog(@"新增商品 %ld",index);
            
            break;
        }
        case 2:   // 下架商品
        case 3: { // 删除商品
            NSInteger index = [self removeModelWithProductId:productId rank:rank];
            NSLog(@"删除商品 %ld",index);
            
            break;
        }
        case 4: { // 新增商品
            PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:content];
            NSInteger index = [self addModel:model atFirst:YES];
            NSLog(@"新增商品 %ld",index);
            
            break;
        }
        case 5: { // 更新商品
            int type;
            PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:content];
            NSInteger index = [self updateModel:model type:&type];
            NSLog(@"更新商品 type(1:更新；2:增加；3:删除):%d %ld",type,index);
            
            break;
        }
        case 6:   // 上移商品
        case 7: { // 下移商品
            if ([content isKindOfClass:NSArray.class]) {
                if ([(NSArray *)content count] == 2) {
                    PLVCommodityModel *model1 = [PLVCommodityModel commodityModelWithDict:content[0]];
                    PLVCommodityModel *model2 = [PLVCommodityModel commodityModelWithDict:content[1]];
//                    __weak typeof(self)weakSelf = self;
                    [self switchModel:model1 with:model2 completion:^(NSInteger idx1, NSInteger idx2, int code) {
                        NSLog(@"交换商品 code(0 参数错误/无需处理；1 更新商品rank值；2 更新一条商品数据（删除&新增）；3 交换数据):%d %ld %ld", code,idx1,idx2);
                    }];
                }
            }
            
            break;
        }
        case 8: { // 置顶商品
            break;
        }
        case 9: { // 推送商品
            break;
        }
        default:
            break;
    }
}

#pragma mark [ Private Methods ]
- (void)requestCommodityInfo:(NSInteger)rank completion:(void (^)(NSError *))completion {
    if (self.loading || self.totalItems == self.models.count) {
        return;
    }
    
    _loading = YES;
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (rank == 0) {
        [self.models removeAllObjects];
    }
    
    __weak typeof(self)weakSelf = self;
    [roomData requestCommodityList:roomData.channelId.integerValue
                              rank:rank
                             count:20
                        completion:^(NSUInteger total, NSArray<PLVCommodityModel *> *commoditys) {
        weakSelf.loading = NO;
        weakSelf.totalItems = total;
        
        [weakSelf.models addObjectsFromArray:commoditys];
        
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError * _Nonnull error) {
        weakSelf.loading = NO;
        NSLog(@"requestCommodityInfo error description: %@",error.localizedDescription);
        if (completion) {
            completion(error);
        }
    }];
}

- (NSInteger)addModel:(PLVCommodityModel *)newModel atFirst:(BOOL)first {
    if (!newModel) {
        return -1;
    }
    if (1 != newModel.status) { // 非上架商品
        return -2;
    }
    
    if (first) { // 插入首位（新增商品）
        [self.models insertObject:newModel atIndex:0];
        self.totalItems ++;
        return 0;
    } else if (self.models.count > 0 && newModel.rank > self.models.lastObject.rank) { // 待添加商品在列表商品排序范围内（上架商品）
        for (int i=0; i < self.models.count; i++) {
            PLVCommodityModel *model = self.models[i];
            if (newModel.rank > model.rank) { // 排序
                [self.models insertObject:newModel atIndex:i];
                [self updateShowIdToIndex:i increase:YES];
                self.totalItems ++;
                return i;
            }
        }
    } else if (self.totalItems == self.models.count) { // 不在商品列表，且没有更多数据时插入到最后（上架商品）
        [self.models addObject:newModel];
        [self updateShowIdToIndex:self.models.count-1 increase:YES];
        self.totalItems ++;
        return self.models.count - 1;
    }
    
    return -1;
}

- (NSInteger)removeModelWithProductId:(NSInteger)productId rank:(NSInteger)rank {
    if (self.models.count && rank >= self.models.lastObject.rank) { // 待移除商品在列表中
        for (int i=0; i < self.models.count; i++) {
            PLVCommodityModel *model = self.models[i];
            if (model.productId == productId) {
                [self.models removeObjectAtIndex:i];
                [self updateShowIdToIndex:i increase:NO];
                self.totalItems --;
                return i;
            }
        }
    }
    
    return -1;
}

- (NSInteger)updateModel:(PLVCommodityModel *)newModel type:(int *)type {
    if (!newModel) {
        return -1;
    }
    
    if (1 != newModel.status) { // 非上架商品
        *type = 3; // 更新的商品非上架商品，执行删除操作
        return [self removeModelWithProductId:newModel.productId rank:newModel.rank];
    }
    
    if (newModel.rank >= self.models.lastObject.rank) { // 待更新上架商品在列表商品排序范围内
        for (int i=0; i < self.models.count; i++) {
            PLVCommodityModel *model = self.models[i];
            if (newModel.rank >= model.rank) {
                if (newModel.rank == model.rank &&
                    newModel.productId == model.productId) { // 已存在的商品，更新操作
                    [self.models replaceObjectAtIndex:i withObject:newModel];
                    *type = 1;
                    return i;
                } else { // 更新的商品未查找到，执行插入操作
                    [self.models insertObject:newModel atIndex:i];
                    [self updateShowIdToIndex:i increase:YES];
                    self.totalItems ++;
                    *type = 2;
                    return i;
                }
            }
        }
    } else if (self.totalItems == self.models.count) { // 不在商品列表，且没有更多数据时插入到最后（上架商品）
        [self.models addObject:newModel];
        self.totalItems ++;
        return self.models.count - 1;
    }
    
    return -1;
}

- (void)switchModel:(PLVCommodityModel *)aModel with:(PLVCommodityModel *)anotherModel completion:(void (^)(NSInteger, NSInteger, int))completion {
    if (!aModel || !anotherModel) {
        if (completion) {
            completion(0, 0, 0);
        }
        return;
    }
    
    // 包含下架商品
    if (2 == aModel.status || 2 == anotherModel.status) {
        NSInteger idx1 = -1, idx2 = -1;
        if (1 == aModel.status) { // 更新上架的商品rank值
            idx1 = [self updateModel:aModel.productId withRank:aModel.rank];
        }
        if (1 == anotherModel.status) { // 更新上架的商品rank值
            idx2 = [self updateModel:anotherModel.productId withRank:anotherModel.rank];
        }
        if (completion) {
            completion(idx1, idx2, 1);
        }
        return;
    }
    
    // 两个上架商品交换
    NSInteger minRank = self.models.lastObject.rank;
    if (aModel.rank >= minRank || anotherModel.rank >= minRank) { // 至少一个在列表中
        int idx1 = -1, idx2 = -1;
        for (int i=0; i < self.models.count; i++) {
            PLVCommodityModel *model = self.models[i];
            if (model.productId == aModel.productId) {
                idx1 = i;
            } else if (model.productId == anotherModel.productId) {
                idx2 = i;
            }
        }
        if (idx1 >= 0 || idx2 >= 0) {
            if (idx1 >= 0 && idx2 >= 0) { // 都在列表中检索到数据
                [self.models replaceObjectAtIndex:idx1 withObject:anotherModel];
                [self.models replaceObjectAtIndex:idx2 withObject:aModel];
                if (completion) {
                    completion(idx1, idx2, 3);
                }
            } else if (idx1 >= 0) { // 只检索到idx1
                [self.models replaceObjectAtIndex:idx1 withObject:anotherModel];
                if (completion) {
                    completion(idx1, idx2, 2);
                }
            } else { // 只检索到idx2
                [self.models replaceObjectAtIndex:idx2 withObject:aModel];
                if (completion) {
                    completion(idx1, idx2, 2);
                }
            }
        } else {
            if (completion) {
                completion(0, 0, 0);
            }
        }
    } else {
        if (completion) {
            completion(0, 0, 0);
        }
    }
}

/// 更新商品rank信息
- (NSInteger)updateModel:(const NSInteger)productId withRank:(NSInteger)rank {
    if (productId < 0 || rank < 0) {
        return -1;
    }
    
    for (int i=0; i < self.models.count; i++) {
        PLVCommodityModel *model = self.models[i];
        if (productId == model.productId) {
            model.rank = rank;
            return i;
        }
    }
    
    return -1;
}

// 更新showId
- (void)updateShowIdToIndex:(NSUInteger)index increase:(BOOL)increase {
    for (int i = 0; i < index; i ++) {
        PLVCommodityModel *model = self.models[i];
        if (increase) {
            model.showId ++;
        } else {
            model.showId --;
            if (model.showId < 0) {
                model.showId = 0;
            }
        }
    }
}

@end
