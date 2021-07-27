//
//  PLVToast.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 手机开播通用 toast
@interface PLVToast : UIView

/// 显示 toast
/// @param message toast 文本
/// @param view toast 在视图
+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
