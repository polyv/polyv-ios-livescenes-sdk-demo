//
//  PLVInteractLatestGenericView.m
//  PolyvLiveScenesDemo
//
//  最新互动页容器视图（叠加在原互动页之上）
//

#import "PLVInteractLatestGenericView.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

static NSString *const kPLVInteractLatestWeiXinUniversalLinks = @"https://help.wechat.com/app/"; // 微信 Universal Links；scheme weixin://

@interface PLVInteractLatestGenericView () <
WKNavigationDelegate,
PLVInteractWebViewBridgeDelegate>

/// UI
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) WKWebView *webView;

/// 数据
@property (nonatomic, assign) BOOL forbidRotateNow; //此时是否不允许转屏
@property (nonatomic, strong) PLVInteractWebViewBridge *webViewBridge;
@property (nonatomic, assign) BOOL webviewLoadFinish; //webview 是否已加载完成
@property (nonatomic, assign) BOOL webviewLoadFaid; //webview 是否加载失败
@property (nonatomic, assign) BOOL isLiveRoom; //是否是直播的房间
@property (nonatomic, assign) PLVInteractGenericViewLiveType liveType; //直播场景
@property (nonatomic, assign) BOOL urlLoadSkipped; // 加载链接跳过

@end

@implementation PLVInteractLatestGenericView

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    PLV_LOG_INFO(PLVConsoleLogModuleTypeInteract, @"%s",__FUNCTION__);
}

- (instancetype)initWithLiveType:(PLVInteractGenericViewLiveType)liveType liveRoom:(BOOL)liveRoom {
    if (self = [super init]) {
        self.isLiveRoom = liveRoom;
        self.liveType = liveType;
        [self setupData];
        [self setupUI];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)loadOnlineInteract{
    if (![PLVRoomDataManager sharedManager].roomData.channelInfo) {
        self.urlLoadSkipped = YES;
        return;
    }
    [self.webView stopLoading];
    
    NSString *urlString = [NSString stringWithFormat:@"%@?livePlayBack=%@", PLVLiveConstantsInteractLatestWebViewURL, @(!self.isLiveRoom)];
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL enableSecurity = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSInteger security = enableSecurity ? ([PLVFSignConfig sharedInstance].encryptType == PLVEncryptType_SM2 ? 2 : 1) : 0;
    NSString *language = ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) ? @"zh_CN" : @"en";
    urlString = [urlString stringByAppendingFormat:@"&security=%ld&resourceAuth=%d&secureApi=%d&lang=%@", security, (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), language];
    NSURL *interactURL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:interactURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
    [self layoutSelfView];
}

- (void)updateUserInfo {
    if (self.urlLoadSkipped) {
        self.urlLoadSkipped = NO;
        [self loadOnlineInteract];
    }
    NSDictionary *userInfo = [self getUserInfo];
    [self.webViewBridge updateNativeAppParamsInfo:userInfo];
}

- (void)openInteractAppWithEventName:(NSString *)eventName {
    if ([PLVFdUtil checkStringUseable:eventName]) {
        [self.webViewBridge callWebViewEvent:@{@"event" : eventName}];
    }
}

#pragma mark - [ Private Method ]

- (void)setupData {
    self.keepInteractViewTop = YES;
    
    self.webViewBridge = [[PLVInteractWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
    
    [self addSubview:self.webView];
    [self.webView addSubview:self.closeBtn];
}

- (void)layoutSelfView {
    [self layoutWebviewFrame];
    
    float topPadding = [PLVFdUtil isiPhoneXSeries] ? 30.0 : 10.0;
    CGFloat originX = self.webView.frame.size.width - 11.0 - 28.0;
    CGFloat originY = 11.0 + topPadding;
    self.closeBtn.frame = CGRectMake(originX, originY, 28.0, 28.0);
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

- (void)showWebView:(BOOL)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = !show;
        if (show && self.keepInteractViewTop) {
            [self.superview bringSubviewToFront:self]; /// 移至最顶层
        } else if (!show) {
            [self updateForbidRotateNow:NO];
            [PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate = NO;
        }
    });
}

- (void)updateForbidRotateNow:(BOOL)forbidRotateNow {
    _forbidRotateNow = forbidRotateNow;
    if ([PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate == NO) { // 若原本是‘允许转屏’
        if (forbidRotateNow == YES &&
            [UIDevice currentDevice].orientation != UIDeviceOrientationPortrait) {
            // 收到需要 ‘禁止转屏’ 时，将检查当前设备方向，若不是竖屏，则强制转为竖屏
            [PLVFdUtil changeDeviceOrientationToPortrait];
        }
        // 更新 triviaCardUnableRotate 值
        [PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate = forbidRotateNow;
    }
    // 注: 若原本是‘不可转屏’，则直到 [closeWebview] 被调用，都将保持不可转屏，避免部分交互页面不支持转屏
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
        @"platformPublicKey" : [NSString stringWithFormat:@"%@", [PLVFSignConfig sharedInstance].serverSM2PublicKey],
        @"userPrivateKey" : [NSString stringWithFormat:@"%@", [PLVFSignConfig sharedInstance].clientSM2PrivateKey]
    };
    
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    [mutableDict setObject:userInfo forKey:@"userInfo"];
    [mutableDict setObject:channelInfo forKey:@"channelInfo"];
    [mutableDict setObject:sm2Key forKey:@"sm2Key"];
    [mutableDict addEntriesFromDictionary:sessionDict];
    if (roomData.menuInfo.promotionInfo) {
        [mutableDict setObject:roomData.menuInfo.promotionInfo forKey:@"promotionInfo"];
    }
    NSString *liveScene = self.liveType == PLVInteractGenericViewLiveTypeLC ? @"0" : @"1";
    [mutableDict setObject:liveScene forKey:@"liveScene"]; // 0 表示云课堂场景，1 表示直播带货场景
    NSString *chatToken = [PLVSocketManager sharedManager].chatToken;
    if ([PLVFdUtil checkStringUseable:chatToken]) {
        [mutableDict setObject:chatToken forKey:@"chatToken"];
    }
    
    return mutableDict;
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
        if (@available(iOS 14.0, *)) {
    #ifdef __IPHONE_14_0
            config.defaultWebpagePreferences.allowsContentJavaScript = YES;
    #endif
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

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

#pragma mark - [ Event ]

- (void)closeButtonAction {
    [self showWebView:NO];
}

#pragma mark - [ Delegate ]

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // 更新 加载状态
    self.webviewLoadFaid = NO;
    self.webviewLoadFinish = YES;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    // 更新 加载状态
    self.webviewLoadFinish = NO;
    self.webviewLoadFaid = YES;
}

#pragma mark PLVInteractWebViewBridgeDelegate

- (void)plvInteractWebViewBridgeShowWebView:(PLVInteractWebViewBridge *)webViewBridge {
    [self showWebView:YES];
}

- (void)plvInteractWebViewBridgeWebViewDidFinish:(PLVInteractWebViewBridge *)webViewBridge {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.closeBtn.hidden = YES;
    });
}

- (void)plvInteractWebViewBridgeCloseWebView:(PLVInteractWebViewBridge *)webViewBridge {
    [self showWebView:NO];
}

- (void)plvInteractWebViewBridge:(PLVInteractWebViewBridge *)webViewBridge openLink:(nonnull NSString *)linkString {
    if (![PLVFdUtil checkStringUseable:linkString]) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeInteract, @"PLVInteractLatestGenericView - linkClick param illegal %@",linkString);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:linkString] options:@{} completionHandler:nil];
    });
}

- (void)plvInteractWebViewBridgeLockPortraitScreen:(PLVInteractWebViewBridge *)webViewBridge {
    [self updateForbidRotateNow:YES];
}

- (NSDictionary *)getAPPInfoInInteractWebViewBridge:(PLVInteractWebViewBridge *)webViewBridge {
    return [self getUserInfo];
}

@end

