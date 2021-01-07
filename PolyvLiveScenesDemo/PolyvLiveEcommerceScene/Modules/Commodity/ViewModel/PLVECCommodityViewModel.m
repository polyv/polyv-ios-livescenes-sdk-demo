//
//  PLVECCommodityViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCommodityViewModel.h"
#import <UIKit/UIKit.h>

@interface PLVECCommodityViewModel ()

@property (nonatomic, strong) NSMutableArray<PLVECCommodityCellModel *> *cellModels;

@end

@implementation PLVECCommodityViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cellModels = [NSMutableArray array];
    }
    return self;
}

- (NSAttributedString *)titleAttrStr {
    if (self.totalItems < 0) {
        self.totalItems = 0;
    }
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSMutableAttributedString *mAttriStr = [[NSMutableAttributedString alloc] initWithString:@"共件商品" attributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:UIColor.whiteColor}];
    NSAttributedString *countStr = [[NSAttributedString alloc] initWithString:@(self.totalItems).stringValue attributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor colorWithRed:1 green:153/255.0 blue:17/255.0 alpha:1]}];
    [mAttriStr insertAttributedString:countStr atIndex:1];
    return mAttriStr;
}

#pragma mark - Public

- (NSInteger)addModel:(PLVECCommodityModel *)newModel atFirst:(BOOL)first {
    if (!newModel) {
        return -1;
    }
    if (1 != newModel.status) { // 非上架商品
        return -2;
    }
    
    PLVECCommodityCellModel *cellModel = [[PLVECCommodityCellModel alloc] initWithModel:newModel];
    
    if (first) { // 插入首位（新增商品）
        [self.cellModels insertObject:cellModel atIndex:0];
        self.totalItems ++;
        return 0;
    } else if (self.cellModels.count > 0 && newModel.rank > self.cellModels.lastObject.model.rank) { // 待添加商品在列表商品排序范围内（上架商品）
        for (int i=0; i < self.cellModels.count; i++) {
            PLVECCommodityModel *model = [self.cellModels[i] model];
            if (newModel.rank > model.rank) { // 排序
                [self.cellModels insertObject:cellModel atIndex:i];
                [self updateShowIdToIndex:i increase:YES];
                self.totalItems ++;
                return i;
            }
        }
    } else if (!self.moreData) { // 不在商品列表，且没有更多数据时插入到最后（上架商品）
        [self.cellModels addObject:cellModel];
        [self updateShowIdToIndex:self.cellModels.count-1 increase:YES];
        self.totalItems ++;
        return self.cellModels.count - 1;
    }
    
    return -1;
}

- (NSInteger)removeModelWithProductId:(NSInteger)productId rank:(NSInteger)rank {
    if (self.cellModels.count && rank >= self.cellModels.lastObject.model.rank) { // 待移除商品在列表中
        for (int i=0; i < self.cellModels.count; i++) {
            PLVECCommodityModel *model = [self.cellModels[i] model];
            if (model.productId == productId) {
                [self.cellModels removeObjectAtIndex:i];
                [self updateShowIdToIndex:i increase:NO];
                self.totalItems --;
                return i;
            }
        }
    }
    
    return -1;
}

- (NSInteger)updateModel:(PLVECCommodityModel *)newModel type:(int *)type {
    if (!newModel) {
        return -1;
    }
    
    if (1 != newModel.status) { // 非上架商品
        *type = 3; // 更新的商品非上架商品，执行删除操作
        return [self removeModelWithProductId:newModel.productId rank:newModel.rank];
    }
    
    PLVECCommodityCellModel *cellModel = [[PLVECCommodityCellModel alloc] initWithModel:newModel];
    
    if (newModel.rank >= self.cellModels.lastObject.model.rank) { // 待更新上架商品在列表商品排序范围内
        for (int i=0; i < self.cellModels.count; i++) {
            PLVECCommodityModel *model = [self.cellModels[i] model];
            if (newModel.rank >= model.rank) {
                if (newModel.rank == model.rank &&
                    newModel.productId == model.productId) { // 已存在的商品，更新操作
                    [self.cellModels replaceObjectAtIndex:i withObject:cellModel];
                    *type = 1;
                    return i;
                } else { // 更新的商品未查找到，执行插入操作
                    [self.cellModels insertObject:cellModel atIndex:i];
                    [self updateShowIdToIndex:i increase:YES];
                    self.totalItems ++;
                    *type = 2;
                    return i;
                }
            }
        }
    } else if (!self.moreData) { // 不在商品列表，且没有更多数据时插入到最后（上架商品）
        [self.cellModels addObject:cellModel];
        self.totalItems ++;
        return self.cellModels.count - 1;
    }
    
    return -1;
}

- (void)switchModel:(PLVECCommodityModel *)aModel with:(PLVECCommodityModel *)anotherModel completion:(void (^)(NSInteger, NSInteger, int))completion {
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
    NSInteger minRank = self.cellModels.lastObject.model.rank;
    if (aModel.rank >= minRank || anotherModel.rank >= minRank) { // 至少一个在列表中
        PLVECCommodityCellModel *cellModel1 = [[PLVECCommodityCellModel alloc] initWithModel:aModel];
        PLVECCommodityCellModel *cellModel2 = [[PLVECCommodityCellModel alloc] initWithModel:anotherModel];
        
        int idx1 = -1, idx2 = -1;
        for (int i=0; i < self.cellModels.count; i++) {
            PLVECCommodityModel *model = [self.cellModels[i] model];
            if (model.productId == aModel.productId) {
                idx1 = i;
            } else if (model.productId == anotherModel.productId) {
                idx2 = i;
            }
        }
        if (idx1 >= 0 || idx2 >= 0) {
            if (idx1 >= 0 && idx2 >= 0) { // 都在列表中检索到数据
                [self.cellModels replaceObjectAtIndex:idx1 withObject:cellModel2];
                [self.cellModels replaceObjectAtIndex:idx2 withObject:cellModel1];
                if (completion) {
                    completion(idx1, idx2, 3);
                }
            } else if (idx1 >= 0) { // 只检索到idx1
                [self.cellModels replaceObjectAtIndex:idx1 withObject:cellModel2];
                if (completion) {
                    completion(idx1, idx2, 2);
                }
            } else { // 只检索到idx2
                [self.cellModels replaceObjectAtIndex:idx2 withObject:cellModel1];
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

#pragma mark - Private

/// 更新商品rank信息
- (NSInteger)updateModel:(const NSInteger)productId withRank:(NSInteger)rank {
    if (productId < 0 || rank < 0) {
        return -1;
    }
    
    for (int i=0; i < self.cellModels.count; i++) {
        PLVECCommodityModel *model = [self.cellModels[i] model];
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
        PLVECCommodityModel *model = [self.cellModels[i] model];
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
