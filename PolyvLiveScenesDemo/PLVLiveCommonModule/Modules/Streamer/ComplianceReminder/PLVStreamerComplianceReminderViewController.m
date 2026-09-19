//
//  PLVStreamerComplianceReminderViewController.m
//  PolyvLiveScenesDemo
//
//  Created by PLV on 2026/8/31.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVStreamerComplianceReminderViewController.h"

#import "PLVMultiLanguageManager.h"

#import <WebKit/WebKit.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat const kPLVComplianceReminderMaxWidth = 320.0;
static CGFloat const kPLVComplianceReminderMinContentHeight = 120.0;
static CGFloat const kPLVComplianceReminderMaxContentHeight = 260.0;

@interface PLVStreamerComplianceReminderViewController ()<WKNavigationDelegate>

@property (nonatomic, copy) NSString *reminderTitle;
@property (nonatomic, copy) NSString *htmlContent;
@property (nonatomic, copy) void (^disagreeHandler)(void);
@property (nonatomic, copy) void (^agreeHandler)(void);

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *disagreeButton;
@property (nonatomic, strong) UIButton *agreeButton;
@property (nonatomic, strong) CAGradientLayer *agreeButtonGradientLayer;

@end

@implementation PLVStreamerComplianceReminderViewController

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.providesPresentationContextTransitionStyle = YES;
        self.definesPresentationContext = YES;
        if (@available(iOS 13.0, *)) {
            self.modalInPresentation = YES;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];

    [self.view addSubview:self.contentView];
    [self.contentView addSubview:self.titleLabel];
    if (self.htmlContent.length > 0) {
        [self.contentView addSubview:self.webView];
        [self loadHTMLContent];
    }
    [self.contentView addSubview:self.disagreeButton];
    [self.contentView addSubview:self.agreeButton];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    CGFloat contentViewWidth = MIN(kPLVComplianceReminderMaxWidth, CGRectGetWidth(self.view.bounds) - 40.0);
    BOOL hasTitle = self.reminderTitle.length > 0;
    BOOL hasContent = self.htmlContent.length > 0;
    CGFloat titleTop = hasTitle ? 18.0 : 0;
    CGFloat titleHeight = hasTitle ? 44.0 : 0;
    CGFloat contentTop = hasContent ? (hasTitle ? 8.0 : 20.0) : 0;
    CGFloat contentHeight = 0;
    if (hasContent) {
        CGFloat availableHeight = CGRectGetHeight(self.view.bounds) - 180.0;
        contentHeight = MAX(kPLVComplianceReminderMinContentHeight,
                            MIN(kPLVComplianceReminderMaxContentHeight, availableHeight));
    }
    CGFloat buttonTop = hasContent ? 16.0 : (hasTitle ? 10.0 : 20.0);
    CGFloat buttonHeight = 40.0;
    CGFloat bottomGap = 16.0;
    CGFloat contentViewHeight = titleTop + titleHeight + contentTop + contentHeight + buttonTop + buttonHeight + bottomGap;

    self.contentView.bounds = CGRectMake(0, 0, contentViewWidth, contentViewHeight);
    self.contentView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    self.titleLabel.frame = CGRectMake(20.0, titleTop, contentViewWidth - 40.0, titleHeight);
    self.webView.frame = hasContent ? CGRectMake(16.0,
                                                  CGRectGetMaxY(self.titleLabel.frame) + contentTop,
                                                  contentViewWidth - 32.0,
                                                  contentHeight) : CGRectZero;

    CGFloat buttonWidth = (contentViewWidth - 16.0 * 2 - 12.0) / 2.0;
    CGFloat buttonY = contentViewHeight - bottomGap - buttonHeight;
    self.disagreeButton.frame = CGRectMake(16.0, buttonY, buttonWidth, buttonHeight);
    self.agreeButton.frame = CGRectMake(CGRectGetMaxX(self.disagreeButton.frame) + 12.0,
                                        buttonY,
                                        buttonWidth,
                                        buttonHeight);
    self.agreeButtonGradientLayer.frame = self.agreeButton.bounds;
}

#pragma mark - [ Public Method ]

+ (instancetype)complianceReminderControllerWithTitle:(NSString *)title
                                               content:(NSString *)content
                                      disagreeHandler:(void (^)(void))disagreeHandler
                                         agreeHandler:(void (^)(void))agreeHandler {
    PLVStreamerComplianceReminderViewController *viewController = [[self alloc] init];
    viewController.reminderTitle = [title isKindOfClass:[NSString class]] ? title : @"";
    viewController.htmlContent = [content isKindOfClass:[NSString class]] ? content : @"";
    viewController.disagreeHandler = disagreeHandler;
    viewController.agreeHandler = agreeHandler;
    return viewController;
}

#pragma mark - [ Private Method ]

- (void)loadHTMLContent {
    NSString *htmlString = [NSString stringWithFormat:
                            @"<meta name=\"viewport\" content=\"width=device-width,initial-scale=1.0,maximum-scale=1.0\">"
                            "<style>html,body{margin:0;padding:0;background:transparent;color:rgba(255,255,255,.8);font:14px -apple-system,BlinkMacSystemFont,sans-serif;word-wrap:break-word;}img,video{max-width:100%%;height:auto;}a{color:#3399FF;}</style>"
                            "%@<div style=\"height:24px;width:100%%;clear:both;\"></div>",
                            self.htmlContent];
    [self.webView loadHTMLString:htmlString baseURL:nil];
}

#pragma mark - [ WKNavigationDelegate ]

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
 decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    BOOL userClickedLink = navigationAction.navigationType == WKNavigationTypeLinkActivated;
    BOOL openedInNewWindow = navigationAction.targetFrame == nil;
    if (userClickedLink || openedInNewWindow) {
        NSURL *url = navigationAction.request.URL;
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - [ Action ]

- (void)disagreeButtonAction {
    [self dismissViewControllerAnimated:NO completion:^{
        if (self.disagreeHandler) {
            self.disagreeHandler();
        }
    }];
}

- (void)agreeButtonAction {
    [self dismissViewControllerAnimated:NO completion:^{
        if (self.agreeHandler) {
            self.agreeHandler();
        }
    }];
}

#pragma mark - [ Getter ]

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = PLV_UIColorFromRGB(@"#2C2C2C");
        _contentView.layer.cornerRadius = 8.0;
        _contentView.layer.masksToBounds = YES;
    }
    return _contentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = self.reminderTitle;
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.preferences.javaScriptEnabled = NO;
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        _webView.navigationDelegate = self;
        _webView.opaque = NO;
        _webView.backgroundColor = UIColor.clearColor;
        _webView.scrollView.backgroundColor = UIColor.clearColor;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _webView;
}

- (UIButton *)disagreeButton {
    if (!_disagreeButton) {
        _disagreeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _disagreeButton.layer.cornerRadius = 4.0;
        _disagreeButton.layer.borderWidth = 1.0;
        _disagreeButton.layer.borderColor = PLV_UIColorFromRGB(@"#0080FF").CGColor;
        _disagreeButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0];
        [_disagreeButton setTitle:PLVLocalizedString(@"不同意") forState:UIControlStateNormal];
        [_disagreeButton setTitleColor:PLV_UIColorFromRGB(@"#3399FF") forState:UIControlStateNormal];
        [_disagreeButton addTarget:self action:@selector(disagreeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _disagreeButton;
}

- (UIButton *)agreeButton {
    if (!_agreeButton) {
        _agreeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _agreeButton.layer.cornerRadius = 4.0;
        _agreeButton.layer.masksToBounds = YES;
        _agreeButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0];
        [_agreeButton setTitle:PLVLocalizedString(@"同意") forState:UIControlStateNormal];
        [_agreeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_agreeButton.layer insertSublayer:self.agreeButtonGradientLayer atIndex:0];
        [_agreeButton addTarget:self action:@selector(agreeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _agreeButton;
}

- (CAGradientLayer *)agreeButtonGradientLayer {
    if (!_agreeButtonGradientLayer) {
        _agreeButtonGradientLayer = [CAGradientLayer layer];
        _agreeButtonGradientLayer.colors = @[(id)PLV_UIColorFromRGB(@"#0080FF").CGColor,
                                             (id)PLV_UIColorFromRGB(@"#3399FF").CGColor];
        _agreeButtonGradientLayer.startPoint = CGPointMake(0, 0.5);
        _agreeButtonGradientLayer.endPoint = CGPointMake(1, 0.5);
    }
    return _agreeButtonGradientLayer;
}

@end
