//
//  PLVStreamerComplianceReminderViewController.h
//  PolyvLiveScenesDemo
//
//  Created by PLV on 2026/8/31.
//  Copyright © 2026 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播合规提醒弹窗
@interface PLVStreamerComplianceReminderViewController : UIViewController

/// 创建合规提醒弹窗
/// @param title 标题
/// @param content HTML 格式的正文
/// @param disagreeHandler 点击“不同意”后的回调
/// @param agreeHandler 点击“同意”后的回调
+ (instancetype)complianceReminderControllerWithTitle:(NSString *)title
                                               content:(NSString *)content
                                      disagreeHandler:(void (^)(void))disagreeHandler
                                         agreeHandler:(void (^)(void))agreeHandler;

@end

NS_ASSUME_NONNULL_END
