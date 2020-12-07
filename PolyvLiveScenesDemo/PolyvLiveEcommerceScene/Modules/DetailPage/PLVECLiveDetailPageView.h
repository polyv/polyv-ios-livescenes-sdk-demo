//
//  PLVECLiveDetailPageView.h
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 直播详情页视图容器
@interface PLVECLiveDetailPageView : UIView

- (void)addLiveInfoCardView:(NSString *)content;

- (void)addBulletinCardView:(NSString *)content;

- (void)removeBulletinCardView;

@end

NS_ASSUME_NONNULL_END
