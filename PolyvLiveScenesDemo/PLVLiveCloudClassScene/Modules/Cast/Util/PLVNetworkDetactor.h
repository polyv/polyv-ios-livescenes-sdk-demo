//
//  PLVNetworkDetactor.h
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/15.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVFoundationSDK/PLVReachability.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *PLVWifiChangedNotification;

@interface PLVNetworkDetactor : NSObject

+ (NSString *)getWIFIName;

- (BOOL)isWIFIReachable;

- (PLVNetworkStatus)networkStatus;

- (void)startListenNetworkChanged;

- (void)stopListenNetworkChanged;

@end

NS_ASSUME_NONNULL_END
