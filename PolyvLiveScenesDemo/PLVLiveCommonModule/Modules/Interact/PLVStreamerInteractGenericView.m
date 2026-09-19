//
//  PLVStreamerInteractGenericView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2024/5/13.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVStreamerInteractGenericView.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface PLVStreamerInteractGenericView () <
WKNavigationDelegate,
UIDocumentPickerDelegate,
PLVStreamerInteractWebViewBridgeDelegate,
PLVSocketManagerProtocol
>

/// UI
@property (nonatomic, strong) WKWebView *webView;

/// 数据
@property (nonatomic, strong) PLVStreamerInteractWebViewBridge *webViewBridge;
@property (nonatomic, copy) NSString *webViewURLString;
@property (nonatomic, assign) BOOL webviewLoadFinish; //webview 是否已加载完成
@property (nonatomic, assign) BOOL webviewLoadFaid; //webview 是否加载失败
@property (nonatomic, copy) NSString *pendingEventName; // webview 未就绪时待发送的事件

@end

@implementation PLVStreamerInteractGenericView

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    [[PLVSocketManager sharedManager] removeDelegate:self];
    PLV_LOG_INFO(PLVConsoleLogModuleTypeInteract, @"%s",__FUNCTION__);
}

- (instancetype)init {
    return [self initWithWebViewURLString:PLVLiveConstantsStreamerInteractWebViewURL];
}

- (instancetype)initWithWebViewURLString:(NSString *)webViewURLString {
    if (self = [super init]) {
        self.webViewURLString = [PLVFdUtil checkStringUseable:webViewURLString] ? webViewURLString : PLVLiveConstantsStreamerInteractWebViewURL;
        [self setupData];
        [self setupUI];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)loadInteractWebView {
    [self.webView stopLoading];
    self.webviewLoadFinish = NO;
    self.webviewLoadFaid = NO;
    
    NSString *urlString = [PLVFdUtil checkStringUseable:self.webViewURLString] ? self.webViewURLString : PLVLiveConstantsStreamerInteractWebViewURL;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL security = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSString *language = ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) ? @"zh_CN" : @"en";
    urlString = [urlString stringByAppendingFormat:@"?security=%d&resourceAuth=%d&secureApi=%d&lang=%@", (security ? 1 : 0), (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), language];
    NSURL *interactURL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:interactURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
    [self layoutWebviewFrame];
}

- (void)updateUserInfo {
    NSDictionary *userInfo = [self getUserInfo];
    [self.webViewBridge updateNativeAppParamsInfo:userInfo];
}

- (void)openInteractViewWithEventName:(NSString *)eventName {
    [self setInteractWebViewShow:YES];
    // 先保证 WebView 有有效尺寸，避免加载完成后才布局导致短暂空白
    if (!CGRectEqualToRect(self.bounds, CGRectZero)) {
        self.webView.frame = self.bounds;
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    // 打开前同步最新 socketId，保证 H5 查询答题卡进行中可用
    [self updateUserInfo];
    if (![PLVFdUtil checkStringUseable:eventName]) {
        return;
    }
    if (self.webviewLoadFinish) {
        self.pendingEventName = nil;
        [self.webViewBridge callWebViewEvent:@{@"event" : eventName}];
    } else {
        // 页面未就绪时先缓存，didFinish 后再补发，避免 SHOW_ANSWER_CARD 丢失
        self.pendingEventName = eventName;
        if (self.webviewLoadFaid) {
            [self loadInteractWebView];
        }
    }
}

#pragma mark - [ Private Method ]

- (void)setupData {    
    self.webViewBridge = [[PLVStreamerInteractWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
    self.hidden = YES;
    
    [self addSubview:self.webView];
}

- (void)setInteractWebViewShow:(BOOL)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = !show;
        if (show) {
            [self.superview bringSubviewToFront:self]; /// 移至最顶层
        }
    });
}

- (void)layoutWebviewFrame {
    if (self.webviewLoadFinish) {
        self.webView.frame = self.bounds;
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    } else if(!self.webviewLoadFaid) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf layoutWebviewFrame];
        });
    }
}

- (NSDictionary *)getUserInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSDictionary *extraParam = @{
        @"userType" : @"teacher",
        @"webVersion" : @"0.6.0"
    };
    NSMutableDictionary *userInfo = [[roomData nativeAppUserParamsWithExtraParam:extraParam] mutableCopy];
    // 开播端答题卡查询进行中需要聊天室服务器分配的 socketId
    NSString *socketId = [PLVSocketManager sharedManager].socketId;
    if ([PLVFdUtil checkStringUseable:socketId]) {
        userInfo[@"socketId"] = socketId;
    }
    return userInfo;
}

#pragma mark - Download File
- (void)downloadFileWithURL:(NSURL *)url {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (location) {
            // 解析文件名
            NSString *fileName;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSString *contentDisposition = httpResponse.allHeaderFields[@"Content-Disposition"];
                if (contentDisposition) {
                    fileName = [self parseContentDisposition:contentDisposition];
                }
            }

            // 修改文件名或者后缀
            NSURL *newFileURL = [self changeFileNameOrExtensionAtURL:location newName:fileName newExtension:@"xls"];
            if (newFileURL) {
                // 调用保存文件的方法
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentDocumentPickerWithFileURL:newFileURL];
                });
            }
        } else {
            NSLog(@"Error downloading file: %@", error.localizedDescription);
        }
    }];
    [downloadTask resume];
}

- (NSString *)parseContentDisposition:(NSString *)content {
    NSString *prefix = @"filename=\"";
    NSRange range = [content rangeOfString:prefix];
    if (range.location != NSNotFound) {
        NSUInteger start = range.location + range.length;
        NSRange endRange = [content rangeOfString:@"\"" options:0 range:NSMakeRange(start, content.length - start)];
        if (endRange.location != NSNotFound) {
            NSString *filename = [content substringWithRange:NSMakeRange(start, endRange.location - start)];
            return filename;
        }
    }
    return nil;
}

- (NSURL *)changeFileNameOrExtensionAtURL:(NSURL *)originalURL newName:(NSString *)newName newExtension:(NSString *)newExtension {
    NSString *originalFilePath = originalURL.path;
    NSString *directoryPath = [originalFilePath stringByDeletingLastPathComponent];
    NSString *originalFileName = [originalFilePath lastPathComponent];
    NSString *newPath = [[directoryPath stringByAppendingPathComponent:[originalFileName stringByDeletingPathExtension]] stringByAppendingPathExtension:newExtension];
    // 服务器有返回文件名
    if ([PLVFdUtil checkStringUseable:newName]) {
        // URL 解码
        newName = [newName stringByRemovingPercentEncoding];
        // 替换特殊字符
        NSCharacterSet *illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]\" <>|{}^`"];
        newName = [[newName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@"_"];
        newPath = [directoryPath stringByAppendingPathComponent:newName];
    }

    NSError *error = nil;
    NSURL *newURL = [NSURL fileURLWithPath:newPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 已经存在文件则先删除
    if ([fileManager fileExistsAtPath:newPath]) {
        [fileManager removeItemAtURL:newURL error:&error];
        if (error) {
            NSLog(@"Error removing existing file: %@", error);
            return nil;
        }
    }
    
    if ([fileManager moveItemAtURL:originalURL toURL:newURL error:&error]) {
        NSLog(@"File saved with new path at: %@", newURL.path);
        return newURL;
    } else {
        NSLog(@"Error saving file with new path: %@", error.localizedDescription);
        return nil;
    }
}

- (void)presentDocumentPickerWithFileURL:(NSURL *)fileURL {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURLs:@[fileURL] inMode:UIDocumentPickerModeExportToService];
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [[PLVFdUtil getCurrentViewController] presentViewController:documentPicker animated:YES completion:nil];
}

#pragma mark Utils
// 将 JSON 数据转化为字典
- (NSDictionary *)dictionaryFromJSONObject:(id)jsonObject {
    if (!jsonObject) {
        return nil;
    }
    
    if ([PLVFdUtil checkDictionaryUseable:jsonObject]) {
        return (NSDictionary *)jsonObject;
    }
    
    NSData *jsonData = [jsonObject dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
    return dataDict;
}

#pragma mark Getter & Setter
- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration * config = [[WKWebViewConfiguration alloc] init];
        if (@available(iOS 10.0, *)) {
            config.dataDetectorTypes = WKDataDetectorTypeNone;
        }
        if (@available(iOS 13.0, *)) {
            config.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        }
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.navigationDelegate = self;
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        _webView.contentMode = UIViewContentModeRedraw;
        _webView.opaque = NO;
        _webView.scrollView.bounces = NO;
        if(@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _webView;
}

#pragma mark - [ Delegate ]

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString {
    // socketId 在登录成功后才可用，同步给 H5 用于查询答题卡进行中
    [self updateUserInfo];
}

#pragma mark WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // 更新 加载状态
    self.webviewLoadFaid = NO;
    self.webviewLoadFinish = YES;
    [self layoutWebviewFrame];
    if ([PLVFdUtil checkStringUseable:self.pendingEventName]) {
        NSString *eventName = self.pendingEventName;
        self.pendingEventName = nil;
        // H5 Vue 挂载与事件监听略晚于 didFinish，稍延迟再发避免丢失
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.webViewBridge callWebViewEvent:@{@"event" : eventName}];
        });
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    // 更新 加载状态
    self.webviewLoadFinish = NO;
    self.webviewLoadFaid = YES;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.webviewLoadFinish = NO;
    self.webviewLoadFaid = YES;
}

#pragma mark PLVStreamerInteractWebViewBridgeDelegate
- (NSDictionary *)getAPPInfoInStreamerInteractBridge:(PLVStreamerInteractWebViewBridge *)webViewBridge {
    return [self getUserInfo];
}

- (void)plvStreamerInteractBridgeShowWebView:(PLVStreamerInteractWebViewBridge *)webViewBridge {
    [self setInteractWebViewShow:YES];
}

- (void)plvStreamerInteractBridgeCloseWebView:(PLVStreamerInteractWebViewBridge *)webViewBridge {
    [self setInteractWebViewShow:NO];
}

- (void)plvStreamerInteractBridge:(PLVStreamerInteractWebViewBridge *)webViewBridge callAppEvent:(id)jsonObject {
    NSDictionary *dict = [self dictionaryFromJSONObject:jsonObject];
    NSString *event = PLV_SafeStringForDictKey(dict, @"event");
    if ([event isEqualToString:@"downloadSignInRecord"] ||
        [event isEqualToString:@"downloadAnswerCardRecord"] ||
        [event isEqualToString:@"downloadQuickAnswerRecord"]) { // 下载签到/答题卡/快速问答记录
        NSDictionary *valueDcit = PLV_SafeDictionaryForDictKey(dict, @"value");
        NSString *downloadURL = PLV_SafeStringForDictKey(valueDcit, @"downloadURL");
        if ([PLVFdUtil checkStringUseable:downloadURL]) {
            [self downloadFileWithURL:[NSURL URLWithString:downloadURL]];
        }
    }
}

#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSLog(@"保存文件成功");
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSLog(@"取消下载操作");
}

@end
