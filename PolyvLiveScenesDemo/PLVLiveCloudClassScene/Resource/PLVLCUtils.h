//
//  PLVLCUtils.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCUtils : NSObject

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view;

+ (void)showHUDWithTitle:(NSString * _Nullable)title detail:(NSString *)detail view:(UIView *)view afterDelay:(CGFloat)delay;

+ (UIImage *)imageForLiveRoomResource:(NSString *)imageName;

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName;

+ (UIImage *)imageForMediaResource:(NSString *)imageName;

+ (UIImage *)imageForMenuResource:(NSString *)imageName;

+ (UIImage *)imageForChatroomResource:(NSString *)imageName;

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
