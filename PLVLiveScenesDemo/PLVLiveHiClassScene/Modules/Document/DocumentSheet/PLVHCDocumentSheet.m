//
//  PLVHCDocumentSheet.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDocumentSheet.h"

/// 工具
#import "PLVHCUtils.h"

/// UI
#import "PLVHCDocumentListView.h"
#import "PLVHCDocumentUploadTipsView.h"

/// 模块
#import "PLVDocumentConvertManager.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCDocumentSheet ()<
PLVHCDocumentListViewDelegate,
PLVDocumentUploadErrorDelegate,
UIDocumentPickerDelegate
>

#pragma mark UI
/// view hierarchy
///
/// (PLVHCDocumentSheet) self
///    ├─ (PLVHCDocumentListView) docListView
///

@property (nonatomic, strong) PLVHCDocumentListView *docListView;   // 文档列表视图

#pragma mark  数据
@property (nonatomic, assign) BOOL firstClick; // 登录后是否首次点击进入【文档列表】，NO 为 首次

@end

@implementation PLVHCDocumentSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#22273D"];
        self.layer.cornerRadius = 16;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.docListView];
        
        [PLVDocumentUploadClient sharedClient].errorDelegate = self;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.docListView.frame = self.bounds;
    
    if (!self.firstClick) {
        self.firstClick = YES;
        
        if ([[PLVDocumentUploadClient sharedClient].uploadingArray count] > 0) {
            [PLVHCUtils showAlertWithMessage:@"存在上传中断的任务，是否恢复？" cancelActionTitle:@"恢复上传" cancelActionBlock:^{
                [[PLVDocumentUploadClient sharedClient] continueAllUpload];
            } confirmActionTitle:@"删除" confirmActionBlock:^{
                [[PLVDocumentUploadClient sharedClient] clearAllUpload];
            }];
        }
    }
    
}
#pragma mark - [ Public Methods ]

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    
    [[PLVDocumentConvertManager sharedManager] polling:YES];
    [self.docListView refreshListView];
    [parentView addSubview:self];
}

- (void)dismiss {
    [[PLVDocumentConvertManager sharedManager] polling:NO];
    [self.docListView dismissDeleteView];
    [self removeFromSuperview];
}

#pragma mark - [ Private Methods ]
#pragma mark Getter

- (PLVHCDocumentListView *)docListView {
    if (! _docListView) {
        _docListView = [[PLVHCDocumentListView alloc] init];
        _docListView.delegate = self;
    }
    
    return _docListView;
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
    if (!fileExtension ||
        fileExtension.length == 0) {
        return NO;
    }
    return ([fileExtension isEqualToString:@"ppt"] || [fileExtension isEqualToString:@"pptx"]);
}

/// 判断选中文档的格式是否符合要求
- (BOOL)judgeFileType:(NSURL *)url {
    NSString *fileExtension = url.pathExtension;
    if (!fileExtension ||
        fileExtension.length == 0) {
        return NO;
    }
    
    NSSet<NSString *> *supperFileExtensions = [[NSSet alloc] initWithObjects:@"pdf", @"jpg", @"jpeg", @"png", @"doc", @"docx", @"ppt", @"pptx", @"xls", @"xlsx", nil];
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
#pragma mark PLVHCDocumentListViewDelegate

- (void)documentListViewUploadDocument:(PLVHCDocumentListView *)documentListView {
    if ([[PLVDocumentUploadClient sharedClient].uploadingArray count] >= 3) {
        [PLVHCUtils showToastInWindowWithMessage:@"最多同时上传3个文件，请稍后重试"];
    } else {
        UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:[self documentTypes] inMode:UIDocumentPickerModeImport];
        documentPicker.delegate = self;
        UIViewController *currentViewController = [PLVFdUtil getCurrentViewController];
        documentPicker.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [currentViewController presentViewController:documentPicker animated:YES completion:nil];
    }
}

- (void)documentListViewShowTip:(PLVHCDocumentListView *)documentListView {
    PLVHCDocumentUploadTipsView *tipsView = [[PLVHCDocumentUploadTipsView alloc] init];
    [tipsView showInView:self.superview];
}

- (void)documentListView:(PLVHCDocumentListView *)documentListView didSelectItemModel:(PLVDocumentModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentSheet:didSelectAutoId:)]) {
        BOOL allow = [self.delegate documentSheet:self didSelectAutoId:model.autoId];
        if (!allow) {
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_DocumentCountOver message:@"只支持同时打开5个文件"];
        }
    }
}

#pragma mark PLVDocumentUploadErrorDelegate

- (void)uploadError:(NSError *)error {
    if (PLVFErrorModulCode(error.code) == PLVFErrorCodeModulUpload) {
        if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentCopyError) {
            // 拷贝文档到沙盒失败
            [PLVHCUtils showToastInWindowWithMessage:@"读取文档失败"];
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentUploadingExist) {
            // 文档上传任务已存在
            [PLVHCUtils showToastInWindowWithMessage:@"已存在相同上传任务"];
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentUploadedExist) {
            // 文档已存在服务端
            [PLVHCUtils showToastInWindowWithMessage:@"文档已存在服务端"];
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentOSSTaskError) {
            // 阿里 OSS 上传失败
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeDocumentOSSTokenRefreshError) {
            // 刷新 OSS STS token 失败
        } else if (PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeGetToken_ParameterError ||
                   PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeGetToken_CodeError ||
                   PLVFErrorDetailCode(error.code) == PLVFUploadErrorCodeGetToken_DataError) {
            // 获取文档上传 token 失败
            [PLVHCUtils showToastInWindowWithMessage:@"上传文档失败"];
        }
    }
}

#pragma mark UIDocumentPicker Delegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (![self judgeFileType:url]) {
        [PLVHCUtils showAlertWithMessage:@"不支持的文档格式" cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:nil];
        return;
    }
    
    if (![self judgeFileByte:url]) {
        [PLVHCUtils showAlertWithMessage:@"上传文档不得超过500M" cancelActionTitle:nil cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:nil];
        return;
    }
    
    if ([self fileIsPPT:url] &&
        [PLVDocumentUploadClient sharedClient].pptAnimationEnabled) {
        NSString *message = @"快速转码：不含PPT动效，速度\n较快动画转码：含PPT动效，\n速度较慢，仅支持Microsoft\n Ofiice 保存的PPT";
        [PLVHCUtils showAlertWithTitle:@"选择 PPT 转码方式" message:message cancelActionTitle:@"快速转码" cancelActionBlock:^{
            [[PLVDocumentUploadClient sharedClient] uploadDocumentWithFileURL:url convertType:@"common"];
        } confirmActionTitle:@"动画转码" confirmActionBlock:^{
            [[PLVDocumentUploadClient sharedClient] uploadDocumentWithFileURL:url convertType:@"animate"];
        }];
    } else {
        [[PLVDocumentUploadClient sharedClient] uploadDocumentWithFileURL:url convertType:@"common"];
    }
}



@end
