//
//  PLVLCIframeViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCIframeViewController.h"
#import <WebKit/WebKit.h>

@interface PLVLCIframeViewController ()

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation PLVLCIframeViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.webView.frame = self.view.bounds;
}

#pragma mark - Getter & Setter

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] init];
    }
    return _webView;
}

#pragma mark - Public Method

- (void)loadURLString:(NSString *)urlString {
    if (!urlString || ![urlString isKindOfClass:[NSString class]] || urlString.length == 0) {
        return;;
    }
    
    NSURL *h5Url = [NSURL URLWithString:urlString];
    if (h5Url && [h5Url isKindOfClass:NSURL.class]) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:h5Url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
        [self.webView loadRequest:request];
    }
}

@end
