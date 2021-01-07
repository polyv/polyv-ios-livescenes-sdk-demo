//
//  PLVInteractSignIn.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/14.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVInteractSignIn.h"

#import "PLVInteractBaseApp+General.h"

@interface PLVInteractSignIn ()

@property (nonatomic, copy) NSString * checkinId; /// 签到Id (可用于判断，当前是否正在显示签到)

@end

@implementation PLVInteractSignIn

#pragma mark - [ Father Public Methods ]
- (instancetype)initWithJsBridge:(PLVJSBridge *)jsBridge{
    if (self = [super initWithJsBridge:jsBridge]) {
        [jsBridge addJsFunctionsReceiver:self];
        [jsBridge addObserveJsFunctions:@[@"submitSign",@"closeWebview"]];
    }
    return self;
}

- (void)processInteractMessageString:(NSString *)msgString jsonDict:(NSDictionary *)jsonDict{
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:PLVSocketInteraction_onSignIn_start]) { /// 发起签到
        [self startSign:msgString];
    } else if ([subEvent isEqualToString:PLVSocketInteraction_onSignIn_stop]) { /// 结束签到
        [self stopSign:msgString];
    }
}


#pragma mark - [ Private Methods ]
- (void)startSign:(NSString *)json {
    NSError * jsonError = nil;
    NSData * jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
    if (jsonError == nil && jsonDict != nil) {
        self.checkinId = jsonDict[@"data"][@"checkinId"];
        NSString * jsonParam = [NSString stringWithFormat:@"{\"limitTime\":%ld, \"message\":\"%@\"}", (long)((NSNumber *)jsonDict[@"data"][@"limitTime"]).integerValue, jsonDict[@"data"][@"message"]];
        [self.jsBridge call:@"startSign" params:@[jsonParam]];
        [self callWebviewShow];
    }
}

- (void)stopSign:(NSString *)json {
    if ([PLVFdUtil checkStringUseable:self.checkinId]) {
        [self.jsBridge call:@"stopSign" params:nil];
        [self callWebviewShow];
    }else{
        NSLog(@"PLVInteractAnswer - stopSign failed, not signId exsit:%@",self.checkinId);
    }
}


#pragma mark - [ Delegate ]
#pragma mark JS Callback
// 接收到js已签到消息
- (void)submitSign:(id)placeholder {
    NSDictionary * dict = @{@"checkinId" : [NSString stringWithFormat:@"%@",self.checkinId]};
    
    NSString * event = @"TO_SIGN_IN";

    NSDictionary * user = @{@"nick" : [NSString stringWithFormat:@"%@",[PLVSocketManager sharedManager].viewerName],
                            @"userId" : [NSString stringWithFormat:@"%@",[PLVSocketManager sharedManager].viewerId]};
    NSDictionary * baseJSON = @{@"EVENT" : event,
                                @"user" : user,
                                @"roomId" : [NSString stringWithFormat:@"%@", [PLVSocketManager sharedManager].roomId]};
    
    NSMutableDictionary * jsonDict = [[NSMutableDictionary alloc] init];
    [jsonDict addEntriesFromDictionary:baseJSON];
    [jsonDict addEntriesFromDictionary:dict];
    
    [self emitInteractMsg:jsonDict event:event];

    self.checkinId = nil;
}

// 接收到js关闭webview请求
- (void)closeWebview:(id)placeholder {
    self.checkinId = nil;
}

@end
