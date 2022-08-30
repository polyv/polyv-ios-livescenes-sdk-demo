//
//  PLVCommodityDetailViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCommodityDetailViewController.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <WebKit/WebKit.h>

@interface PLVCommodityDetailViewController ()<WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSURL *commodityURL;

@end

@implementation PLVCommodityDetailViewController

#pragma mark - Life Cycle

- (instancetype)initWithCommodityURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        self.commodityURL = URL;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationPortrait];

    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 44, 44);
    [leftButton setImage:[self imageForCommodityResource:@"plv_commodity_webview_leftBack_btn"] forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -40, 0, 0);
    UIBarButtonItem *barButtonItem =[[UIBarButtonItem alloc] initWithCustomView:leftButton];
    self.navigationItem.leftBarButtonItems = @[barButtonItem];
    
    [self.view addSubview:self.webView];
    [self loadURL];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.webView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

#pragma mark - Getter

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] init];
        _webView.navigationDelegate = self;
    }
    return _webView;
}

#pragma mark - Utils

- (UIImage *)imageForCommodityResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVCommodity" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

#pragma mark - Action

- (void)backAction {
    if (self.navigationController) {
        if ([self.navigationController.viewControllers count] == 1) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvCommodityDetailViewControllerAfterTheBack)]) {
        [self.delegate plvCommodityDetailViewControllerAfterTheBack];
    }
}

- (void)loadURL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.commodityURL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
}

#pragma mark - [ Delegate ]
#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    NSString *scheme = url.scheme;
    if (navigationAction.targetFrame == nil) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        if (![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"about"]) {
            [[UIApplication sharedApplication] openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }
}

@end
