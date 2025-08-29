//
//  PLVSAManageCommoditySheet.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2022/10/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSAManageCommoditySheet.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVSAManageCommoditySheet ()<
WKUIDelegate,
WKNavigationDelegate,
PLVStreamerCommodityWebViewBridgeDelegate>
/// UI
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIView *backgroundView;
/// 数据
@property (nonatomic, strong) PLVStreamerCommodityWebViewBridge *webViewBridge;
@end

@implementation PLVSAManageCommoditySheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self.contentView addSubview:self.backgroundView];
        [self.contentView addSubview:self.webView];
        self.webViewBridge = [[PLVStreamerCommodityWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
        self.webViewBridge.delegate = self;
    }
    return self;
}

#pragma mark - [ Override ]

- (void)showInView:(UIView *)parentView {
    [super showInView:parentView];
    
    [self loadWebView];
}

- (void)dismiss {
    [super dismiss];
    
    [self.webView stopLoading];
}

#pragma mark - [ Private Method ]

- (void)loadWebView {
    NSString *urlString = PLVLiveConstantsStreamerProductHTML;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL security = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSString *language = ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH) ? @"zh_CN" : @"en";
    urlString = [urlString stringByAppendingFormat:@"?security=%d&resourceAuth=%d&secureApi=%d&lang=%@", (security ? 1 : 0), (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), language];

    NSURL *posterURL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:posterURL];
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
        @"sessionId" : [NSString stringWithFormat:@"%@", roomData.sessionId]
    };
    
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    [mutableDict setObject:userInfo forKey:@"userInfo"];
    [mutableDict setObject:channelInfo forKey:@"channelInfo"];
    [mutableDict addEntriesFromDictionary:sessionDict];
    
    return mutableDict;
}

#pragma mark Getter & Setter

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
    }
    return _backgroundView;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        if (@available(iOS 13.0, *)) {
            config.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        }
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        _webView.opaque = NO;
        _webView.scrollView.bounces = NO;
        if (@available(iOS 11.0,*)) {
            [_webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _webView;
}

#pragma mark - [ Delegate ]

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated){
        NSString * url = navigationAction.request.URL.absoluteString;
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark PLVStreamerCommodityWebViewBridgeDelegate

- (NSDictionary *)getAPPInfoInStreamerCommodityWebViewBridge:(PLVStreamerCommodityWebViewBridge *)webViewBridge {
    return [self getUserInfo];
}

@end
