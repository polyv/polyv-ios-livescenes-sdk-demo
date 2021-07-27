//
//  PLVLSUtils.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLSUtils.h"
#import <PLVFoundationSDK/PLVProgressHUD.h>
#import "PLVToast.h"
#import "PLVAlertViewController.h"

static float _safeSidePad = 0;
static float _safeBottomPad = 0;

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

+ (void)setSafeSidePad:(float)safeSidePad {
    _safeSidePad = safeSidePad;
}

+ (void)setSafeBottomPad:(float)safeBottomPad {
    _safeBottomPad = safeBottomPad;
}

#pragma mark - Public Method

+ (void)showToastInHomeVCWithMessage:(NSString *)message {
    [PLVToast showToastWithMessage:message inView:[PLVLSUtils sharedUtils].homeVC.view];
}

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view {
    [PLVToast showToastWithMessage:message inView:view];
}

+ (void)showAlertWithMessage:(NSString *)message
           cancelActionTitle:(NSString *)cancelActionTitle
           cancelActionBlock:(void(^)(void))cancelActionBlock {
    PLVAlertViewController *alert = [PLVAlertViewController alertControllerWithMessage:message cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:nil confirmHandler:nil];
    [[PLVLSUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
}

+ (void)showAlertWithMessage:(NSString *)message
           cancelActionTitle:(NSString *)cancelActionTitle
           cancelActionBlock:(void(^)(void))cancelActionBlock
          confirmActionTitle:(NSString *)confirmActionTitle
          confirmActionBlock:(void(^)(void))confirmActionBlock {
    PLVAlertViewController *alert = [PLVAlertViewController alertControllerWithMessage:message cancelActionTitle:cancelActionTitle cancelHandler:cancelActionBlock confirmActionTitle:confirmActionTitle confirmHandler:confirmActionBlock];
    [[PLVLSUtils sharedUtils].homeVC presentViewController:alert animated:NO completion:nil];
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

#pragma mark - Private Method

+ (NSBundle *)LCBundle {
    return [NSBundle bundleForClass:[PLVLSUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName{
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVLSUtils LCBundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
