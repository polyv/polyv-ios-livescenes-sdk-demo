//
//  PLVECCommodityView.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/28.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECBottomView.h"
#import "PLVECCommodityPresenter.h"

NS_ASSUME_NONNULL_BEGIN

/// 商品视图（唯一可由外部模块控制的类）
@interface PLVECCommodityView : PLVECBottomView <PLVECCommodityViewProtocol, PLVECCommodityPresenterProtocol>

@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UIImageView *notAddedImageView;

@property (nonatomic, strong) UILabel *tipLabel;

@property (nonatomic, copy) void(^ _Nullable goodsSelectedHandler)(NSURL *goodsURL);

@end

NS_ASSUME_NONNULL_END
