//
//  PLVHCBroadcastAlertView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/12/17.
//  Copyright © 2021 PLV. All rights reserved.
// 广播通知弹窗

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/**
 * 定义Block回调事件
 */
typedef void(^PLVHCBroadcastAlertViewBlock)(void);

@interface PLVHCBroadcastAlertView : UIView

/// 互动学堂广播通知弹窗
/// @param message 内容
/// @param confirmActionBlock 确认点击回调
+ (void)showAlertViewWithMessage:(NSString *)message
                confirmActionBlock:(PLVHCBroadcastAlertViewBlock _Nullable)confirmActionBlock;

@end

NS_ASSUME_NONNULL_END
