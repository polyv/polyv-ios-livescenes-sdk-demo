//
//  PLVECCommodityPushView.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/8/20.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVECCommodityCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECCommodityPushView : UIView

@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, strong) UILabel *showIdLabel;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *realPriceLabel;

@property (nonatomic, strong) UILabel *priceLabel;

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UIButton *jumpButton;

@property (nonatomic, strong) PLVECCommodityCellModel *cellModel;

@property (nonatomic, weak) id<PLVECCommodityDelegate> delegate;

- (void)destroy;

@end

NS_ASSUME_NONNULL_END
