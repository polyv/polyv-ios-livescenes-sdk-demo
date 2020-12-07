//
//  PLVInteractBaseApp+General.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/14.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVInteractBaseApp (General)

- (void)triviaCardAckHandleNoRetry:(NSArray *)ackResArray event:(NSString *)event;

- (void)triviaCardAckHandle:(NSArray *)ackResArray event:(NSString *)event jsonDict:(NSDictionary *)jsonDict retryCount:(NSInteger)retryCount;

- (void)emitInteractMsg:(id)content event:(NSString *)event;

@end

NS_ASSUME_NONNULL_END
