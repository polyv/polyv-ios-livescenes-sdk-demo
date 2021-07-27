//
//  PLVECRewardView.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/6/28.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECBottomView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECGiftItem : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *imageName;

+ (instancetype)giftItemWithName:(NSString *)name imageName:(NSString *)imageName;

@end

@class PLVECRewardView;
@protocol PLVECRewardViewDelegate <NSObject>

@optional

- (void)rewardView:(PLVECRewardView *)rewardView didSelectItem:(PLVECGiftItem *)giftItem;

@end

/// 打赏视图
@interface PLVECRewardView : PLVECBottomView

@property (nonatomic, weak) id<PLVECRewardViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
