//
//  PLVLCTuwenViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCTuwenViewController.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLCTuwenViewController ()<
WKNavigationDelegate,
PLVTuWenWebViewBridgeDelegate
>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) BOOL showBigImage;
@property (nonatomic, assign) BOOL isLive; // 是否正在直播中
@property (nonatomic, strong) PLVTuWenWebViewBridge *webViewBridge;

@end

@implementation PLVLCTuwenViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#141518"];
    [self.view addSubview:self.webView];
    
    self.webViewBridge = [[PLVTuWenWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
    
    NSString *urlString = PLVLiveConstantsLiveFrontPictureTextURL;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL enableSecurity = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSInteger security = enableSecurity ? ([PLVFSignConfig sharedInstance].encryptType == PLVEncryptType_SM2 ? 2 : 1) : 0;
    NSString *language = ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) ? @"zh_CN" : @"en";
    urlString = [urlString stringByAppendingFormat:@"?security=%ld&resourceAuth=%d&secureApi=%d&lang=%@", security, (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), language];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self.webView loadRequest:request];
}

- (void)viewWillLayoutSubviews {
    self.webView.frame = self.view.bounds;
}
    
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.delegate && self.showBigImage) {
       [self notificationForGestureEnable:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.delegate && self.showBigImage) {
        [self notificationForGestureEnable:YES];
    }
}

#pragma mark - [ Public Method ]

- (void)updateUserInfo {
    NSDictionary *userInfo = [self getUserInfo];
    [self.webViewBridge updateNativeAppParamsInfo:userInfo];
}

- (void)updateLiveStatusIsLive:(BOOL)isLive {
    self.isLive = isLive;
    [self updateUserInfo];
}

#pragma mark - [ Private Method ]

- (void)notificationForGestureEnable:(BOOL)enable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickTuwenImage:)]) {
        [self.delegate clickTuwenImage:!enable];
    }
}

- (NSDictionary *)getUserInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSDictionary *dict = @{@"isLive" : self.isLive ? @"1" : @"0"};
    return [roomData nativeAppUserParamsWithExtraParam:dict];
}

// 将 JSON 数据转化为字典
- (NSDictionary *)dictionaryFromJSONObject:(id)jsonObject {
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

#pragma mark - [ Delegate ]

#pragma mark PLVTuWenWebViewBridgeDelegate
- (NSDictionary *)getAPPInfoInTuWenWebViewBridge:(PLVTuWenWebViewBridge *)webViewBridge {
    return [self getUserInfo];
}

- (void)plvTuWenWebViewBridge:(PLVTuWenWebViewBridge *)webViewBridge callAppEvent:(id)jsonObject {
    if (!jsonObject) { return; }
    
    NSDictionary *dict = [self dictionaryFromJSONObject:jsonObject];
    NSString *event = PLV_SafeStringForDictKey(dict, @"event");
    if ([event isEqualToString:@"clickTuwenImage"]) {
        self.showBigImage = YES;
        [self notificationForGestureEnable:NO];
    } else if ([event isEqualToString:@"tuwenImageHide"]) {
        self.showBigImage = NO;
        [self notificationForGestureEnable:YES];
    }
}

@end
