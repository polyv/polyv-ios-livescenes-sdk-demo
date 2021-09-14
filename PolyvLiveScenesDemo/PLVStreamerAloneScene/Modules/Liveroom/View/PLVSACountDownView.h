//
//  PLVSACountDownView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//
// 直播开始时倒计时视图，覆盖在 PLVSAStreamerViewController 之上

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSACountDownView : UIView

/// 倒计时结束回调
@property (nonatomic, strong) void (^countDownCompletedHandler) (void);

/// 开始倒计时
- (void)startCountDown;

@end

NS_ASSUME_NONNULL_END
