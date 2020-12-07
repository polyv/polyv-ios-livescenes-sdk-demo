//
//  PLVECSwitchView.h
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECBottomView.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVECSwitchView;
@protocol PLVPlayerSwitchViewDelegate <NSObject>

@optional
- (void)playerSwitchView:(PLVECSwitchView *)playerSwitchView didSelectItem:(NSString *)item;

@end

/// 切换视图
@interface PLVECSwitchView : PLVECBottomView

@property (nonatomic, weak) id<PLVPlayerSwitchViewDelegate> delegate;

@property (nonatomic, strong) UILabel *titleLable;

@property (nonatomic, copy) NSArray<NSString *> *items;

@property (nonatomic, assign) NSUInteger selectedIndex;

@end

NS_ASSUME_NONNULL_END
