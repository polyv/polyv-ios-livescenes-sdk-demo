//
//  PLVKeyMomentsListView.h
//  PLVLiveScenesDemo
//
//  Created by Developer on 2025/01/01.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVKeyMomentModel;
@protocol PLVKeyMomentsListViewDelegate;

/// 精彩看点列表视图
@interface PLVKeyMomentsListView : UIView

@property (nonatomic, weak) id<PLVKeyMomentsListViewDelegate> delegate;
@property (nonatomic, strong) NSArray<PLVKeyMomentModel *> *keyMoments;

/// 显示列表
- (void)show;

/// 隐藏列表
- (void)hide;

@end

@protocol PLVKeyMomentsListViewDelegate <NSObject>

/// 点击精彩看点列表项
/// @param listView 列表视图
/// @param keyMoment 被点击的精彩看点
- (void)keyMomentsListView:(PLVKeyMomentsListView *)listView didSelectKeyMoment:(PLVKeyMomentModel *)keyMoment;

/// 精彩看点列表即将关闭
/// @param listView 列表视图
- (void)keyMomentsListViewWillDismiss:(PLVKeyMomentsListView *)listView;

@end

NS_ASSUME_NONNULL_END
