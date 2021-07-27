//
//  PLVECCommodityPushView.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/8/20.
//  Copyright © 2020 PLV. All rights reserved.
//  推送商品

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVCommodityModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECCommodityPushViewDelegate <NSObject>

- (void)jumpToGoodsDetail:(NSURL *)goodsURL;

@end

@interface PLVECCommodityPushView : UIView

@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, strong) UILabel *showIdLabel;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *realPriceLabel;

@property (nonatomic, strong) UILabel *priceLabel;

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UIButton *jumpButton;

@property (nonatomic, strong) PLVCommodityModel *model;

@property (nonatomic, weak) id<PLVECCommodityPushViewDelegate> delegate;

- (void)destroy;

@end

NS_ASSUME_NONNULL_END
