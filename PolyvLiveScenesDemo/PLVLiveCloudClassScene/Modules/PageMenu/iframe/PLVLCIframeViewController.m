//
//  PLVLCIframeViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCIframeViewController.h"
#import <WebKit/WebKit.h>
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

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

#pragma mark - Private Method

/// 构建带参数的URL
- (NSString *)buildURLWithParams:(NSString *)baseURL {
    if (![PLVFdUtil checkStringUseable:baseURL]) {
        return baseURL;
    }
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (!roomData) {
        return baseURL;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSString *userId = roomData.roomUser.viewerId;
    if ([PLVFdUtil checkStringUseable:userId]) {
        params[@"userId"] = userId;
    }
    
    NSString *nickname = roomData.roomUser.viewerName;
    if ([PLVFdUtil checkStringUseable:nickname]) {
        params[@"nickname"] = nickname;
    }
    
    NSString *channelId = roomData.channelId;
    if ([PLVFdUtil checkStringUseable:channelId]) {
        params[@"channelId"] = channelId;
    }
    
    NSString *sessionId = roomData.sessionId;
    if ([PLVFdUtil checkStringUseable:sessionId]) {
        params[@"sessionId"] = sessionId;
    }
    
    NSString *param4 = roomData.customParam.liveParam4;
    if ([PLVFdUtil checkStringUseable:param4]) {
        params[@"param4"] = param4;
    }
    
    NSString *param5 = roomData.customParam.liveParam5;
    if ([PLVFdUtil checkStringUseable:param5]) {
        params[@"param5"] = param5;
    }
    
    if (params.count == 0) {
        return baseURL;
    }
    
    NSMutableString *paramString = [NSMutableString string];
    NSArray *keys = params.allKeys;
    for (NSInteger i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        NSString *value = params[key];
        NSString *encodedValue = [PLVFdUtil URLEncodedString:value];
        if (i == 0) {
            [paramString appendFormat:@"%@=%@", key, encodedValue];
        } else {
            [paramString appendFormat:@"&%@=%@", key, encodedValue];
        }
    }
    
    NSString *separator = [baseURL containsString:@"?"] ? @"&" : @"?";
    return [NSString stringWithFormat:@"%@%@%@", baseURL, separator, paramString];
}

#pragma mark - Public Method

- (void)loadURLString:(NSString *)urlString {
    if (!urlString || ![urlString isKindOfClass:[NSString class]] || urlString.length == 0) {
        return;;
    }
    
    NSString *urlStringWithParams = [self buildURLWithParams:urlString];
    
    NSURL *h5Url = [NSURL URLWithString:urlStringWithParams];
    if (h5Url && [h5Url isKindOfClass:NSURL.class]) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:h5Url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
        [self.webView loadRequest:request];
    }
}

@end
