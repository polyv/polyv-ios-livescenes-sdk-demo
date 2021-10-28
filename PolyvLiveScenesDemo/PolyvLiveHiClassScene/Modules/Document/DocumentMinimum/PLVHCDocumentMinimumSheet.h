//
//  PLVHCDocumentMinimumSheet.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/26.
//  Copyright © 2021 polyv. All rights reserved.
// 文档最小化弹层
// 集成了最小化数量悬浮按钮视图、最小化文档列表视、最小化新手引导视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCDocumentMinimumModel;
@class PLVHCDocumentMinimumSheet;

@protocol PLVHCDocumentMinimumSheetDelegate <NSObject>

///  选择文档回调
- (void)documentMinimumSheet:(PLVHCDocumentMinimumSheet *)documentMinimumSheet didSelectItemModel:(PLVHCDocumentMinimumModel *)model;

///  关闭文档回调
- (void)documentMinimumSheet:(PLVHCDocumentMinimumSheet *)documentMinimumSheet didCloseItemModel:(PLVHCDocumentMinimumModel *)model;

@end


@interface PLVHCDocumentMinimumSheet : UIView

@property (nonatomic, weak)id<PLVHCDocumentMinimumSheetDelegate> delegate;

/// 是否为最大最小化文档数量，当前版本限制最多为5个
@property (nonatomic, assign, readonly, getter=isMaxMinimumNum) BOOL maxMinimumNum;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 收起弹层
- (void)dismiss;

/// 设置最小化数量
/// @param total js返回的最小化数量数据
- (void)refreshPptContainerTotal:(NSInteger)total;

/// 刷新最小化的容器(ppt、word各类文档统称)数据
/// @param dataArray js 回调的最小化的容器数据
- (void)refreshMinimizeContainerDataArray:(NSArray <PLVHCDocumentMinimumModel *> *)dataArray;

@end

NS_ASSUME_NONNULL_END
