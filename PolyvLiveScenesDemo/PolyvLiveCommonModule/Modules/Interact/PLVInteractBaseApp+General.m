//
//  PLVInteractBaseApp+General.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/14.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVInteractBaseApp+General.h"

@implementation PLVInteractBaseApp (General)

- (void)triviaCardAckHandleNoRetry:(NSArray *)ackResArray event:(NSString *)event{
    [self triviaCardAckHandle:ackResArray event:event jsonDict:nil retryCount:0];
}

- (void)triviaCardAckHandle:(NSArray *)ackResultArray event:(NSString *)event jsonDict:(NSDictionary *)jsonDict retryCount:(NSInteger)retryCount{
    if ([PLVFdUtil checkArrayUseable:ackResultArray]) {
        NSString *ack = ackResultArray.firstObject;
        if ([PLVFdUtil checkStringUseable:ack]) {
            if ([ack isEqualToString:@"NO ACK"]) {
                if (jsonDict) {
                    /// 携带 socketObj 代表需重发
                    __weak typeof(self) weakSelf = self;
                    __block NSInteger count = (retryCount > 0 ? retryCount : 1);
                    
                    [[PLVSocketManager sharedManager] emitMessage:jsonDict timeout:5.0 callback:^(NSArray *ackArray) {
                        if (count < weakSelf.triviaCardMaxRetryCount) {
                            count ++;
                            [weakSelf triviaCardAckHandle:ackArray event:event jsonDict:jsonDict retryCount:count];
                        }else{
                            [weakSelf submitResultTimeoutCallback:event];
                        }
                    }];
                }else{
                    [self submitResultTimeoutCallback:event];
                }
            }else{
                [self submitResultCallback:ack event:event];
            }
        }
    }
}

- (void)emitInteractMsg:(id)content event:(nonnull NSString *)event{
    __weak typeof(self) weakSelf = self;
    [[PLVSocketManager sharedManager] emitMessage:content timeout:self.triviaCardTimeoutSec callback:^(NSArray * ackResultArray) {
        [weakSelf triviaCardAckHandle:ackResultArray event:event jsonDict:content retryCount:0];
    }];
}

@end
