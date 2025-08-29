//
//  PLVStickerTextEditorView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import "PLVStickerTextModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVStickerTextEditorView;

@protocol PLVStickerTextEditorViewDelegate <NSObject>

/// 文本内容实时更新的回调
- (void)textEditorView:(PLVStickerTextEditorView *)editorView didUpdateText:(NSString *)text;

/// 完成文本编辑的回调
- (void)textEditorView:(PLVStickerTextEditorView *)editorView didFinishEditingWithText:(NSString *)text;

/// 取消编辑的回调
- (void)textEditorViewDidCancel:(PLVStickerTextEditorView *)editorView;

@end

@interface PLVStickerTextEditorView : PLVSABottomSheet

@property (nonatomic, weak) id<PLVStickerTextEditorViewDelegate> delegate;

/// 初始化方法
/// @param model 初始文本数据模型
/// @param height 弹窗高度
- (instancetype)initWithTextModel:(PLVStickerTextModel *)model height:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END 
