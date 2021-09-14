//
//  PLVLSChannelInfoSheet.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/3.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSChannelInfoSheet.h"
#import "PLVLSChannelInfoTopView.h"
#import "PLVRoomDataManager.h"
#import "PLVLSUtils.h"
#import "PLVPhotoBrowser.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <PLVLiveScenesSDK/PLVLiveVideoChannelMenuInfo.h>
#import <WebKit/WebKit.h>

static CGFloat kTopViewHeight = 100.0; // 频道信息摘要视图高度
static CGFloat kTopViewWidth = 350.0; // 频道信息摘要视图宽度

@interface PLVLSChannelInfoSheet ()<
WKNavigationDelegate
>

/// UI
@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIView *splitLine; // 标题底部分割线
@property (nonatomic, strong) PLVLSChannelInfoTopView *topView; // 频道信息摘要视图
@property (nonatomic, strong) WKWebView *webView; // 展示直播简介webview控件
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser

/// 数据
@property (nonatomic, copy) NSString *content; // 直播简介文本
@property (nonatomic, copy) NSMutableArray *imageArray;

@end

@implementation PLVLSChannelInfoSheet

#pragma mark - Life Cycle

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight {
    self = [self initWithSheetHeight:sheetHeight showSlider:YES];
    return self;
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight showSlider:(BOOL)showSlider {
    self = [super initWithSheetHeight:sheetHeight showSlider:YES];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.splitLine];
        [self.contentView addSubview:self.webView];
        [self.webView.scrollView addSubview:self.topView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat sidePad = PLVLSUtils.safeSidePad;
    self.sheetTitleLabel.frame = CGRectMake(sidePad + 28, 12, self.bounds.size.width - (sidePad + 28) * 2, 40);
    self.splitLine.frame = CGRectMake(CGRectGetMinX(self.sheetTitleLabel.frame), CGRectGetMaxY(self.sheetTitleLabel.frame), self.sheetTitleLabel.frame.size.width, 1);
    
    CGFloat webViewOriginY = CGRectGetMaxY(self.splitLine.frame);
    self.webView.frame = CGRectMake(sidePad, webViewOriginY, self.bounds.size.width - sidePad * 2, self.sheetHight - webViewOriginY);
    self.topView.frame = CGRectMake(20, 0, kTopViewWidth, kTopViewHeight);
}

#pragma mark - Getter

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sheetTitleLabel.text = @"频道信息";
    }
    return _sheetTitleLabel;
}

- (UIView *)splitLine {
    if (!_splitLine) {
        _splitLine = [[UIView alloc] init];
        _splitLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.1];
    }
    return _splitLine;
}

- (WKWebView *)webView {
    if (_webView == nil) {
        _webView = [[WKWebView alloc] init];
        _webView.opaque = NO;
        _webView.navigationDelegate = self;
        _webView.autoresizingMask = UIViewAutoresizingNone;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
        _webView.hidden = YES;
    }
    return _webView;
}

- (PLVLSChannelInfoTopView *)topView {
    if (!_topView) {
        _topView = [[PLVLSChannelInfoTopView alloc] init];
    }
    return _topView;
}

- (NSMutableArray *)imageArray {
    if (!_imageArray) {
        _imageArray = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return _imageArray;
}

- (PLVPhotoBrowser *)photoBrowser {
    if (!_photoBrowser) {
        _photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return _photoBrowser;
}

#pragma mark - Public Method

- (void)updateChannelInfoWithData:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    NSString *titleString = menuInfo.name;
    if (!titleString || ![titleString isKindOfClass:[NSString class]]) {
        titleString = @"";
    }
        
    NSString *dateString = menuInfo.startTime;
    if (!dateString || ![dateString isKindOfClass:[NSString class]] || dateString.length == 0) {
        dateString = @"无";
    }
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    [self.topView setTitle:titleString date:dateString channelId:roomData.channelId];
    
    NSArray<PLVLiveVideoChannelMenu*> *channelMenus = menuInfo.channelMenus;
    if (!menuInfo.channelMenus || ![menuInfo.channelMenus isKindOfClass:[NSArray class]] ||
        [menuInfo.channelMenus count] == 0 ) {
        return;
    }
    
    NSString *content = nil;
    for (int i = 0; i < [channelMenus count]; i++) {
        PLVLiveVideoChannelMenu *menu = channelMenus[i];
        if ([menu.menuType isEqualToString:@"desc"]) {
            content = menu.content;
            break;
        }
    }
    [self refreshWebViewWithContent:content];
}

- (void)refreshWebViewWithContent:(NSString *)content {;
    
    int verticalPadding = 0;
    int leftPadding = 52 - 16;
    int rightPadding = 0;
    int fontSize = 12;
    NSString *fontColor = @"#CFD1D6";
    
    if (!content || ![content isKindOfClass:[NSString class]]) {
        self.content = @"";
    } else {
        self.content = [content stringByReplacingOccurrencesOfString:@"<img src=\"//" withString:@"<img src=\"https://"];
    }
    
    NSString *htmlContent = [NSString stringWithFormat:@"<html>\n<body style=\" position:absolute;left:%dpx;right:%dpx;top:%dpx;bottom:%dpx;font-size:%d; color:%@;\"><script type='text/javascript'>window.onload = function(){\nvar $img = document.getElementsByTagName('img');\nfor(var p in  $img){\n $img[p].style.width = '100%%';\n$img[p].style.height ='auto'\n}\n}</script><div style=\"height:%fpx; width:%fpx;\"> </div>%@</body></html>", leftPadding, rightPadding, verticalPadding, verticalPadding, fontSize, fontColor,kTopViewHeight,kTopViewWidth,self.content]; // 图片自适应设备宽，设置字体大小、边距;在webview顶部插入空白view
    
    [self.webView loadHTMLString:htmlContent baseURL:[NSURL URLWithString:@""]];
}

#pragma mark - Privat

// 获取html中的图片URL
- (void)getImages {
    [self.imageArray removeAllObjects];
    __weak typeof(self) weakSelf = self;
    [self nodeCountOfTag:@"img" withNodeCountCallback:^(NSInteger count) {
        for (int i = 0; i < count; ++i) {
            NSString* jsStr = [NSString stringWithFormat:@"document.getElementsByTagName('img')[%d].src", i];
            [weakSelf.webView evaluateJavaScript:jsStr completionHandler:^(id object, NSError *error) {
                if (!error) {
                   [weakSelf.imageArray addObject:(NSString*)object];
                }
            }];
        }
    }];
}

// 获取某个标签的结点数量
- (void)nodeCountOfTag:(NSString*)tag withNodeCountCallback:(void(^)(NSInteger))callback {
    NSString* jsStr = [NSString stringWithFormat:@"document.getElementsByTagName('%@').length", tag];
    [self.webView evaluateJavaScript:jsStr completionHandler:^(id object, NSError *error) {
        NSInteger count = error ? 0 : [object integerValue];
        callback(count);
    }];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation; {
    
    // 滚到顶部
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 *NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //延迟设置offset，不然不准确
        NSString *scriptString = @"window.scrollTo(0,0);";
        [self.webView evaluateJavaScript:scriptString completionHandler:nil];
        //显示webview
        self.webView.hidden = NO;
    });
    
    // 禁止双指缩放
    NSString *noScaleJS = @"var script = document.createElement('meta');"
    "script.name = 'viewport';"
    "script.content=\"user-scalable=no,width=device-width,initial-scale=1.0,maximum-scale=1.0\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    [self.webView evaluateJavaScript:noScaleJS completionHandler:nil];
    
    // 给图片添加点击事件
    [self.webView evaluateJavaScript:@"function assignImageClickAction(){var imgs=document.getElementsByTagName('img');var length=imgs.length;for(var i=0; i < length;i++){img=imgs[i];if(\"ad\" ==img.getAttribute(\"flag\")){var parent = this.parentNode;if(parent.nodeName.toLowerCase() != \"a\")return;}img.onclick=function(){window.location.href='image-preview:'+this.src}}}"
                   completionHandler:nil];
    // 给图片添加点击事件
    [self.webView evaluateJavaScript: @"assignImageClickAction();" completionHandler:nil];

    // 获取html中的图片URL
    [self getImages];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if (navigationAction.targetFrame == nil) {
        [[UIApplication sharedApplication] openURL:url];
    }
    
    if ([url.scheme isEqualToString: @"image-preview"]) {
        NSString *imageUrlStr = [url.absoluteString substringFromIndex:14];
        if (self.imageArray.count != 0) {
//            NSUInteger index = [self.imageArray indexOfObject:imageUrlStr];
            UIImageView *imageView = [[UIImageView alloc] init];
            [imageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]];
            imageView.frame = CGRectMake(0, 0, 0, 0);
            imageView.center = CGPointMake(self.superview.bounds.size.width / 2.0, self.superview.bounds.size.height / 2.0);
            [self.photoBrowser scaleImageViewToFullScreen:imageView];
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
