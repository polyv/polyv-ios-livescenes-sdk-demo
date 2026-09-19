//
//  PLVStreamerComplianceReminderManager.h
//  PolyvLiveScenesDemo
//
//  Created by PLV on 2026/8/31.
//  Copyright © 2026 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播合规提醒管理器
@interface PLVStreamerComplianceReminderManager : NSObject

/// 初始化管理器，内部会固定当前频道和用户角色
- (instancetype)initWithPresentingViewController:(UIViewController *)presentingViewController;

/// 预请求当前用户的合规提醒配置
- (void)requestComplianceReminder;

/// 嘉宾进入三分屏开播页面时调用；配置加载完成后自动展示提醒
- (void)showComplianceReminderForGuestWhenReady;

/// 开播前检查合规提醒；无需确认、请求失败或等待超过 3 秒时直接执行 completion
- (void)checkComplianceReminderWithCompletion:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
