//
//  PLVScreenshotHelper.m
//  PLVLiveScenesDemo
//
//  Created by PLV on 2026/10/9.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVScreenshotHelper.h"
#import "PLVLiveToast.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVAuthorizationManager.h>

static BOOL PLVShowScreenshotView = YES;

@interface PLVScreenshotHelper ()

@property (nonatomic, weak) UIView *hostView;

@end

@implementation PLVScreenshotHelper

+ (BOOL)isShowScreenshotView {
    if ([PLVRoomDataManager sharedManager].roomData.systemScreenShotProtect) {
        return NO;
    }
    return PLVShowScreenshotView;
}

+ (void)setShowScreenshotView:(BOOL)showScreenshotView {
    PLVShowScreenshotView = showScreenshotView;
}

+ (instancetype)sharedHelper {
    static PLVScreenshotHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[PLVScreenshotHelper alloc] init];
    });
    return helper;
}

+ (void)startScreenCaptureFromView:(UIView *)view {
    if (!view || ![self isShowScreenshotView]) {
        return;
    }
    PLVScreenshotHelper *helper = [PLVScreenshotHelper sharedHelper];
    helper.hostView = view;
    PLVAuthorizationStatus status = [PLVAuthorizationManager authorizationStatusWithType:PLVAuthorizationTypePhotoLibrary];
    if (status == PLVAuthorizationStatusAuthorized) {
        [helper captureAndSave];
        return;
    }
    if (status == PLVAuthorizationStatusDenied || status == PLVAuthorizationStatusRestricted) {
        UIViewController *viewController = [helper topViewControllerFromView:view];
        [PLVAuthorizationManager showAlertWithTitle:PLVLocalizedString(@"提示")
                                            message:PLVLocalizedString(@"保存图片所需的存储权限被拒绝，请到应用设置的权限管理中恢复")
                                     viewController:viewController];
        return;
    }
    [PLVAuthorizationManager requestAuthorizationWithType:PLVAuthorizationTypePhotoLibrary completion:^(BOOL granted) {
        if (granted) {
            [helper captureAndSave];
        } else {
            [helper showMessage:PLVLocalizedString(@"请允许存储权限后再保存图片")];
        }
    }];
}

- (void)captureAndSave {
    UIView *hostView = self.hostView;
    UIWindow *window = hostView.window ?: [self keyWindow];
    if (!window) {
        [self showMessage:PLVLocalizedString(@"保存图片失败")];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![PLVScreenshotHelper isShowScreenshotView]) {
            return;
        }
        UIImage *image = [self imageFromWindow:window];
        if (!image) {
            [self showMessage:PLVLocalizedString(@"保存图片失败")];
            return;
        }
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    });
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        [self showMessage:PLVLocalizedString(@"保存图片失败")];
    } else {
        [self showMessage:PLVLocalizedString(@"图片已保存到系统相册")];
    }
}

- (UIImage *)imageFromWindow:(UIWindow *)window {
    CGRect bounds = window.bounds;
    if (CGRectIsEmpty(bounds)) {
        return nil;
    }
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = window.screen.scale;
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:bounds.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        [window drawViewHierarchyInRect:bounds afterScreenUpdates:YES];
    }];
}

- (UIWindow *)keyWindow {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]] || scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return UIApplication.sharedApplication.keyWindow;
}

- (UIViewController *)topViewControllerFromView:(UIView *)view {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return self.keyWindow.rootViewController;
}

- (void)showMessage:(NSString *)message {
    UIView *hostView = self.hostView.window ?: self.hostView;
    if (!hostView) {
        hostView = [self keyWindow];
    }
    if (!hostView) {
        return;
    }
    [PLVLiveToast showToastWithMessage:message inView:hostView];
}

@end
