//
//  PLVECCommodityModel.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCommodityModel.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>

@implementation PLVECCommodityModel

+ (instancetype)modelWithDict:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    
    PLVECCommodityModel *model = [[PLVECCommodityModel alloc] init];
    if (model) {
        model.productId = PLV_SafeIntegerForDictKey(dict, @"productId");
        model.showId = PLV_SafeIntegerForDictKey(dict, @"showId");
        model.rank = PLV_SafeIntegerForDictKey(dict, @"rank");
        model.name = PLV_SafeStringForDictKey(dict, @"name");
        model.price = PLV_SafeStringForDictKey(dict, @"price");
        model.realPrice = PLV_SafeStringForDictKey(dict, @"realPrice");
        model.cover = PLV_SafeStringForDictKey(dict, @"cover");
        model.status = PLV_SafeIntegerForDictKey(dict, @"status");
        model.linkType = PLV_SafeIntegerForDictKey(dict, @"linkType");
        model.link = PLV_SafeStringForDictKey(dict, @"link");
        model.mobileAppLink = PLV_SafeStringForDictKey(dict, @"mobileAppLink");
    }
    return model;
}

@end
