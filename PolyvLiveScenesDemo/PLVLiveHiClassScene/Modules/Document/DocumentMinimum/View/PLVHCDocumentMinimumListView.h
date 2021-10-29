//
//  PLVHCDocumentMinimumListView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/9.
//  Copyright © 2021 PLV. All rights reserved.
// 文档最小化文档列表视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCDocumentMinimumListView;
@class PLVHCDocumentMinimumModel;

@protocol PLVHCDocumentMinimumListViewDelegate <NSObject>

///  选择文档回调
- (void)documentMinimumListView:(PLVHCDocumentMinimumListView *)documentMinimumListView didSelectItemModel:(PLVHCDocumentMinimumModel *)model;

///  关闭文档回调
- (void)documentMinimumListView:(PLVHCDocumentMinimumListView *)documentMinimumListView didCloseItemModel:(PLVHCDocumentMinimumModel *)model;

@end

@interface PLVHCDocumentMinimumListView : UIView

@property (nonatomic, weak) id<PLVHCDocumentMinimumListViewDelegate> delegate;

/// 本视图是否正在显示
@property (nonatomic, assign, readonly, getter=isShowing) BOOL showing;

@property (nonatomic, assign, readonly) NSInteger minimumNum; // 最小化数量

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 隐藏列表视图
- (void)dismiss;

/// 刷新最小化的容器(ppt、word各类文档统称)数据
/// @param dataArray js 回调的最小化的容器数据
- (void)refreshMinimizeContainerDataArray:(NSArray <PLVHCDocumentMinimumModel *> *)dataArray;

@end

NS_ASSUME_NONNULL_END
