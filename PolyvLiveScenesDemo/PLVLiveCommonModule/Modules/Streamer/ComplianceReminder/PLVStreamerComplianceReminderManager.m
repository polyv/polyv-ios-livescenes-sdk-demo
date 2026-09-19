//
//  PLVStreamerComplianceReminderManager.m
//  PolyvLiveScenesDemo
//
//  Created by PLV on 2026/8/31.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVStreamerComplianceReminderManager.h"

#import "PLVStreamerComplianceReminderViewController.h"
#import "PLVAlertViewController.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"

#import <PLVLiveScenesSDK/PLVLiveVideoAPI.h>

static NSTimeInterval const kPLVComplianceReminderBusinessTimeout = 3.0;
static NSString *const kPLVComplianceReminderConfirmedVersionKeyPrefix = @"PLVStreamerComplianceReminder_Confirmed";

typedef NS_ENUM(NSUInteger, PLVComplianceReminderRequestState) {
    PLVComplianceReminderRequestStateIdle = 0,
    PLVComplianceReminderRequestStateLoading,
    PLVComplianceReminderRequestStateFinished
};

@interface PLVStreamerComplianceReminderManager ()

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSString *role;
@property (nonatomic, assign) PLVComplianceReminderRequestState requestState;
@property (nonatomic, strong) PLVComplianceReminderModel *reminderModel;
@property (nonatomic, copy) dispatch_block_t pendingAction;
@property (nonatomic, copy) dispatch_block_t confirmationAction;
@property (nonatomic, assign) BOOL showWhenLoaded;
@property (nonatomic, assign) BOOL failOpen;
@property (nonatomic, strong) PLVStreamerComplianceReminderViewController *reminderViewController;
@property (nonatomic, strong) PLVAlertViewController *disagreeViewController;

@end

@implementation PLVStreamerComplianceReminderManager

#pragma mark - [ Life Cycle ]

- (instancetype)initWithPresentingViewController:(UIViewController *)presentingViewController {
    self = [super init];
    if (self) {
        _presentingViewController = presentingViewController;
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        _channelId = [roomData.channelId copy];
        if (roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
            _role = @"Teacher";
        } else if (roomData.roomUser.viewerType == PLVRoomUserTypeGuest) {
            _role = @"Guest";
        }
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)requestComplianceReminder {
    if (self.requestState != PLVComplianceReminderRequestStateIdle) {
        return;
    }
    if (self.channelId.length == 0 || self.role.length == 0) {
        self.requestState = PLVComplianceReminderRequestStateFinished;
        self.failOpen = YES;
        return;
    }

    self.requestState = PLVComplianceReminderRequestStateLoading;
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI requestComplianceReminderWithChannelId:self.channelId role:self.role completion:^(PLVComplianceReminderModel *model) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleRequestSuccess:model];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleRequestFailure];
        });
    }];
}

- (void)showComplianceReminderForGuestWhenReady {
    if (![self.role isEqualToString:@"Guest"] || self.failOpen) {
        return;
    }
    if (self.requestState == PLVComplianceReminderRequestStateIdle) {
        [self requestComplianceReminder];
    }
    if (self.requestState == PLVComplianceReminderRequestStateFinished) {
        [self showComplianceReminderIfNeededWithAction:nil];
    } else {
        self.showWhenLoaded = YES;
    }
}

- (void)checkComplianceReminderWithCompletion:(dispatch_block_t)completion {
    if (!completion) {
        return;
    }
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf checkComplianceReminderWithCompletion:completion];
        });
        return;
    }
    if (self.failOpen) {
        completion();
        return;
    }
    if (self.requestState == PLVComplianceReminderRequestStateIdle) {
        [self requestComplianceReminder];
    }
    if (self.requestState == PLVComplianceReminderRequestStateFinished) {
        [self showComplianceReminderIfNeededWithAction:completion];
        return;
    }
    if (self.pendingAction) {
        return;
    }

    self.pendingAction = completion;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPLVComplianceReminderBusinessTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!weakSelf.pendingAction) {
            return;
        }
        dispatch_block_t action = weakSelf.pendingAction;
        weakSelf.pendingAction = nil;
        weakSelf.failOpen = YES;
        weakSelf.showWhenLoaded = NO;
        action();
    });
}

#pragma mark - [ Request ]

- (void)handleRequestSuccess:(PLVComplianceReminderModel *)model {
    self.requestState = PLVComplianceReminderRequestStateFinished;
    self.reminderModel = model;
    [self prepareReminderViewControllerIfNeeded];

    if (self.pendingAction) {
        dispatch_block_t action = self.pendingAction;
        self.pendingAction = nil;
        [self showComplianceReminderIfNeededWithAction:action];
    } else if (self.showWhenLoaded) {
        self.showWhenLoaded = NO;
        [self showComplianceReminderIfNeededWithAction:nil];
    }
}

- (void)handleRequestFailure {
    self.requestState = PLVComplianceReminderRequestStateFinished;
    self.reminderModel = nil;
    self.failOpen = YES;
    self.showWhenLoaded = NO;

    if (self.pendingAction) {
        dispatch_block_t action = self.pendingAction;
        self.pendingAction = nil;
        action();
    }
}

#pragma mark - [ Compliance Reminder ]

- (BOOL)needsConfirmation {
    if (self.failOpen || !self.reminderModel.remindEnabled) {
        return NO;
    }
    NSString *confirmedVersion = [[NSUserDefaults standardUserDefaults] stringForKey:[self confirmedVersionDefaultsKey]];
    return ![confirmedVersion isEqualToString:[self currentReminderVersion]];
}

- (NSString *)currentReminderVersion {
    NSString *reminderId = self.reminderModel.reminderId ?: @"";
    return [NSString stringWithFormat:@"%@_%lld", reminderId, self.reminderModel.updateTime];
}

- (NSString *)confirmedVersionDefaultsKey {
    return [NSString stringWithFormat:@"%@_%@_%@", kPLVComplianceReminderConfirmedVersionKeyPrefix, self.channelId, self.role];
}

- (void)prepareReminderViewControllerIfNeeded {
    if (self.reminderViewController || ![self needsConfirmation]) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    self.reminderViewController = [PLVStreamerComplianceReminderViewController complianceReminderControllerWithTitle:self.reminderModel.title
                                                                                                             content:self.reminderModel.content
                                                                                                    disagreeHandler:^{
        [weakSelf handleDisagree];
    } agreeHandler:^{
        [weakSelf handleAgree];
    }];
    // 提前触发 WKWebView 创建及 HTML 加载，避免展示弹窗后才开始渲染正文。
    [self.reminderViewController loadViewIfNeeded];
    self.reminderViewController.view.frame = self.presentingViewController.view.bounds;
    [self.reminderViewController.view setNeedsLayout];
    [self.reminderViewController.view layoutIfNeeded];
}

- (void)showComplianceReminderIfNeededWithAction:(dispatch_block_t)action {
    if (![self needsConfirmation]) {
        self.reminderViewController = nil;
        if (action) {
            action();
        }
        return;
    }

    [self prepareReminderViewControllerIfNeeded];

    UIViewController *presentingViewController = self.presentingViewController;
    if (!presentingViewController.viewIfLoaded.window ||
        presentingViewController.isBeingDismissed ||
        presentingViewController.presentedViewController) {
        if (action) {
            self.failOpen = YES;
            self.reminderViewController = nil;
            action();
        }
        return;
    }

    self.confirmationAction = action;
    [presentingViewController presentViewController:self.reminderViewController animated:NO completion:nil];
}

- (void)handleAgree {
    self.reminderViewController = nil;
    [[NSUserDefaults standardUserDefaults] setObject:[self currentReminderVersion]
                                              forKey:[self confirmedVersionDefaultsKey]];

    dispatch_block_t action = self.confirmationAction;
    self.confirmationAction = nil;
    if (action) {
        action();
    }
}

- (void)handleDisagree {
    UIViewController *presentingViewController = self.presentingViewController;
    if (!presentingViewController.viewIfLoaded.window || presentingViewController.presentedViewController) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    self.disagreeViewController = [PLVAlertViewController alertControllerWithTitle:PLVLocalizedString(@"提示")
                                                                           message:PLVLocalizedString(@"为了您有更好的开播体验，请同意协议后再直播")
                                                                 cancelActionTitle:PLVLocalizedString(@"返回")
                                                                     cancelHandler:^{
        weakSelf.disagreeViewController = nil;
        [weakSelf showComplianceReminderIfNeededWithAction:weakSelf.confirmationAction];
    }
                                                            confirmActionTitle:nil
                                                                confirmHandler:nil];
    [presentingViewController presentViewController:self.disagreeViewController animated:NO completion:nil];
}

@end
