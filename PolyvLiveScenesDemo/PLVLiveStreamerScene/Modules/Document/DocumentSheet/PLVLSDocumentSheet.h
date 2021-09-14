//
//  PLVLSDocumentSheet.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/9.
//  Copyright © 2021 PLV. All rights reserved.
//  文档弹出层

#import <UIKit/UIKit.h>
#import "PLVLSBottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVLSDocumentSheet;

@protocol PLVLSDocumentSheetDelegate <NSObject>

///  选择文档、文档页回调
///
/// @param documentSheet 文档窗对象
/// @param autoId 选择的文档autoId
/// @param pageIndex 选择的文档页序号（页码）
- (void)documentSheet:(PLVLSDocumentSheet *)documentSheet didSelectAutoId:(NSInteger)autoId pageIndex:(NSInteger)pageIndex;

@end

@interface PLVLSDocumentSheet : PLVLSBottomSheet

@property (nonatomic, weak) id<PLVLSDocumentSheetDelegate> delegate;
@property (nonatomic, assign, readonly) NSInteger selectAutoId;   // 选择文档的AutoId
@property (nonatomic, assign, readonly) NSInteger selectPageId;   // 选择文档的PageId

///  设置文档页面缩略图
///
/// @param imageUrls 文档页面缩略图url列表数据
/// @param autoId 文档autoId
- (void)setDocumentImageUrls:(NSArray <NSString *> *)imageUrls autoId:(NSInteger)autoId;

///  选择文档页面
///
/// @param autoId 文档autoId
/// @param pageIndex 文档页码
- (void)selectDocumentWithAutoId:(NSInteger)autoId pageIndex:(NSInteger)pageIndex;

@end

NS_ASSUME_NONNULL_END
