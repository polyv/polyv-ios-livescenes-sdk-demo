//
//  PLVDocumentContainerView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVDocumentContainerView.h"

// 模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <WebKit/WebKit.h>

static NSString *kPPTUrlString = @"https://player.polyv.net/resp/white-board-sdk/latest/web-view/small-class-mobile.html";
@interface PLVDocumentContainerView()<
WKNavigationDelegate,
PLVContainerWebViewBridgeDelegate,
PLVSocketManagerProtocol
>

@property (nonatomic, strong) WKWebView *webView; // 文档容器功能模块视图

/// 模块
@property (nonatomic, strong) PLVContainerWebViewBridge *jsBridge; // 文档容器功能模块js交互

@end

@implementation PLVDocumentContainerView {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.webView];
        // 需要注册js -> native 方法后,才成功建立与js的桥接
        [self.jsBridge registerSendSocketData];
        [self.jsBridge registerStartEditText];
        [self.jsBridge registerToggleOperationStatus];
        
        if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) { // 讲师专属
            [self.jsBridge registerRefreshMinimizeContainerData];
            [self.jsBridge registerRefreshPptContainerTotal];
            [self.jsBridge registerZoomPercenChange];
        } else { // 学生专属
            [self.jsBridge registerChangeApplianceType];
            [self.jsBridge registerChangeStrokeHexColor];
        }
        
        // 注册socket监听
        socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.webView.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (void)loadRequestWitParamString:(NSString *)paramString {
    NSString *urlString = kPPTUrlString;
    BOOL hasParam = NO;
    if ([PLVFdUtil checkStringUseable:paramString]) {
        hasParam = YES;
        urlString = [NSString stringWithFormat:@"%@?%@", urlString, paramString];
    }
    
    NSString *chatApiDomain = [PLVLiveVideoConfig sharedInstance].chatApiDomain;
    if ([PLVFdUtil checkStringUseable:chatApiDomain]) {
        urlString = [urlString stringByAppendingFormat:@"%@domainName=%@", (hasParam ? @"&" : @"?"), chatApiDomain];
    }
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [self.webView loadRequest:request];
}

#pragma mark native -> js

- (void)changeApplianceType:(PLVContainerApplianceType)type {
    [self.jsBridge changeApplianceType:type];
}

- (void)changeFontSize:(NSUInteger)fontSize {
    [self.jsBridge changeFontSize:fontSize];
}

- (void)changeLineWidth:(NSUInteger)width {
    [self.jsBridge changeLineWidth:width];
}

- (void)changeStrokeWithHexColor:(NSString *)hexColor {
    [self.jsBridge changeStrokeHexColor:hexColor];
}

- (void)closePptWithAutoId:(NSUInteger)autoId {
    [self.jsBridge closePptWithAutoId:autoId];
}

- (void)doClear {
    [self.jsBridge doClear];
}

- (void)doRedo {
    [self.jsBridge doRedo];
}

- (void)doUndo {
    [self.jsBridge doUndo];
}

- (void)doDelete {
    [self.jsBridge doDelete];
}

- (void)openPptWithAutoId:(NSUInteger)autoId {
    [self.jsBridge openPptWithAutoId:autoId];
}

- (void)operateContainerWithContainerId:(NSString *)containerId close:(BOOL)close {
    [self.jsBridge operateContainerWithContainerId:containerId close:close];
}

- (void)finishEditText:(NSString *)text {
    [self.jsBridge finishEditText:text];
}

- (void)cancelEditText {
    [self.jsBridge cancelEditText];
}

- (void)givePaintBrushAuth {
    __weak typeof(self) weakSelf = self;
    [self.jsBridge givePaintBrushAuth:^(id _Nonnull responseData) {
        [weakSelf notifyListenerDidRefreshBrushPermission:YES userId:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    }];
}

- (void)removePaintBrushAuth{
    __weak typeof(self) weakSelf = self;
    [self.jsBridge removePaintBrushAuth:^(id _Nonnull responseData) {
        [weakSelf notifyListenerDidRefreshBrushPermission:NO userId:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    }];
}

#pragma mark 画笔权限授权、取消授权

#pragma mark 画笔权限业务流程：讲师发送socket设置画笔权限 -> socket 回调 -> 判断是否为自己 -> 自己调用js方法设置画笔权限

- (void)setPaintBrushAuthWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    
    [self.jsBridge setPaintBrushAuthWithUserId:userId sessionId:[PLVRoomDataManager sharedManager].roomData.sessionId];
}

- (void)removePaintBrushAuthWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    
    [self.jsBridge removePaintBrushAuthWithUserId:userId];
}

- (void)resetZoom {
    [self.jsBridge resetZoom];
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *config = [WKWebViewConfiguration new];
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        _webView.contentMode = UIViewContentModeRedraw;
        _webView.opaque = NO;
        _webView.navigationDelegate = self;
        _webView.scrollView.bounces = NO;
        if(@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _webView;
}

- (PLVContainerWebViewBridge *)jsBridge {
    if (!_jsBridge) {
        _jsBridge = [[PLVContainerWebViewBridge alloc] initBridgeWithWebview:self.webView webviewDelegate:self];
        _jsBridge.delegate = self;
    }
    return _jsBridge;
}

#pragma mark 处理socket回调

- (void)handleSocket_TEACHER_SET_PERMISSION:(NSDictionary *)jsonDict{
    NSString * type = PLV_SafeStringForDictKey(jsonDict, @"type");;
    NSString * userId = PLV_SafeStringForDictKey(jsonDict, @"userId");
    NSString * status = [NSString stringWithFormat:@"%@", PLV_SafeStringForDictKey(jsonDict, @"status")];
    NSString *viewId  = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
   
    if ([PLVFdUtil checkStringUseable:type] &&
        [type isEqualToString:@"paint"]) { // 画笔权限
        
        if ([PLVFdUtil checkStringUseable:userId] &&
            [PLVFdUtil checkStringUseable:viewId] &&
            [viewId isEqualToString:userId]) { // 自己的画笔权限，需要发送JS事件后回调状态
            
            if ([status isEqualToString:@"1"]) { // 被授予画笔权限
                [self givePaintBrushAuth];
            }else if ([status isEqualToString:@"0"]){ // 被移除画笔权限
                [self removePaintBrushAuth];
            }
            
        } else { // 其他人的画笔权限，直接回调状态
            [self notifyListenerDidRefreshBrushPermission:[status isEqualToString:@"1"] ? YES : NO userId:userId];
        }
        
    }
}

#pragma mark  Listener

- (void)notifyListenerDidFinishLoading {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerViewDidFinishLoading:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerViewDidFinishLoading:self];
        })
    }
}

- (void)notifyListenerDidLoadFailWithError:(NSError *)error {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:didLoadFailWithError:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self didLoadFailWithError:error];
        })
    }
}

- (void)notifyListenerDidRefreshMinimizeContainerDataWithJsonObject:(id)jsonObject {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:didRefreshMinimizeContainerDataWithJsonObject:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self didRefreshMinimizeContainerDataWithJsonObject:jsonObject];
        })
    }
}

- (void)notifyListenerDidRefreshPptContainerTotalWithJsonObject:(id)jsonObject {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:didRefreshPptContainerTotalWithJsonObject:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self didRefreshPptContainerTotalWithJsonObject:jsonObject];
        })
    }
}

- (void)notifyListenerDidRefreshBrushToolStatusWithJsonObject:(id)jsonObject {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:didRefreshBrushToolStatusWithJsonObject:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self didRefreshBrushToolStatusWithJsonObject:jsonObject];
        })
    }
}

- (void)notifyListenerWillStartEditTextWithJsonObject:(id)jsonObject {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:willStartEditTextWithJsonObject:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self willStartEditTextWithJsonObject:jsonObject];
        })
    }
}

- (void)notifyListenerDidRefreshBrushPermission:(BOOL)permission userId:(NSString *)userId {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:didRefreshBrushPermission:userId:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self didRefreshBrushPermission:permission userId:userId];
        })
    }
}

- (void)notifyListenerDidChangeApplianceType:(PLVContainerApplianceType)applianceType{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:didChangeApplianceType:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self didChangeApplianceType:applianceType];
        })
    }
}

- (void)notifyListenerDidChangeStrokeHexColor:(NSString *)strokeHexColor{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:didChangeStrokeHexColor:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self didChangeStrokeHexColor:strokeHexColor];
        })
    }
}

- (void)notifyListenerDidChangeZoomPercent:(CGFloat)zoomPercent{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentContainerView:didChangeZoomPercent:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentContainerView:self didChangeZoomPercent:zoomPercent];
        })
    }
}

#pragma mark - [ Delegate ]

#pragma mark WKNavigation Delegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    webView.backgroundColor = [UIColor clearColor];
    [self notifyListenerDidFinishLoading];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSError *myError = [[PLVWErrorManager sharedManager] errorWithModul:PLVFErrorCodeModulPPT
                                                                   code:PLVFPPTErrorCodeWebLoadFail];
    [[PLVWLogReporterManager sharedManager] reportWithErrorCode:myError.code information:error.description];
    
    [self notifyListenerDidLoadFailWithError:error];
}

#pragma mark PLVContainerWebViewBridgeDelegate

- (void)containerWebViewBridge:(PLVContainerWebViewBridge *)containerWebViewBridge didSendSocketEventWithJsonObject:(id)jsonObject {
    if (jsonObject) {
        NSDictionary *tempDict = nil;
        if ([jsonObject isKindOfClass:[NSString class]]) {
            NSData *data = [jsonObject dataUsingEncoding:NSUTF8StringEncoding];
            tempDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        } else if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            tempDict = (NSDictionary *)jsonObject;
        }
        
        if (tempDict &&
            [tempDict isKindOfClass:[NSDictionary class]]) {
            NSString *socketDataString = PLV_SafeStringForDictKey(tempDict, @"socketData");
            if ([PLVFdUtil checkStringUseable:socketDataString]) {
                NSData *data = [socketDataString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *socketDataDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if (socketDataDict) {
                    [[PLVSocketManager sharedManager] emitMessage:socketDataDict];
                }
            }
        }
    }
}

- (void)containerWebViewBridge:(PLVContainerWebViewBridge *)containerWebViewBridge  didRefreshMinimizeContainerDataWithJsonObject:(id)jsonObject {
    [self notifyListenerDidRefreshMinimizeContainerDataWithJsonObject:jsonObject];
}

- (void)containerWebViewBridge:(PLVContainerWebViewBridge *)containerWebViewBridge  didRefreshPptContainerTotalWithJsonObject:(id)jsonObject {
    [self notifyListenerDidRefreshPptContainerTotalWithJsonObject:jsonObject];
}

- (void)containerWebViewBridge:(PLVContainerWebViewBridge *)containerWebViewBridge didRefreshBrushToolStatusWithJsonObject:(id)jsonObject {
    [self notifyListenerDidRefreshBrushToolStatusWithJsonObject:jsonObject];
}

- (void)containerWebViewBridge:(PLVContainerWebViewBridge *)containerWebViewBridge willStartEditTextWithJsonObject:(id)jsonObject {
    [self notifyListenerWillStartEditTextWithJsonObject:jsonObject];
}

- (void)containerWebViewBridge:(PLVContainerWebViewBridge *)containerWebViewBridge didChangeApplianceType:(PLVContainerApplianceType)applianceType {
    [self notifyListenerDidChangeApplianceType:applianceType];
}

- (void)containerWebViewBridge:(PLVContainerWebViewBridge *)containerWebViewBridge didChangeStrokeHexColor:(NSString *)strokeHexColor {
    [self notifyListenerDidChangeStrokeHexColor:strokeHexColor];
}

- (void)containerWebViewBridge:(PLVContainerWebViewBridge *)containerWebViewBridge didChangeZoomPercent:(CGFloat)percent {
    [self notifyListenerDidChangeZoomPercent:percent];
}

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    // webview 关心的事件需要转发给webview
    if ([subEvent isEqualToString:@"onSliceID"] ||
        [subEvent isEqualToString:@"onSliceDraw"] ||
        [subEvent isEqualToString:@"onSliceOpen"] ||
        [subEvent isEqualToString:@"onSliceClose"] ||
        [subEvent isEqualToString:@"onSliceControl"]) {
        [self.jsBridge joinSocketData:jsonString];
    }
    // 讲师给学生授予画笔权限
    if ([subEvent isEqualToString:@"TEACHER_SET_PERMISSION"]) {
        [self handleSocket_TEACHER_SET_PERMISSION:jsonDict];
    }
}

@end
