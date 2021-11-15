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
    [[PLVSAUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
}

+ (void)showAlertWithTitle:(NSString *)title
         cancelActionTitle:(NSString *)cancelActionTitle
         cancelActionBlock:(void(^)(void))cancelActionBlock
        confirmActionTitle:(NSString *)confirmActionTitle
        confirmActionBlock:(void(^)(void))confirmActionBlock {
    PLVSAStreamAlertController *alert = [PLVSAStreamAlertController alertControllerWithTitle:title Message:nil cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:confirmActionTitle confirmHandler:confirmActionBlock];
    [[PLVSAUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
}

+ (void)showAlertWithTitle:(NSString *)title
                   Message:(NSString *)message
         cancelActionTitle:(NSString *)cancelActionTitle
         cancelActionBlock:(void(^)(void))cancelActionBlock
        confirmActionTitle:(NSString *)confirmActionTitle
        confirmActionBlock:(void(^)(void))confirmActionBlock {
    PLVSAStreamAlertController *alert = [PLVSAStreamAlertController alertControllerWithTitle:title Message:message cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:confirmActionTitle confirmHandler:confirmActionBlock];
    
    [[PLVSAUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
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

#pragma mark - [ Private Method ]

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:[PLVSAUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVSAUtils bundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
