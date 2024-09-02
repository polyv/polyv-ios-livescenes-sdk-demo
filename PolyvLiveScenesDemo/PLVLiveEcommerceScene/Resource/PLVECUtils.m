//
//  PLVECUtils.m
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVProgressHUD.h>
#import <PLVLiveScenesSDK/PLVConsoleLogger.h>

@interface PLVECUtils ()
@property (nonatomic, assign) UIEdgeInsets areaInsets;

@property (nonatomic, assign) UIDeviceOrientation deviceOrientation; // 设备方向，缺省值为UIDeviceOrientationPortrait(竖屏）

@end

@implementation PLVECUtils

#pragma mark - [ Public Methods ]

+ (instancetype)sharedUtils {
    static PLVECUtils *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PLVECUtils alloc] init];
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

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view {
    [self showHUDWithTitle:title detail:detail view:view afterDelay:2.0];
}

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view afterDelay:(CGFloat)delay {
    PLV_LOG_INFO(PLVConsoleLogModuleTypeVerbose,@"HUD info title:%@,detail:%@",title,detail);
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

+ (UIImage *)imageForWatchResource:(NSString *)imageName {
    return [self imageFromBundle:@"WatchResource" imageName:imageName];
}

+ (NSURL *)URLForWatchResource:(NSString *)resourceName {
    NSBundle *bundle = [NSBundle bundleForClass:[PLVECUtils class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"WatchResource" ofType:@"bundle"]];
    NSURL *resourceURL = [resourceBundle URLForResource:resourceName withExtension:nil];
    return resourceURL;
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

+ (NSBundle *)ECBundle {
    return [NSBundle bundleForClass:[PLVECUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName{
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVECUtils ECBundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
