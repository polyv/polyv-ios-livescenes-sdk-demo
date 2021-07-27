//
//  PLVLSDocumentPagesView.h
//  PLVLiveStreamerDemo
//
//  Created by Hank on 2021/3/9.
//  Copyright © 2021 PLV. All rights reserved.
//  文档页面列表

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSDocumentPagesView;

@protocol PLVLSDocumentPagesViewDelegate <NSObject>

///  点击返回按钮响应回调
///
/// @param documentPagesView 文档列表页面对象
- (void)documentPagesViewDidBackAction:(PLVLSDocumentPagesView *)documentPagesView;

///  选中文档页面回调
///
/// @param documentPagesView 文档列表页面对象
/// @param index 选择的文档页面序号
- (void)documentPagesView:(PLVLSDocumentPagesView *)documentPagesView didSelectItemAtIndex:(NSInteger)index;

@end

@interface PLVLSDocumentPagesView : UIView

@property (nonatomic, weak) id<PLVLSDocumentPagesViewDelegate> delegate;
@property (nonatomic, strong) NSString *title;

///  设置文档页面缩略图
///
/// @param imageUrls 文档页面缩略图url列表数据
- (void)setPagesViewDatas:(NSArray<NSString *> *)imageUrls;

///  选择文档页面
///
/// @param index 文档页面缩略图序号（页码）
- (void)setSelectPageIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
