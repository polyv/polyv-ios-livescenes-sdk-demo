//
//  PLVDocumentView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/4/29.
//  Copyright © 2021 PLV. All rights reserved.
//  

#import "PLVDocumentView.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVSocketManager.h>

@interface PLVDocumentView ()<
WKNavigationDelegate,
PLVWebViewBridgeProtocol,
PLVSocketManagerProtocol
>

/// view hierarchy
///
/// (PLVStreamerPPTView) self
/// ├── (UIImageView) backgroudImageView (lowest)
/// └── (WKWebView) webView (top)
///
/// UI
@property (nonatomic, strong) UIImageView *backgroudImageView;      // pptView 背景视图
@property (nonatomic, assign) CGFloat bgImageViewWidthScale;        // 背景视图占总宽比例
@property (nonatomic, strong) WKWebView *webView;                   // PPT 功能模块视图

/// 模块
@property (nonatomic, strong) PLVWebViewBridge *jsBridge;           // PPT 功能模块js交互

/// 数据
@property (nonatomic, assign) BOOL webviewLoadFinish;               // webview 是否已加载完成
@property (nonatomic, assign) PLVDocumentViewScene scene;        // 当前所处场景类型
@property (nonatomic, strong) NSDictionary *userInfo;               // 登录用户信息
@property (nonatomic, assign) BOOL userInfoHadSeted;                // 已设置登录用户信息
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;

/// scene 为 PLVDocumentViewSceneCloudClass 或 PLVDocumentViewSceneEcommerce 的数据
@property (nonatomic, assign) BOOL mainSpeakerPPTOnMain;            // 观看场景中 主讲的PPT当前是否在主屏

/// scene 为 PLVDocumentViewSceneStreamer 的数据
@property (nonatomic, assign) NSInteger autoId;                     // ppt id, 0是白板
@property (nonatomic, assign) NSInteger currPageNum;                // 当前页码
@property (nonatomic, assign) NSInteger totalPageNum;               // 总页码
@property (nonatomic, assign) NSUInteger pptStep;                   // 当前文档所处于动画步数
@property (nonatomic, assign) BOOL isChangePPT;                     // 在文档间进行切换的标识

@end

@implementation PLVDocumentView

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithScene:PLVDocumentViewSceneCloudClass];
}

- (instancetype)initWithScene:(PLVDocumentViewScene)scene {
    if (self = [super init]) {
        self.scene = scene;
        
        [self addSubview:self.backgroudImageView];
        [self addSubview:self.webView];
        
        [[PLVSocketManager sharedManager] addDelegate:self
                                        delegateQueue:dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT)];
        
        if (self.scene == PLVDocumentViewSceneStreamer) {
            PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
            self.userInfo = @{@"nick":(roomUser.viewerName ?: @""),
                              @"pic":(roomUser.viewerAvatar ?: @""),
                              @"userId":(roomUser.viewerId ?: @"")};
            
            self.autoId = 0;
            self.currPageNum = 0;
            self.totalPageNum = 1;
            self.pptStep = 0;
            
            [self.jsBridge registerSocketEventFunction];
            [self.jsBridge registerPPTStatusChangeFunction];
            [self.jsBridge registerPPTInputFunction];
        } else if (self.scene == PLVDocumentViewSceneCloudClass ||
                   self.scene == PLVDocumentViewSceneEcommerce) {
            // 观看场景的 userInfo 需登录完 sockt 后获取
            
            self.mainSpeakerPPTOnMain = YES;
            
            [self.jsBridge registerPPTPrepareFunction];
            [self.jsBridge registerSocketEventFunction];
            [self.jsBridge registerVideoDurationFunction];
            [self.jsBridge registerChangePPTPositionFunction];
        }
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGSize backgroudImageSize = self.backgroudImageView.image.size;
    if (self.backgroudImageView.image &&
        backgroudImageSize.width > 0 &&
        backgroudImageSize.height > 0) {
        CGFloat backgroudImageViewWHScale = backgroudImageSize.width / backgroudImageSize.height;
        CGFloat backgroudImageViewWidth = self.bgImageViewWidthScale * backgroudImageSize.width;
        CGFloat backgroudImageViewHeight = backgroudImageViewWidth / backgroudImageViewWHScale;
        self.backgroudImageView.frame = CGRectMake((viewWidth - backgroudImageViewWidth) / 2.0,
                                                   (viewHeight - backgroudImageViewHeight) / 2.0,
                                                   backgroudImageViewWidth,
                                                   backgroudImageViewHeight);
    }
    
    self.webView.frame = self.bounds;
}

#pragma mark - Getter

- (UIImageView *)backgroudImageView {
    if (!_backgroudImageView) {
        _backgroudImageView = [[UIImageView alloc] init];
        _backgroudImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _backgroudImageView;
}

- (WKWebView *)webView {
    if (! _webView) {
        WKWebViewConfiguration *config = [WKWebViewConfiguration new];
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        _webView.contentMode = UIViewContentModeRedraw;
        _webView.opaque = NO;
        if(@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        /// 推流场景且嘉宾角色下，默认关闭webview该属性
        if (self.scene == PLVDocumentViewSceneStreamer &&
            self.viewerType == PLVRoomUserTypeGuest) {
            _webView.userInteractionEnabled = NO;
        }
    }
    
    return _webView;
}

- (PLVWebViewBridge *)jsBridge {
    if (!_jsBridge) {
        _jsBridge = [PLVWebViewBridge bridgeWithWebview:self.webView webviewDelegate:self];
        [_jsBridge setDelegate:self];
    }
    return _jsBridge;
}

- (PLVRoomUserType)viewerType{
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
}

#pragma mark - Public Method

- (void)setBackgroudImage:(UIImage *)image widthScale:(CGFloat)widthScale {
    self.bgImageViewWidthScale = MAX(0, MIN(1, widthScale));
    self.backgroudImageView.image = image;
    self.backgroudImageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
}

- (void)loadRequestWitParamString:(NSString *)paramString {
    NSString *urlString = PLVLiveConstantsDocumentPPTForMobileHTML;
    BOOL hasParam = NO;
    if ([PLVFdUtil checkStringUseable:paramString]) {
        hasParam = YES;
        urlString = [NSString stringWithFormat:@"%@?%@", urlString, paramString];
    }
    
    NSString *chatApiDomain = [PLVLiveVideoConfig sharedInstance].chatApiDomain;
    if ([PLVFdUtil checkStringUseable:chatApiDomain]) {
        urlString = [urlString stringByAppendingFormat:@"%@domainName=%@", (hasParam ? @"&" : @"?"), chatApiDomain];
    }
    
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [self.webView loadRequest:request];
}

#pragma mark 观看专用方法

- (void)setSEIDataWithNewTimestamp:(long)newTimeStamp {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce) {
        return;
    }
    [self.jsBridge setSEIData:newTimeStamp];
}

- (void)pptStart:(NSString *)vid {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce) {
        return;
    }
    [self.jsBridge pptStartWithVid:vid];
}

#pragma mark 推流专用方法

- (void)setPaintStatus:(BOOL)open {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    [self.jsBridge setPaintStatus:open];
}

- (void)setDrawType:(PLVWebViewBrushPenType)type {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    [self.jsBridge setDrawType:type];
}

- (void)changeTextContent:(NSString *)content {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    [self.jsBridge changeTextContent:content];
}

- (void)changeColor:(NSString *)hexString {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    [self.jsBridge changeColor:hexString];
}

- (void)toDelete {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    [self.jsBridge toDelete];
}

- (void)deleteAllPaint {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    [self.jsBridge deleteAllPaint];
}

- (void)setSliceStart:(NSDictionary *)jsonDict {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    [self.jsBridge setSliceStart:jsonDict];
}

- (void)changePPTWithAutoId:(NSUInteger)autoId pageNumber:(NSInteger)pageNumber {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    self.isChangePPT = self.autoId != autoId;
    
    self.autoId = autoId;
    self.currPageNum = pageNumber;
    
    [self switchPPT];
}

- (void)turnPage:(BOOL)isNextPage {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    if (isNextPage) {
        self.currPageNum += 1;
    } else {
        self.currPageNum -= 1;
    }
    [self switchPPT];
}

- (void)addWhiteboard {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    if (self.autoId != 0) { // 白板才能添加
        return;
    }
    
    self.totalPageNum += 1;
    self.currPageNum = self.totalPageNum - 1;
    [self switchPPT];
}

#pragma mark - Private Method

/// 当属性 autoId、currPageNum 发生变化时调用该方法
- (void)switchPPT {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    // 当 autoId 改变时，currPageNum 此处不起作用，需通过属性 isChangePPT 进行二次切换
    [self.jsBridge changePPTWithAutoId:self.autoId pageNumber:self.currPageNum];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_pageStatusChangeWithAutoId:pageNumber:totalPage:pptStep:)]) {
        [self.delegate documentView_pageStatusChangeWithAutoId:self.autoId
                                               pageNumber:self.currPageNum
                                                totalPage:self.totalPageNum
                                                  pptStep:self.pptStep];
    }
}

- (void)setUserInfo {
    if (!self.webviewLoadFinish ||
        ![PLVFdUtil checkDictionaryUseable:self.userInfo] ||
        self.userInfoHadSeted) {
        return;
    }
    
    self.userInfoHadSeted = YES;
    [self.jsBridge setUserInfo:self.userInfo];
}

#pragma mark - PLVSocketManager Protocol

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce &&
        self.viewerType == PLVRoomUserTypeTeacher) { // 推流场景且讲师角色，不需要用到以下消息监听
        return;
    }
    
    if ([subEvent isEqualToString:@"LOGIN"]){
        self.userInfo = jsonDict;
        [self setUserInfo];
    } else if ([subEvent isEqualToString:@"changeVideoAndPPTPosition"]){
        [self receiveChangePPTPositionMessageWithjsonObject:jsonDict];
    } else if ([subEvent isEqualToString:@"onSliceID"] ||
              [subEvent isEqualToString:@"onSliceOpen"] ||
              [subEvent isEqualToString:@"onSliceStart"] ||
              [subEvent isEqualToString:@"onSliceDraw"] ||
              [subEvent isEqualToString:@"onSliceControl"]) {
        [self receiveOnSliceMessageWithjson:jsonString jsonObject:jsonDict];
    }
}

- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([event isEqualToString:@"assistantSliceControl"]) {
        [self receiveAssistantSliceControltEventWithJsonObject:jsonDict];
    }
}

- (void)receiveChangePPTPositionMessageWithjsonObject:(NSDictionary *)jsonDict {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce) { // 目前推流场景不需要用到以下消息监听
        return;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentView_changePPTPositionToMain:)]) {
        BOOL wannaVideoOnMainSite = ((NSNumber *)jsonDict[@"status"]).boolValue;
        BOOL pptToMain = !wannaVideoOnMainSite;
        self.mainSpeakerPPTOnMain = pptToMain;
        [self.delegate documentView_changePPTPositionToMain:pptToMain];
    }
}

- (void)receiveOnSliceMessageWithjson:(NSString *)jsonString
                           jsonObject:(NSDictionary *)jsonDict {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce &&
        self.viewerType == PLVRoomUserTypeTeacher) { // 推流场景且讲师角色，不需要用到以下消息监听
        return;
    }
        
    if (self.scene == PLVDocumentViewSceneStreamer) {
        NSDictionary * dataDict = PLV_SafeDictionaryForDictKey(jsonDict, @"data");
        NSInteger autoId = PLV_SafeIntegerForDictKey(dataDict, @"autoId");
        NSInteger pageId = PLV_SafeIntegerForDictKey(dataDict, @"pageId");
        self.autoId = autoId;
        self.currPageNum = pageId;
        [self.jsBridge refreshPPTWithJsonObject:jsonDict delay:0];
    }else{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(documentView_getRefreshDelayTime)]) {
            unsigned int delayTime = [self.delegate documentView_getRefreshDelayTime];
            [self.jsBridge refreshPPTWithJsonObject:jsonDict delay:delayTime];
        }
    }
  
    BOOL inClass = [jsonDict[@"inClass"] boolValue];
    if (inClass) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(documentView_changePPTPositionToMain:)]) {
            // 从 socket 消息通知获取 ‘PPT与播放器的默认位置’
            BOOL wannaVideoOnMainSite = ((NSNumber *)jsonDict[@"pptAndVedioPosition"]).boolValue;
            BOOL pptToMain = !wannaVideoOnMainSite;
            self.mainSpeakerPPTOnMain = pptToMain;
            [self.delegate documentView_changePPTPositionToMain:pptToMain];
        }
    }
}

- (void)receiveAssistantSliceControltEventWithJsonObject:(NSDictionary *)jsonObject {
    if (self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSString *channelId = roomData.channelId;
    NSDictionary *dataDict = PLV_SafeDictionaryForDictKey(jsonObject, @"data");
    NSInteger pageId = PLV_SafeIntegerForDictKey(dataDict, @"pageId");
    NSString *roomId = PLV_SafeStringForDictKey(jsonObject, @"roomId");
    
    if (pageId != self.currPageNum && [roomId isEqualToString:channelId]) {
        self.currPageNum = pageId;
        [self switchPPT];
    }
}

#pragma mark - WKNavigation Delegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    webView.backgroundColor = [UIColor clearColor];
    self.webviewLoadFinish = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_webViewDidFinishLoading)]) {
        [self.delegate documentView_webViewDidFinishLoading];
    }
    
    if (self.scene == PLVDocumentViewSceneStreamer) {
        [self setUserInfo];
        [self.jsBridge setPaintPermission:@"speaker"];
        [self.jsBridge setPaintStatus:NO];
        
        if (self.viewerType == PLVRoomUserTypeTeacher) { // 当前身份为讲师才需要发送此方法
            [self switchPPT];
        }
    } else if (self.scene == PLVDocumentViewSceneCloudClass ||
               self.scene == PLVDocumentViewSceneEcommerce) {
        [self setUserInfo];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    self.webviewLoadFinish = NO;
    
    NSError *myError = [[PLVWErrorManager sharedManager] errorWithModul:PLVFErrorCodeModulPPT
                                                                   code:PLVFPPTErrorCodeWebLoadFail];
    [[PLVWLogReporterManager sharedManager] reportWithErrorCode:myError.code information:error.description];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_webViewLoadFailWithError:)]) {
        [self.delegate documentView_webViewLoadFailWithError:myError];
    }
}

#pragma mark  - PLVWebViewBridge Protocol

- (void)jsbridge_PPTHadPrepare {
    // 回放时 ppt 加载完成回调
}

- (NSTimeInterval)jsbridge_getCurrentPlaybackTime {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentView_getPlayerCurrentTime)]) {
        return [self.delegate documentView_getPlayerCurrentTime];
    } else {
        return 0;
    }
}

- (void)jsbridge_changePPTPosition:(BOOL)status {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentView_changePPTPositionToMain:)]) {
        [self.delegate documentView_changePPTPositionToMain:status];
    }
}

- (void)jsbridge_pageStatusChangeWithAutoId:(NSUInteger)autoId pageNumber:(NSUInteger)pageNumber
                                  totalPage:(NSUInteger)totalPage pptStep:(NSUInteger)step {
    if (autoId != self.autoId) { // 文档切换控制权在推流端，不在其他端，如果发过来的 autoId 与 当前autoId 不符肯定是错误的
        return;
    }
    self.currPageNum = pageNumber;
    self.totalPageNum = totalPage;
    self.pptStep = step;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_pageStatusChangeWithAutoId:pageNumber:totalPage:pptStep:)]) {
        [self.delegate documentView_pageStatusChangeWithAutoId:autoId
                            pageNumber:pageNumber totalPage:totalPage pptStep:step];
    }
}

- (void)jsbridge_sendSocketEventWithJson:(id)jsonObject {
    if (jsonObject) {
        NSDictionary *tempDict = nil;
        if ([jsonObject isKindOfClass:[NSString class]]) {
            NSData *data = [jsonObject dataUsingEncoding:NSUTF8StringEncoding];
            tempDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        } else if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            tempDict = (NSDictionary *)jsonObject;
        }
        
        if (tempDict && [tempDict isKindOfClass:[NSDictionary class]]) {
            NSString *event = PLV_SafeStringForDictKey(tempDict, @"EVENT");
            if (![PLVFdUtil checkStringUseable:event]) {
                return;
            }
            //未开播，在接收到'sendSocketEvent' js事件时，不发送画笔'onSliceDraw'事件
            //避免未开播的画笔事件传递到下一次直播。
            if ([event isEqualToString:@"onSliceDraw"] &&
                !self.startClass) {
                return;
            }
            
            [[PLVSocketManager sharedManager] emitMessage:tempDict];
        }
    }
}

- (void)jsbridge_documentInputWithText:(NSString *)inputText textColor:(NSString *)textColor {
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_inputWithText:textColor:)]) {
        [self.delegate documentView_inputWithText:inputText textColor:textColor];
    }
}

- (void)jsbridge_documentChangeWithAutoId:(NSUInteger)autoId imageUrls:(NSArray *)imageUrls {
    if (self.isChangePPT) { // 当autoId改变时，currPageNum此处起作用
        [self.jsBridge changePPTWithAutoId:self.autoId pageNumber:self.currPageNum];
        self.isChangePPT = NO;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_changeWithAutoId:imageUrls:)]) {
        [self.delegate documentView_changeWithAutoId:autoId imageUrls:imageUrls];
    }
}

@end
