//
//  PLVHCDemoUtil.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageDownloader.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCDemoUtils : NSObject

/// 获取互动学堂图片
/// @param imageName 图片昵称
+ (UIImage *)imageForHiClassResource:(NSString *)imageName;

/// 获取互动学堂plist字典
/// @param plistName plist文件名
+ (NSDictionary *)plistDictionartForHiClassResource:(NSString *)plistName;

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url;

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder;

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options;

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock;

+ (void)setImageView:(UIImageView *)imageView
                 url:(nullable NSURL *)url
    placeholderImage:(nullable UIImage *)placeholder
             options:(SDWebImageOptions)options
            progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
           completed:(nullable SDExternalCompletionBlock)completedBlock;

@end

NS_ASSUME_NONNULL_END
