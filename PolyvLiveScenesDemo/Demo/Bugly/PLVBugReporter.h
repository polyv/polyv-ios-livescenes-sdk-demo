//
//  PLVBugReporter.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVBuglyBundleType) {
    PLVBuglyBundleTypeWatch = 0,
    PLVBuglyBundleTypeStreamer,
};

@interface PLVBugReporter : NSObject

/// 启动异常上报功能，默认不启动
+ (void)openWithType:(PLVBuglyBundleType)type;

/// 使用用户的 viewerID 设置用户标识
+ (void)setUserIdentifier:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
