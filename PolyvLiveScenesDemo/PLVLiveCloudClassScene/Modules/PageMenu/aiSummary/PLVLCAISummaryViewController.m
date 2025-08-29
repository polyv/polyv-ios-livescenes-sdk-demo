//
//  PLVLCAISummaryViewController.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2025/07/22.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLCAISummaryViewController.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVLCAISummaryViewController () <WKNavigationDelegate, PLVAISummaryWebViewBridgeDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) PLVAISummaryWebViewBridge *webViewBridge;
@property (nonatomic, copy) NSString *webViewURL;
@property (nonatomic, copy) NSString *videoId;
@property (nonatomic, copy) NSString *videoType;
@property (nonatomic, assign) NSTimeInterval currentTime;

@end

@implementation PLVLCAISummaryViewController

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentTime = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadWebView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.webView.frame = self.view.bounds;
}

#pragma mark - [ Public Method ]

- (void)updateVideoInfoWithVideoId:(NSString *)videoId 
                         videoType:(NSString *)videoType {
//    NSMutableDictionary *muDict = [NSMutableDictionary dictionary];
//    [muDict setObject:[PLVFdUtil checkStringUseable:videoId] ? videoId : @"" forKey:@"id"];
//    [muDict setObject:[PLVFdUtil checkStringUseable:videoType] ? videoType : @"" forKey:@"type"];
//    [self.webViewBridge callWebViewEvent:@{@"event" : @"setupVideo",
//                                           @"data" : [muDict copy]}];
    self.videoId = [PLVFdUtil checkStringUseable:videoId] ? videoId : @"";
    self.videoType = [PLVFdUtil checkStringUseable:videoType] ? videoType : @"";
    if (self.webViewBridge && self.webView.URL) {
        [self.webViewBridge setupVideoWithVideoId:videoId 
                                        videoType:videoType];
    }
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.view addSubview:self.webView];
}

- (void)loadWebView {
    self.webViewBridge = [[PLVAISummaryWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
    
    NSString *urlString = PLVLiveConstantsAISummaryHTML;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL enableSecurity = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSInteger security = enableSecurity ? ([PLVFSignConfig sharedInstance].encryptType == PLVEncryptType_SM2 ? 2 : 1) : 0;
    NSString *language = ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) ? @"zh_CN" : @"en";
    urlString = [urlString stringByAppendingFormat:@"?security=%ld&resourceAuth=%d&secureApi=%d&lang=%@", security, (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), language];
    NSURL *webURL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
}

- (NSDictionary *)getUserInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSDictionary *userInfo = @{
        @"nick" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerName],
        @"userId" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerId],
        @"pic" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerAvatar]
    };
    NSDictionary *channelInfo = @{
        @"channelId" : [NSString stringWithFormat:@"%@", roomData.channelId],
        @"roomId" : [NSString stringWithFormat:@"%@", roomData.channelId]
    };
    NSDictionary *sessionDict = @{
        @"appId" : [NSString stringWithFormat:@"%@", [PLVLiveVideoConfig sharedInstance].appId],
        @"appSecret" : [NSString stringWithFormat:@"%@", [PLVLiveVideoConfig sharedInstance].appSecret],
        @"accountId" : [NSString stringWithFormat:@"%@", [PLVLiveVideoConfig sharedInstance].userId],
        @"sessionId" : [NSString stringWithFormat:@"%@", roomData.sessionId],
        @"webVersion" : @"0.6.0"
    };
    NSDictionary *sm2Key = @{
        @"platformPublicKey" : [NSString stringWithFormat:@"%@", [PLVFSignConfig sharedInstance].serverSM2PublicKey], // 平台公钥(接口提交参数加密用)
        @"userPrivateKey" : [NSString stringWithFormat:@"%@", [PLVFSignConfig sharedInstance].clientSM2PrivateKey] // 用户私钥(接口返回内容解密用)
    };
    
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    [mutableDict setObject:userInfo forKey:@"userInfo"];
    [mutableDict setObject:channelInfo forKey:@"channelInfo"];
    [mutableDict setObject:sm2Key forKey:@"sm2Key"];
    if (roomData.menuInfo.promotionInfo) {
        [mutableDict setObject:roomData.menuInfo.promotionInfo forKey:@"promotionInfo"];
    }
    [mutableDict addEntriesFromDictionary:sessionDict];
    
    NSString *chatToken = [PLVSocketManager sharedManager].chatToken;
    if ([PLVFdUtil checkStringUseable:chatToken]) {
        [mutableDict setObject:chatToken forKey:@"chatToken"];
    }
    
    return mutableDict;
}

#pragma mark - [ Getter & Setter ]

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration * config = [[WKWebViewConfiguration alloc] init];
        if (@available(iOS 13.0, *)) {
            config.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        }
        config.allowsInlineMediaPlayback = YES;
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        _webView.opaque = NO;
        _webView.scrollView.bounces = NO;
        if (@available(iOS 11.0,*)) {
            [_webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
        _webView.backgroundColor = [UIColor clearColor];
        _webView.scrollView.backgroundColor = [UIColor clearColor];
        _webView.navigationDelegate = self;
    }
    return _webView;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    PLV_LOG_INFO(PLVConsoleLogModuleTypeJSBridge, @"AI Summary WebView did finish navigation");
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    PLV_LOG_ERROR(PLVConsoleLogModuleTypeJSBridge, @"AI Summary WebView did fail navigation with error: %@", error);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    PLV_LOG_ERROR(PLVConsoleLogModuleTypeJSBridge, @"AI Summary WebView did fail provisional navigation with error: %@", error);
}

#pragma mark - PLVAISummaryWebViewBridgeDelegate

- (void)aiSummaryWebViewBridge:(id)bridge seekToTime:(NSTimeInterval)time {
    PLV_LOG_INFO(PLVConsoleLogModuleTypeJSBridge, @"AI Summary WebView requested seek to time: %f", time);
    if (self.delegate && [self.delegate respondsToSelector:@selector(aiSummaryViewController:seekToTime:)]) {
        [self.delegate aiSummaryViewController:self seekToTime:time];
    }
}

- (void)aiSummaryWebViewBridgeShouldSetupVideo:(PLVAISummaryWebViewBridge *)bridge {
    if (self.delegate && [self.delegate respondsToSelector:@selector(aiSummaryViewControllerShouldSetupVideo:)]) {
        [self.delegate aiSummaryViewControllerShouldSetupVideo:self];
    }
}

- (NSDictionary *)getAPPInfoInAISummaryWebViewBridge:(PLVAISummaryWebViewBridge *)bridge {
    return [self getUserInfo];
}

@end 
