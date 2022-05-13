//
//  PLVInteractGenericView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/12/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVInteractGenericView.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVRoomDataManager.h"

static NSString *const PLVInteractLotteryWinRecordMessageNewCallbackNotification = @"PLVInteractLotteryWinRecordMessageNewCallbackNotification";

@interface PLVInteractGenericView () <
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

@end

@implementation PLVInteractGenericView

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    PLV_LOG_INFO(PLVConsoleLogModuleTypeInteract, @"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupData];
        [self setupUI];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)loadOnlineInteract{
    [self.webView stopLoading];
    NSURL *interactURL = [NSURL URLWithString:PLVLiveConstantsInteractNewWebViewURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:interactURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
    [self layoutSelfView];
}

- (void)loadLocalInteractWithHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL{
    [self.webView stopLoading];
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
    [self layoutSelfView];
}

- (void)updateUserInfo {
    NSDictionary *userInfo = [self getUserInfo];
    [self.webViewBridge updateNativeAppParamsInfo:userInfo];
}

- (void)openLastBulletin {
    [self.webViewBridge callWebViewEvent:@{@"event" : @"SHOW_BULLETIN"}];
}

- (void)openLotteryWinRecord {
    [self.webViewBridge callWebViewEvent:@{@"event" : @"SHOW_LOTTERY_RECORD"}];
}

#pragma mark - [ Private Method ]

- (void)setupData {
    self.keepInteractViewTop = YES;
    
    self.webViewBridge = [[PLVInteractWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
    self.webViewBridge.delegate = self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
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
            [[UIApplication sharedApplication].keyWindow addSubview:self];
            [self.superview bringSubviewToFront:self];/// 移至最顶层
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


#pragma mark - [ Event ]

#pragma mark Action

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
        NSLog(@"PLVInteractGenericWebView - linkClick param illegal %@",linkString);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:linkString]];
    });
}

- (void)plvInteractWebViewBridge:(PLVInteractWebViewBridge *)webViewBridge updateAppStatuWithJSONObject:(id)jsonObject {
    NSDictionary *dict = [self dictionaryFromJSONObject:jsonObject];
    NSString *event = PLV_SafeStringForDictKey(dict, @"event");
    if ([event isEqualToString:@"SHOW_LOTTERY_RECORD"]) { // 中奖记录按钮状态
        NSDictionary *eventDict = PLV_SafeDictionaryForDictKey(dict, @"value");
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVInteractLotteryWinRecordMessageNewCallbackNotification object:nil userInfo:eventDict];
    }
}

- (void)plvInteractWebViewBridgeLockPortraitScreen:(PLVInteractWebViewBridge *)webViewBridge {
    [self updateForbidRotateNow:YES];
}

- (NSDictionary *)getAPPInfoInInteractWebViewBridge:(PLVInteractWebViewBridge *)webViewBridge {
    return [self getUserInfo];
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

@end
