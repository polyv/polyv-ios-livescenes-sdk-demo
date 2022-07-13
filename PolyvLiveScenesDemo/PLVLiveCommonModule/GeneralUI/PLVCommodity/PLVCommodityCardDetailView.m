//
//  PLVCommodityCardDetailView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/7/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVCommodityCardDetailView.h"
#import <WebKit/WebKit.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVCommodityCardDetailView ()

@property (nonatomic, strong) UIView *backgroudView;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) NSURL *cardURL;
@property (nonatomic, assign) CGRect initialFrame;

@end

@implementation PLVCommodityCardDetailView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.backgroudView];
        [self.backgroudView addSubview:self.webView];
        [self.backgroudView addSubview:self.closeButton];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL fullScreen = PLVScreenWidth > PLVScreenHeight;
    self.webView.frame = self.backgroudView.bounds;
    self.closeButton.hidden = fullScreen;
    self.closeButton.frame = CGRectMake(PLVScreenWidth - 12 - 24, 12, 24, 24);
}

#pragma mark - [ Public Method ]

- (void)loadWebviewWithCardURL:(NSURL *)url {
    self.cardURL = url;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.cardURL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [self.webView loadRequest:request];
}

- (void)showOnView:(UIView *)superView frame:(CGRect)frame {
    BOOL fullScreen = PLVScreenWidth > PLVScreenHeight;
    CGFloat originX = fullScreen ? PLVScreenWidth : 0;
    CGFloat originY = fullScreen ? 0 : PLVScreenHeight;
    CGFloat sizeHeight = frame.size.height;
    CGFloat sizeWidth = frame.size.width;
    self.initialFrame = CGRectMake(originX, originY, sizeWidth, sizeHeight);
    self.backgroudView.frame = self.initialFrame;
    self.frame = superView.bounds;

    [superView addSubview:self];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 1;
        weakSelf.backgroudView.frame = CGRectMake(frame.origin.x, frame.origin.y, sizeWidth, sizeHeight);
    } completion:nil];
}

- (void)hiddenCardDetailView {
    if (self.alpha == 0 && !self.superview) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0;
        weakSelf.backgroudView.frame = weakSelf.initialFrame;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
        weakSelf.cardURL = nil;
    }];
}

#pragma mark - [ Private Method ]

#pragma mark - Utils

- (UIImage *)imageForCommodityResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVCommodity" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

#pragma mark - Getter

- (UIView *)backgroudView {
    if (!_backgroudView) {
        _backgroudView = [[UIView alloc] init];
    }
    return _backgroudView;
}

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] init];
        if (@available(iOS 11.0,*)) {
            [_webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _webView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        UIImage *image = [self imageForCommodityResource:@"plv_commodity_webview_close_btn"];
        [_closeButton setImage:image forState:UIControlStateNormal];
    }
    return _closeButton;
}

#pragma mark - Action

- (void)tapAction {
    [self hiddenCardDetailView];
}

- (void)closeButtonAction:(UIButton *)sender {
    [self hiddenCardDetailView];
}

@end
