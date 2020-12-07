//
//  PLVECLiveIntroductionCardView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECLiveIntroductionCardView.h"
#import "PLVECUtils.h"

@interface PLVECLiveIntroductionCardView () <WKNavigationDelegate>

@end

@implementation PLVECLiveIntroductionCardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLB.text = @"直播介绍";
        self.iconImgView.image = [PLVECUtils imageForWatchResource:@"plv_liveInfo_icon"];
        
        self.backgroundLable = [[UILabel alloc] init];
        self.backgroundLable.text = @"暂无直播介绍～";
        self.backgroundLable.textColor = UIColor.blackColor;
        self.backgroundLable.textAlignment = NSTextAlignmentCenter;
        self.backgroundLable.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.backgroundLable];
        
        self.webView = [[WKWebView alloc] init];
        self.webView.navigationDelegate = self;
        self.webView.opaque = NO;
        self.webView.scrollView.scrollEnabled = NO;
        self.webView.scrollView.showsVerticalScrollIndicator = NO;
        self.webView.scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:self.webView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundLable.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds)-40, 14);
    self.backgroundLable.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    
    CGFloat originY = CGRectGetMaxY(self.iconImgView.frame);
    self.webView.frame = CGRectMake(15, originY+10, CGRectGetWidth(self.bounds)-30, CGRectGetHeight(self.bounds)-originY-20);
}

#pragma mark - Setter

- (void)setHtmlCont:(NSString *)htmlCont {
    _htmlCont = htmlCont;
    if ([htmlCont isKindOfClass:NSString.class] && htmlCont.length) {
        self.backgroundLable.hidden = YES;
        [self.webView loadHTMLString:[self processHtml:htmlCont] baseURL:[NSURL URLWithString:@""]];
    }
}

#pragma mark - Private

- (NSString *)processHtml:(NSString *)htmlCont {
    /// 图片自适应设备宽，边距，禁用双指缩放
    int offset = 0;
    int fontSize = 12;
    NSString *content = [htmlCont stringByReplacingOccurrencesOfString:@"<img src=\"//" withString:@"<img src=\"https://"];
    content = [NSString stringWithFormat:@"<html>\n<body style=\"position:absolute;left:%dpx;right:%dpx;top:%dpx;bottom:%dpx;font-size:%d\"><script type='text/javascript'>window.onload = function(){\nvar $img = document.getElementsByTagName('img');\nfor(var p in  $img){\n $img[p].style.width = '100%%';\n$img[p].style.height ='auto'\n}\n}</script>%@</body></html>", offset, offset, offset, offset, fontSize, content];
    return content;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation; {
    /// 禁止双指缩放
    NSString *noScaleJS = @"var script = document.createElement('meta');"
    "script.name = 'viewport';"
    "script.content=\"user-scalable=no,width=device-width,initial-scale=1.0,maximum-scale=1.0\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    [webView evaluateJavaScript:noScaleJS completionHandler:nil];
    
    __weak typeof(self)weakSelf = self;
    [webView evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        //NSLog(@"scrollHeight: %.2f",[result floatValue]);
        if ([weakSelf.liDelegate respondsToSelector:@selector(cardView:didLoadWebViewHeight:)]) {
            [weakSelf.liDelegate cardView:weakSelf didLoadWebViewHeight:[result floatValue]];
        }
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        webView.hidden = NO;
        [webView.scrollView setContentOffset:CGPointZero animated:NO];
    });
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.targetFrame == nil) {
        if ([self.liDelegate respondsToSelector:@selector(cardView:didInteractWithURL:)]) {
            [self.liDelegate cardView:self didInteractWithURL:navigationAction.request.URL];
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
