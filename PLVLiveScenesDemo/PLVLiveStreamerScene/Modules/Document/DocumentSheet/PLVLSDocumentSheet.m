//
//  PLVLSDocumentSheet.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/9.
//  Copyright © 2021 PLV. All rights reserved.
//  文档弹出层

#import "PLVLSDocumentSheet.h"

/// 工具
#import "PLVLSUtils.h"

/// UI
#import "PLVLSDocumentListView.h"
#import "PLVLSDocumentPagesView.h"
#import "PLVLSDocumentUploadTipsView.h"

/// 模块
#import "PLVDocumentConvertManager.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVDocumentUploadClient.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSDocumentSheet ()
<
PLVLSDocumentListViewDelegate,
PLVLSDocumentPagesViewDelegate,
PLVDocumentUploadErrorDelegate,
UIDocumentPickerDelegate
>

/// UI
@property (nonatomic, strong) UIScrollView *scrollView ;            // 文档父层View
@property (nonatomic, strong) PLVLSDocumentListView *docListView;   // 文档列表视图
@property (nonatomic, strong) PLVLSDocumentPagesView *docPagesView; // 文档页面列表视图

/// 数据
@property (nonatomic, strong) NSString *pagesTitle;                 // 文档页面列表标题
@property (nonatomic, strong) NSArray *imageUrls;                   // 文档页面列表数据
@property (nonatomic, assign) NSInteger selectPageId;               // 选择文档的PageId（页序号）
@property (nonatomic, assign) BOOL isChangeDocument;                // 是否切换到新文档状态
@property (nonatomic, assign) BOOL firstClick;      // 登录后是否首次点击进入【文档列表】，NO 为 首次

@end

@implementation PLVLSDocumentSheet

#pragma mark - [ Life Period ]

- (instancetype)init {
    CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.75;
    if (self = [super initWithSheetHeight:sheetHeight showSlider:YES]) {
        [self.contentView addSubview:self.scrollView];
        [self.scrollView addSubview:self.docListView];
        
        [PLVDocumentUploadClient sharedClient].errorDelegate = self;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.scrollView.frame = CGRectMake(PLVLSUtils.safeSidePad, 21, UIViewGetWidth(self.contentView) - 2 * PLVLSUtils.safeSidePad, UIViewGetHeight(self.contentView) - 21 - PLVLSUtils.safeBottomPad);
    self.docListView.frame = self.scrollView.bounds;
    
    if (!self.firstClick) {
        self.firstClick = YES;
        
        if ([[PLVDocumentUploadClient sharedClient].uploadingArray count] > 0) {
            [PLVLSUtils showAlertWithMessage:@"存在上传中断的任务，是否恢复？" cancelActionTitle:@"恢复上传" cancelActionBlock:^{
                [[PLVDocumentUploadClient sharedClient] continueAllUpload];
            } confirmActionTitle:@"删除" confirmActionBlock:^{
                [[PLVDocumentUploadClient sharedClient] clearAllUpload];
            }];
        }
    }
    
}

#pragma mark - [ Getter ]
- (UIScrollView *)scrollView {
    if (! _scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        _scrollView.scrollEnabled = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    
    return _scrollView;
}

- (PLVLSDocumentListView *)docListView {
    if (! _docListView) {
        _docListView = [[PLVLSDocumentListView alloc] init];
        _docListView.delegate = self;
    }
    
    return _docListView;
}

- (NSInteger)selectAutoId {
    return self.docListView.selectAutoId;
}

#pragma mark - [ Public Methods ]

- (void)setDocumentImageUrls:(NSArray <NSString *> *)imageUrls autoId:(NSInteger)autoId {
    if (self.selectAutoId != autoId || !self.isChangeDocument) {
        return;
    }
    
    _imageUrls = imageUrls;
    
    [self dismiss];
}

- (void)selectDocumentWithAutoId:(NSInteger)autoId pageIndex:(NSInteger)pageIndex {
    if (self.selectAutoId != autoId) {
        return;
    }
    
    _selectPageId = pageIndex;
    
    if (self.docPagesView) {
        [self.docPagesView setSelectPageIndex:pageIndex];
    }
}

- (void)showInView:(UIView *)parentView {
    [[PLVDocumentConvertManager sharedManager] polling:YES];
    
    if (self.selectAutoId > 0) { // 有已选择文档跳到文档页面列表
        [self scrollToDocumentPageViewWithAnimate:NO];
    } else { // 当前在文档页面列表，刷新列表
        [self.docListView refreshListView];
    }
    
    [super showInView:parentView];
}

- (void)dismiss {
    [[PLVDocumentConvertManager sharedManager] polling:NO];
    [super dismiss];
    [self.docListView dismissDeleteView];
}

#pragma mark - [ Private Methods ]

/// 滚动到文档列表页面
- (void)scrollToDocumentListViewWithAnimate:(BOOL)animate {
    [self scrollToPageIndex:0 animate:animate];
}

/// 滚动到文档详情页面
- (void)scrollToDocumentPageViewWithAnimate:(BOOL)animate {
    [self scrollToPageIndex:1 animate:animate];
}

/// 方法 '-scrollToDocumentListViewWithAnimate:' 和 '-scrollToDocumentPageViewWithAnimate:' 的调用方法
- (void)scrollToPageIndex:(NSInteger)index animate:(BOOL)animate {
    if (index < 0 || index > 1) {
        return;
    }
    
    CGFloat scrollX = (index == 1) ? self.docListView.frame.size.width : 0;
    if (scrollX == self.scrollView.contentOffset.x) {
        return;
    }
    
    if (index == 0) {
        [self.docPagesView removeFromSuperview];
        self.docPagesView = nil;
    } else {
        [self.docListView stopSelectCellLoading];
        
        if (! self.docPagesView) {
            _docPagesView = [[PLVLSDocumentPagesView alloc] init];
            self.docPagesView.delegate = self;
        }
        
        [self.scrollView addSubview:self.docPagesView];
        
        CGRect pagesFrame = self.docListView.frame;
        pagesFrame.origin.x += pagesFrame.size.width;
        self.docPagesView.frame = pagesFrame;
        
        self.docPagesView.title = self.pagesTitle;
        [self.docPagesView setPagesViewDatas:self.imageUrls];
        [self.docPagesView setSelectPageIndex:self.selectPageId];
    }
    
    if (animate) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear
                         animations:^{
            self.scrollView.contentOffset = CGPointMake(scrollX, 0);
        } completion:nil];
    } else {
        self.scrollView.contentOffset = CGPointMake(scrollX, 0);
    }
}

#pragma mark Document Utils

/// 【文件】中可选文档类型
- (NSArray *)documentTypes {
    NSArray *types = @[
     @"com.adobe.pdf",
     @"public.jpeg", @"public.jpeg-2000", @"public.png",
     @"com.microsoft.excel.xls",// xls
     @"com.microsoft.word.doc", // doc
     @"org.openxmlformats.spreadsheetml.sheet", // xlsx
     @"org.openxmlformats.wordprocessingml.document", // docx
     @"public.presentation", // pptx,ppt
    ];
    return types;
}

/// 判断选中文档是否是 ppt 或 pptx
- (BOOL)fileIsPPT:(NSURL *)url {
    NSString *fileExtension = url.pathExtension;
    if (!fileExtension || fileExtension.length == 0) {
        return NO;
    }
    return ([fileExtension isEqualToString:@"ppt"] || [fileExtension isEqualToString:@"pptx"]);
}

/// 判断选中文档的格式是否符合要求
- (BOOL)judgeFileType:(NSURL *)url {
    NSString *fileExtension = url.pathExtension;
    if (!fileExtension || fileExtension.length == 0) {
        return NO;
    }
    
    NSSet<NSString *> *supperFileExtensions = [[NSSet alloc] initWithObjects:
        @"pdf", @"jpg", @"jpeg", @"png", @"doc", @"docx", @"ppt", @"pptx", @"xls", @"xlsx", nil
    ];
    return [supperFileExtensions containsObject:fileExtension];
}

/// 判断选中文档的大小是否超过 500M
- (BOOL)judgeFileByte:(NSURL *)url {
    NSData *fileData = [NSData dataWithContentsOfURL:url];
    if (fileData.length <= 500 * 1024 * 1024) {// 不能大于 500M
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - [ Delegate ]
#pragma mark PLVLSDocumentListViewDelegate

- (void)documentListViewUploadDocument:(PLVLSDocumentListView *)documentListView {
    if ([[PLVDocumentUploadClient sharedClient].uploadingArray count] >= 3) {
        [PLVLSUtils showToastInHomeVCWithMessage:@"最多同时上传3个文件，请稍后重试"];
    } else {
        UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:[self documentTypes] inMode:UIDocumentPickerModeImport];
        documentPicker.delegate = self;
        UIViewController *currentViewController = [PLVFdUtil getCurrentViewController];
        documentPicker.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [currentViewController presentViewController:documentPicker animated:YES completion:nil];
    }
}

- (void)documentListViewShowTip:(PLVLSDocumentListView *)documentListView {
    PLVLSDocumentUploadTipsView *tipsView = [[PLVLSDocumentUploadTipsView alloc] init];
    [tipsView showInView:self.superview];
}

- (void)documentListView:(PLVLSDocumentListView *)documentListView didSelectItemModel:(PLVDocumentModel *)model changeDocument:(BOOL)isChangeDocument {
    _isChangeDocument = isChangeDocument;
    
    _pagesTitle = [NSString stringWithFormat:@"%@.%@", model.fileName, model.fileType];
    
    if (isChangeDocument) {
        [documentListView startSelectCellLoading];
        _imageUrls = nil;
        _selectPageId = 0;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(documentSheet:didSelectAutoId:pageIndex:)]) {
            [self.delegate documentSheet:self didSelectAutoId:model.autoId pageIndex:0];
        }
    } else {
        [self scrollToDocumentPageViewWithAnimate:YES];
    }
}

#pragma mark PLVLSDocumentPagesViewDelegate

- (void)documentPagesViewDidBackAction:(PLVLSDocumentPagesView *)documentPagesView {
    [self scrollToDocumentListViewWithAnimate:YES];
}

- (void)documentPagesView:(PLVLSDocumentPagesView *)documentPagesView didSelectItemAtIndex:(NSInteger)index {
    _isChangeDocument = NO; // 只是切换文档页面
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentSheet:didSelectAutoId:pageIndex:)]) {
        [self.delegate documentSheet:self didSelectAutoId:self.selectAutoId pageIndex:index];
    }
}

#pragma mark UIDocumentPicker Delegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (![self judgeFileType:url]) {
        [PLVLSUtils showAlertWithMessage:@"不支持的文档格式" cancelActionTitle:@"确定" cancelActionBlock:nil];
        return;
    }
    
    if (![self judgeFileByte:url]) {
        [PLVLSUtils showAlertWithMessage:@"上传文档不得超过500M" cancelActionTitle:@"确定" cancelActionBlock:nil];
        return;
    }
    
    if ([self fileIsPPT:url] && [PLVDocumentUploadClient sharedClient].pptAnimationEnabled) {
        NSString *message = @"请选择PPT转码方式\n快速转码：不含PPT动效，速度较快\n动画转码：含PPT动效，速度较慢，仅支持Microsoft Ofiice 保存的PPT";
        [PLVLSUtils showAlertWithMessage:message cancelActionTitle:@"快速转码" cancelActionBlock:^{
            [[PLVDocumentUploadClient sharedClient] uploadDocumentWithFileURL:url convertType:@"common"];
        } confirmActionTitle:@"动画转码" confirmActionBlock:^{
            [[PLVDocumentUploadClient sharedClient] uploadDocumentWithFileURL:url convertType:@"animate"];
        }];
    } else {
        [[PLVDocumentUploadClient sharedClient] uploadDocumentWithFileURL:url convertType:@"common"];
    }
}

#pragma mark PLVSDocumentUploadError Delegate

- (void)uploadError:(NSError *)error {
    if (PLVFErrorModulCode(error.code) == PLVFErrorCodeModulUpload) {
        if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentCopyError) {
            // 拷贝文档到沙盒失败
            [PLVLSUtils showToastInHomeVCWithMessage:@"读取文档失败"];
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentUploadingExist) {
            // 文档上传任务已存在
            [PLVLSUtils showToastInHomeVCWithMessage:@"已存在相同上传任务"];
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentUploadedExist) {
            // 文档已存在服务端
            [PLVLSUtils showToastInHomeVCWithMessage:@"文档已存在服务端"];
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentOSSTaskError) {
            // 阿里 OSS 上传失败
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentOSSTokenRefreshError) {
            // 刷新 OSS STS token 失败
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeGetToken_ParameterError ||
                   PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeGetToken_CodeError ||
                   PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeGetToken_DataError) {
            // 获取文档上传 token 失败
            [PLVLSUtils showToastInHomeVCWithMessage:@"上传文档失败"];
        }
    }
}
@end
