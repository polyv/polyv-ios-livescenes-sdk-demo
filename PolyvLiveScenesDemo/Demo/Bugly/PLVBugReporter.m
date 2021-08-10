//
//  PLVBugReporter.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVBugReporter.h"
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>

@interface PLVBugReporter ()

@property (class, nonatomic, assign) BOOL on;

@end

@implementation PLVBugReporter

#pragma mark - Class Property

static BOOL _on = NO;

+ (BOOL)on {
  return _on;
}

+ (void)setOn:(BOOL)on {
    _on = on;
}

#pragma mark - Public

+ (void)openWithType:(PLVBuglyBundleType)type {

}

+ (void)setUserIdentifier:(NSString *)userId {

}

#pragma mark - Private

+ (BOOL)isInnerTestWithType:(PLVBuglyBundleType)type {
    return NO;
}

+ (NSString *)appIdWithType:(PLVBuglyBundleType)type {
    NSString *appId = nil;
    return appId;
}

@end
