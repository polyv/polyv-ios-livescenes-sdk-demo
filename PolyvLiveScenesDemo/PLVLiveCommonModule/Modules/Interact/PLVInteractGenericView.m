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

static NSString *const PLVInteractUpdateChatButtonCallbackNotification = @"PLVInteractUpdateChatButtonCallbackNotification";
static NSString *const PLVInteractUpdateIarEntranceCallbackNotification = @"PLVInteractUpdateIarEntranceCallbackNotification";
static NSString *const PLVInteractChannelSwitchCallbackNotification = @"PLVLCChatroomFunctionGotNotification";

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
@property (nonatomic, assign) BOOL isLiveRoom; //是否是直播的房间
@property (nonatomic, assign) PLVInteractGenericViewLiveType liveType; //直播场景
@property (nonatomic, assign) BOOL receivedSwitchNotification; //是否已经收到频道开关的通知

@end

@implementation PLVInteractGenericView

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    [self removeObserver];
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
    [self.webView stopLoading];
    
    NSString *urlString = [NSString stringWithFormat:@"%@?livePlayBack=%@", PLVLiveConstantsInteractNewWebViewURL, @(!self.isLiveRoom)];
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL security = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    urlString = [urlString stringByAppendingFormat:@"&security=%d&resourceAuth=%d&secureApi=%d", (security ? 1 : 0), (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0)];
    NSURL *interactURL = [NSURL URLWithString:urlString];
    
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

- (void)openNewPushCardWithDict:(NSDictionary *)dict {
    if ([PLVFdUtil checkDictionaryUseable:dict]) {
        [self.webViewBridge callWebViewEvent:@{@"event" : @"SHOW_PUSH_CARD",
                                               @"data" : dict}];
    }
}

- (void)openRedpackWithChatModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]] ||
        ![model.message isKindOfClass:[PLVRedpackMessage class]]) {
        return;
    }
    
    PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)model.message;
    
    NSMutableDictionary *muDict = [[NSMutableDictionary alloc] init];
    muDict[@"EVENT"] = @"REDPAPER";
    muDict[@"msgSource"] = @"redpaper";
    muDict[@"type"] = redpackMessage.typeString ?: @"";
    muDict[@"content"] = redpackMessage.content ?: @"";
    muDict[@"redCacheId"] = redpackMessage.redCacheId ?: @"";
    muDict[@"redpackId"] = redpackMessage.redpackId ?: @"";
    muDict[@"number"] = @(redpackMessage.number);
    muDict[@"totalAmount"] = @(redpackMessage.totalAmount);
    muDict[@"timestamp"] = [NSString stringWithFormat:@"%lld", (long long)redpackMessage.time];
    
    NSDictionary *userDict = @{@"nick" : (model.user.userName ?: @""),
                               @"pic" : (model.user.avatarUrl ?: @"")};
    muDict[@"user"] = userDict;
    
    [self.webViewBridge callWebViewEvent:@{@"event" : @"OPEN_RED_PAPER",
                                           @"data" : [muDict copy]}];
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
    
    [self addObserver];
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

- (void)updateChannelConfigInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSDictionary *parames = @{@"event" : @"UPDATE_CHANNEL_SWITCH",
                            @"value" :@[@{@"type" : @"watchFeedbackEnabled",
                                            @"enabled" : roomData.watchFeedbackEnabled ? @"Y" : @"N"},
                                       @{@"type" : @"conditionLotteryEnabled",
                                            @"enabled" : roomData.conditionLotteryEnabled ? @"Y" : @"N"}]
    };
    [self.webViewBridge updateChannelConfigInfo:parames];
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
    [mutableDict addEntriesFromDictionary:sessionDict];
    if (roomData.menuInfo.promotionInfo) {
        [mutableDict setObject:roomData.menuInfo.promotionInfo forKey:@"promotionInfo"];
    }
    NSString *liveScene = self.liveType == PLVInteractGenericViewLiveTypeLC ? @"0" : @"1";
    [mutableDict setObject:liveScene forKey:@"liveScene"]; // 0 表示云课堂场景，1 表示直播带货场景

    return mutableDict;
}

#pragma mark - NSNotification
- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interactChannelSwitchCallback:)
                                                 name:PLVInteractChannelSwitchCallbackNotification
                                               object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PLVInteractChannelSwitchCallbackNotification
                                                  object:nil];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeButtonAction {
    [self showWebView:NO];
}

#pragma mark - NSNotification
- (void)interactChannelSwitchCallback:(NSNotification *)notification {
    self.receivedSwitchNotification = YES;
    if (self.webviewLoadFinish) {
        // 更新频道配置
        [self updateChannelConfigInfo];
    }
}

#pragma mark - [ Delegate ]

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // 更新 加载状态
    self.webviewLoadFaid = NO;
    self.webviewLoadFinish = YES;
    if (self.receivedSwitchNotification) {
        // 更新频道配置
        [self updateChannelConfigInfo];
    }
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
    if ([event isEqualToString:@"UPDATE_CHAT_BUTTON"]) { // 更新聊天室按钮
        NSDictionary *eventDict = PLV_SafeDictionaryForDictKey(dict, @"value");
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVInteractUpdateChatButtonCallbackNotification object:nil userInfo:eventDict];
    } else if ([event isEqualToString:@"UPDATE_IAR_PENDANT"]) { // 更新挂件控件
        NSDictionary *eventDict = PLV_SafeDictionaryForDictKey(dict, @"value");
        plv_dispatch_main_async_safe(^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(plvInteractGenericView:updateLotteryWidget:)]) {
                [self.delegate plvInteractGenericView:self updateLotteryWidget:eventDict];
            }
        })
    }
}

- (void)plvInteractWebViewBridgeLockPortraitScreen:(PLVInteractWebViewBridge *)webViewBridge {
    [self updateForbidRotateNow:YES];
}

- (void)plvInteractWebViewBridge:(PLVInteractWebViewBridge *)webViewBridge callAppEvent:(id)jsonObject {
    NSDictionary *dict = [self dictionaryFromJSONObject:jsonObject];
    NSString *event = PLV_SafeStringForDictKey(dict, @"event");
    if ([event isEqualToString:@"openLink"]) { // 打开卡片推送链接
        NSDictionary *valueDcit = PLV_SafeDictionaryForDictKey(dict, @"value");
        NSString *type = PLV_SafeStringForDictKey(valueDcit, @"type");
        NSString *urlString = PLV_SafeStringForDictKey(valueDcit, @"url");
        BOOL insideLoad = [type isEqualToString:@"inside"];
        if ([PLVFdUtil checkStringUseable:urlString]) {
            NSURL *url = [NSURL URLWithString:urlString];
            plv_dispatch_main_async_safe(^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(plvInteractGenericView:loadWebViewURL:insideLoad:)]) {
                    [self.delegate plvInteractGenericView:self loadWebViewURL:url insideLoad:insideLoad];
                }
            })
        }
    } else if ([event isEqualToString:@"UPDATE_IAR_ENTRANCE"]) { // 更新互动入口状态
        NSDictionary *eventDict = PLV_SafeDictionaryForDictKey(dict, @"value");
        [[NSNotificationCenter defaultCenter]postNotificationName:PLVInteractUpdateIarEntranceCallbackNotification object:nil userInfo:eventDict];
    } else if ([event isEqualToString:@"changeRedpackStatus"]) { // 打开红包
        NSDictionary *valueDcit = PLV_SafeDictionaryForDictKey(dict, @"value");
        NSString *redpackId = PLV_SafeStringForDictKey(valueDcit, @"redpackId");
        NSString *status = PLV_SafeStringForDictKey(valueDcit, @"status");
        if ([PLVFdUtil checkStringUseable:redpackId] &&
            [PLVFdUtil checkStringUseable:status]) {
            plv_dispatch_main_async_safe(^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(plvInteractGenericView:didOpenRedpack:status:)]) {
                    [self.delegate plvInteractGenericView:self didOpenRedpack:redpackId status:status];
                }
            })
        }
    }
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
