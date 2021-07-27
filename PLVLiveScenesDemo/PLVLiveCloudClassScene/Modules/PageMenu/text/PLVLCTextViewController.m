//
//  PLVLCTextViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCTextViewController.h"
#import <WebKit/WebKit.h>

@interface PLVLCTextViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation PLVLCTextViewController

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
        _webView.backgroundColor = [UIColor clearColor];
        _webView.opaque = false;
        _webView.navigationDelegate = self;
    }
    return _webView;
}

#pragma mark - Public Method

- (void)loadHtmlWithContent:(NSString *)content {
    if (content && [content isKindOfClass:[NSString class]] && content.length > 0) {
        NSString *htmlString = [self html:content];
        [self.webView loadHTMLString:htmlString baseURL:nil];
    }
}

#pragma mark - Private Method

- (NSString *)html:(NSString *)content {
    NSString *processedContent = [content stringByReplacingOccurrencesOfString:@"<img src=\"//" withString:@"<img src=\"https://"];
    processedContent = [processedContent stringByReplacingOccurrencesOfString:@"<img " withString:@"<img style=\"width:100%\""];
    processedContent = [processedContent stringByReplacingOccurrencesOfString:@"<table>" withString:@"<table border=\"1\" rules=all style=\"color:#ADADC0;\">"];
    processedContent = [processedContent stringByReplacingOccurrencesOfString:@"<li>" withString:@"<li style=\"color:#ADADC0;\">"];
    processedContent = [processedContent stringByReplacingOccurrencesOfString:@"<td>" withString:@"<td width=\"36\">"];
    processedContent = [processedContent stringByReplacingOccurrencesOfString:@"<p>" withString:@"<p style=\"word-break:break-all;color:#ADADC0;\">"];
    processedContent = [processedContent stringByReplacingOccurrencesOfString:@"<div>" withString:@"<div style=\"word-break:break-all;color:#ADADC0;\">"];
    /*
    NSString *header = @"<!DOCTYPE html><html><head><meta charset=\"utf-8\" /><title></title></head><body>";
    NSString *bodyEnd = @"</body></html>";
    NSString *resultString = [NSString stringWithFormat:@"%@%@%@", header, processedContent, bodyEnd];
     */
    return processedContent;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation; {
    self.webView.hidden = NO;
    
    // 滚到顶部
    NSString *scriptString = @"window.scrollTo(0,0);";
    [self.webView evaluateJavaScript:scriptString completionHandler:nil];
    
    // 禁止双指缩放
    NSString *noScaleJS = @"var script = document.createElement('meta');"
    "script.name = 'viewport';"
    "script.content=\"user-scalable=no,width=device-width,initial-scale=1.0,maximum-scale=1.0\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    [self.webView evaluateJavaScript:noScaleJS completionHandler:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.targetFrame == nil) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
