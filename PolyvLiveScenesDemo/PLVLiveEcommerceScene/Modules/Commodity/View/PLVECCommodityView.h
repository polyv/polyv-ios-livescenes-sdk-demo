//
//  PLVECCommodityView.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/6/28.
//  Copyright © 2020 PLV. All rights reserved.
//  商品列表View

#import "PLVECBottomView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECCommodityView : PLVECBottomView

// 开放 tableview 数据代理
@property (nonatomic, weak, nullable) id <UITableViewDataSource> dataSource;
// 开放 tableview UI代理
@property (nonatomic, weak, nullable) id <UITableViewDelegate> delegate;

/// 开启loading
- (void)startLoading;

/// 停止loading
- (void)stopLoading;

/// 加载视图数据
- (void)reloadData:(NSInteger)total;

@end

NS_ASSUME_NONNULL_END
