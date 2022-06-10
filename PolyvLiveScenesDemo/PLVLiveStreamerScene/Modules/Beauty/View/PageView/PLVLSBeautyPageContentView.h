//
//  PLVLSBeautyPageContentView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVLSBeautyPageContentView;
@protocol PLVLSBeautyPageContentViewDeleagte <NSObject>

- (void)pageContentView:(PLVLSBeautyPageContentView *)pageContentView didSelectedIndex:(NSUInteger)index;

@end

@interface PLVLSBeautyPageContentView : UIView

@property (nonatomic, weak) id<PLVLSBeautyPageContentViewDeleagte> delegate;

/// 初始化
/// @param childArray 分页子视图数组
/// @param parentVC 父控件
- (instancetype)initWithChildArray:(NSArray<UIViewController *> *)childArray parentViewController:(UIViewController *)parentVC;

/// 设置分页视图
/// @param index 下标
- (void)setPageContentViewWithTargetIndex:(NSUInteger)index;

@end

