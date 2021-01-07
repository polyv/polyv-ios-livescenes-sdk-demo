//
//  PLVLCTuwenViewController.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCTuwenViewController.h"
#import <PolyvFoundationSDK/PLVJSBridge.h>
#import <PolyvFoundationSDK/PLVColorUtil.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static NSString *kUrlString = @"https://live.polyv.net/front/tuwen/index";

@interface PLVLCTuwenViewController ()<
PLVJSBridgeDelegate,
PLVSocketManagerProtocol
>

@property (nonatomic, strong) NSNumber *channelId;

@property (nonatomic, strong) PLVJSBridge *jsBridge;

@property (nonatomic, assign) BOOL showBigImage;

@end

@implementation PLVLCTuwenViewController {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - Life Cycle

- (instancetype)initWithChannelId:(NSNumber *)channelId {
    self = [super init];
    if (self) {
        _channelId = channelId;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#141518"];
    
    /// 添加 socket 事件监听
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    [self.jsBridge loadWebView:kUrlString inView:self.view];
    
    if (@available(iOS 11.0, *)) {
        self.jsBridge.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

- (void)viewWillLayoutSubviews {
    self.jsBridge.webView.frame = self.view.bounds;
}
    
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.delegate && self.showBigImage) {
       [self notificationForGestureEnable:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.delegate && self.showBigImage) {
        [self notificationForGestureEnable:YES];
    }
}

#pragma Getter & Setter

- (PLVJSBridge *)jsBridge {
    if (_jsBridge == nil) {
        _jsBridge = [[PLVJSBridge alloc] init];
        _jsBridge.delegate = self;
        [_jsBridge addJsFunctionsReceiver:self];
        [_jsBridge addObserveJsFunctions:@[@"clickTuwenImage", @"tuwenImageHide"]];
    }
    return _jsBridge;
}

#pragma mark - Public Method

- (void)reconnect {
    [self.jsBridge call:@"CONNECT" params:nil];
}

#pragma mark - JSBridge Method

// web 通知 app：点击大图触发
- (void)clickTuwenImage:(id)sender {
    self.showBigImage = YES;
    [self notificationForGestureEnable:NO];
}

// web 通知 app：点击隐藏大图触发
- (void)tuwenImageHide:(id)sender {
    self.showBigImage = NO;
    [self notificationForGestureEnable:YES];
}

#pragma mark - PLVJSBridge Delegate

- (void)plvJSBridgeWebviewDidFinishLoad:(PLVJSBridge *)jsBridge {
    [self.jsBridge call:@"INIT_TUWEN" params:@[self.channelId]];
}

#pragma mark - Private

- (void)notificationForGestureEnable:(BOOL)enable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickTuwenImage:)]) {
        [self.delegate clickTuwenImage:!enable];
    }
}

#pragma mark PLVSocketManager Protocol

/// socket 接收到 "message" 事件
- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    if ([subEvent isEqualToString:@"DELETE_IMAGE_TEXT"] // 删除图文
        || [subEvent isEqualToString:@"SET_TOP_IMAGE_TEXT"] // 置顶图文
        || [subEvent isEqualToString:@"CREATE_IMAGE_TEXT"]  // 发布图文
        || [subEvent isEqualToString:@"SET_IMAGE_TEXT_MSG"]) {  // 编辑现有图文
        [self.jsBridge call:subEvent params:@[jsonString]];
    }
}

@end
