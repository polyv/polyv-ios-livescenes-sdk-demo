//
//  PLVLCDescBottomView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCDescBottomView.h"
#import <WebKit/WebKit.h>

@interface PLVLCDescBottomView ()<
WKNavigationDelegate
>

@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation PLVLCDescBottomView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.webView];
        [self addSubview:self.line];
    }
    return self;
}

- (void)layoutSubviews {
    self.webView.frame = self.bounds;
    self.line.frame = CGRectMake(0, 0, self.bounds.size.width, 1);
}

#pragma mark - Getter & Setter

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [UIColor blackColor];
    }
    return _line;
}

- (WKWebView *)webView {
    if (_webView == nil) {
        _webView = [[WKWebView alloc] init];
        _webView.opaque = NO;
        _webView.navigationDelegate = self;
        _webView.autoresizingMask = UIViewAutoresizingNone;
        _webView.hidden = YES;
    }
    return _webView;
}

- (void)setContent:(NSString *)content {
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return;
    }
    _content = [content copy];
    [self refreshWebView];
}

#pragma mark - Private Method

- (void)refreshWebView {;
    int verticalPadding = 12;
    int horizontalPadding = 16;
    int fontSize = 16;
    NSString *fontColor = @"#ADADC0";
    
    NSString *content = [self.content stringByReplacingOccurrencesOfString:@"<img src=\"//" withString:@"<img src=\"https://"];
    NSString *htmlContent = [NSString stringWithFormat:@"<html>\n<body style=\" position:absolute;left:%dpx;right:%dpx;top:%dpx;bottom:%dpx;font-size:%d; color:%@;\"><script type='text/javascript'>window.onload = function(){\nvar $img = document.getElementsByTagName('img');\nfor(var p in  $img){\n $img[p].style.width = '100%%';\n$img[p].style.height ='auto'\n}\n}</script>%@</body></html>", horizontalPadding, horizontalPadding, verticalPadding, verticalPadding, fontSize, fontColor, content]; // 图片自适应设备宽，设置字体大小、边距
    
    [self.webView loadHTMLString:htmlContent baseURL:[NSURL URLWithString:@""]];
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
