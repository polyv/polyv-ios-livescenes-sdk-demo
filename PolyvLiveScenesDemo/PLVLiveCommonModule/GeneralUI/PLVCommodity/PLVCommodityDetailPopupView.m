//
//  PLVCommodityDetailPopupView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/9/29.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVCommodityDetailPopupView.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVProductDetailWebViewBridge.h>

@interface PLVCommodityDetailPopupView () <WKNavigationDelegate, PLVProductDetailWebViewBridgeDelegate>

/// 商品ID
@property (nonatomic, copy) NSString *productId;

/// WebView
@property (nonatomic, strong) WKWebView *webView;

/// WebView Bridge
@property (nonatomic, strong) PLVProductDetailWebViewBridge *webViewBridge;

@end

@implementation PLVCommodityDetailPopupView

#pragma mark - [ Public Methods ]

- (void)showWithProductId:(NSString *)productId {
    if (![PLVFdUtil checkStringUseable:productId]) {
        return;
    }
    
    // 设置商品ID
    _productId = [productId copy];
    
    self.hidden = NO;
    // 开始加载商品详情
    [self loadProductDetail];
}

- (void)hide {
    // 移除WebView
    [self.webView removeFromSuperview];
    self.webView = nil;
    
    // 移除WebView Bridge
    self.webViewBridge = nil;
    self.hidden = YES;
}

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.webView.frame = self.bounds;
}

#pragma mark - [ Private Method ]

- (void)setupWebView {
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    WKWebViewConfiguration * config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = userContentController;
    config.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        config.dataDetectorTypes = WKDataDetectorTypeNone;
        // WKAudiovisualMediaTypeNone 音视频的播放不需要用户手势触发, 即为自动播放
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    } else {
        if (@available(iOS 9.0, *)) {
            config.requiresUserActionForMediaPlayback = NO;
        }
    }
    if (@available(iOS 13.0, *)) {
        config.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
    }
    if (@available(iOS 14.0, *)) {
        config.defaultWebpagePreferences.allowsContentJavaScript = YES;
    }
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    self.webView .navigationDelegate = self;
    self.webView .autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    self.webView .contentMode = UIViewContentModeRedraw;
    self.webView .opaque = NO;
    self.webView .scrollView.bounces = NO;
    if(@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    [self addSubview:self.webView];
    self.webView.frame = self.bounds;
    
    // 设置WebView Bridge
    self.webViewBridge = [[PLVProductDetailWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
}

- (void)loadProductDetail {
    if (!self.productId || self.productId.length == 0) {
        NSLog(@"商品ID不能为空");
        return;
    }
    
    [self setupWebView];
    
    // 构建URL
    NSString *baseURL = PLVLiveConstantsProductDetailHTML;
    NSString *urlString = [NSString stringWithFormat:@"%@?productId=%@", baseURL, self.productId];
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL enableSecurity = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSInteger security = enableSecurity ? ([PLVFSignConfig sharedInstance].encryptType == PLVEncryptType_SM2 ? 2 : 1) : 0;
    NSString *language = ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) ? @"zh_CN" : @"en";
    urlString = [urlString stringByAppendingFormat:@"&security=%ld&resourceAuth=%d&secureApi=%d&lang=%@", security, (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), language];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
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

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self){
        return nil;
    }
    return hitView;
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
    
    if ([PLVFdUtil checkStringUseable:jsonObject]){
        NSData *jsonData = [jsonObject dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        return dataDict;
    }
    
    return nil;
}


#pragma mark - [ Action ]

#pragma mark - [ WKNavigationDelegate ]

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
}

#pragma mark - [ PLVProductDetailWebViewBridgeDelegate ]

- (NSDictionary *)getAPPInfoInProductDetailWebViewBridge:(PLVProductDetailWebViewBridge *)webViewBridge {
    // 返回APP信息
    return [self getUserInfo];
}

- (void)closeCurrentWebviewInProductDetailWebViewBridge:(PLVProductDetailWebViewBridge *)webViewBridge {
    // 关闭当前WebView回调
    [self hide];
}

- (void)plvProductDetailWebViewBridge:(PLVProductDetailWebViewBridge *)webViewBridge clickProductButtonWithJSONObject:(id)jsonObject {
    NSDictionary *dict = [self dictionaryFromJSONObject:jsonObject];
    NSDictionary *data = PLV_SafeDictionaryForDictKey(dict, @"data");
    
    if ([PLVFdUtil checkDictionaryUseable:data]) {
        PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:data];
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvCommodityDetailPopupView:didClickProductButton:)]) {
            
            [self.delegate plvCommodityDetailPopupView:self didClickProductButton:model];
        }
    }
    
    // 点击购买按钮回调
    
}

@end
