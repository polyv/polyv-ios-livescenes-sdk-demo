//
//  PLVRewardGoodsModel.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/9.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVRewardGoodsModel.h"

/// 打赏奖品数据模型
@implementation PLVRewardGoodsModel

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary{
    if (dictionary && [dictionary isKindOfClass:NSDictionary.class] && dictionary.count > 0) {
        PLVRewardGoodsModel * model = [[PLVRewardGoodsModel alloc]init];
        model.goodName = [NSString stringWithFormat:@"%@",dictionary[@"name"]];
        model.goodImgURL = [NSString stringWithFormat:@"%@",dictionary[@"img"]];

        model.goodPrice = [[NSString stringWithFormat:@"%@",dictionary[@"price"]] floatValue];
        model.goodEnabled = [(NSNumber *)dictionary[@"enabled"] boolValue];
        return model;
    }else{
        return nil;
    }
}

+ (instancetype)modelWithSocketObject:(NSDictionary *)object {
    if (object && [object isKindOfClass:NSDictionary.class]) {
        PLVRewardGoodsModel *model = [[PLVRewardGoodsModel alloc]init];
        NSString *gimg = [NSString stringWithFormat:@"%@", object[@"gimg"]];
        NSString *rewardContent = [NSString stringWithFormat:@"%@", object[@"rewardContent"]];
        model.goodName = rewardContent;
        model.goodImgURL = gimg;
        return model;
    } else {
        return nil;
    }
}

- (NSString *)goodImgFullURL{
    NSString * fullURL = self.goodImgURL;
    if ([fullURL hasPrefix:@"//"]) { fullURL = [@"https:" stringByAppendingString:fullURL]; }
    return fullURL;
}

@end
