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
PLVSocketManagerProtocol,
UIGestureRecognizerDelegate
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
@property (nonatomic, assign) BOOL hasPaintPermission; // 用户是否拥有画笔权限（讲师默认拥有）
@property (nonatomic, assign) BOOL allowChangePPT; // 是否允许切换PPT（双师模式时为YES）
@property (nonatomic, assign, readonly) PLVRoomUserType viewerType;
@property (nonatomic, assign, readonly) PLVChannelVideoType videoType;
@property (nonatomic, assign, readonly) BOOL liveStatusIsLiving; // 当前直播是否正在进行

/// scene 为 PLVDocumentViewSceneCloudClass 、 PLVDocumentViewSceneEcommerce 、PLVDocumentViewSceneStreamer 的数据
@property (nonatomic, assign) BOOL mainSpeakerPPTOnMain;            // 场景中 主讲的PPT当前是否在主屏

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
        
        self.mainSpeakerPPTOnMain = YES;
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
            [self.jsBridge registerPPTThumbnailFunction];
            [self.jsBridge registerWhiteboardPPTZoomChangeFunction];
        } else if (self.scene == PLVDocumentViewSceneCloudClass ||
                   self.scene == PLVDocumentViewSceneEcommerce) {
            // 观看场景的 userInfo 需登录完 sockt 后获取
            
            [self.jsBridge registerPPTPrepareFunction];
            [self.jsBridge registerSocketEventFunction];
            [self.jsBridge registerVideoDurationFunction];
            [self.jsBridge registerChangePPTPositionFunction];
            // 云课堂场景，需要监听registerWatchPPTStatusChangeFunction，用于本地翻页
            if (self.scene == PLVDocumentViewSceneCloudClass) {
                [self.jsBridge registerWatchPPTStatusChangeFunction];
            }
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
        if (@available(iOS 13.0, *)) {
            config.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        }
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        _webView.contentMode = UIViewContentModeRedraw;
        _webView.opaque = NO;
        _webView.scrollView.bounces = NO; // 关闭webview弹性，避免影响画笔操作
        if(@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        /// 推流场景 讲师角色或者嘉宾为主讲时开启userInteractionEnabled；其他场景均设为NO，不允许交互。
        if (self.scene == PLVDocumentViewSceneStreamer && self.viewerType == PLVRoomUserTypeTeacher) {
            _webView.userInteractionEnabled = YES;
            self.hasPaintPermission = YES;
        } else {
            _webView.userInteractionEnabled = NO;
            self.hasPaintPermission = NO;
        }
        
        // 禁用拷贝查询弹出框
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:nil];
        longPress.delegate = self;
        longPress.minimumPressDuration = 0.4;
        [_webView addGestureRecognizer:longPress];
    }
    
    return _webView;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
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

- (BOOL)liveStatusIsLiving {
    return [PLVRoomDataManager sharedManager].roomData.liveStatusIsLiving;
}

- (PLVChannelVideoType)videoType {
    return [PLVRoomDataManager sharedManager].roomData.videoType;
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
        hasParam = YES;
    }
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL enableSecurity = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSInteger security = enableSecurity ? ([PLVFSignConfig sharedInstance].encryptType == PLVEncryptType_SM2 ? 2 : 1) : 0;
    urlString = [urlString stringByAppendingFormat:@"%@security=%ld&resourceAuth=%d&secureApi=%d", (hasParam ? @"&" : @"?"), security, (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0)];
    
    // 避免拼接参数中含有特殊字符#被编码导致请求拼接异常
    NSString *charactersToEscape = @"#";
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [self.webView loadRequest:request];
}

- (void)loadRequestWithLocalHtml:(NSString *)filePath allowingReadAccessToURL:(NSString *)accessPath {
    if ([PLVFdUtil checkStringUseable:filePath] &&
        [PLVFdUtil checkStringUseable:accessPath]) {
        
        NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
        NSURL *accessUrl = [NSURL fileURLWithPath:accessPath isDirectory: YES];
        if (@available(iOS 9.0, *)) {
            [self.webView loadFileURL:fileUrl allowingReadAccessToURL:accessUrl];
        }
    }
}

- (void)changePPTPageWithType:(PLVChangePPTPageType)type {
    [self.jsBridge changePPTPageWithType:type];
}

#pragma mark 观看专用方法

- (void)pptSetOfflinePath:(NSString *)path {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce) {
        return;
    }
    [self.jsBridge pptSetLocalPath:path];
}

- (void)pptLocalStartWithVideoId:(NSString *)videoId vid:(NSString *)vid {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce) {
        return;
    }
    [self.jsBridge pptLocalStartWithVideoId:videoId vid:vid];
}

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

- (void)pptStartWithVideoId:(NSString *)videoId channelId:(NSString *)channelId {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce) {
        return;
    }
    [self.jsBridge pptStartWithVideoId:videoId channelId:channelId];
}

- (void)pptStartWithFileId:(NSString *)fileId channelId:(NSString *)channelId {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce) {
        return;
    }
    [self.jsBridge pptStartWithFileId:fileId channelId:channelId];
}

#pragma mark 操作白板的方法

- (void)setDocumentUserInteractionEnabled:(BOOL)enabled {
    BOOL streamerUser = (self.scene == PLVDocumentViewSceneStreamer);
    BOOL watchUser = (self.scene == PLVDocumentViewSceneCloudClass);
    if (streamerUser || watchUser) {
        self.webView.userInteractionEnabled = enabled;
        self.hasPaintPermission = enabled;
    }
}

- (void)openChangePPTPermission {
    self.allowChangePPT = YES;
}

- (void)setPaintStatus:(BOOL)open {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge setPaintStatus:open];
}

- (void)setDrawType:(PLVWebViewBrushPenType)type {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge setDrawType:type];
}

- (void)changeTextContent:(NSString *)content {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge changeTextContent:content];
}

- (void)changeColor:(NSString *)hexString {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge changeColor:hexString];
}

- (void)doUndo {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge doUndo];
}

- (void)toDelete {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge toDelete];
}

- (void)deleteAllPaint {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge deleteAllPaint];
}

- (void)setSliceStart:(NSDictionary *)jsonDict {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge setSliceStart:jsonDict];
}

- (void)changePPTWithAutoId:(NSUInteger)autoId pageNumber:(NSInteger)pageNumber {
    if (!self.hasPaintPermission &&
        !self.allowChangePPT) {
        return;
    }
    
    self.isChangePPT = self.autoId != autoId;
    
    self.autoId = autoId;
    self.currPageNum = pageNumber;
    
    [self switchPPT];
}

- (void)turnPage:(BOOL)isNextPage {
    if (!self.hasPaintPermission) {
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
    if (!self.hasPaintPermission) {
        return;
    }
    
    if (self.autoId != 0) { // 白板才能添加
        return;
    }
    
    self.totalPageNum += 1;
    self.currPageNum = self.totalPageNum - 1;
    [self switchPPT];
}

- (void)resetWhiteboardPPTZoomRatio {
    if (!self.hasPaintPermission) {
        return;
    }
    
    [self.jsBridge resetWhiteboardPPTZoomRatio];
}

#pragma mark - Private Method

/// 当属性 autoId、currPageNum 发生变化时调用该方法
- (void)switchPPT {
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
        self.viewerType == PLVRoomUserTypeTeacher) {
        if (self.liveStatusIsLiving) { // 推流场景且讲师角色未断流，只需要监听"onSliceID"消息
            if ([subEvent isEqualToString:@"onSliceID"]) {
                NSDictionary * dataDict = PLV_SafeDictionaryForDictKey(jsonDict, @"data");
                NSInteger autoId = PLV_SafeIntegerForDictKey(dataDict, @"autoId");
                NSInteger pageId = PLV_SafeIntegerForDictKey(dataDict, @"pageId");
                if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_continueClassWithAutoId:pageNumber:)]) {
                    [self.delegate documentView_continueClassWithAutoId:autoId pageNumber:pageId];
                }
            }
        }

        // 讲师也需要监听 "onSliceStart" "onSliceControl" "onSliceDraw" "changeVideoAndPPTPosition" 消息
        if ([subEvent isEqualToString:@"onSliceOpen"] ||
            [subEvent isEqualToString:@"onSliceDraw"] ||
            [subEvent isEqualToString:@"onSliceControl"]) {
            [self receiveOnSliceMessageWithjson:jsonString jsonObject:jsonDict];
        } else if ([subEvent isEqualToString:@"changeVideoAndPPTPosition"]) {
            [self receiveChangePPTPositionMessageWithjsonObject:jsonDict];
        }
        
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
    } else if ([subEvent isEqualToString:@"TEACHER_SET_PERMISSION"]){
        [self receiveTeacherSetPermissionMessageWithJSONObject:jsonDict];
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
    if (self.videoType != PLVChannelVideoType_Playback) { // 新增条件判断：非直播回放时，才更新PPT位置
        if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_changePPTPositionToMain:)]) {
            BOOL wannaVideoOnMainSite = ((NSNumber *)jsonDict[@"status"]).boolValue;
            BOOL pptToMain = !wannaVideoOnMainSite;
            self.mainSpeakerPPTOnMain = pptToMain;
            [self.delegate documentView_changePPTPositionToMain:pptToMain];
        }
    }
}

- (void)receiveOnSliceMessageWithjson:(NSString *)jsonString
                           jsonObject:(NSDictionary *)jsonDict {
    if (self.scene != PLVDocumentViewSceneCloudClass &&
        self.scene != PLVDocumentViewSceneEcommerce &&
        self.scene != PLVDocumentViewSceneStreamer) {
        return;
    }
        
    if (self.scene == PLVDocumentViewSceneStreamer) {
        NSDictionary * dataDict = PLV_SafeDictionaryForDictKey(jsonDict, @"data");
        NSString *eventType = PLV_SafeStringForDictKey(dataDict, @"type");
        if (![eventType isEqualToString:@"changeVideoAndPPTPosition"]) { // 切换主副屏时，消息体内未返回autoId与pageId字段，此事件下，不需要更新
            NSInteger autoId = PLV_SafeIntegerForDictKey(dataDict, @"autoId");
            NSInteger pageId = PLV_SafeIntegerForDictKey(dataDict, @"pageId");
            self.autoId = autoId;
            self.currPageNum = pageId;
        }
        [self.jsBridge refreshPPTWithJsonObject:jsonDict delay:0];
    }else {
        if (self.videoType != PLVChannelVideoType_Playback) { // 新增条件判断：非直播回放时，才更新画笔数据
            if ([self.delegate respondsToSelector:@selector(documentView_getRefreshDelayTime)]) {
                unsigned int delayTime = [self.delegate documentView_getRefreshDelayTime];
                [self.jsBridge refreshPPTWithJsonObject:jsonDict delay:delayTime];
            }
        }
    }
  
    BOOL inClass = [jsonDict[@"inClass"] boolValue];
    if (inClass && self.videoType != PLVChannelVideoType_Playback) { /// 新增条件判断：非直播回放时，才更新PPT位置
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

- (void)receiveTeacherSetPermissionMessageWithJSONObject:(NSDictionary *)jsonObject {
    NSString *type = PLV_SafeStringForDictKey(jsonObject, @"type");
    NSString *userId = PLV_SafeStringForDictKey(jsonObject, @"userId");
    BOOL status = PLV_SafeBoolForDictKey(jsonObject, @"status");
    
    if ([PLVFdUtil checkStringUseable:type] && [type isEqualToString:@"paint"]) { // 画笔权限
        plv_dispatch_main_async_safe(^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_teacherSetPaintPermission:userId:)]) {
                [self.delegate documentView_teacherSetPaintPermission:status userId:userId];
            }
        });
    }
}

#pragma mark - WKNavigation Delegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    webView.backgroundColor = [UIColor clearColor];
    // 禁止长按 复制
    [webView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:nil];
    [webView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none';" completionHandler:nil];
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
    } else if (self.scene == PLVDocumentViewSceneCloudClass) {
        [self setUserInfo];
        [self.jsBridge setPaintPermission:@"speaker"];
        [self.jsBridge setPaintStatus:NO];
    } else if (self.scene == PLVDocumentViewSceneEcommerce) {
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

- (void)jsbridge_pageStatusChangeWithAutoId:(NSUInteger)autoId pageNumber:(NSUInteger)pageNumber totalPage:(NSUInteger)totalPage pptStep:(NSUInteger)step maxNextNumber:(NSUInteger)maxNextNumber {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentView_pageStatusChangeWithAutoId:pageNumber:totalPage:pptStep:maxNextNumber:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate documentView_pageStatusChangeWithAutoId:autoId pageNumber:pageNumber totalPage:totalPage pptStep:step maxNextNumber:maxNextNumber];
        })
    }
}

- (void)jsbridge_sendSocketEventWithJson:(id)jsonObject {
    // 当前场景不是推流场景（三分屏、纯视频开播）或 观看端观众（云课堂），不需要帮JS转发socket消息
    if (!self.hasPaintPermission) {
        return;
    }
    
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

- (void)jsbridge_documentChangeWithAutoId:(NSUInteger)autoId imageUrls:(NSArray *)imageUrls fileName:(NSString *)fileName {
    if (self.isChangePPT) { // 当autoId改变时，currPageNum此处起作用
        [self.jsBridge changePPTWithAutoId:self.autoId pageNumber:self.currPageNum];
        self.isChangePPT = NO;
    }
    
    fileName = self.liveStatusIsLiving ? fileName : nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_changeWithAutoId:imageUrls:fileName:)]) {
        [self.delegate documentView_changeWithAutoId:autoId imageUrls:imageUrls fileName:fileName];
    }
    
    /// 使用一次后注销，防止重复调用PPTThumbnail
    if ([PLVFdUtil checkStringUseable:fileName]) {
        [self.jsBridge removePPTThumbnailFunction];
    }
}

- (void)jsbridge_updateWhiteboardPPTZoomRatio:(NSInteger)zoomRatio {
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentView_whiteboardPPTZoomChangeRatio:)]) {
        [self.delegate documentView_whiteboardPPTZoomChangeRatio:zoomRatio];
    }
}

@end
