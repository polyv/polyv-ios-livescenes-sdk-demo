//
//  PLVECCommodityCellNew.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVCommodityModel.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECCommodityCell;

@protocol PLVECCommodityCellDelegate <NSObject>

- (void)didSelectWithCommodityCell:(PLVECCommodityCell *)commodityCell;

@end

@interface PLVECCommodityCell : UITableViewCell

@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, strong) UILabel *showIdLabel;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *realPriceLabel;

@property (nonatomic, strong) UILabel *priceLabel;

@property (nonatomic, strong) UIButton *selectButton;

@property (nonatomic, strong) PLVCommodityModel *model;

@property (nonatomic, weak) id<PLVECCommodityCellDelegate> delegate;

@property (nonatomic, strong, readonly) NSURL *jumpLinkUrl;

@end

NS_ASSUME_NONNULL_END
