//
//  PLVLCQAViewController.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/10/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCQAViewController.h"
#import "PLVRoomDataManager.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVLCQAViewController ()<
PLVJSBridgeDelegate,
PLVSocketManagerProtocol
>

@property (nonatomic, strong) PLVJSBridge *jsBridge; //Webview Js交互器 (WKWebview 封装类)
#pragma mark 数据
@property (nonatomic, strong) PLVRoomData *roomData;
@property (nonatomic, copy) NSString *theme; //皮肤

@end

@implementation PLVLCQAViewController{
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - [ Life Cycle ]

- (instancetype)initWithRoomData:(PLVRoomData *)roomData theme:(NSString *)theme {
    self = [super init];
    if (self) {
        _roomData = roomData;
        _theme = theme;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#141518"];

    /// 添加 socket 事件监听
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    
    NSString *urlString = PLVLiveConstantsWatchQAURL;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    BOOL security = liveConfig.enableSha256 || liveConfig.enableSignatureNonce || liveConfig.enableResponseEncrypt || liveConfig.enableRequestEncrypt;
    urlString = [urlString stringByAppendingFormat:@"?security=%d&resourceAuth=%d&secureApi=%d", (security ? 1 : 0), (liveConfig.enableResourceAuth ? 1 : 0), (liveConfig.enableSecureApi ? 1 : 0)];
    [self.jsBridge loadWebView:urlString inView:self.view];
    
    if (@available(iOS 11.0, *)) {
        self.jsBridge.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.jsBridge.webView.frame = self.view.bounds;
}

#pragma mark - [ Private Method ]

- (NSString *)getMessageInitJsonString {
    PLVRoomUser *roomUser = self.roomData.roomUser;
    NSDictionary *userInfo =
    @{@"userId" : [NSString stringWithFormat:@"%@", roomUser.viewerId],
      @"nick" : [NSString stringWithFormat:@"%@", roomUser.viewerName],
      @"pic"  : [NSString stringWithFormat:@"%@", roomUser.viewerAvatar]};
    NSDictionary *channelInfo =
    @{@"channelId" : [NSString stringWithFormat:@"%@", self.roomData.channelId],
      @"roomId"  : [NSString stringWithFormat:@"%@", self.roomData.channelId],
      @"sessionId" : [NSString stringWithFormat:@"%@", self.roomData.sessionId]};
    NSDictionary *qaSetting = @{@"theme" : [NSString stringWithFormat:@"%@", self.theme]}; //QA皮肤设置默认白色
    NSDictionary *params = @{@"userInfo" :  userInfo,
                             @"channelInfo" : channelInfo,
                             @"qaSetting" : qaSetting };
    NSError *jsonErr;
    NSData *arrayData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&jsonErr];
    if (jsonErr) {
        NSLog(@"PLVLCQAViewController - JSON处理失败 %@",jsonErr);
        return nil;
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:arrayData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
}

#pragma mark Getter & Setter

- (PLVJSBridge *)jsBridge {
    if (_jsBridge == nil) {
        _jsBridge = [[PLVJSBridge alloc] init];
        _jsBridge.delegate = self;
        [_jsBridge addJsFunctionsReceiver:self];
        [_jsBridge addObserveJsFunctions:@[@"launchQ"]];
    }
    return _jsBridge;
}

#pragma mark - JSBridge Method

// web 通知 app：发出问答
- (void)launchQ:(NSDictionary *)dict {
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        NSLog(@"PLVLCQAViewController - [js call] launchQ param illegal %@",dict);
        return;
    }
    [[PLVSocketManager sharedManager] emitMessage:dict timeout:5.0 callback:^(NSArray * _Nonnull ackArray) {
        if (ackArray && [PLVFdUtil checkArrayUseable:ackArray]) {
            NSString *jsonString = ackArray.firstObject;
            if (jsonString && [PLVFdUtil checkStringUseable:jsonString]) {
                [self.jsBridge call:@"LAUNCH_Q" params:@[jsonString]];
            }
        }
    }];
}

#pragma mark - PLVJSBridge Delegate

- (void)plvJSBridgeWebviewDidFinishLoad:(PLVJSBridge *)jsBridge {
    NSString *jsonString = [self getMessageInitJsonString];
    if ([PLVFdUtil checkStringUseable:jsonString]) {
        [self.jsBridge call:@"messageInit" params:@[jsonString]];
    }
}

#pragma mark PLVSocketManager Protocol

/// socket 接收到 "message" 事件
- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    if ([subEvent isEqualToString:@"LAUNCH_A"] // 回复问答
        || [subEvent isEqualToString:@"DELETE_QA_ANSWER"]) { // 删除问答
        [self.jsBridge call:subEvent params:@[jsonString]];
    }
}

@end
