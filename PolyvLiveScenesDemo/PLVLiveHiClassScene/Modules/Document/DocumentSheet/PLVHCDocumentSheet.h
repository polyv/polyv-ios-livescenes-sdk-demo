//
//  PLVHCDocumentSheet.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//
// 文档管理弹层

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCDocumentSheet;
@class PLVDocumentModel;

@protocol PLVHCDocumentSheetDelegate <NSObject>

///  选择文档时回调
/// @param documentSheet 文档窗对象
/// @param model 选择的文档模型
- (void)documentSheet:(PLVHCDocumentSheet *)documentSheet didSelectModel:(PLVDocumentModel *)model;

@end

///  文档弹出层
@interface PLVHCDocumentSheet : UIView

@property (nonatomic, weak) id<PLVHCDocumentSheetDelegate> delegate;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 收起弹层
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
