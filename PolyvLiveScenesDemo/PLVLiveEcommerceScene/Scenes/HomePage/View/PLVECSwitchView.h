//
//  PLVECSwitchView.h
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECBottomView.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVECSwitchView;

@protocol PLVPlayerSwitchViewDelegate <NSObject>

- (NSArray<NSString *> *)dataSourceOfSwitchView:(PLVECSwitchView *)switchView;

@optional

- (void)playerSwitchView:(PLVECSwitchView *)playerSwitchView
        didSelectedIndex:(NSUInteger)selectedIndex
            selectedItem:(NSString *)selectedItem;

@end

/// 切换视图
@interface PLVECSwitchView : PLVECBottomView

@property (nonatomic, weak) id<PLVPlayerSwitchViewDelegate> delegate;

@property (nonatomic, strong) UILabel *titleLable;

@property (nonatomic, assign) NSUInteger selectedIndex;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
