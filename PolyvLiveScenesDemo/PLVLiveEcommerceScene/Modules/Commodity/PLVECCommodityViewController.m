//
//  PLVECCommodityViewController.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/1/20.
//  Copyright © 2021 PLV. All rights reserved.
//  商品列表核心类

#import "PLVECCommodityViewController.h"
#import "PLVECUtils.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVECCommodityViewController ()<
UIGestureRecognizerDelegate,
WKNavigationDelegate,
PLVProductWebViewBridgeDelegate
>

/// UI
@property (nonatomic, strong) WKWebView *webView;

/// 数据
@property (nonatomic, strong) PLVProductWebViewBridge *webViewBridge;

@end

@implementation PLVECCommodityViewController

#pragma mark - [ Life Cycle ]

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([PLVECUtils sharedUtils].isLandscape) {
        self.webView.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - 375 , 0, 375, CGRectGetMaxY(self.view.frame));
    } else {
        CGFloat height = 410;
        CGRect frame = CGRectMake(0, CGRectGetHeight(self.view.bounds)-height, CGRectGetWidth(self.view.bounds), height);
        self.webView.frame = frame;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self loadWebView];
    [self.webViewBridge callWebViewEvent:@{@"event" : @"OPEN_PRODUCT"}];
}

#pragma mark - [ Public Method ]

- (void)updateUserInfo {
    NSDictionary *userInfo = [self getUserInfo];
    [self.webViewBridge updateNativeAppParamsInfo:userInfo];
}

#pragma mark - [ Private Method ]

- (void)loadWebView {
    self.webViewBridge = [[PLVProductWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
    
    NSString *urlString = PLVLiveConstantsProductListHTML;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL enableSecurity = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSInteger security = enableSecurity ? ([PLVFSignConfig sharedInstance].encryptType == PLVEncryptType_SM2 ? 2 : 1) : 0;
    NSString *language = ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) ? @"zh_CN" : @"en";
    urlString = [urlString stringByAppendingFormat:@"?security=%ld&resourceAuth=%d&secureApi=%d&lang=%@", security, (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), language];
    NSURL *interactURL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:interactURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
}

- (void)setupUI {
    [self.view addSubview:self.webView];
    // 添加点击关闭按钮关闭页面回调
    __weak typeof(self) weakSelf = self;

    // 添加单击关闭页面手势
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    [tapGestureRecognizer addTarget:self action:@selector(tapAction:)];
    tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapGestureRecognizer];
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
    
    return mutableDict;
}

#pragma mark Getter & Setter

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration * config = [[WKWebViewConfiguration alloc] init];
        if (@available(iOS 13.0, *)) {
            config.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        }
        CGFloat height = 410;
        CGRect frame = CGRectMake(0, CGRectGetHeight(self.view.bounds)-height, CGRectGetWidth(self.view.bounds), height);
        _webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        _webView.opaque = NO;
        _webView.scrollView.bounces = NO;
        if (@available(iOS 11.0,*)) {
            [_webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _webView;
}

#pragma mark - Action

- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - [ Delegate ]

#pragma mark UIGestureRecognizerDelegate

-(BOOL) gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    return touch.view == self.view; // 设置商品列表View不响应手势
}

#pragma mark PLVProductWebViewBridgeDelegate

- (NSDictionary *)getAPPInfoInProductWebViewBridge:(PLVProductWebViewBridge *)webViewBridge {
    return [self getUserInfo];
}

- (void)plvProductWebViewBridge:(PLVProductWebViewBridge *)webViewBridge clickProductButtonWithJSONObject:(id)jsonObject {
    if ([PLVFdUtil checkDictionaryUseable:jsonObject]) {
        [self tapAction:nil];
        
        NSDictionary *data = PLV_SafeDictionaryForDictKey(jsonObject, @"data");
        PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:data];
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvECCommodityViewController:didClickCommodityModel:)]) {
            [self.delegate plvECCommodityViewController:self didClickCommodityModel:model];
        }
    }
}

- (void)plvProductWebViewBridge:(PLVProductWebViewBridge *)webViewBridge showJobDetailWithJSONObject:(id)jsonObject {
    if ([PLVFdUtil checkDictionaryUseable:jsonObject]) {
        [self tapAction:nil];
        NSDictionary *data = PLV_SafeDictionaryForDictKey(jsonObject, @"data");
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvECCommodityViewController:didShowJobDetail:)]) {
            [self.delegate plvECCommodityViewController:self didShowJobDetail:data];
        }
    }
}

@end
