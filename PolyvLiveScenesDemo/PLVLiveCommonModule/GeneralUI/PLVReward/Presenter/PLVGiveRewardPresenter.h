//
//  PLVRewardPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/2/25.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVRewardGoodsModel.h"


@interface PLVGiveRewardPresenter : NSObject

/// 获取打赏配置信息
+ (void)requestRewardSettingCompletion:(void (^)(BOOL rewardEnable, NSString *payWay, NSArray *modelArray, NSString *pointUnit))completion failure:(void (^)(NSString *error))failure;

/// 获取用户积分点数
+ (void)requestUserPointCompletion:(void (^)(NSString *userPoint))completion failure:(void (^)(NSString *error))failure;

/// 进行积分打赏
+ (void)requestDonatePoint:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num completion:(void (^)(NSString *remainingPoint))completion failure:(void (^)(NSString *error))failure;

/// 进行免费道具打赏
+ (void)requestFreeDonate:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num completion:(void (^)(void))completion failure:(void (^)(NSString *error))failure;

@end

