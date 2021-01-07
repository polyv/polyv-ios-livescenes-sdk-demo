//
//  PLVBugReporter.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVBugReporter : NSObject

/// 启动异常上报功能，默认不启动
+ (void)open;

/// 使用用户的 viewerID 设置用户标识
+ (void)setUserIdentifier:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
