//
//  PLVLivePictureInPictureRestoreManager.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/16.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLivePictureInPictureRestoreManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVLivePictureInPictureRestoreManager ()
@property (nonatomic, strong) UINavigationController *holdingNavigation;
@end

@implementation PLVLivePictureInPictureRestoreManager

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    if (self = [super init]) {
        [self addObserver];
    }
    return self;
}

#pragma mark - [ Public Method ]

+ (instancetype)sharedInstance {
    static PLVLivePictureInPictureRestoreManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });
    return _sharedInstance;
}

- (void)cleanRestoreManager {
    self.holdingViewController = nil;
    self.holdingNavigation = nil;
    self.restoreWithPresent = NO;
}

#pragma mark - [ Private Method ]
- (void)addObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - Getter & Setter
- (void)setHoldingViewController:(UIViewController *)holdingViewController {
    _holdingViewController = holdingViewController;
    self.holdingNavigation = holdingViewController.navigationController;
}

#pragma mark - [ Delegate ]

#pragma mark - PLVLivePictureInPictureRestoreDelegate

-(void)plvPictureInPictureRestoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    // 点击画中画恢复按钮，先执行这里的代码执行恢复逻辑，然后再关闭画中画
    if (self.holdingNavigation) {
        NSArray *vcArray = self.holdingNavigation.viewControllers;
        NSInteger index = -1;
        for (NSInteger i = 0; i < vcArray.count; i++) {
            UIViewController *child = vcArray[i];
            if ([child isEqual:self.holdingViewController]) {
                index = i;
            }
        }
        if (index == -1) {
            // 不在导航栈内
            [self.holdingNavigation pushViewController:self.holdingViewController animated:YES];
        }
        else if (index == vcArray.count - 1) {
            // 在栈顶，则直接恢复
        }else {
            [self.holdingNavigation popToViewController:self.holdingViewController animated:YES];
        }
    }
    else {
        UIViewController *currentViewController = [PLVFdUtil getCurrentViewController];
        if (currentViewController != self.holdingViewController) {
            if (self.restoreWithPresent) {
                [currentViewController presentViewController:self.holdingViewController animated:YES completion:nil];
            }else {
                [currentViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
    [self cleanRestoreManager];
    completionHandler(YES);
}

- (void)applicationDidBecomeActive{
    UIViewController *currentViewController = [PLVFdUtil getCurrentViewController];
    if (self.holdingViewController && currentViewController == self.holdingViewController) {
        // 回到前台，如果当前是开启画中画的页面，需要关闭画中画，以播放器模式播放
        // 延迟0.3秒 否则stopPictureInPicture 不生效
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive &&
                [PLVLivePictureInPictureManager sharedInstance].isAutoStarted) {
                // 暂停 画中画
                [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
            }
        });
    }
}

@end
