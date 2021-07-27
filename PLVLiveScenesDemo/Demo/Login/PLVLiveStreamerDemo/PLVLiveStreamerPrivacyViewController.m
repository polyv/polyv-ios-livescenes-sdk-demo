//
//  PLVLiveStreamerPrivacyViewController.m
//  PLVCloudClassStreamerDemo
//
//  Created by MissYasiky on 2020/2/4.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLiveStreamerPrivacyViewController.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <WebKit/WebKit.h>

@interface PLVLiveStreamerPrivacyViewController ()

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSString *urlString;

@end

@implementation PLVLiveStreamerPrivacyViewController

#pragma mark - Public

- (instancetype)initWithUrlString:(NSString *)urlString {
    self = [super init];
    if (self) {
        _urlString = urlString;
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initNavigationBar];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.urlString]];
    [self.webView loadRequest:request];
}

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:@"title" context:nil];
    _webView = nil;
}

#pragma mark - Initialize

- (void)initNavigationBar {
    [self.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    
    NSDictionary *titleAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"PingFangSC-Medium" size:20],
                                      NSForegroundColorAttributeName:PLV_UIColorFromRGB(@"0x333333")};
    [self.navigationController.navigationBar setTitleTextAttributes:titleAttributes];
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 44, 44);
    [leftButton setImage:[[self class] imageWithImageName:@"plvls_login_btn_leftBack"] forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -40, 0, 0);
    UIBarButtonItem *backItem =[[UIBarButtonItem alloc] initWithCustomView:leftButton];
    self.navigationItem.leftBarButtonItem = backItem;
}

#pragma mark - Getter & Setter

- (WKWebView *)webView {
    if (_webView == nil) {
        WKWebViewConfiguration *config = [WKWebViewConfiguration new];
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.contentMode = UIViewContentModeRedraw;
        _webView.opaque = NO;
        [self.view addSubview:_webView];

        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        if(@available(iOS 11.0, *)) {
            CGRect navigationBarRect = self.navigationController.navigationBar.frame;
            CGFloat originY = navigationBarRect.origin.y + navigationBarRect.size.height + statusBarHeight;
            _webView.frame = CGRectMake(0, originY, self.view.bounds.size.width, self.view.bounds.size.height - originY);
            _webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        } else {
            _webView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
            
            UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, statusBarHeight)];
            bg.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:bg];
        }
        
        [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return _webView;
}

#pragma mark Utils

+ (UIImage *)imageWithImageName:(NSString *)imageName {
    NSString *bundleName = @"LiveStreamer";
    NSBundle *bundle = [NSBundle bundleForClass:[self class]]; // 本代码应该与资源文件存放在同个Bundle下
    NSString *bundlePath = [bundle pathForResource:bundleName ofType:@"bundle"]; // 获取到 LiveStreamer.bundle 所在 Bundle
    NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
    UIImage *image = [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
    return image;
}

#pragma mark - Action

- (void)backButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"]) {
        if (object == self.webView) {
            self.title = self.webView.title;
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
}

@end
