//
//  PLVSABeautyBaseViewController.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVSABeautyCellModel.h"
#import "PLVSABEAutyViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVSABeautyBaseViewController : UIViewController

#pragma mark 数据
/// 数据源
@property (nonatomic, strong) NSArray <PLVSABeautyCellModel *> *dataArray;
/// 当前选中下标
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
/// 当前美颜类型
@property (nonatomic, assign) PLVSABeautyType beautyType;

/// 设置数据源
- (void)setupDataArray;

/// 显示ContentView
- (void)showContentView;

/// 开启美颜
/// @param open YES: 开启 NO: 关闭
- (void)beautyOpen:(BOOL)open;

/// 重置美颜
- (void)resetBeauty;

@end

NS_ASSUME_NONNULL_END
