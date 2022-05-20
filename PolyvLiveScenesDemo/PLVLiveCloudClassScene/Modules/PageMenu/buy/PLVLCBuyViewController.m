//
//  PLVLCBuyViewController.m
//  PolyvLiveScenesDemo
//
//  Created by 黄佳玮 on 2022/4/11.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCBuyViewController.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVRoomDataManager.h"

@interface PLVLCBuyViewController ()<
WKNavigationDelegate,
PLVProductWebViewBridgeDelegate>

/// UI
@property (nonatomic, strong) WKWebView *webView;

/// 数据
@property (nonatomic, strong) PLVProductWebViewBridge *webViewBridge;

@end

@implementation PLVLCBuyViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupData];
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

- (void)setupData {
    self.webViewBridge = [[PLVProductWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
    NSURL *interactURL = [NSURL URLWithString:PLVLiveConstantsProductListHTML];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:interactURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
}

- (void)setupUI {
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#141518"];
    [self.view addSubview:self.webView];
}

- (NSDictionary *)getUserInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSDictionary *userInfo = @{
        @"nick" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerName],
        @"userId" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerId],
        @"pic" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerAvatar]
    };
    NSDictionary *channelInfo = @{
        @"channelId" : [NSString stringWithFormat:@"%@", [PLVSocketManager sharedManager].roomId],
        @"roomId" : [NSString stringWithFormat:@"%@", [PLVSocketManager sharedManager].roomId]
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
    }
    return _webView;
}

#pragma mark - [ Delegate ]

#pragma mark PLVProductWebViewBridgeDelegate

- (NSDictionary *)getAPPInfoInProductWebViewBridge:(PLVProductWebViewBridge *)webViewBridge {
    return [self getUserInfo];
}

- (void)plvProductWebViewBridge:(PLVProductWebViewBridge *)webViewBridge clickProductButtonWithJSONObject:(id)jsonObject {
    if ([PLVFdUtil checkDictionaryUseable:jsonObject]) {
        NSDictionary *data = PLV_SafeDictionaryForDictKey(jsonObject, @"data");
        PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:data];
        NSURL *linkURL;
        if (model.linkType == 10) { // 通用链接
            linkURL = [NSURL URLWithString:model.link];
        } else if (model.linkType == 11) { // 多平台链接
            linkURL = [NSURL URLWithString:model.mobileAppLink];
        }
        
        if (linkURL && !linkURL.scheme) {
            linkURL = [NSURL URLWithString:[@"http://" stringByAppendingString:linkURL.absoluteString]];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCClickProductInViewController:linkURL:)]) {
            [self.delegate plvLCClickProductInViewController:self linkURL:linkURL];
        }
    }
}

@end
