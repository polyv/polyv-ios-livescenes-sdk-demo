//
//  PLVStickerTextTemplateView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVStickerTextModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 模版选择操作类型
typedef NS_ENUM(NSInteger, PLVStickerTemplateOperationType) {
    PLVStickerTemplateOperationTypeAdd = 0,      // 新增贴纸
    PLVStickerTemplateOperationTypeEdit = 1     // 编辑贴纸
};

@class PLVStickerTextTemplateView;

@protocol PLVStickerTextTemplateViewDelegate <NSObject>

/// 新增贴纸回调
- (void)textTemplateView:(PLVStickerTextTemplateView *)templateView addTextModel:(PLVStickerTextModel *)textModel;

/// 选择文本模板的回调（用于编辑现有贴纸）
- (void)textTemplateView:(PLVStickerTextTemplateView *)templateView didSelectTextModel:(PLVStickerTextModel *)textModel;

/// 确认操作回调（done按钮）
- (void)textTemplateView:(PLVStickerTextTemplateView *)templateView didDoneWithOperationType:(PLVStickerTemplateOperationType)operationType;

/// 取消操作回调（cancel按钮）
- (void)textTemplateView:(PLVStickerTextTemplateView *)templateView didCancelWithOperationType:(PLVStickerTemplateOperationType)operationType;

@end

@interface PLVStickerTextTemplateView : UIView

@property (nonatomic, weak) id<PLVStickerTextTemplateViewDelegate> delegate;

/// 当前操作类型
@property (nonatomic, assign, readonly) PLVStickerTemplateOperationType operationType;

/// 是否处于删除状态
@property (nonatomic, assign) BOOL deleteState;

/// 显示新增贴纸模版选择
/// @param parentView 父视图
- (void)showForAddInView:(UIView *)parentView;

/// 显示编辑贴纸模版选择
/// @param parentView 父视图
/// @param textModel 要编辑的文本模型
- (void)showForEditInView:(UIView *)parentView textModel:(PLVStickerTextModel *)textModel;

/// 隐藏视图并从父视图中移除
/// @param completion 隐藏完成后的回调
- (void)hideWithCompletion:(void(^)(void))completion;

/// 执行完成操作
- (void)executeDoneAction;



@end

NS_ASSUME_NONNULL_END 
