//
//  PLVNetworkDetactor.m
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/15.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVNetworkDetactor.h"
#import <SystemConfiguration/CaptiveNetwork.h>

NSString *PLVWifiChangedNotification = @"PLVWifiChangedNotification";

@interface PLVNetworkDetactor ()

@property (nonatomic, strong) PLVReachability *myReachability;
@property (nonatomic, assign) PLVNetworkStatus currentNetworkStatus;

@end

@implementation PLVNetworkDetactor

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *hostName = @"www.apple.com";
        self.myReachability = [PLVReachability reachabilityWithHostName:hostName];
        self.currentNetworkStatus = [self networkStatus];
    }
    return self;
}

- (void)dealloc {
    [self stopListenNetworkChanged];
}

#pragma mark - Public

+ (NSString *)getWIFIName {
    NSString *name = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            name = info[@"SSID"];
        }
    }
    return name;
}

- (BOOL)isWIFIReachable {
    return [self networkStatus] == PLVReachableViaWiFi;
}

- (PLVNetworkStatus)networkStatus {
    return [self.myReachability currentReachabilityStatus];
}

- (void)startListenNetworkChanged {
    [self.myReachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kPLVReachabilityChangedNotification
                                               object:nil];
}

- (void)stopListenNetworkChanged {
    [self.myReachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification

- (void)reachabilityChanged:(NSNotification *)notif {
    if (self.currentNetworkStatus == [self networkStatus]) {
        return;
    }
    
    self.currentNetworkStatus = [self networkStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVWifiChangedNotification object:nil];
}

@end
