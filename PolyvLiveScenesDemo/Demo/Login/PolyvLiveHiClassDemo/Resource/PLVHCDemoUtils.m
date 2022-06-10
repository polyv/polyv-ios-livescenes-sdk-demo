//
//  PLVHCDemoUtil.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDemoUtils.h"

@implementation PLVHCDemoUtils

#pragma mark - [ Public Method ]
+ (UIImage *)imageForHiClassResource:(NSString *)imageName {
    return [self imageFromBundle:@"HiClass" imageName:imageName];
}

+ (NSDictionary *)plistDictionartForHiClassResource:(NSString *)plistName {
    return [self plistDictionartFromBundle:@"HiClass" plistName:plistName];
}

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url {
    [self setImageView:imageView url:url placeholderImage:nil options:0 progress:nil completed:nil];
}

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self setImageView:imageView url:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self setImageView:imageView url:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

+ (void)setImageView:(UIImageView *)imageView url:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self setImageView:imageView url:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

+ (void)setImageView:(UIImageView *)imageView
                 url:(nullable NSURL *)url
    placeholderImage:(nullable UIImage *)placeholder
             options:(SDWebImageOptions)options
            progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
           completed:(nullable SDExternalCompletionBlock)completedBlock {
    if (!imageView || ![imageView isKindOfClass:UIImageView.class]) {
        return;
    }
    
    if (!url) {
        return;
    }
    
    if ([url.absoluteString containsString:@".gif"]) {
        [[SDWebImageDownloader sharedDownloader]downloadImageWithURL:url options:SDWebImageDownloaderUseNSURLCache progress:progressBlock completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            if (finished) {
                UIImage *imageData = [UIImage imageWithData:data];
                [imageView setImage:imageData];
            } else {
                imageView.image = placeholder;
            }
            if (completedBlock) {
                completedBlock(image, error, SDImageCacheTypeNone, nil);
            }
        }];
    } else {
        [imageView sd_setImageWithURL:url placeholderImage:placeholder options:options progress:progressBlock completed:completedBlock];
    }
}

#pragma mark - [ Private Method ]

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:[self class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVHCDemoUtils bundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

+ (NSDictionary *)plistDictionartFromBundle:(NSString *)bundleName plistName:(NSString *)plistName {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVHCDemoUtils bundle] pathForResource:bundleName ofType:@"bundle"]];
    NSString *plistPath = [resourceBundle pathForResource:plistName ofType:@"plist"];
    return [[NSDictionary alloc] initWithContentsOfFile:plistPath];
}
@end
