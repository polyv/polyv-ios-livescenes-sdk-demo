//
//  PLVLiveUtil.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/12.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveUtil.h"
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

CGFloat P_SafeAreaTopEdgeInsets(void) {
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets edgeInsets = UIApplication.sharedApplication.delegate.window.safeAreaInsets;
        return edgeInsets.top;
    } else {
        return 0;
    }
}

CGFloat P_SafeAreaLeftEdgeInsets(void) {
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets edgeInsets = UIApplication.sharedApplication.delegate.window.safeAreaInsets;
        return edgeInsets.left;
    } else {
        return 0;
    }
}

CGFloat P_SafeAreaBottomEdgeInsets(void) {
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets edgeInsets = UIApplication.sharedApplication.delegate.window.safeAreaInsets;
        return edgeInsets.bottom;
    } else {
        return 0;
    }
}

CGFloat P_SafeAreaRightEdgeInsets(void) {
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets edgeInsets = UIApplication.sharedApplication.delegate.window.safeAreaInsets;
        return edgeInsets.right;
    } else {
        return 0;
    }
}

@implementation PLVLiveUtil

+ (void)drawViewCornerRadius:(UIView *)view cornerRadii:(CGSize)cornerRadii corners:(UIRectCorner)corners {
    [self drawViewCornerRadius:view size:view.bounds.size cornerRadii:cornerRadii corners:corners];
}

+ (void)drawViewCornerRadius:(UIView *)view size:(CGSize)size cornerRadii:(CGSize)cornerRadii corners:(UIRectCorner)corners {
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:cornerRadii];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    view.layer.mask = maskLayer;
}

#pragma mark - HUD

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view {
    NSLog(@"HUD info title:%@,detail:%@",title,detail);
    if (view == nil) {
        return;
    }
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = title;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:2.0];
}

#pragma mark - Common

+ (UIViewController *)getCurrentViewController{
    UIViewController* currentViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    BOOL runLoopFind = YES;
    while (runLoopFind) {
        if (currentViewController.presentedViewController) {
            currentViewController = currentViewController.presentedViewController;
        } else if ([currentViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController* navigationController = (UINavigationController* )currentViewController;
            currentViewController = [navigationController.childViewControllers lastObject];
        } else if ([currentViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController* tabBarController = (UITabBarController* )currentViewController;
            currentViewController = tabBarController.selectedViewController;
        } else {
            NSUInteger childViewControllerCount = currentViewController.childViewControllers.count;
            if (childViewControllerCount > 0) {
                currentViewController = currentViewController.childViewControllers.lastObject;
                return currentViewController;
            } else {
                return currentViewController;
            }
        }
    }
    return currentViewController;
}

+ (BOOL)isiPhoneXSeries{
    BOOL isPhoneX = NO;
    if (PLV_iOSVERSION_Available_11_0) { isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0; }
    return isPhoneX;
}

+ (void)changeDeviceOrientationToPortrait{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIDeviceOrientationPortrait;  // 强制把设备UIDevice的方向设置为竖屏
        [invocation setArgument:&val atIndex:2];// 从2开始，因为0 1 两个参数已经被selector和target占用
        [invocation invoke];
    }
}

@end
