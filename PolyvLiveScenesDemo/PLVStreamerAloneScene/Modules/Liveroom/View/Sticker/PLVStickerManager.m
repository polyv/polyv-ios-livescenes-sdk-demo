//
//  PLVStickerManager.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVStickerManager.h"
#import "PLVStickerCanvas.h"
#import "PLVStickerTextView.h"
#import "PLVStickerTextTemplateView.h"
#import "PLVStickerTextEditorView.h"
#import <Photos/Photos.h>
#import "PLVImagePickerViewController.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"


@interface PLVStickerManager () <
    PLVStickerTypeSelectionViewDelegate,
    PLVStickerTextTemplateViewDelegate,
    PLVStickerTextEditorViewDelegate,
    PLVStickerCanvasDelegate
>

@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, strong) PLVStickerCanvas *stickerCanvas;
@property (nonatomic, weak) PLVStickerTextView *currentEditingTextView;
@property (nonatomic, strong) PLVStickerTextTemplateView *currentTemplateView; // 当前显示的模版界面
@property (nonatomic, weak) PLVStickerTextView *pendingDeleteTextView; // 待删除的文本贴纸

@end

@implementation PLVStickerManager

#pragma mark - Life Cycle

-(void)dealloc{
    
}

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    if (self) {
        _parentView = parentView;
        [self setupCanvas];
    }
    return self;
}

#pragma mark - Setup

- (void)setupCanvas {
    // 创建贴图画布
    self.stickerCanvas = [[PLVStickerCanvas alloc] initWithFrame:self.parentView.bounds];
    self.stickerCanvas.delegate = self;
    self.stickerCanvas.frame = self.parentView.bounds;
    self.stickerCanvas.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (PLVStickerTextView *)currentEditingTextView{
    return self.stickerCanvas.currentEditingTextView;
}

#pragma mark - Public Methods

- (void)showStickerTypeSelection {
    // 确保有 stickerCanvas
    if (!self.stickerCanvas) {
        [self setupCanvas];
    }
    
    PLVStickerTypeSelectionView *selectionView = [[PLVStickerTypeSelectionView alloc] initWithSheetHeight:240 sheetLandscapeWidth:375];
    selectionView.delegate = self;
    [selectionView showInView:self.parentView];
}

- (UIImage *)generateStickerImage {
    return [self.stickerCanvas generateImageWithTransparentBackground];
}

- (void)clearAllStickers {
    // 移除所有子视图
    for (UIView *subview in self.stickerCanvas.contentView.subviews) {
        [subview removeFromSuperview];
    }
}

#pragma mark - Private Methods

// 显示图片选择器
- (void)showImagePicker {
    PLVImagePickerViewController *imagePickerVC = [[PLVImagePickerViewController alloc] initWithColumnNumber:4];
    imagePickerVC.allowPickingOriginalPhoto = YES;
    imagePickerVC.allowPickingVideo = NO;
    imagePickerVC.allowTakePicture = NO;
    imagePickerVC.allowTakeVideo = NO;
    imagePickerVC.maxImagesCount = 10;
    __weak typeof(self) weakSelf = self;
    
    if (self.stickerCanvas.curImageCount > 0){
        imagePickerVC.maxImagesCount = 10 - self.stickerCanvas.curImageCount ;
    }
    [imagePickerVC setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        //实现图片选择回调
        if (photos.count > 0) {
            // 不使用懒加载初始化
            if (!weakSelf.stickerCanvas){
                weakSelf.stickerCanvas = [[PLVStickerCanvas alloc] init];
                weakSelf.stickerCanvas.delegate = self;
            }
            // 确保 stickerCanvas 已添加到视图层次结构
            if (!weakSelf.stickerCanvas.superview) {
                [weakSelf.parentView addSubview:self.stickerCanvas];
                weakSelf.stickerCanvas.frame = self.parentView.bounds;
                [weakSelf.stickerCanvas layoutIfNeeded];
            }
            [weakSelf.stickerCanvas showCanvasWithImages:photos];
        }
    }];
     
    [imagePickerVC setImagePickerControllerDidCancelHandle:^{
        //实现图片选择取消回调
    }];
    
    [self presentImagePickerController:imagePickerVC];
}

- (void)presentImagePickerController:(PLVImagePickerViewController *)imagePickerVC {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:imagePickerVC animated:YES completion:nil];
}

#pragma mark - PLVStickerTypeSelectionViewDelegate

- (void)stickerTypeSelectionView:(PLVStickerTypeSelectionView *)selectionView didSelectType:(PLVStickerType)type {
    switch (type) {
        case PLVStickerTypeText:
            [self showTextTemplateSelection];
            break;
            
        case PLVStickerTypeImage:
            [self showImagePicker];
            break;
    }
}

- (void)stickerTypeSelectionViewDidCancel:(PLVStickerTypeSelectionView *)selectionView {
    // 用户取消选择，不做任何处理
}

#pragma mark - PLVStickerTextTemplateViewDelegate

- (void)textTemplateView:(PLVStickerTextTemplateView *)templateView didSelectTextModel:(PLVStickerTextModel *)textModel {
    // 确保 stickerCanvas 已添加到视图层次结构
    if (!self.stickerCanvas.superview) {
        [self.parentView addSubview:self.stickerCanvas];
        self.stickerCanvas.frame = self.parentView.bounds;
    }

    // 如果有待删除的贴纸并且刚刚从删除状态退出，恢复显示
    if (self.pendingDeleteTextView && !templateView.deleteState) {
        self.pendingDeleteTextView.hidden = NO;
        self.pendingDeleteTextView = nil;
    }

    // 实时预览模版效果
    [self.stickerCanvas updateTextStickerWithModel:textModel];
}

- (void)textTemplateView:(PLVStickerTextTemplateView *)templateView addTextModel:(PLVStickerTextModel *)textModel {
    // 确保 stickerCanvas 已添加到视图层次结构
    if (!self.stickerCanvas.superview) {
        [self.parentView addSubview:self.stickerCanvas];
        self.stickerCanvas.frame = self.parentView.bounds;
    }
    // 将选中的文本模板添加到画布
    [self.stickerCanvas addTextStickerWithModel:textModel];
}

/// done 完成回调
- (void)textTemplateView:(PLVStickerTextTemplateView *)templateView didDoneWithOperationType:(PLVStickerTemplateOperationType)operationType {
 
    // 如果有待删除的贴纸，执行确认删除
    if (self.pendingDeleteTextView) {
        [self.stickerCanvas executeConfirmDelete:self.pendingDeleteTextView];
        self.pendingDeleteTextView = nil;
    } else {
        // 正常的新增或编辑操作
        switch (operationType) {
            case PLVStickerTemplateOperationTypeAdd:
                // 新增贴纸：
                [self.stickerCanvas executeDone];
                break;

            case PLVStickerTemplateOperationTypeEdit:
                // 编辑贴纸：
                [self.stickerCanvas executeDone];
                break;
        }
    }

    // 清除模版界面引用
    self.currentTemplateView = nil;

    // canvas 退出编辑模式
    [self.stickerCanvas exitEditMode];
}

- (void)textTemplateView:(PLVStickerTextTemplateView *)templateView didCancelWithOperationType:(PLVStickerTemplateOperationType)operationType {
    // 如果有待删除的贴纸，执行取消删除
    if (self.pendingDeleteTextView) {
        [self.stickerCanvas executeCancelDelete:self.pendingDeleteTextView];
        self.pendingDeleteTextView = nil;
    } else {
        // 正常的取消操作
        switch (operationType) {
            case PLVStickerTemplateOperationTypeAdd:
                // 取消新增：移除刚添加的贴纸
                [self cancelAddOperation];
                break;

            case PLVStickerTemplateOperationTypeEdit:
                // 取消编辑：恢复原始样式
                [self.stickerCanvas executeCancel];
                break;
        }
    }

    // 清除模版界面引用
    self.currentTemplateView = nil;
    
    // canvas 退出编辑模式
    [self.stickerCanvas exitEditMode];
}

#pragma mark - PLVStickerTextEditorViewDelegate

- (void)textEditorView:(PLVStickerTextEditorView *)editorView didUpdateText:(NSString *)text {
    if (self.currentEditingTextView) {
        [self.currentEditingTextView updateText:text];
    }
}

- (void)textEditorView:(PLVStickerTextEditorView *)editorView didFinishEditingWithText:(NSString *)text {
    if (self.currentEditingTextView) {
        [self.currentEditingTextView updateText:text];
        // 编辑完成后回到actionshow状态
        [self.currentEditingTextView endTextEditing];
        self.currentEditingTextView.textUpdated = YES; // 标记文本已更新

        self.currentEditingTextView = nil;
    }
}

- (void)textEditorViewDidCancel:(PLVStickerTextEditorView *)editorView {
    // 取消文本编辑，回到actionshow状态
    if (self.currentEditingTextView) {
        [self.currentEditingTextView endTextEditing];
    }

    self.currentEditingTextView = nil;
}

#pragma mark - PLVStickerCanvasDelegate

- (void)stickerCanvasExitEditMode:(PLVStickerCanvas *)stickerCanvas {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerManagerDidExitEditMode:)]) {
        [self.delegate stickerManagerDidExitEditMode:self];
    }
}

- (void)stickerCanvasEnterEditMode:(PLVStickerCanvas *)stickerCanvas {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerManagerDidEnterEditMode:)]) {
        [self.delegate stickerManagerDidEnterEditMode:self];
    }
}

- (void)stickerCanvasBeginEditingText:(PLVStickerCanvas *)stickerCanvas {
    if (self.currentEditingTextView){
        PLVStickerTextEditorView *editorView = [[PLVStickerTextEditorView alloc] initWithTextModel:self.currentEditingTextView.textModel
                                                                                              height:self.parentView.bounds.size.height];
        editorView.delegate = self;
        [editorView showInView:self.parentView];
    }
}

- (void)stickerCanvasEndEditingText:(PLVStickerCanvas *)stickerCanvas {
    self.currentEditingTextView = nil;
}


- (void)stickerCanvasTextEditStateChanged:(PLVStickerCanvas *)stickerCanvas textView:(PLVStickerTextView *)textView {
   // 显示模版视图
    if (textView.editState >= PLVStickerTextEditStateActionVisible){
        // 父视图中不存在
        BOOL isExist = NO;
        for (UIView *subview in self.parentView.subviews){
            if ([subview isKindOfClass:[PLVStickerTextTemplateView class]]){
                isExist = YES;
            }
        }
        if (!isExist){
            [self showTextTemplateSelectionForEdit:textView.textModel];
        } else {
            // 如果模版界面已存在，更新引用
            for (UIView *subview in self.parentView.subviews){
                if ([subview isKindOfClass:[PLVStickerTextTemplateView class]]){
                    self.currentTemplateView = (PLVStickerTextTemplateView *)subview;
                    break;
                }
            }
        }
    }
}

- (void)stickerCanvasRequestHandleTemplateViewState:(PLVStickerCanvas *)stickerCanvas {
    // 处理模版界面状态：自动执行done操作并隐藏界面
    if (self.currentTemplateView) {
        // 自动执行done操作，保存当前文本贴纸的所有修改
        [self.currentTemplateView executeDoneAction];

        // 注意：doneButtonAction会自动调用hideWithCompletion，所以不需要手动隐藏
        // 并且在didConfirmWithModel回调中会清除currentTemplateView引用
    }
}

- (void)stickerCanvasTextViewDidEnterDeleteMode:(PLVStickerTextView *)textView {
    // 保存待删除的文本贴纸引用
    self.pendingDeleteTextView = textView;
    
    // 保持模版界面显示，不做任何修改
}

#pragma mark - Helper Methods

- (void)showTextTemplateSelection {
    if (self.stickerCanvas.hasMaxTextCount){
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"最多添加10个文字贴图") inView:self.parentView];
        return;
    }

    PLVStickerTextTemplateView *templateView = [[PLVStickerTextTemplateView alloc] init];
    templateView.delegate = self;
    self.currentTemplateView = templateView; // 保存当前模版界面引用
    [templateView showForAddInView:self.parentView];
}

- (void)showTextTemplateSelectionForEdit:(PLVStickerTextModel *)textModel {
    PLVStickerTextTemplateView *templateView = [[PLVStickerTextTemplateView alloc] init];
    templateView.delegate = self;
    self.currentTemplateView = templateView; // 保存当前模版界面引用
    [templateView showForEditInView:self.parentView textModel:textModel];
}

#pragma mark - Cancel Operations

- (void)cancelAddOperation {
    // 移除最后添加的贴纸（通常是最新的一个）
    if (self.currentEditingTextView){
        [self.currentEditingTextView removeFromSuperview];
    }
}

@end 
