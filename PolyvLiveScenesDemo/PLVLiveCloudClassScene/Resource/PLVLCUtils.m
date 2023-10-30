//
//  PLVLCUtils.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVProgressHUD.h>

@implementation PLVLCUtils

#pragma mark - [ Public Methods ]

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view {
    [self showHUDWithTitle:title detail:detail view:view afterDelay:2.0];
}

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view afterDelay:(CGFloat)delay {
    NSLog(@"HUD info title:%@,detail:%@",title,detail);
    if (view == nil) {
        return;
    }
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = title;
    hud.label.numberOfLines = 0;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:delay];
}

+ (UIImage *)imageForLiveRoomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLiveRoom" imageName:imageName];
}

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLinkMic" imageName:imageName];
}

+ (NSURL *)URLForLinkMicResource:(NSString *)resourceName {
    NSBundle *bundle = [NSBundle bundleWithPath:[[PLVLCUtils LCBundle] pathForResource:@"PLVLinkMic" ofType:@"bundle"]];
    NSURL *resourceURL = [bundle URLForResource:resourceName withExtension:nil];
    return resourceURL;
}

+ (UIImage *)imageForMediaResource:(NSString *)imageName{
    return [self imageFromBundle:@"PLVMedia" imageName:imageName];
}

+ (UIImage *)imageForMenuResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVMenu" imageName:imageName];
}

+ (UIImage *)imageForChatroomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVChatroom" imageName:imageName];
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

#pragma mark - [ Private Methods ]
+ (NSBundle *)LCBundle {
    return [NSBundle bundleForClass:[PLVLCUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName{
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVLCUtils LCBundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
