//
//  SampleHandler.m
//  PLVScreenShareExtension
//
//  Created by Sakya on 2022/2/9.
//  Copyright © 2022 PLV. All rights reserved.
//


#import "SampleHandler.h"
#import <PLVBusinessSDK/PLVBusinessSDK.h>
#import <mach/mach.h>

#define kPLVAppGroup @"group.polyv.PolyvLiveScenesDemo.ScreenShare.test"

@interface SampleHandler ()<PLVBroadcastSampleHandlerDelegate>
 
@property (nonatomic, strong) PLVBroadcastSampleHandler *sampleHandler;

@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    [self createSampleHandler];
    /// 用户已启动广播
    [self.sampleHandler broadcastStarted];
}

- (void)broadcastPaused {
    /// 暂停录屏
    [self.sampleHandler broadcastPaused];
}

- (void)broadcastResumed {
    ///恢复录屏
    [self.sampleHandler broadcastResumed];
}

- (void)broadcastFinished {
    /// 完成录屏
    [self.sampleHandler broadcastFinished];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    [self.sampleHandler sendSampleBuffer:sampleBuffer withType:sampleBufferType];
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (PLVBroadcastSampleHandler *)createSampleHandler {
    if (!_sampleHandler) {
        _sampleHandler = [PLVBroadcastSampleHandler broadcastSampleHandlerWithAppGroup:kPLVAppGroup];
        _sampleHandler.delegate = self;
    }
    return _sampleHandler;
}

#pragma mark - [ Delegate ]

#pragma mark PLVBroadcastSampleHandlerDelegate

- (void)plvBroadcastSampleHandler:(PLVBroadcastSampleHandler *)sampleHandler broadcastFinished:(PLVBroadcastSampleHandlerReason)reason {
    NSString *tip = @"";
    switch (reason) {
        case PLVBroadcastSampleHandlerReasonRequestedByMain:
            tip = @"结束屏幕录制";
            break;
        case PLVBroadcastSampleHandlerReasonDisconnected:
            tip = @"链接断开，结束屏幕录制";
            break;
        case PLVBroadcastSampleHandlerReasonVersionMismatch:
            tip = @"版本号与主进程SDK不符，结束屏幕录制";
            break;
    }

    NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class)
                                         code:0
                                     userInfo:@{
                                         NSLocalizedFailureReasonErrorKey:tip
                                     }];
    [self finishBroadcastWithError:error];
}

@end
