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
@property (nonatomic, strong) UIView *contentBackgroundView;   // 内容背景视图 负责承载PPT 功能模块视图 和 连麦视图
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
@property (nonatomic, assign) NSInteger lastAutoId;                 // 直播中断前的文档autoId
@property (nonatomic, assign) NSInteger lastPageId;                 // 直播中断前的文档pageId
@property (nonatomic, assign) BOOL isMainSpeaker;                 // 本地用户是否是主讲人

@end

@implementation PLVLSDocumentAreaView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = PLV_UIColorFromRGB(@"#313540");
        self.layer.cornerRadius = 8;
        self.clipsToBounds = YES;
        
        [self addSubview:self.contentBackgroundView];
        [self displayExternalView:self.pptView];
        [self addSubview:self.docPlaceholder];
        [self addSubview:self.waitLivePlaceholderView];
        [self addSubview:self.brushView];
        [self addSubview:self.toolView];
        [self addSubview:self.pageNum];
        
        [self startLoading];
        
        if (self.viewerType == PLVRoomUserTypeGuest) {
            self.toolView.hidden = YES;
            [self showWaitLivePlaceholderView:YES];
            [self.toolView showBtnBrush:NO];
            [self.toolView showBtnAddPage:NO];
            [self.toolView showBtnNexth:NO];
            [self.toolView showBtnPrevious:NO];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentBackgroundView.frame = self.bounds;
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
    CGFloat brushHeight = 32;
    self.brushView.frame = CGRectMake(bgSize.width - brushWidth - rightPad,
                                      bgSize.height - brushHeight - bottomPad,
                                      brushWidth, brushHeight);
    
    CGFloat toolViewWidth = 32;
    CGFloat toolViewHeight = bgSize.height - CGRectGetMaxY(self.pageNum.frame) - 12 - bottomPad;
    self.toolView.frame = CGRectMake(bgSize.width - toolViewWidth - rightPad,
                                         CGRectGetMaxY(self.pageNum.frame) + 12,
                                         toolViewWidth, toolViewHeight);
    
    if (self.viewLoading && self.viewLoading.isAnimating) {
        self.viewLoading.center = CGPointMake(bgSize.width / 2.0, bgSize.height / 2.0);
    }
    if (_docSheet) {
        CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.75;
        [_docSheet refreshWithSheetHeight:sheetHeight];
    }
}

#pragma mark - Getter

- (UIView *)contentBackgroundView {
    if (!_contentBackgroundView) {
        _contentBackgroundView = [[UIView alloc] init];
    }
    return _contentBackgroundView;
}

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

- (void)dismissDocument {
    [self.docSheet dismiss];
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
        [self showWaitLivePlaceholderView:NO];
        [self.pageNum setCurrentPage:self.pptView.currPageNum + 1 totalPage:self.pptView.totalPageNum];
    }
}

- (void)finishClass {
    self.pptView.startClass = NO;
    
    if (self.viewerType == PLVRoomUserTypeGuest) {
        self.toolView.hidden = YES;
        [self.toolView setFullScreenButtonSelected:NO];
        [self.pageNum setCurrentPage:0 totalPage:0];
        [self showWaitLivePlaceholderView:YES];
        [self documentView_changePPTPositionToMain:YES];
    }
}

- (void)updateDocumentSpeakerAuth:(BOOL)auth {
    _isMainSpeaker = auth;
    [self.toolView showBtnNexth:auth];
    [self.toolView showBtnPrevious:auth];
    if (auth) {
        [self documentView_changePPTPositionToMain:self.pptView.mainSpeakerPPTOnMain];
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

- (void)synchronizeDocumentData {
    [self.docSheet setDocumentWithAutoId:self.lastAutoId pageId:self.lastPageId];
}

- (void)documentToolViewShow:(BOOL)show {
    self.toolView.hidden = show;
}

- (void)displayExternalView:(UIView *)externalView {
    if (externalView && [externalView isKindOfClass:UIView.class]) {
        [self updateControlsWithExternalView:externalView];
        [self removeSubview:self.contentBackgroundView];
        externalView.frame = self.contentBackgroundView.bounds;
        externalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentBackgroundView insertSubview:externalView atIndex:0];
    }else{
        NSLog(@"PLVLSDocumentAreaView - displayExternalView failed, externalView:%@",externalView);
    }
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

- (void)updateControlsWithExternalView:(UIView *)externalView {
    if ([externalView isKindOfClass:PLVDocumentView.class]) {
        self.pageNum.alpha = 1;
        if ([self canManageDocuments]) {
            // 有管理文档的权限
            [self.toolView showBtnNexth:YES];
            [self.toolView showBtnPrevious:YES];
        }
        if (self.viewerType == PLVRoomUserTypeTeacher) {
            // 嘉宾暂无画笔权限
            [self.toolView showBtnAddPage:YES];
            [self.toolView showBtnBrush:YES];
        }
    } else {
        self.brushView.hidden = YES;
        self.pageNum.alpha = 0;
        [self.toolView showBtnNexth:NO];
        [self.toolView showBtnPrevious:NO];
        [self.toolView showBtnBrush:NO];
        [self.toolView showBtnAddPage:NO];
        [self.toolView setBrushSelected:NO];
        [self.pptView setPaintStatus:NO];
    }
}

- (BOOL)canManageDocuments {
    if (self.viewerType == PLVRoomUserTypeTeacher || (self.viewerType == PLVRoomUserTypeGuest && self.isMainSpeaker)) {
        return YES;
    }
    
    return NO;
}

- (void)removeSubview:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

#pragma mark Callback

- (void)callbackForChangePPTPositionToMain:(BOOL)pptToMain syncRemoteUser:(BOOL)needSync {
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentAreaView:pptView:changePPTPositionToMain:syncRemoteUser:)]) {
        [self.delegate documentAreaView:self pptView:self.pptView changePPTPositionToMain:pptToMain syncRemoteUser:needSync];
    }
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

- (void)documentView_changePPTPositionToMain:(BOOL)pptToMain {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.toolView setChangeButtonSelected:!pptToMain];
        [self callbackForChangePPTPositionToMain:pptToMain syncRemoteUser:NO];
    });
}

- (void)documentView_inputWithText:(NSString *)inputText textColor:(NSString *)textColor {
    [self.inputView presentWithText:inputText textColor:textColor inViewController:[PLVLSUtils sharedUtils].homeVC];
}

- (void)documentView_changeWithAutoId:(NSUInteger)autoId imageUrls:(NSArray *)imageUrls fileName:(NSString *)fileName {
    if ([PLVFdUtil checkStringUseable:fileName]) {
        /// 续播时需要直接显示文档详情
        [self.docSheet showInView:self.superview];
        [self.docSheet setDocumentImageUrls:imageUrls autoId:autoId pagesTitle:fileName];
    } else {
        [self.docSheet setDocumentImageUrls:imageUrls autoId:autoId];
    }
}

- (void)documentView_pageStatusChangeWithAutoId:(NSUInteger)autoId
                                pageNumber:(NSUInteger)pageNumber
                                 totalPage:(NSUInteger)totalPage
                                   pptStep:(NSUInteger)step {
    if (autoId == 0) {
        self.currWhiteboardNum = pageNumber;
    }
    
    if (self.viewerType == PLVRoomUserTypeGuest && !self.pptView.startClass) { // 嘉宾身份时，当前没有开始上课，则不要显示页码
        [self.pageNum setCurrentPage:0 totalPage:0];
    } else {
        [self.pageNum setCurrentPage:pageNumber + 1 totalPage:totalPage];
    }
    
    [self.toolView setPageNum:pageNumber + 1 totalNum:totalPage];
    [self.docSheet selectDocumentWithAutoId:autoId pageIndex:pageNumber];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaView:didShowWhiteboardOrDocument:)]) {
        [self.delegate documentAreaView:self didShowWhiteboardOrDocument:!autoId];
    }
}

- (void)documentView_continueClassWithAutoId:(NSUInteger)autoId pageNumber:(NSUInteger)pageNumber {
    self.lastAutoId = autoId;
    self.lastPageId = pageNumber;
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

- (void)controlToolsView:(PLVLSDocumentToolView *)controlToolsView changePPTPositionToMain:(BOOL)pptToMain {
    [self callbackForChangePPTPositionToMain:pptToMain syncRemoteUser:YES];
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
