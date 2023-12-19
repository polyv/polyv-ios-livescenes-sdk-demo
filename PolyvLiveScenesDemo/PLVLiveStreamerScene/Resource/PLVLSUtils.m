//
//  PLVLSUtils.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLSUtils.h"
#import "PLVToast.h"
#import "PLVAlertViewController.h"

static float _safeSidePad = 0;
static float _safeBottomPad = 0;
static float _safeTopPad = 0;

@implementation PLVLSUtils

+ (instancetype)sharedUtils {
    static PLVLSUtils *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PLVLSUtils alloc] init];
    });
    return instance;
}

#pragma mark - Getter & Setter

+ (float)safeSidePad {
    return _safeSidePad;
}

+ (float)safeBottomPad {
    return _safeBottomPad;
}

+ (float)safeTopPad {
    return _safeTopPad;
}

+ (void)setSafeSidePad:(float)safeSidePad {
    _safeSidePad = safeSidePad;
}

+ (void)setSafeBottomPad:(float)safeBottomPad {
    _safeBottomPad = safeBottomPad;
}

+ (void)setSafeTopPad:(float)safeTopPad {
    _safeTopPad = safeTopPad;
}

#pragma mark - Public Method

+ (void)showToastInHomeVCWithMessage:(NSString *)message {
    [PLVToast showToastWithMessage:message inView:[PLVLSUtils sharedUtils].homeVC.view];
}

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view {
    [PLVToast showToastWithMessage:message inView:view];
}

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view afterDelay:(CGFloat)delay {
    [PLVToast showToastWithMessage:message inView:view afterDelay:delay];
}

+ (void)showToastWithCountMessage:(NSString *)message inView:(UIView *)view afterCountdown:(CGFloat)countdown finishHandler:(void(^)(void))finishHandler {
    [PLVToast showToastWithCountMessage:message inView:view afterCountdown:countdown finishHandler:finishHandler];
}

+ (void)showAlertWithMessage:(NSString *)message
           cancelActionTitle:(NSString *)cancelActionTitle
           cancelActionBlock:(void(^)(void))cancelActionBlock {
    PLVAlertViewController *alert = [PLVAlertViewController alertControllerWithMessage:message cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:nil confirmHandler:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PLVLSUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
    });
}

+ (void)showAlertWithMessage:(NSString *)message
           cancelActionTitle:(NSString *)cancelActionTitle
           cancelActionBlock:(void(^)(void))cancelActionBlock
          confirmActionTitle:(NSString *)confirmActionTitle
          confirmActionBlock:(void(^)(void))confirmActionBlock {
    PLVAlertViewController *alert = [PLVAlertViewController alertControllerWithMessage:message cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:confirmActionTitle confirmHandler:confirmActionBlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PLVLSUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
    });
}

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
         cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
        confirmActionBlock:(void(^ _Nullable)(void))confirmActionBlock {
    PLVAlertViewController *alert = [PLVAlertViewController alertControllerWithTitle:title message:message cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:confirmActionTitle confirmHandler:confirmActionBlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PLVLSUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
    });
}

+ (UIImage *)imageForStatusResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLSStatus" imageName:imageName];
}

+ (UIImage *)imageForDocumentResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLSDocument" imageName:imageName];
}

+ (UIImage *)imageForChatroomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLSChatroom" imageName:imageName];
}

+ (UIImage *)imageForMemberResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLSMember" imageName:imageName];
}

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName{
    return [self imageFromBundle:@"PLVLSLinkMic" imageName:imageName];
}

+ (UIImage *)imageForBeautyResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLSBeauty" imageName:imageName];
}

+ (UIImage *)imageForLiveroomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLSLiveroom" imageName:imageName];
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

#pragma mark - Private Method

+ (NSBundle *)LCBundle {
    return [NSBundle bundleForClass:[PLVLSUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName{
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVLSUtils LCBundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
