//
//  PLVLSDocumentAreaView.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//  

#import "PLVLSDocumentAreaView.h"

/// 工具类
#import "PLVLSUtils.h"

/// 模块
#import "PLVRoomDataManager.h"

/// UI
#import "PLVDocumentView.h"
#import "PLVLSDocumentNumView.h"
#import "PLVLSDocumentToolView.h"
#import "PLVLSDocumentBrushView.h"
#import "PLVLSDocumentInputView.h"
#import "PLVLSDocumentSheet.h"
#import "PLVLSDocumentWaitLiveView.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSDocumentAreaView ()<
PLVDocumentViewDelegate,
PLVLSDocumentToolViewDelegate,
PLVLSDocumentBrushViewDelegate,
PLVLSDocumentSheetDelegate,
UIGestureRecognizerDelegate
>

/// UI
@property (nonatomic, strong) UIActivityIndicatorView *viewLoading; // webView加载
@property (nonatomic, strong) PLVDocumentView *pptView;             // PPT 功能模块视图
@property (nonatomic, strong) PLVLSDocumentNumView *pageNum;        // 页码
@property (nonatomic, strong) PLVLSDocumentToolView *toolView;      // 控制条视图
@property (nonatomic, strong) PLVLSDocumentBrushView *brushView;    // 画笔条视图
@property (nonatomic, strong) PLVLSDocumentInputView *inputView;    // 文字输入视图
@property (nonatomic, strong) UIImageView *docPlaceholder;          // 文档缺省图
@property (nonatomic, strong) PLVLSDocumentWaitLiveView *waitLivePlaceholderView; // ‘直播未开始’占位视图 适用于‘非讲师角色’
@property (nonatomic, strong) PLVLSDocumentSheet *docSheet;         // 文档弹出层

/// 数据
@property (nonatomic, assign) NSInteger currWhiteboardNum;          // 白板当前页码
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;


@end

@implementation PLVLSDocumentAreaView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = PLV_UIColorFromRGB(@"#313540");
        self.layer.cornerRadius = 8;
        self.clipsToBounds = YES;
        
        [self addSubview:self.pptView];
        [self addSubview:self.docPlaceholder];
        [self addSubview:self.waitLivePlaceholderView];
        [self addSubview:self.brushView];
        [self addSubview:self.toolView];
        [self addSubview:self.pageNum];
        
        [self startLoading];
        
        if (self.viewerType == PLVRoomUserTypeGuest) {
            [self showWaitLivePlaceholderView:YES];
            [self.toolView showBtnBrush:NO];
            [self.toolView showBtnAddPage:NO];
            [self.toolView showBtnNexth:NO];
            [self.toolView showBtnPrevious:NO];
            self.pageNum.guestFinishClass = YES;
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.pptView.frame = self.bounds;
    self.docPlaceholder.frame = self.bounds;
    self.waitLivePlaceholderView.frame = self.bounds;
    
    CGSize bgSize = self.bounds.size;
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width == self.bounds.size.width;
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11, *)) {
        if (fullScreen) {
            safeAreaInsets = self.safeAreaInsets;
        }
    }
    
    CGFloat topPad = fullScreen ? 16 + safeAreaInsets.top : 8;
    CGFloat bottomPad = fullScreen ? 16 + safeAreaInsets.bottom : 8;
    CGFloat leftPad = fullScreen ? 16 + safeAreaInsets.left : 8;
    CGFloat rightPad = fullScreen ? 16 + safeAreaInsets.right : 8;
    
    CGFloat numLabelWidth = 120;
    CGFloat numLabelHeight = 24;
    self.pageNum.frame = CGRectMake(bgSize.width - rightPad - numLabelWidth, topPad, numLabelWidth, numLabelHeight);
    
    CGFloat maxBrushWidth = bgSize.width - leftPad - rightPad;
    CGFloat brushWidth = MIN(maxBrushWidth, 504);
    CGFloat brushHeight = 36;
    self.brushView.frame = CGRectMake(bgSize.width - brushWidth - rightPad,
                                      bgSize.height - brushHeight - bottomPad,
                                      brushWidth, brushHeight);
    
    CGFloat toolViewWidth = 36;
    CGFloat toolViewHeight = bgSize.height - CGRectGetMaxY(self.pageNum.frame) - 12 - bottomPad;
    self.toolView.frame = CGRectMake(bgSize.width - toolViewWidth - rightPad,
                                         CGRectGetMaxY(self.pageNum.frame) + 12,
                                         toolViewWidth, toolViewHeight);
    
    if (self.viewLoading && self.viewLoading.isAnimating) {
        self.viewLoading.center = CGPointMake(bgSize.width / 2.0, bgSize.height / 2.0);
    }
}

#pragma mark - Getter

- (PLVDocumentView *)pptView {
    if (! _pptView) {
        _pptView = [[PLVDocumentView alloc] initWithScene:PLVDocumentViewSceneStreamer];
        _pptView.delegate = self;
        // hasPageBtn = 0 参数表示不显示底部翻页按钮与页码
        // whiteBackColor=#313540 用于修改白板背景色
        [_pptView loadRequestWitParamString:@"version=1&hasPageBtn=0&whiteBackColor=#313540"];
    }
    return _pptView;
}

- (PLVLSDocumentToolView *)toolView {
    if (! _toolView) {
        _toolView = [[PLVLSDocumentToolView alloc] init];
        _toolView.delegate = self;
        _toolView.userInteractionEnabled = NO;
    }
    return _toolView;
}

- (PLVLSDocumentNumView *)pageNum {
    if (!_pageNum) {
        _pageNum = [[PLVLSDocumentNumView alloc] init];
    }
    return _pageNum;
}

- (PLVLSDocumentBrushView *)brushView {
    if (! _brushView) {
        _brushView = [[PLVLSDocumentBrushView alloc] init];
        _brushView.delegate = self;
        _brushView.hidden = YES;
    }
    return _brushView;
}

- (PLVLSDocumentInputView *)inputView {
    if (_inputView == nil) {
        _inputView = [[PLVLSDocumentInputView alloc] init];
        __weak typeof(self) weakSelf = self;
        _inputView.documentInputCompleteHandler = ^(NSString * _Nonnull inputText) {
            [weakSelf.pptView changeTextContent:inputText];
        };
    }
    return _inputView;
}

- (PLVLSDocumentSheet *)docSheet {
    if (! _docSheet) {
        _docSheet = [[PLVLSDocumentSheet alloc] init];
        _docSheet.delegate = self;
    }
    return _docSheet;
}

- (UIImageView *)docPlaceholder {
    if (! _docPlaceholder) {
        _docPlaceholder = [[UIImageView alloc] init];
        _docPlaceholder.backgroundColor = PLV_UIColorFromRGB(@"#313540");
        _docPlaceholder.image = [PLVLSUtils imageForDocumentResource:@"plvls_doc_empty"];
        _docPlaceholder.contentMode = UIViewContentModeScaleAspectFit;
        _docPlaceholder.hidden = YES;
    }
    return _docPlaceholder;
}

- (PLVLSDocumentWaitLiveView *)waitLivePlaceholderView{
    if (!_waitLivePlaceholderView) {
        _waitLivePlaceholderView = [[PLVLSDocumentWaitLiveView alloc] init];
        _waitLivePlaceholderView.hidden = YES;
    }
    return _waitLivePlaceholderView;
}

- (PLVRoomUserType)viewerType{
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
}

#pragma mark - Public Method

- (void)showWhiteboard {
    if (self.pptView.autoId == 0 && self.docPlaceholder.hidden) {
        return;
    }
    
    self.docPlaceholder.hidden = YES;
    
    [self.toolView setBrushStyle:YES];
    [self.pageNum setCurrentPage:self.currWhiteboardNum totalPage:self.currWhiteboardNum];
    [self.toolView setPageNum:self.currWhiteboardNum totalNum:self.currWhiteboardNum];
    [self.pptView changePPTWithAutoId:0 pageNumber:self.currWhiteboardNum];
}

- (void)showDocument {
    [self.toolView setBrushStyle:NO];
    
    if (self.pptView.autoId == 0) { // 白板切到文档时
        if (self.docSheet && self.docSheet.selectAutoId != 0) { // 之前选择过文档
            [self.pptView changePPTWithAutoId:self.docSheet.selectAutoId pageNumber:self.docSheet.selectPageId];
            return; // 此时不打开文档窗
        } else {                                                 // 未选择过文档
            // 关闭画笔
            self.brushView.hidden = YES;
            [self.toolView setBrushSelected:NO];
            if (self.delegate && [self.delegate respondsToSelector:@selector(documentAreaView:openBrush:)]) {
                [self.delegate documentAreaView:self openBrush:NO];
            }
            
            self.docPlaceholder.hidden = NO;
            [self.pageNum setCurrentPage:0 totalPage:0];
            [self.toolView setPageNum:0 totalNum:0];
        }
    }
    
    [self.docSheet showInView:self.superview];
}

- (void)showWaitLivePlaceholderView:(BOOL)show{
    self.waitLivePlaceholderView.hidden = !show;
}

- (void)startClass:(NSDictionary *)onSliceStartDict {
    self.pptView.startClass = YES;
    
    if ([PLVFdUtil checkDictionaryUseable:onSliceStartDict]) {
        [self.pptView setSliceStart:onSliceStartDict];
    }
    
    if (self.viewerType == PLVRoomUserTypeGuest) {
        self.toolView.hidden = NO;
        self.pageNum.guestFinishClass = NO;
        [self showWaitLivePlaceholderView:NO];
    }
}

- (void)finishClass {
    self.pptView.startClass = NO;
    
    if (self.viewerType == PLVRoomUserTypeGuest) {
        self.toolView.hidden = YES;
        [self.toolView setFullScreenButtonSelected:NO];
        self.pageNum.guestFinishClass = YES;
        [self showWaitLivePlaceholderView:YES];
    }
}

- (NSDictionary *)getCurrentDocumentInfoDict {
    NSInteger autoId = self.pptView.autoId;
    BOOL pptOpenned = !(autoId == 0); // 需根据ppt打开状态
    NSUInteger pageId = pptOpenned ? self.pptView.currPageNum : 0;
    NSUInteger step = pptOpenned ? self.pptView.pptStep : 0;
    
    NSMutableDictionary * jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"isNoCount"] = @(0);
    jsonDict[@"docType"] = @(1);
    jsonDict[@"version"] = @"2.0";
    jsonDict[@"data"] = @{@"autoId": @(autoId), @"pageId": @(pageId), @"isCamClosed": @(0), @"step":@(step)};
    return jsonDict;
}

#pragma mark - [ Private Methods ]

// 开启webview loading
- (void)startLoading {
    if (!_viewLoading) {
        _viewLoading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _viewLoading.color = [UIColor grayColor];
    }
    [self.viewLoading startAnimating];
    [self addSubview:self.viewLoading];
}

// 关闭webview loading
- (void)stopLoading {
    [self.viewLoading stopAnimating];
    [self.viewLoading removeFromSuperview];
    _viewLoading = nil;
}

#pragma mark - PLVStreamerPPTView Delegate

- (void)documentView_webViewDidFinishLoading {
    self.pptView.backgroundColor = [UIColor clearColor];
    
    [self stopLoading];
    self.toolView.userInteractionEnabled = YES;
}

- (void)documentView_webViewLoadFailWithError:(NSError *)error {
    [PLVLSUtils showToastInHomeVCWithMessage:@"PPT 加载失败"];
}

- (void)documentView_inputWithText:(NSString *)inputText textColor:(NSString *)textColor {
    [self.inputView presentWithText:inputText textColor:textColor inViewController:[PLVLSUtils sharedUtils].homeVC];
}

- (void)documentView_changeWithAutoId:(NSUInteger)autoId imageUrls:(NSArray *)imageUrls {
    [self.docSheet setDocumentImageUrls:imageUrls autoId:autoId];
}

- (void)documentView_pageStatusChangeWithAutoId:(NSUInteger)autoId
                                pageNumber:(NSUInteger)pageNumber
                                 totalPage:(NSUInteger)totalPage
                                   pptStep:(NSUInteger)step {
    if (autoId == 0) {
        self.currWhiteboardNum = pageNumber;
    }
    
    [self.pageNum setCurrentPage:pageNumber + 1 totalPage:totalPage];
    [self.toolView setPageNum:pageNumber + 1 totalNum:totalPage];
    [self.docSheet selectDocumentWithAutoId:autoId pageIndex:pageNumber];
}

#pragma mark - PLVSControlToolsView Delegate

- (BOOL)controlToolsView:(PLVLSDocumentToolView *)controlToolsView openBrush:(BOOL)isOpen {
    if (!self.docPlaceholder.hidden) {
        [PLVLSUtils showToastInHomeVCWithMessage:@"请选择文档后再使用画笔"];
        return NO;
    }
    
    self.brushView.hidden = !isOpen;
    [self.pptView setPaintStatus:isOpen];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentAreaView:openBrush:)]) {
        [self.delegate documentAreaView:self openBrush:isOpen];
    }
    
    return YES;
}

- (void)controlToolsViewDidAddPage:(PLVLSDocumentToolView *)controlToolsView {
    [self.pptView addWhiteboard];
    self.currWhiteboardNum = self.pptView.currPageNum;
}

- (void)controlToolsView:(PLVLSDocumentToolView *)controlToolsView changeFullScreen:(BOOL)isFullScreen {
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentAreaView:changeFullScreen:)]) {
        [self.delegate documentAreaView:self changeFullScreen:isFullScreen];
    }
}

- (void)controlToolsView:(PLVLSDocumentToolView *)controlToolsView turnNextPage:(BOOL)isNextPage {
    [self.pptView turnPage:isNextPage];
    if (self.pptView.autoId == 0) {
        self.currWhiteboardNum = self.pptView.currPageNum;
    }
}

#pragma mark - PLVSBrushView Delegate

- (void)brushView:(PLVLSDocumentBrushView *)brushView changeType:(PLVLSDocumentBrushViewType)type {
    if (type == PLVLSDocumentBrushViewTypeClearAll) { // 清屏
        __weak typeof(self) weakSelf = self;
        [PLVLSUtils showAlertWithMessage:@"清屏后画笔痕迹将无法恢复，确认清屏吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"清屏" confirmActionBlock:^{
            [weakSelf.pptView deleteAllPaint];
        }];
        return;
    }
    
    if (type == PLVLSDocumentBrushViewTypeClear) {
        [self.pptView toDelete]; // 设置为橡皮擦
    } else if (type == PLVLSDocumentBrushViewTypeText) {
        [self.pptView setDrawType:PLVWebViewBrushPenTypeText]; // 设置为文字
    } else if (type == PLVLSDocumentBrushViewTypeArrow) {
        [self.pptView setDrawType:PLVWebViewBrushPenTypeArrow]; // 设置为箭头
    } else if (type == PLVLSDocumentBrushViewTypeFreePen) {
        [self.pptView setDrawType:PLVWebViewBrushPenTypeFreePen];
    }
}

- (void)brushView:(PLVLSDocumentBrushView *)brushView changeColor:(NSString *)color {
    [self.pptView changeColor:color];
}

#pragma mark - PLVLSDocumentSheet Delegate

- (void)documentSheet:(PLVLSDocumentSheet *)documentSheet didSelectAutoId:(NSInteger)autoId pageIndex:(NSInteger)pageIndex {
    self.docPlaceholder.hidden = YES;
    
    [self.pptView changePPTWithAutoId:autoId pageNumber:pageIndex];
}

@end
