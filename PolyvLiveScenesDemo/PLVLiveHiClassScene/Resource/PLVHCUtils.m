//
//  PLVHCUtils.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCUtils.h"
#import "PLVHCAlertView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCUtils ()

@property (nonatomic, assign) UIEdgeInsets areaInsets;
/// 当前屏幕方向，缺省值为UIInterfaceOrientationLandscapeRight
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@end

@implementation PLVHCUtils

#pragma mark - [ Public Method ]

+ (instancetype)sharedUtils {
    static PLVHCUtils *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PLVHCUtils alloc] init];
        instance.interfaceOrientation = UIInterfaceOrientationLandscapeRight;
    });
    return instance;
}

- (void)setupAreaInsets:(UIEdgeInsets)areaInsets {
    self.areaInsets = areaInsets;
}

- (void)setupInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight ||
        interfaceOrientation == UIInterfaceOrientationLandscapeLeft) { // 主视图只支持左右旋转，避免其他方向污染
        self.interfaceOrientation = interfaceOrientation;
    }
}

#pragma mark Toast

+ (void)showToastInWindowWithMessage:(NSString *)message {
    [PLVHCHiClassToast showToastWithMessage:message];
}

+ (void)showToastWithType:(PLVHCToastType)type message:(NSString *)message {
    [PLVHCHiClassToast showToastWithType:type message:message];
}

#pragma mark Alert

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
         cancelActionTitle:(NSString * _Nullable)cancelActionTitle
         cancelActionBlock:(void(^ _Nullable)(void))cancelActionBlock
        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
        confirmActionBlock:(void(^)(void))confirmActionBlock {
    if (![PLVFdUtil checkStringUseable:title] ||
        ![PLVFdUtil checkStringUseable:message]) {
        return;
    }
    [PLVHCAlertView alertViewWithTitle:title message:message cancelTitle:cancelActionTitle confirmTitle:confirmActionTitle cancelActionBlock:cancelActionBlock confirmActionBlock:confirmActionBlock];
}

+ (void)showAlertWithMessage:(NSString *)message cancelActionTitle:(NSString *)cancelActionTitle cancelActionBlock:(void (^)(void))cancelActionBlock confirmActionTitle:(NSString *)confirmActionTitle confirmActionBlock:(void (^)(void))confirmActionBlock {
    if (![PLVFdUtil checkStringUseable:message]) {
        return;
    }
    
    [PLVHCAlertView alertViewWithTitle:nil message:message cancelTitle:cancelActionTitle confirmTitle:confirmActionTitle cancelActionBlock:cancelActionBlock confirmActionBlock:confirmActionBlock];
}

#pragma mark Image

+ (UIImage *)imageForLiveroomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVHCLiveroom" imageName:imageName];
}

+ (UIImage *)imageForStatusbarResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVHCStatusbar" imageName:imageName];
}

+ (UIImage *)imageForToolbarResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVHCToolbar" imageName:imageName];
}

+ (UIImage *)imageForDocumentResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVHCDocument" imageName:imageName];
}

+ (UIImage *)imageForMemberResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVHCMember" imageName:imageName];
}

+ (UIImage *)imageForChatroomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVHCChatroom" imageName:imageName];
}

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVHCLinkMic" imageName:imageName];
}

#pragma mark NSBundle

+ (NSBundle *)bundlerForLiveroom {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVHCUtils bundle] pathForResource:@"PLVHCLiveroom" ofType:@"bundle"]];
    return resourceBundle;
}

#pragma mark UIWindow

+ (UIWindow *)getCurrentWindow {
    return [PLVFdUtil getFirstUIWindowFormUIApplication];
}

#pragma mark Getter
- (BOOL)isPad {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

#pragma mark - [ Private Method ]

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:[PLVHCUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVHCUtils bundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
