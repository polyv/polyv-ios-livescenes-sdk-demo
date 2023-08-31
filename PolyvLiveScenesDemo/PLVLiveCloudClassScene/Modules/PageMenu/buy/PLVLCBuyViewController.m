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
@property (nonatomic, strong) UIView *contentBackgroudView;

/// 数据
@property (nonatomic, strong) PLVProductWebViewBridge *webViewBridge;

@end

@implementation PLVLCBuyViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self loadWebView];
}

// 规避左右页面切换时webview布局异常问题
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.webView layoutSubviews];
    [self.webViewBridge callWebViewEvent:@{@"event" : @"OPEN_PRODUCT"}];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        self.webView.frame = CGRectMake(self.contentBackgroudView.bounds.size.width - 375, 0, 375, self.contentBackgroudView.bounds.size.height);
    } else {
        self.contentBackgroudView.frame = self.view.bounds;
        self.webView.frame = self.contentBackgroudView.bounds;
    }
}

#pragma mark - [ Public Method ]

- (void)updateUserInfo {
    NSDictionary *userInfo = [self getUserInfo];
    [self.webViewBridge updateNativeAppParamsInfo:userInfo];
}

- (void)rollbackProductPageContentView {
    [self.contentBackgroudView removeFromSuperview];
    [self.view addSubview:self.contentBackgroudView];
    self.contentBackgroudView.frame = self.view.bounds;
    self.contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)showInLandscape {
    [self viewWillLayoutSubviews];
    [self.webViewBridge callWebViewEvent:@{@"event" : @"OPEN_PRODUCT"}];
}

#pragma mark - [ Private Method ]

- (void)loadWebView {
    self.webViewBridge = [[PLVProductWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
    
    NSString *urlString = PLVLiveConstantsProductListHTML;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL security = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    urlString = [urlString stringByAppendingFormat:@"?security=%d&resourceAuth=%d&secureApi=%d", (security ? 1 : 0), (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0)];
    NSURL *interactURL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:interactURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
}

- (void)setupUI {
    [self.view addSubview:self.contentBackgroudView];
    [self.contentBackgroudView addSubview:self.webView];
    self.contentBackgroudView.frame = self.view.bounds;
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
        @"webVersion" : @"0.5.0"
    };
    
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    [mutableDict setObject:userInfo forKey:@"userInfo"];
    [mutableDict setObject:channelInfo forKey:@"channelInfo"];
    if (roomData.menuInfo.promotionInfo) {
        [mutableDict setObject:roomData.menuInfo.promotionInfo forKey:@"promotionInfo"];
    }
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
        if (@available(iOS 11.0,*)) {
            [_webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _webView;
}

- (UIView *)contentBackgroudView {
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc] init];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [_contentBackgroudView addGestureRecognizer:tap];
    }
    return _contentBackgroudView;
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

#pragma mark - Action

- (void)tapAction {
    [self rollbackProductPageContentView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCCloseProductViewInViewController:)]) {
        [self.delegate plvLCCloseProductViewInViewController:self];
    }
}

@end
