//
//  PLVStickerTextView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVStickerTextModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 文本贴纸编辑状态枚举
typedef NS_ENUM(NSInteger, PLVStickerTextEditState) {
    PLVStickerTextEditStateNormal = 0,          // 普通状态
    PLVStickerTextEditStateSelected = 1,        // 选中状态(状态1) - 显示虚线边框，可拖动
    PLVStickerTextEditStateActionVisible = 2,   // 显示操作按钮(状态2) - 显示删除和编辑按钮
    PLVStickerTextEditStateTextEditing = 3      // 文本编辑状态(状态3) - 弹出文本编辑框
};

@class PLVStickerTextView;

@protocol PLVStickerTextViewDelegate <NSObject>

@optional
/// 点击文本贴图内容视图的回调
- (void)plv_StickerTextViewDidTapContentView:(PLVStickerTextView *)stickerTextView;

/// 移动文本贴图的回调
- (void)plv_StickerTextViewHandleMove:(PLVStickerTextView *)stickerTextView point:(CGPoint)point gestureEnded:(BOOL)ended;

/// 开始编辑文本内容的回调
- (void)plv_StickerTextViewDidBeginEditing:(PLVStickerTextView *)stickerTextView;

/// 结束编辑文本内容的回调
- (void)plv_StickerTextViewDidEndEditing:(PLVStickerTextView *)stickerTextView;

/// 点击删除按钮的回调
- (void)plv_StickerTextViewDidTapDeleteButton:(PLVStickerTextView *)stickerTextView;

/// 编辑状态改变的回调
- (void)plv_StickerTextView:(PLVStickerTextView *)stickerTextView didChangeEditState:(PLVStickerTextEditState)editState;

@end

@interface PLVStickerTextView : UIView <UIGestureRecognizerDelegate>

/// 代理对象
@property (nonatomic, weak, nullable) id<PLVStickerTextViewDelegate> delegate;

/// 是否启用控制功能
@property (nonatomic, assign) BOOL enabledControl;

/// 是否显示边框
@property (nonatomic, assign) BOOL enabledBorder;

/// 是否启用编辑模式
@property (nonatomic, assign) BOOL enableEdit;

/// 当前编辑状态
@property (nonatomic, assign) PLVStickerTextEditState editState;

/// 文本数据模型
@property (nonatomic, strong) PLVStickerTextModel *textModel;

/// 文本内容是否更新过
@property (nonatomic, assign) BOOL textUpdated;

/// 是否为新增的贴纸 (用于区分删除操作中的取消行为)
@property (nonatomic, assign) BOOL isNewlyAdded;

/// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame textModel:(PLVStickerTextModel *)textModel;

/// 执行点击操作
- (void)performTapOperation;

/// 更新文本内容
- (void)updateText:(NSString *)text;

/// 更新模版样式 和 文本
- (void)updateTextMode:(PLVStickerTextModel* )textModel;

/// done 操作 保存贴纸
- (void)executeDone;

/// cancel 操作 取消贴纸编辑 新增
- (void)executeCancel;

/// 重置到普通状态
- (void)resetToNormalState;

/// 手动触发编辑状态改变
- (void)triggerEditStateChange;

/// 结束文本编辑，回到actionshow状态
- (void)endTextEditing;

@end

NS_ASSUME_NONNULL_END 
