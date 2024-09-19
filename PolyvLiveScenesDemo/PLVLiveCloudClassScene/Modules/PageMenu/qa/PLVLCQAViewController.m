//
//  PLVLCQAViewController.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/10/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCQAViewController.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVLCQAViewController ()<
WKNavigationDelegate,
PLVQAWebViewBridgeDelegate
>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) PLVQAWebViewBridge *webViewBridge;

#pragma mark 数据
@property (nonatomic, strong) PLVRoomData *roomData;
@property (nonatomic, copy) NSString *theme; //皮肤

@end

@implementation PLVLCQAViewController

#pragma mark - [ Life Cycle ]

- (instancetype)initWithRoomData:(PLVRoomData *)roomData theme:(NSString *)theme {
    self = [super init];
    if (self) {
        _roomData = roomData;
        _theme = theme;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#141518"];
    [self.view addSubview:self.webView];

    self.webViewBridge = [[PLVQAWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
    
    NSString *urlString = PLVLiveConstantsWatchQAURL;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL enableSecurity = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSInteger security = enableSecurity ? ([PLVFSignConfig sharedInstance].encryptType == PLVEncryptType_SM2 ? 2 : 1) : 0;
    NSString *theme = [PLVFdUtil checkStringUseable:self.theme] ? self.theme : @""; //QA皮肤设置默认白色
    NSString *language = ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH) ? @"zh_CN" : @"en";
    urlString = [urlString stringByAppendingFormat:@"?security=%ld&resourceAuth=%d&secureApi=%d&theme=%@&lang=%@", security, (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), theme, language];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self.webView loadRequest:request];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.webView.frame = self.view.bounds;
}

#pragma mark - [ Public Method ]

- (void)updateUserInfo {
    NSDictionary *userInfo = [self getUserInfo];
    [self.webViewBridge updateNativeAppParamsInfo:userInfo];
}

#pragma mark - [ Private Method ]
#pragma mark Getter & Setter
- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration * config = [[WKWebViewConfiguration alloc] init];
        if (@available(iOS 13.0, *)) {
            config.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        }
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        _webView.opaque = NO;
        _webView.scrollView.bounces = NO;
        if (@available(iOS 11.0,*)) {
            [_webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _webView;
}

- (NSDictionary *)getUserInfo {
    NSString *chatToken = [PLVSocketManager sharedManager].chatToken;
    if ([PLVFdUtil checkStringUseable:chatToken]) {
        NSDictionary *dict = @{@"chatToken" : chatToken};
        return  [self.roomData nativeAppUserParamsWithExtraParam:dict];
    } else {
        return [self.roomData nativeAppUserParamsWithExtraParam:nil];
    }
}

#pragma mark - [ Delegate ]
#pragma mark PLVQAWebViewBridgeDelegate
- (NSDictionary *)getAPPInfoInQAWebViewBridge:(PLVQAWebViewBridge *)webViewBridge {
    return [self getUserInfo];
}

@end
