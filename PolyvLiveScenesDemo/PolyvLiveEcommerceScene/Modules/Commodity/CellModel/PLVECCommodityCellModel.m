//
//  PLVECCommodityCellModel.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/8/20.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCommodityCellModel.h"
#import <UIKit/UIKit.h>

@implementation PLVECCommodityCellModel

- (void)setModel:(PLVECCommodityModel *)model {
    _model = model;
    if (!model) {
        return;
    }
    
    // 封面地址
    if ([model.cover hasPrefix:@"http"]) {
        _coverUrl = [NSURL URLWithString:model.cover];
    } else if (model.cover) {
        _coverUrl = [NSURL URLWithString:[@"https:" stringByAppendingString:model.cover]];
    }
    
    // 实际价格显示逻辑
    if ([model.realPrice isEqualToString:@"0"]) {
        _realPriceStr = @"免费";
    } else if (model.realPrice) {
        _realPriceStr = [NSString stringWithFormat:@"¥ %@",model.realPrice];
    }
    
    // 原价格显示逻辑
    if (!model.price || [model.price isEqualToString:model.realPrice]
        || [model.price isEqualToString:@"0"]) {
        _priceAtrrStr = nil;
    } else if (model.realPrice) {
        UIColor *grayColor = [UIColor colorWithRed:173/255.f green:173/255.f blue:192/255.f alpha:1];
        NSDictionary *attrParams = @{NSForegroundColorAttributeName:grayColor,
                                     NSFontAttributeName:[UIFont systemFontOfSize:12],
                                     NSStrikethroughStyleAttributeName:@(NSUnderlineStyleSingle),
                                     NSStrikethroughColorAttributeName:grayColor,
                                     NSBaselineOffsetAttributeName:@(0)};
        _priceAtrrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"¥ %@",model.price] attributes:attrParams];
    }

    // 跳转地址
    if (10 == model.linkType) { // 通用链接
        _jumpLinkUrl = [NSURL URLWithString:model.link];
    } else if (11 == model.linkType) { // 多平台链接
        _jumpLinkUrl = [NSURL URLWithString:model.mobileAppLink];
    } else {
        _jumpLinkUrl = nil;
    }
    if (_jumpLinkUrl && !_jumpLinkUrl.scheme) {
        _jumpLinkUrl = [NSURL URLWithString:[@"http://" stringByAppendingString:_jumpLinkUrl.absoluteString]];
    }
}

- (instancetype)initWithModel:(PLVECCommodityModel *)model {
    self = [super init];
    if (self) {
        self.model = model;
    }
    return self;
}

@end
