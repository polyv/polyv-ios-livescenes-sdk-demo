//
//  PLVRewardPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/2/25.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVGiveRewardPresenter.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

@implementation PLVGiveRewardPresenter

#pragma mark - [Public methods]
+ (void)requestRewardSettingCompletion:(void (^)(BOOL rewardEnable, NSString *payWay, NSArray *modelArray, NSString *pointUnit))completion failure:(void (^)(NSString * error))failure {
    NSString *channelId = [PLVGiveRewardPresenter channelId];
    [PLVLiveVideoAPI requestRewardWithChannelId:channelId completion:^(NSDictionary * dataDict) {
        if (dataDict) {
            NSDictionary *giftDonateDict = PLV_SafeDictionaryForDictKey(dataDict, @"giftDonate");
            NSString *payWay = PLV_SafeStringForDictKey(giftDonateDict, @"payWay");
            BOOL donateEnabled = [PLVFdUtil checkStringUseable:payWay];
            NSArray *donateArray = [NSArray array];
            NSMutableArray *modelArray = [NSMutableArray array];
            NSString *pointUnit;
            NSInteger goodId = 0;
            BOOL cashReward = NO;
            if ([payWay isEqualToString:@"CASH"]) { // 现金支付 （移动端不支持现金支付功能，只能打赏免费礼物）
                donateArray = PLV_SafeArraryForDictKey(giftDonateDict, @"cashPays");
                pointUnit = PLV_SafeStringForDictKey(giftDonateDict, @"cashUnit");
                cashReward = YES;
            } else if ([payWay isEqualToString:@"POINT"]) { // 积分支付
                donateArray = PLV_SafeArraryForDictKey(giftDonateDict, @"pointPays");
                pointUnit = PLV_SafeStringForDictKey(giftDonateDict, @"pointUnit");
            } else {
                NSString * desc = PLVLocalizedString(@"礼物打赏功能未开启");
                NSString * tips = [[desc componentsSeparatedByString:@","].firstObject componentsSeparatedByString:@":"].lastObject;
                failure(tips);
                return;
            }
            
            for (NSDictionary *dict in donateArray) {
                goodId ++;
                PLVRewardGoodsModel * model = [PLVRewardGoodsModel modelWithDictionary:dict];
                model.cashReward = cashReward;
                model.goodId = goodId;
                if (model.cashReward) {
                    if (model.goodPrice == 0 && model.goodEnabled) {
                        [modelArray addObject:model];
                    }
                } else {
                    if (model.goodEnabled) {
                        [modelArray addObject:model];
                    }
                }
            }
            completion(donateEnabled,payWay,modelArray,pointUnit);
        }
    } failure:^(NSError * error) {
        NSString * desc = error.localizedDescription;
        NSString * tips = [[desc componentsSeparatedByString:@","].firstObject componentsSeparatedByString:@":"].lastObject;
        failure(tips);
    }];
}

+ (void)requestUserPointCompletion:(void (^)(NSString *userPoint))completion failure:(void (^)(NSString *error))failure {
    PLVRoomUser *user = [PLVGiveRewardPresenter roomUser];
    NSInteger channelId = [[PLVGiveRewardPresenter channelId] integerValue];
    [PLVLiveVideoAPI requestViewerPointWithViewerId:user.viewerId nickName:user.viewerName channelId:channelId completion:^(NSString * pointString) {
        if (completion) {
            completion (pointString);
        }
    } failure:^(NSError * error) {
        NSString * desc = error.localizedDescription;
        NSString * tips = [[desc componentsSeparatedByString:@","].firstObject componentsSeparatedByString:@":"].lastObject;
        failure ? failure(tips) : nil;
    }];
}

+ (void)requestDonatePoint:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num completion:(void (^)(NSString *remainingPoint))completion failure:(void (^)(NSString *error))failure {
    NSInteger channelId = [[PLVGiveRewardPresenter channelId] integerValue];
    PLVRoomUser *user = [PLVGiveRewardPresenter roomUser];
    [PLVLiveVideoAPI requestViewerRewardPointWithViewerId:user.viewerId nickName:user.viewerName avatar:user.viewerAvatar goodId:goodsModel.goodId goodNum:num channelId:channelId completion:^(NSString * remainingPoint) {
        if (completion) {
            completion(remainingPoint);
        }
    } failure:^(NSError * error) {
        NSString * desc = error.localizedDescription;
        NSString * tips = [[desc componentsSeparatedByString:@","].firstObject componentsSeparatedByString:@":"].lastObject;
        failure(tips);
    }];
}

+ (void)requestFreeDonate:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num completion:(void (^)(void))completion failure:(void (^)(NSString *error))failure {
    PLVRoomUser *user = [PLVGiveRewardPresenter roomUser];
    NSInteger channelId = [[PLVGiveRewardPresenter channelId] integerValue];
    NSString *sessionId = [PLVRoomDataManager sharedManager].roomData.sessionId;
    [PLVLiveVideoAPI requestViewerFreeDonateRewardWithViewerId:user.viewerId nickName:user.viewerName avatar:user.viewerAvatar goodId:goodsModel.goodId goodNum:num channelId:channelId sessionId:sessionId completion:^{
        if (completion) {
            completion();
        }
    } failure:^(NSError * error) {
        NSString * desc = error.localizedDescription;
        NSString * tips = [[desc componentsSeparatedByString:@","].firstObject componentsSeparatedByString:@":"].lastObject;
        failure(tips);
    }];
}


#pragma mark - [Private methods]
+ (NSString *)channelId {
    return [PLVRoomDataManager sharedManager].roomData.channelId;
}

+ (PLVRoomUser *)roomUser {
    return [PLVRoomDataManager sharedManager].roomData.roomUser;
}


@end
