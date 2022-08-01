//
//  PLVSAUtils.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAUtils.h"
#import "PLVToast.h"
#import "PLVSAStreamAlertController.h"

@interface PLVSAUtils ()

@property (nonatomic, assign) UIEdgeInsets areaInsets;

@property (nonatomic, assign) UIDeviceOrientation deviceOrientation; // 设备方向，缺省值为UIDeviceOrientationPortrait(竖屏）

@end

@implementation PLVSAUtils

#pragma mark - [ Public Method ]

+ (instancetype)sharedUtils {
    static PLVSAUtils *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PLVSAUtils alloc] init];
        instance.deviceOrientation = UIDeviceOrientationPortrait;
    });
    return instance;
}

- (void)setupAreaInsets:(UIEdgeInsets)areaInsets {
    self.areaInsets = areaInsets;
}

- (void)setupDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    self.deviceOrientation = deviceOrientation;
}

- (UIInterfaceOrientationMask)interfaceOrientationMask { // 屏幕的旋转，枚举值里面的 right/left 是以Home键方向为准的！和设备旋转是相反的！
    if (self.deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        return  UIInterfaceOrientationMaskLandscapeRight;
    } else if(self.deviceOrientation == UIDeviceOrientationLandscapeRight) {
        return UIInterfaceOrientationMaskLandscapeLeft;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (UIInterfaceOrientation)interfaceOrientation { // 屏幕的旋转，枚举值里面的 right/left 是以Home键方向为准的！和设备旋转是相反的！
    if (self.deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        return  UIInterfaceOrientationLandscapeRight;
    } else if(self.deviceOrientation == UIDeviceOrientationLandscapeRight) {
        return UIInterfaceOrientationLandscapeLeft;
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

+ (void)showToastInHomeVCWithMessage:(NSString *)message {
    [PLVToast showToastWithMessage:message inView:[PLVSAUtils sharedUtils].homeVC.view];
}

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view {
    [PLVToast showToastWithMessage:message inView:view];
}

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view afterDelay:(CGFloat)delay {
    [PLVToast showToastWithMessage:message inView:view afterDelay:delay];
}

+ (void)showAlertWithMessage:(NSString *)message
           cancelActionTitle:(NSString *)cancelActionTitle
           cancelActionBlock:(void(^)(void))cancelActionBlock
          confirmActionTitle:(NSString *)confirmActionTitle
          confirmActionBlock:(void(^)(void))confirmActionBlock {
    PLVSAStreamAlertController *alert = [PLVSAStreamAlertController alertControllerWithTitle:nil Message:message cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:confirmActionTitle confirmHandler:confirmActionBlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PLVSAUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
    });
}

+ (void)showAlertWithTitle:(NSString *)title
         cancelActionTitle:(NSString *)cancelActionTitle
         cancelActionBlock:(void(^)(void))cancelActionBlock
        confirmActionTitle:(NSString *)confirmActionTitle
        confirmActionBlock:(void(^)(void))confirmActionBlock {
    PLVSAStreamAlertController *alert = [PLVSAStreamAlertController alertControllerWithTitle:title Message:nil cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:confirmActionTitle confirmHandler:confirmActionBlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PLVSAUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
    });
}

+ (void)showAlertWithTitle:(NSString *)title
                   Message:(NSString *)message
         cancelActionTitle:(NSString *)cancelActionTitle
         cancelActionBlock:(void(^)(void))cancelActionBlock
        confirmActionTitle:(NSString *)confirmActionTitle
        confirmActionBlock:(void(^)(void))confirmActionBlock {
    PLVSAStreamAlertController *alert = [PLVSAStreamAlertController alertControllerWithTitle:title Message:message cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:confirmActionTitle confirmHandler:confirmActionBlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PLVSAUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
    });
}

+ (UIImage *)imageForLiveroomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVSALiveroom" imageName:imageName];
}

+ (UIImage *)imageForStatusbarResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVSAStatusbar" imageName:imageName];
}

+ (UIImage *)imageForToolbarResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVSAToolbar" imageName:imageName];
}

+ (UIImage *)imageForChatroomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVSAChatroom" imageName:imageName];
}

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVSALinkMic" imageName:imageName];
}

+ (UIImage *)imageForMemberResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVSAMember" imageName:imageName];
}

+ (UIImage *)imageForBeautyResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVSABeauty" imageName:imageName];
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
    return [NSBundle bundleForClass:[PLVSAUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVSAUtils bundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
