//
//  PLVLCDocumentToolView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/10/19.
//  Copyright © 2021 PLV. All rights reserved.
// 文档工具视图，用于操作文档翻页

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVLCDocumentToolView;

@protocol PLVLCDocumentToolViewDelegate <NSObject>

- (void)documentToolView:(PLVLCDocumentToolView *)documentToolView didChangePageWithType:(PLVChangePPTPageType)type;

@end

@interface PLVLCDocumentToolView : UIView

@property (nonatomic, weak)id<PLVLCDocumentToolViewDelegate> delegate;

/// 视图当前宽度，动态计算后的结果
@property (nonatomic, assign, readonly)CGFloat viewWidth;

/// 文档、白板页码 数据设置
/// @param pageNumber 文档当前页码
/// @param totalPage 文档总页码
/// @param maxNextNumber 最大的下一页页码
- (void)setupPageNumber:(NSUInteger)pageNumber totalPage:(NSUInteger)totalPage maxNextNumber:(NSUInteger)maxNextNumber;

/// 设置PPT是否在主页
/// @param mainSpeakerPPTOnMain ppt是否在主讲页
- (void)setupMainSpeakerPPTOnMain:(BOOL)mainSpeakerPPTOnMain;

@end

NS_ASSUME_NONNULL_END
