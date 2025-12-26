//
//  PLVSAAICardView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/11/05.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVSAAICardView.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <WebKit/WebKit.h>
#import <PLVLiveScenesSDK/PLVAICardWebViewBridge.h>

static CGFloat kPLVSAAICardViewTitleBarHeight = 30.0;

@interface PLVSAAICardView ()<WKNavigationDelegate, PLVAICardWebViewBridgeDelegate>

#pragma mark UI
@property (nonatomic, strong) UIView *contentView; // 内容容器
@property (nonatomic, strong) UIView *titleBar; // 标题栏
@property (nonatomic, strong) UIImageView *iconImageView; // 左侧图标
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UIButton *minimizeButton; // 缩小按钮
@property (nonatomic, strong) WKWebView *webView; // WebView

#pragma mark Bridge
@property (nonatomic, strong) PLVAICardWebViewBridge *webViewBridge; // WebView Bridge

#pragma mark Data
@property (nonatomic, assign) BOOL isShowing; // 当前是否正在显示
@property (nonatomic, strong, nullable) PLVCommodityModel *commodityModel; // 商品

@end

@implementation PLVSAAICardView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = CGRectGetWidth(self.bounds);
    CGFloat contentHeight = CGRectGetHeight(self.bounds);

    self.contentView.frame = self.bounds;
    self.titleBar.frame = CGRectMake(0, 0, contentWidth, kPLVSAAICardViewTitleBarHeight);
    self.iconImageView.frame = CGRectMake(12, 9, 20, 20);
    CGFloat titleX = CGRectGetMaxX(self.iconImageView.frame) + 8;
    self.titleLabel.frame = CGRectMake(titleX, 0, contentWidth - titleX - 32 - 24, kPLVSAAICardViewTitleBarHeight);
    self.minimizeButton.frame = CGRectMake(contentWidth - 24 - 4, 4, 24, 24);

    if (self.webView) {
        self.webView.frame = CGRectMake(0, kPLVSAAICardViewTitleBarHeight, contentWidth, contentHeight - kPLVSAAICardViewTitleBarHeight);
    }
}

#pragma mark - [ Public Methods ]

- (void)updateWithCommodityModel:(PLVCommodityModel *)commodityModel {
    if (!commodityModel || commodityModel.productId <= 0) {
        return;
    }
    
    if ([PLVFdUtil checkStringUseable:commodityModel.explainStatus] && [commodityModel.explainStatus isEqualToString:@"explaining"] && [PLVRoomDataManager sharedManager].roomData.menuInfo.productAiCardEnabled) {
        self.commodityModel = commodityModel;
        NSString *productId = [NSString stringWithFormat:@"%ld", (long)commodityModel.productId];
        [self showWithProductId:productId];
    } else if (self.commodityModel && (self.commodityModel.productId == commodityModel.productId)) {
        self.commodityModel = nil;
        [self hide:NO notifyWidgetStatus:NO];
    } else {
        // 忽略其他商品变动消息
    }
    
}

- (void)show:(BOOL)animated {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self show:animated];
        });
        return;
    }
    
    // 如果已经在显示，直接返回
    if (self.isShowing) {
        return;
    }
    
    [self notifyWidgetStatusNeedChange:NO];
    
    if (animated) {
        self.hidden = NO;
        self.isShowing = YES;
        [self layoutIfNeeded];
        
        self.contentView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        self.contentView.alpha = 0.0;
        
        [UIView animateWithDuration:0.25
                              delay:0.0
             usingSpringWithDamping:0.85
              initialSpringVelocity:0.8
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.contentView.transform = CGAffineTransformIdentity;
            self.contentView.alpha = 1.0;
        } completion:nil];
    } else {
        self.hidden = NO;
        self.isShowing = YES;
    }
}

- (void)hide:(BOOL)animated notifyWidgetStatus:(BOOL)notifyWidgetStatus {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hide:animated notifyWidgetStatus:notifyWidgetStatus];
        });
        return;
    }
    
    if (!self.isShowing) {
        [self notifyWidgetStatusNeedChange:notifyWidgetStatus];
        return;
    }
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        self.hidden = YES;
        self.isShowing = NO;
        self.contentView.transform = CGAffineTransformIdentity;
        self.contentView.alpha = 1.0;
        [self notifyWidgetStatusNeedChange:notifyWidgetStatus];
    };
    
    if (animated) {
        [self layoutIfNeeded];
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            self.contentView.transform = CGAffineTransformMakeScale(0.01, 0.01);
            self.contentView.alpha = 0.0;
        } completion:^(BOOL finished) {
            completionBlock(finished);
        }];
    } else {
        completionBlock(YES);
    }
}

- (void)hide:(BOOL)animated {
    [self hide:animated notifyWidgetStatus:NO];
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
    
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.titleBar];
    [self.contentView addSubview:self.webView];
    [self.titleBar addSubview:self.iconImageView];
    [self.titleBar addSubview:self.titleLabel];
    [self.titleBar addSubview:self.minimizeButton];

    self.contentView.layer.anchorPoint = CGPointMake(0.0, 0.0);
    self.contentView.layer.position = CGPointMake(0.0, 0.0);
}

- (NSString *)buildURLWithProductId:(NSString *)productId {
    if (![PLVFdUtil checkStringUseable:productId]) {
        return PLVLiveConstantsAICardHTML;
    }
    
    NSString *urlString = PLVLiveConstantsAICardHTML;
    NSString *separator = [urlString containsString:@"?"] ? @"&" : @"?";
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL enableSecurity = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    NSInteger security = enableSecurity ? ([PLVFSignConfig sharedInstance].encryptType == PLVEncryptType_SM2 ? 2 : 1) : 0;
    NSString *language = @"en";
    if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH ) {
        language = @"zh_CN";
    } else if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) {
        language = @"zh_HK";
    } else if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeKO) {
        language = @"ko";
    } else if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeJA) {
        language= @"ja";
    }
    urlString = [urlString stringByAppendingFormat:@"%@productId=%@&security=%ld&resourceAuth=%d&secureApi=%d&lang=%@",separator,productId, security, (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0), language];
    return urlString;
}

- (void)showWithProductId:(NSString *)productId {
    // 确保在主线程执行
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showWithProductId:productId];
        });
        return;
    }
    
    NSString *urlString = [self buildURLWithProductId:productId];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        self.webViewBridge = [[PLVAICardWebViewBridge alloc] initBridgeWithWebView:self.webView webViewDelegate:self];
        self.webViewBridge.delegate = self;
        NSURL *webURL = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
        [self.webView loadRequest:request];
    }
    
    if (self.isShowing) {
        return;
    }
    
    [self show:YES];
}

- (void)notifyWidgetStatusNeedChange:(BOOL)show {
    if (self.delegate && [self.delegate respondsToSelector:@selector(aiCardView:widgetStatusNeedChange:)]) {
        [self.delegate aiCardView:self widgetStatusNeedChange:show];
    }
}

- (NSDictionary *)getUserInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSDictionary *userInfo = @{
        @"nick" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerName],
        @"userId" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerId],
        @"pic" : [NSString stringWithFormat:@"%@", roomData.roomUser.viewerAvatar],
        @"userType" : @"teacher"
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
    
    NSString *chatToken = [PLVSocketManager sharedManager].chatToken;
    if ([PLVFdUtil checkStringUseable:chatToken]) {
        [mutableDict setObject:chatToken forKey:@"chatToken"];
    }
    
    if (roomData.menuInfo.promotionInfo) {
        [mutableDict setObject:roomData.menuInfo.promotionInfo forKey:@"promotionInfo"];
    }
    
    return mutableDict;
}

#pragma mark - [ Getter ]

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [[PLVColorUtil colorFromHexString:@"#000000"] colorWithAlphaComponent:0.4];
        _contentView.layer.cornerRadius = 12;
        _contentView.layer.masksToBounds = YES;
    }
    return _contentView;
}

- (UIView *)titleBar {
    if (!_titleBar) {
        _titleBar = [[UIView alloc] init];
        _titleBar.backgroundColor = [UIColor clearColor];
    }
    return _titleBar;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *icon = [PLVSAUtils imageForLiveroomResource:@"plvsa_ai_card_icon"];
        _iconImageView.image = icon;
    }
    return _iconImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"AI手卡");
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        if (!_titleLabel.font) {
            _titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        }
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
    }
    return _titleLabel;
}

- (UIButton *)minimizeButton {
    if (!_minimizeButton) {
        _minimizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *icon = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_minimize"];
        [_minimizeButton setImage:icon forState:UIControlStateNormal];
        [_minimizeButton addTarget:self action:@selector(minimizeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _minimizeButton;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
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
        _webView.backgroundColor = [UIColor clearColor];
        _webView.scrollView.bounces = NO;
        if(@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _webView;
}

#pragma mark - [ Event ]

- (void)minimizeButtonAction:(UIButton *)sender {
    [self hide:YES notifyWidgetStatus:YES];
}

#pragma mark - [ WKNavigationDelegate ]

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
}

#pragma mark - [ PLVAICardWebViewBridgeDelegate ]

- (NSDictionary *)getAPPInfoInAICardWebViewBridge:(PLVAICardWebViewBridge *)webViewBridge {
    return [self getUserInfo];
}

@end
