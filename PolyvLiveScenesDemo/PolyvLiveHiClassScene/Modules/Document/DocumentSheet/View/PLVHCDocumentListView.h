//
//  PLVHCDocumentListView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/29.
//  Copyright © 2021 polyv. All rights reserved.
// 文档列表

#import <UIKit/UIKit.h>
#import "PLVDocumentModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVHCDocumentListView;

@protocol PLVHCDocumentListViewDelegate <NSObject>

///  点击上传文档按钮回调
/// @param documentListView 文档列表对象
- (void)documentListViewUploadDocument:(PLVHCDocumentListView *)documentListView;

///  文档上传须知按钮响应回调
/// @param documentListView 文档列表对象
- (void)documentListViewShowTip:(PLVHCDocumentListView *)documentListView;

///  选择文档回调
/// @param documentListView 文档列表对象
/// @param model 选择的文档数据对象
- (void)documentListView:(PLVHCDocumentListView *)documentListView didSelectItemModel:(PLVDocumentModel *)model;

@end

@interface PLVHCDocumentListView : UIView

@property (nonatomic, weak) id<PLVHCDocumentListViewDelegate> delegate;

///  关闭删除视图
- (void)dismissDeleteView;

/// 刷新文档列表
- (void)refreshListView;

@end

NS_ASSUME_NONNULL_END
