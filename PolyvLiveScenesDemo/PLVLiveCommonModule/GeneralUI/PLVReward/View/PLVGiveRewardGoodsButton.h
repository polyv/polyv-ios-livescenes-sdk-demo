//
//  PLVGiveRewardGoodsButton.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVRewardGoodsModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVRewardGoodsModel;

/// 礼物选项按钮（展示礼物图、礼物名、积分）
@interface PLVGiveRewardGoodsButton : UIControl

/// 设置对应的礼物模型
/// @param model 所对应的礼物模型
/// @param pointUnit 礼物单价
- (void)setModel:(PLVRewardGoodsModel *)model pointUnit:(NSString *)pointUnit;

@end

NS_ASSUME_NONNULL_END
