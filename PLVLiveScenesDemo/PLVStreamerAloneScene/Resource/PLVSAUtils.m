//
//  PLVSAUtils.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAUtils.h"
#import "PLVToast.h"
#import "PLVAlertViewController.h"
#import "PLVSAStreamAlertController.h"

@interface PLVSAUtils ()

@property (nonatomic, assign) UIEdgeInsets areaInsets;

@end

@implementation PLVSAUtils

#pragma mark - [ Public Method ]

+ (instancetype)sharedUtils {
    static PLVSAUtils *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PLVSAUtils alloc] init];
    });
    return instance;
}

- (void)setupAreaInsets:(UIEdgeInsets)areaInsets {
    self.areaInsets = areaInsets;
}

+ (void)showToastInHomeVCWithMessage:(NSString *)message {
    [PLVToast showToastWithMessage:message inView:[PLVSAUtils sharedUtils].homeVC.view];
}

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view {
    [PLVToast showToastWithMessage:message inView:view];
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
