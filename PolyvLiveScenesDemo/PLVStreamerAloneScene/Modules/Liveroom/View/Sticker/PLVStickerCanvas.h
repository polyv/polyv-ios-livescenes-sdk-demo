//
//  PLVStickerCanvas.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVStickerTextModel.h"
#import "PLVStickerTextView.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVStickerCanvas;

@protocol PLVStickerCanvasDelegate <NSObject>

/// 退出编辑模式
- (void)stickerCanvasExitEditMode:(PLVStickerCanvas *)stickerCanvas;

/// 进入编辑模式
- (void)stickerCanvasEnterEditMode:(PLVStickerCanvas *)stickerCanvas;

/// 开始编辑文本
- (void)stickerCanvasBeginEditingText:(PLVStickerCanvas *)stickerCanvas;

/// 结束编辑文本
- (void)stickerCanvasEndEditingText:(PLVStickerCanvas *)stickerCanvas;

/// 回调文字贴纸状态变化
- (void)stickerCanvasTextEditStateChanged:(PLVStickerCanvas *)stickerCanvas textView:(PLVStickerTextView *)textView;

/// 请求处理模版界面状态（当需要自动保存并关闭模版界面时）
- (void)stickerCanvasRequestHandleTemplateViewState:(PLVStickerCanvas *)stickerCanvas;

/// 文本贴纸进入删除模式
- (void)stickerCanvasTextViewDidEnterDeleteMode:(PLVStickerTextView *)textView;

@end

@interface PLVStickerCanvas : UIView

@property (nonatomic, weak) id<PLVStickerCanvasDelegate> delegate;

@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, strong) PLVStickerTextView *currentEditingTextView;

@property (nonatomic, assign) BOOL enableEdit;

@property (nonatomic, readonly) NSInteger curImageCount;

@property (nonatomic, readonly) NSInteger curTextCount;

/// 已经达到文本贴图数量限制
@property (nonatomic, readonly) BOOL  hasMaxTextCount;

/// 展示贴图画布
- (void)showCanvasWithImages:(NSArray<UIImage *> *)images;

/// 添加文本贴图
- (void)addTextStickerWithModel:(PLVStickerTextModel *)textModel;

/// 生成带透明通道的图片，子控件不透明
- (UIImage *)generateImageWithTransparentBackground;

/// 更新文本贴图
- (void)updateTextStickerWithModel:(PLVStickerTextModel *)textModel;

/// done 操作 保存贴纸
- (void)executeDone;

/// cancel 操作 取消贴纸编辑、新增
- (void)executeCancel;

/// 取消删除操作
- (void)executeCancelDelete:(PLVStickerTextView *)textView;

/// 确认删除操作
- (void)executeConfirmDelete:(PLVStickerTextView *)textView;

/// 手动退出编辑模式 贴图图像重新生成 隐藏贴图编辑画面
- (void)exitEditMode;

@end

NS_ASSUME_NONNULL_END
