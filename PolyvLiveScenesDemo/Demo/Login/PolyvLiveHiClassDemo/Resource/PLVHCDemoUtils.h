//
//  PLVHCDemoUtil.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/1.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCDemoUtils : NSObject

/// 获取互动学堂图片
/// @param imageName 图片昵称
+ (UIImage *)imageForHiClassResource:(NSString *)imageName;

/// 获取互动学堂plist字典
/// @param plistName plist文件名
+ (NSDictionary *)plistDictionartForHiClassResource:(NSString *)plistName;

@end

NS_ASSUME_NONNULL_END
