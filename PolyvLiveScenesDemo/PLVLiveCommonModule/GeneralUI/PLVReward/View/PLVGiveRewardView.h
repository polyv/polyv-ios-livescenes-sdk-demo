//
//  PLVGiveRewardView.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVRewardGoodsModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 直播场景
typedef NS_ENUM(NSUInteger, PLVRewardViewType) {
    /// 云课堂场景
    PLVRewardViewTypeLC = 0,
    /// 直播带货场景
    PLVRewardViewTypeEC = 1
};

@class PLVGiveRewardView;

@protocol PLVGiveRewardViewDelegate <NSObject>

/// 积分打赏
- (void)plvGiveRewardView:(PLVGiveRewardView *)giveRewardView pointRewardWithGoodsModel:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num;

/// 现金打赏
- (void)plvGiveRewardView:(PLVGiveRewardView *)giveRewardView cashRewardWithGoodsModel:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num;

@end

/// 打赏视图
@interface PLVGiveRewardView : UIView

/// Delegate
@property (nonatomic, weak) id <PLVGiveRewardViewDelegate> delegate;
/// 用户积分单位
@property (nonatomic, copy) NSString * pointUnit;
/// 打赏方式
@property (nonatomic, copy) NSString * payWay;

/// 当前礼物数据数组（通过 -(void)refreshGoods: 方法进行更新）
@property (nonatomic, strong, readonly) NSArray <PLVRewardGoodsModel *> * modelArray;

- (instancetype)initWithRewardType:(PLVRewardViewType)rewardType;
/// 更新礼物列表
- (void)refreshGoods:(NSArray <PLVRewardGoodsModel *> *)goodsModelArray;

/// 更新用户积分
- (void)refreshUserPoint:(NSString *)userPoint;

/// 展示打赏视图
- (void)showOnView:(UIView *)superView;

/// 隐藏打赏视图
- (void)hide;

@end

NS_ASSUME_NONNULL_END
