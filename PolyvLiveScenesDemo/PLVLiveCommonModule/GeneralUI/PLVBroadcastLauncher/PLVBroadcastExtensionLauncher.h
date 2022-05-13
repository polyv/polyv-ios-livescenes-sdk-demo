//
//  PLVBroadcastExtensionLauncher.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2022/2/11.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 用于唤起系统录屏的启动器，使用 [屏幕共享] 功能会用到
@interface PLVBroadcastExtensionLauncher : NSObject

+ (instancetype)sharedInstance;

/// 打开广播的拓展选择器 用于开始录屏广播功能
- (void)launch API_AVAILABLE(ios(12.0));

@end

NS_ASSUME_NONNULL_END
