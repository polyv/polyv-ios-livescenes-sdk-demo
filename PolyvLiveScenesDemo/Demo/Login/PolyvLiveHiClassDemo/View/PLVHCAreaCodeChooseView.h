//
//  PLVHCAreaCodeChooseView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/9/14.
//  Copyright © 2021 polyv. All rights reserved.
// 国家（地区）区号选择器

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCAreaCodeChooseView;

@protocol PLVHCAreaCodeChooseViewDelegate <NSObject>

/// 选中 国家（地区）区号 回调
- (void)areaCodeChooseView:(PLVHCAreaCodeChooseView *)areaCodeChooseView didSelectAreaCode:(NSString *)areaCode;

@end

@interface PLVHCAreaCodeChooseView : UIView

@property (nonatomic, weak)id<PLVHCAreaCodeChooseViewDelegate> delegate;

/// 弹出弹层
/// @param view 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
