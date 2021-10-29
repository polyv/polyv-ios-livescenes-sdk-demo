//
//  PLVHCTeacherLoginManager.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/9/6.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCTeacherLoginManager.h"
#import "PLVHCLaunchScreenViewController.h"
#import "PLVHCNavigationController.h"
#import "PLVHCChooseLessonViewController.h"
#import "PLVHCHiClassViewController.h"
#import "PLVHCChooseRoleViewController.h"
#import "PLVHCTeacherLogoutAlertView.h"

#import "PLVRoomLoginClient.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

//当前用户昵称Key
static NSString *const PLVHCTeacherTokenLoginKey = @"PLVHCTeacherTokenLoginKey";

@interface PLVHCTeacherLoginManager()

@property (nonatomic, strong, readonly) UIWindow *currentWindow;

@end

@implementation PLVHCTeacherLoginManager

#pragma mark Getter & Setter

- (UIWindow *)currentWindow {
    if ([UIApplication sharedApplication].delegate.window) {
        return [UIApplication sharedApplication].delegate.window;
    } else {
        if (@available(iOS 13.0, *)) { // iOS 13.0+
            NSArray *array = [[[UIApplication sharedApplication] connectedScenes] allObjects];
            UIWindowScene *windowScene = (UIWindowScene *)array[0];
            UIWindow *window = [windowScene valueForKeyPath:@"delegate.window"];
            if (!window) {
                window = [UIApplication sharedApplication].windows.firstObject;
            }
            return window;
        } else {
            return [UIApplication sharedApplication].keyWindow;
        }
    }
}

#pragma mark - [ Public Method ]

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static PLVHCTeacherLoginManager *loginManager;
    dispatch_once(&onceToken, ^{
        loginManager = [[self alloc] init];
    });
    return loginManager;
}

+ (PLVHCTokenLoginModel *)readLoginInfo {
    return [[self sharedInstance] readTeacherLoginInfo];
}

+ (void)updateTeacherLoginInfo:(PLVHCTokenLoginModel *)loginInfo {
    if (!loginInfo) {
        return;
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:loginInfo];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:data forKey:PLVHCTeacherTokenLoginKey];
    [userDefaults synchronize];
}

+ (void)clearTeacherLoginInfo {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:PLVHCTeacherTokenLoginKey];
    [userDefaults synchronize];
}

+ (void)updateTeacherLoginLessonId:(NSString * _Nullable)lessonId {
    PLVHCTokenLoginModel *localLoginInfo = [[self sharedInstance] readTeacherLoginInfo];
    if (!localLoginInfo) {
        return;
    }
    
    localLoginInfo.lessonId = lessonId;
    [self updateTeacherLoginInfo:localLoginInfo];
}

+ (void)loadMainViewController {
    [[self sharedInstance] loadMainViewController];
}

+ (void)teacherExitClassroomFromViewController:(UIViewController *)viewController {
    [[self sharedInstance] teacherExitClassroomFromViewController:viewController];
}

+ (void)teacherLogoutFromViewController:(UIViewController *)viewController {
    [[self sharedInstance] teacherLogoutFromViewController:viewController];
 }

#pragma mark - [ Private Method ]

- (PLVHCTokenLoginModel *)readTeacherLoginInfo {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *teacherData = [userDefaults objectForKey:PLVHCTeacherTokenLoginKey];
    PLVHCTokenLoginModel *teacherInfo = [NSKeyedUnarchiver unarchiveObjectWithData:teacherData];
    return teacherInfo;
}

- (void)loadMainViewController {
    [self setupLaunchScreenViewController];
    
    PLVHCTokenLoginModel *loginModel = [self readTeacherLoginInfo];
    if (loginModel) {
        if (loginModel.token) {
            [PLVLiveVClassAPI setTeachToken:loginModel.token];
        }
        if (loginModel.lessonId) {
            [self setupClassroomRootViewController];
        } else {
            [self setupChooseLessonRootViewController];
        }
    } else {
        [self setupChooseRoleRootViewController];
    }
}

- (void)teacherExitClassroomFromViewController:(UIViewController *)viewController {
    BOOL success = [self popToViewControllerName:@"PLVHCChooseLessonViewController" fromViewController:viewController];
    if (!success) {
        [self setupChooseLessonRootViewController];
    }
}

- (void)teacherLogoutFromViewController:(UIViewController *)viewController {
    BOOL success = [self popToViewControllerName:@"PLVHCChooseRoleViewController" fromViewController:viewController];
     if (!success) {
         [self setupChooseRoleRootViewController];
     }
 }

- (BOOL)popToViewControllerName:(NSString *)toVCName
             fromViewController:(UIViewController *)fromVC {
    Class toVCClassName = NSClassFromString(toVCName);
    __block UIViewController *toViewController = nil;
    [fromVC.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull controller, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([controller isKindOfClass:toVCClassName]) {
            toViewController = controller;
            *stop = YES;
        }
    }];
    if (toViewController) {
        [fromVC.navigationController popToViewController:toViewController animated:YES];
        return YES;
    }
    
    return NO;
}

- (void)setupLaunchScreenViewController {
    if (!self.currentWindow.rootViewController) {
        //加载启动页
        PLVHCLaunchScreenViewController *launchScreenVC = [[PLVHCLaunchScreenViewController alloc] init];
        self.currentWindow.rootViewController = launchScreenVC;
    }
}

- (void)setupClassroomRootViewController {
    PLVHCTokenLoginModel *loginModel = [self readTeacherLoginInfo];
    __weak typeof(self) weakSelf = self;
    void(^successBlock)(void) = ^() {
        [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
        PLVHCHiClassViewController *vctrl = [[PLVHCHiClassViewController alloc] initWithHideDevicePreview:YES];
        PLVHCNavigationController *navController = [[PLVHCNavigationController alloc] initWithRootViewController:vctrl];
        navController.navigationBar.hidden = YES;
        //避免主视图切换时卡顿
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [weakSelf setupRootViewController:navController];
         });
    };
    [PLVRoomLoginClient teacherEnterHiClassWithViewerId:loginModel.userId viewerName:loginModel.nickname lessonId:loginModel.lessonId
                                                completion:successBlock
                                                   failure:^(NSString * _Nonnull errorMessage) {
        [weakSelf logoutForRequestFailure:errorMessage];
    }];
}

- (void)setupChooseLessonRootViewController {
    PLVHCTokenLoginModel *loginModel = [self readTeacherLoginInfo];
    PLVHCChooseLessonViewController *vctrl = [[PLVHCChooseLessonViewController alloc] initWithViewerId:loginModel.userId viewerName:loginModel.nickname teacher:YES lessonArray:@[]];
    PLVHCNavigationController *navController = [[PLVHCNavigationController alloc] initWithRootViewController:vctrl];
    navController.navigationBar.hidden = YES;
    [self setupRootViewController:navController];
}

- (void)setupChooseRoleRootViewController {
    PLVHCChooseRoleViewController *vctrl = [[PLVHCChooseRoleViewController alloc] init];
    PLVHCNavigationController *navController = [[PLVHCNavigationController alloc] initWithRootViewController:vctrl];
    navController.navigationBar.hidden = YES;
    [self setupRootViewController:navController];
}

- (void)setupRootViewController:(UIViewController *)viewController {
    UIWindow *window = self.currentWindow;
    [UIView transitionWithView:window duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        BOOL oldState = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        window.rootViewController = viewController;
        [UIView setAnimationsEnabled:oldState];
    } completion:nil];
}

- (void)logoutForRequestFailure:(NSString *)errorMessage {
    [PLVHCTeacherLoginManager clearTeacherLoginInfo];
    [PLVHCTeacherLogoutAlertView alertViewInView:self.currentWindow title:@"提示" message:errorMessage confirmTitle:@"确认" confirmCallback:^{
        [self setupChooseRoleRootViewController];
    }];
}

@end
