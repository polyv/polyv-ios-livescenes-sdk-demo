//
//  PLVBugReporter.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVBuglyBundleType) {
    PLVBuglyBundleTypeWatch = 0,
    PLVBuglyBundleTypeStreamer,
};

@interface PLVBugReporter : NSObject

@end

NS_ASSUME_NONNULL_END
