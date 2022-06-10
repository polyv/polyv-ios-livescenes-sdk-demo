//
//  PLVCommodityDetailViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCommodityDetailViewController.h"
#import <WebKit/WebKit.h>

@interface PLVCommodityDetailViewController ()

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
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
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

    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

#pragma mark - Getter

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] init];
    }
    return _webView;
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

@end