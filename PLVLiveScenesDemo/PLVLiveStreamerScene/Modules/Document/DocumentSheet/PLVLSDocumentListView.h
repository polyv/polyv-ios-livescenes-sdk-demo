//
//  PLVLSDocumentListView.h
//  PLVLiveStreamerDemo
//
//  Created by Hank on 2021/3/8.
//  Copyright © 2021 PLV. All rights reserved.
//  文档列表

#import <UIKit/UIKit.h>
#import "PLVDocumentModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVLSDocumentListView;

@protocol PLVLSDocumentListViewDelegate <NSObject>

///  点击上传文档按钮回调
///
/// @param documentListView 文档列表对象
- (void)documentListViewUploadDocument:(PLVLSDocumentListView *)documentListView;

///  文档上传须知按钮响应回调
///
/// @param documentListView 文档列表对象
- (void)documentListViewShowTip:(PLVLSDocumentListView *)documentListView;

///  选择文档回调
///
/// @param documentListView 文档列表对象
/// @param model 选择的文档数据对象
/// @param isChangeDocument YES 切换文档，NO 没有切换只是单纯的二次点击
- (void)documentListView:(PLVLSDocumentListView *)documentListView didSelectItemModel:(PLVDocumentModel *)model changeDocument:(BOOL)isChangeDocument;

@end

@interface PLVLSDocumentListView : UIView

@property (nonatomic, weak) id<PLVLSDocumentListViewDelegate> delegate;

@property (nonatomic, assign, readonly) NSInteger selectAutoId; // 选择的文档autoId

///  开启选择文档加载视图
- (void)startSelectCellLoading;

///  关闭选择文档加载视图
- (void)stopSelectCellLoading;

///  关闭删除视图
- (void)dismissDeleteView;

/// 刷新文档列表
- (void)refreshListView;

@end

NS_ASSUME_NONNULL_END
